using Fuse;
using Posix;
using Wiz;

static Wiz.Store store;
static Wiz.Commit[255] versions;
static StringBuilder[255] new_blobs;

Wiz.Commit? get_version_from_fh(uint64 fh)
{
	if (fh < 0 || fh > 255)
		return null;
	return versions[fh];
}

int wizfs_getattr(string path, stat *stbuf)
{
	Memory.set((void *)stbuf, 0, sizeof(stat));

	var dirent = DirectoryEntry.find(path);
	if (dirent == null)
		return -ENOENT;

	var version = store.open_bit(dirent.uuid).primary_tip;

	stbuf->st_mode = dirent.mode;

	if (S_ISDIR(dirent.mode)) {
		stbuf->st_nlink = 2;
	} else if (S_ISREG(dirent.mode)) {
		stbuf->st_nlink = 1;
		stbuf->st_size = version.get_length();
	}

	return 0;
}

int wizfs_readdir(string path, void *buf, FillDir filler, off_t offset, ref Fuse.FileInfo fi)
{
	var dirent = DirectoryEntry.find(path);
	if (dirent == null)
		return -ENOENT;

	filler(buf, ".", null, 0);
	filler(buf, "..", null, 0);

	foreach (var child in dirent)
		filler(buf, child.path, null, 0);

	return 0;
}

int wizfs_mknod(string path, mode_t mode, dev_t rdev)
{
	var bit = store.create_bit();

	// Always start from an empty string
	var cb = bit.get_commit_builder();
	var f = new Wiz.File();
	f.set_contents("");
	cb.file = f;
	var v = cb.commit();

	var parent = DirectoryEntry.find_containing(path);

	var de = new DirectoryEntry();
	de.path = Path.get_basename(path);
	de.uuid = bit.uuid;
	de.version = v.version_uuid;
	de.mode = mode;
	
	parent.add_child(de);

	return 0;
}

int wizfs_unlink(string path)
{
	DirectoryEntry.find_containing(path).rm(Path.get_basename(path));
	return 0;
}

int wizfs_utimens(string path, timespec[2] ts)
{
	// Pretend this worked when really we don't try to
	// implement it (create/mod times come from DAG)

	return 0;
}

int wizfs_mkdir(string path, mode_t mode)
{
	DirectoryEntry.find_containing(path).mkdir(Path.get_basename(path), S_IFDIR|mode);
	return 0;
}

int wizfs_rmdir(string path)
{
	DirectoryEntry.find_containing(path).rm(Path.get_basename(path));
	return 0;
}

int wizfs_open(string path, ref Fuse.FileInfo fi)
{
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


int wizfs_read(string path, char *buf, size_t size, off_t offset, ref Fuse.FileInfo fi)
{
	var version = get_version_from_fh(fi.fh);
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

int wizfs_write(string path, char *buf, size_t size, off_t offset, ref Fuse.FileInfo fi)
{
	var version = get_version_from_fh(fi.fh);
	if (version == null)
		return -ENOENT;

	if (new_blobs[fi.fh] == null)
		new_blobs[fi.fh] = new StringBuilder();

	new_blobs[fi.fh].append("%.*s".printf(size, buf));

	return (int) size;
}

int wizfs_release(string path, ref Fuse.FileInfo fi)
{
	var commit = get_version_from_fh(fi.fh);
	if (commit == null)
		return -ENOENT;

	if (new_blobs[fi.fh] != null) {
		var cb = commit.get_commit_builder();
		var f = commit.file;
		f.set_contents(new_blobs[fi.fh].str);
		cb.file = f;
		cb.commit();
	}

	versions[fi.fh] = null;

	return 0;
}

static int main(string [] args)
{
	store = new Wiz.Store("", Path.build_filename(Environment.get_home_dir(), "tmp"));
	versions = new Wiz.Commit[255];
	new_blobs = new StringBuilder[255];
	DirectoryEntry.init();

	var opers = Operations();
	opers.readdir = wizfs_readdir;
	opers.mkdir = wizfs_mkdir;
	opers.rmdir = wizfs_rmdir;
	opers.getattr = wizfs_getattr;
	opers.mknod = wizfs_mknod;
	opers.utimens = wizfs_utimens;
	opers.open = wizfs_open;
	opers.read = wizfs_read;
	opers.write = wizfs_write;
	opers.release = wizfs_release;
	opers.unlink = wizfs_unlink;

	return Fuse.main(args, opers, null);
}

