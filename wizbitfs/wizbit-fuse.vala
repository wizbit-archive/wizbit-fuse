using Fuse;
using Posix;
using Wiz;

static Wiz.Store store;

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

static int wizfs_readdir(string path, void *buf, FillDir filler, off_t offset, Fuse.FileInfo fi)
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

static int wizfs_open(string path, Fuse.FileInfo fi)
{
	var de = DirectoryEntry.find(path);
	if (de == null)
		return -ENOENT;

	// All files are read only
	if ((fi.flags & 3) != O_RDONLY)
		return -EACCES;

	return 0;
}


static int wizfs_read(string path, char *buf, size_t size, off_t offset, Fuse.FileInfo fi)
{
	string wizfs_str = "TEST STRING TEST STRING";
	var len = wizfs_str.len();
	if (offset < len) {
		if (offset + size > len)
			size = len - offset;
		Memory.copy(buf, (char *)wizfs_str + offset, size);
	} else {
		size = 0;
	}
	return (int)size;
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

	return Fuse.main(args, opers, null);
}

