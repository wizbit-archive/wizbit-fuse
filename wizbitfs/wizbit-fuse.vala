using Fuse;
using Posix;
using Wiz;

static const string hello_str = "Hello World!\n";
static const string hello_path = "/hello";

static Wiz.Store store;

public class DirectoryEntryIterator {
	Wiz.Version version;
	char *buf;
	long size;
	long pos;

	public DirectoryEntryIterator(string uuid, string version) {
		this.version = store.open_bit(uuid).open_version(version);
		this.buf = this.version.read_as_string();
		this.size = this.version.get_length();
		this.pos = 0;
	}
	public bool next() {
		return (pos < size);
	}
	public DirectoryEntry get() {
		var de = new DirectoryEntry();

		de.path = (string)this.buf;
		while (pos < size && this.buf[pos] != '\0')
			pos++;
		pos++;

		de.uuid = (string)this.buf;
		while (pos < size && this.buf[pos] != '\0')
			pos++;
		pos++;

		de.version = (string)this.buf;
		while (pos < size && this.buf[pos] != '\0')
			pos++;
		pos++;

		de.mode = (long)((string)this.buf);

		return de;
	}
}

[Compact]
public class DirectoryEntry {
	public string path;
	public string uuid;
	public string version;
	public mode_t mode;

	public DirectoryEntryIterator iterator() {
		return new DirectoryEntryIterator(this.uuid, this.version);
	}

	public DirectoryEntry? find_child(string path_chunk) {
		foreach (var d in this)
			if (d.path == path_chunk)
				return d;
		return null;
	}

	public static DirectoryEntry root() {
		var version = store.open_bit("ROOT").primary_tip;
		var iter = new DirectoryEntryIterator("ROOT", version.version_uuid);
		return iter.get();
	}

	public static DirectoryEntry find(string path) {
		var chunks = path.substring(1).split("/");
		var dirent = DirectoryEntry.root();
		foreach (var chunk in chunks) {
			dirent = dirent.find_child(chunk);
			if (dirent != null)
				break;
		}
		return dirent;
	}
}


static int hello_getattr(string path, stat *stbuf)
{
	int res = 0;

	Memory.set((void *)stbuf, 0, sizeof(stat));

	if (path == "/") {
		stbuf->st_mode = (mode_t)S_IFDIR | 0755;
		stbuf->st_nlink = 2;
	} else if (path == hello_path) {
		stbuf->st_mode = (mode_t)S_IFREG | 0444;
		stbuf->st_nlink = 1;
		stbuf->st_size = hello_str.len();
	} else {
		res = -ENOENT;
	}

	return res;
}

static int hello_readdir(string path, void *buf, FillDir filler, off_t offset, Fuse.FileInfo fi)
{
	if (path != "/")
		return -ENOENT;

	filler(buf, ".", null, 0);
	filler(buf, "..", null, 0);
	filler(buf, "hello", null, 0);

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
	store = new Wiz.Store("~/tmp/");

	var opers = Operations();
	opers.readdir = hello_readdir;
	opers.getattr = hello_getattr;
	opers.open = hello_open;
	opers.read = hello_read;

	return Fuse.main(args, opers, null);
}
