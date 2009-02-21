using Fuse;
using Posix;
using Wiz;

static Wiz.Store store;
static Wiz.Version[255] versions;
static StringBuilder[255] new_blobs;

static Wiz.Version? get_version_from_fh(ref Fuse.FileInfo fi)
{
	if (fi.fh < 0 || fi.fh > 255)
		return null;
	return versions[fi.fh];
}

static int wizfs_getattr(string path, stat *stbuf)
{
	stdout.printf("getattr('%s')\n", path);

	Memory.set((void *)stbuf, 0, sizeof(stat));

	var dirent = DirectoryEntry.find(path);
	if (dirent == null)
		return -ENOENT;

	stbuf->st_mode = dirent.mode;

	if (S_ISDIR(dirent.mode)) {
		stbuf->st_nlink = 2;
	} else if (S_ISREG(dirent.mode)) {
		stbuf->st_nlink = 1;
		stbuf->st_size = 0;
	}

	return 0;
}

static int wizfs_readdir(string path, void *buf, FillDir filler, off_t offset, ref Fuse.FileInfo fi)
{
	stdout.printf("readdir('%s')\n", path);
	var dirent = DirectoryEntry.find(path);
	if (dirent == null)
		return -ENOENT;

	filler(buf, ".", null, 0);
	filler(buf, "..", null, 0);

	foreach (var child in dirent)
		filler(buf, child.path, null, 0);

	return 0;
}

static int wizfs_mkdir(string path, mode_t mode)
{
	stdout.printf("mkdir('%s')\n", path);
	DirectoryEntry.find_containing(path).mkdir(Path.get_basename(path), S_IFDIR|mode);
	return 0;
}

static int wizfs_rmdir(string path)
{
	stdout.printf("rmdir('%s')\n", path);
	DirectoryEntry.find_containing(path).rm(Path.get_basename(path));
	return 0;
}

static int wizfs_open(string path, ref Fuse.FileInfo fi)
{
	stdout.printf("open('%s')\n", path);

	var de = DirectoryEntry.find(path);
	if (de == null)
		return -ENOENT;

	// Find an empty slot
	int fd = -1;
	for (int i=0; i<255; i++) {
		if (versions[i] == null) {
			fd = i;
			break;	
		}
	}

	// If we don't have an open slot, return 'you can not has' error
	if (fd == -1)
		return -EACCES;

	versions[fd] = store.open_bit(de.uuid).primary_tip;
	fi.fh = fd;

	return 0;
}


static int wizfs_read(string path, char *buf, size_t size, off_t offset, ref Fuse.FileInfo fi)
{
	stdout.printf("read('%s', %l, %l)\n", path, (long) size, (long) offset);

	var version = get_version_from_fh(fi);
	if (version == null)
		return -ENOENT;

	char *blob = version.read_as_string();
	long len = version.get_length();

	if (offset < len) {
		if (offset + size > len)
			size = len - offset;
		Memory.copy(buf, blob + offset, size);
	} else {
		size = 0;
	}

	return (int) size;
}

static int wizfs_write(string path, char *buf, size_t size, off_t offset, ref Fuse.FileInfo fi)
{
	stdout.printf("write('%s', %l, %l)\n", path, (long) size, (long) offset);

	var version = get_version_from_fh(fi);
	if (version == null)
		return -ENOENT;

	if (new_blobs[fi.fh] == null)
		new_blobs[fi.fh] = new StringBuilder();

	new_blobs[fi.fh].append("%.*s".printf(size, buf));

	return -EACCES;
}

static int wizfs_release(string path, ref Fuse.FileInfo fi)
{
	stdout.printf("release('%s')\n", path);

	var version = get_version_from_fh(fi);
	if (version == null)
		return -ENOENT;

	if (new_blobs[fi.fh] != null) {
		var cb = version.get_commit_builder();
		cb.blob = new_blobs[fi.fh].str;
		cb.commit();
	}

	versions[fi.fh] = null;

	return 0;
}

static int main(string [] args)
{
	store = new Wiz.Store("", Path.build_filename(Environment.get_home_dir(), "tmp"));
	DirectoryEntry.init();

	var opers = Operations();
	opers.readdir = wizfs_readdir;
	opers.mkdir = wizfs_mkdir;
	opers.rmdir = wizfs_rmdir;
	opers.getattr = wizfs_getattr;
	opers.open = wizfs_open;
	opers.read = wizfs_read;
	opers.write = wizfs_write;
	opers.release = wizfs_release;

	return Fuse.main(args, opers, null);
}

