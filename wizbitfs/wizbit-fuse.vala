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

	public DirectoryEntryIterator(string uuid, string? version) {
		if (store.has_bit(uuid)) {
			if (version != null && version != "") {
				this.version = store.open_bit(uuid).open_version(version);
				this.buf = this.version.read_as_string();
				this.size = this.version.get_length();
			} else {
				this.size = 0;
			}
		} else {
			this.size = 0;
		}
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
		while (pos < size && this.buf[pos] != '\0')
			pos++;
		pos++;

		return de;
	}
}

[Compact]
public class DirectoryEntry {
	public string path;
	public string uuid;
	public string version;
	public mode_t mode;

	public DirectoryEntry() {
		this.path = "";
		this.uuid = "";
		this.version = "";
		this.mode = 0;
	}

	public DirectoryEntryIterator iterator() {
		return new DirectoryEntryIterator(this.uuid, this.version);
	}

	public DirectoryEntry? find_child(string path_chunk) {
		foreach (var d in this)
			if (d.path == path_chunk)
				return d;
		return null;
	}

	public void add_child(DirectoryEntry de) {
		var builder = new StringBuilder();
		foreach (var thing in this)
			builder.append(thing.as_string());
		builder.append(de.as_string());

		var bit = store.open_bit(this.uuid);
		bit.create_next_version_from_string(builder.str, bit.primary_tip);
	}

	public string as_string() {
		var builder = new StringBuilder();
		builder.append(this.path);
		builder.append_c('\0');
		builder.append(this.uuid);
		builder.append_c('\0');
		builder.append(this.version);
		builder.append_c('\0');
		builder.append(((long)this.mode).to_string());
		builder.append_c('\0');
		return builder.str;
	}

	public static DirectoryEntry root() {
		var version = store.open_bit("ROOT").primary_tip;
		if (version == null) {
			var de = new DirectoryEntry();
			de.uuid = "ROOT";
			return de;
		}
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

	public static DirectoryEntry find_containing(string path) {
		var dirname = Path.get_dirname(path);
		if (dirname == ".")
			return DirectoryEntry.root();
		else
			return DirectoryEntry.find(dirname);
	}
}


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

