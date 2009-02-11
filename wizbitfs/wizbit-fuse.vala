using Fuse;
using Posix;
using Wiz;

static const string hello_str = "Hello World!\n";
static const string hello_path = "/hello";

static Wiz.Store store;

static int hello_getattr(string path, stat *stbuf)
{
	Memory.set((void *)stbuf, 0, sizeof(stat));

	if (path == "/") {
		stbuf->st_mode = S_IFDIR | 0444;
		stbuf->st_nlink = 2;
		return 0;
	}

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

static int hello_readdir(string path, void *buf, FillDir filler, off_t offset, Fuse.FileInfo fi)
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

static int hello_mkdir(string path, mode_t mode)
{
	var de = new DirectoryEntry();
	de.path = Path.get_basename(path);
	de.mode = mode;
	DirectoryEntry.find_containing(path).add_child(de);
	return 0;
}

static int hello_open(string path, Fuse.FileInfo fi)
{
	if (path != hello_path)
		return -ENOENT;

	if ((fi.flags & 3) != O_RDONLY)
		return -EACCES;

	return 0;
}


static int hello_read(string path, char *buf, size_t size, off_t offset, Fuse.FileInfo fi)
{
	if (path != hello_path)
		return -ENOENT;
	var len = hello_str.len();
	if (offset < len) {
		if (offset + size > len)
			size = len - offset;
		Memory.copy(buf, (char *)hello_str + offset, size);
	} else {
		size = 0;
	}
	return (int)size;
}

static int main(string [] args)
{
	store = new Wiz.Store("", "~/tmp/");

	if (!store.has_bit("ROOT"))
		store.open_bit("ROOT").create_next_version_from_string("", null);

	var opers = Operations();
	opers.readdir = hello_readdir;
	opers.mkdir = hello_mkdir;
	opers.getattr = hello_getattr;
	opers.open = hello_open;
	opers.read = hello_read;

	return Fuse.main(args, opers, null);
}

