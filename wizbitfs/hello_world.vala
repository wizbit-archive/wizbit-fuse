using Posix;
using Fuse;

static const string hello_str = "Hello World!\n";
static const string hello_path = "/hello";

static int hello_getattr(string path, stat *stbuf)
{
	int res = 0;

	Memory.set((void *)stbuf, 0, sizeof(stat));

	if (path == "/") {
		stbuf->st_mode = S_IFDIR | 0755;
		stbuf->st_nlink = 2;
	} else if (path == hello_path) {
		stbuf->st_mode = S_IFREG | 0444;
		stbuf->st_nlink = 1;
		stbuf->st_size = hello_str.len();
	} else {
		res = -ENOENT;
	}

	return res;
}

static int hello_readdir(string path, void *buf, FillDir filler, int offset, FileInfo fi)
{
	if (path != "/")
		return -ENOENT;

	filler(buf, ".", null, 0);
	filler(buf, "..", null, 0);
	filler(buf, "hello", null, 0);

	return 0;
}

static int hello_open(string path, FileInfo fi)
{
	if (path != hello_path)
		return -ENOENT;

	if ((fi.flags & 3) != O_RDONLY)
		return -EACCES;

	return 0;
}


static int hello_read(string path, char *buf, size_t size, int offset, FileInfo fi)
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
	var opers = Operations();
	opers.readdir = hello_readdir;
	opers.getattr = hello_getattr;
	opers.open = hello_open;
	opers.read = hello_read;

	return Fuse.main(ref args, opers, null);
}

