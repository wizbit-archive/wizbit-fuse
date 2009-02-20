using Fuse;
using Posix;
using Wiz;

public class DirectoryEntryIterator {
	Wiz.Version version;
	char *buf;
	long size;
	long pos;

	public DirectoryEntryIterator(string uuid, string? version) {
		this.size = 0;
		this.pos = 0;

		if (store.has_bit(uuid)) {
			this.version = store.open_bit(uuid).primary_tip;
			if (this.version != null) {
				this.buf = this.version.read_as_string();
				this.size = this.version.get_length();
			}
		}

		stdout.printf("Iterating %s @ %s\n", uuid, version);
	}
	public bool next() {
		return (pos < size);
	}
	public DirectoryEntry get() {
		var de = new DirectoryEntry();

		var old = pos;

		while (pos < size && this.buf[pos] != '\t')
			pos++;
		de.path = ((string)this.buf).substring(old, pos-old);
		old = pos = pos+1;

		while (pos < size && this.buf[pos] != '\t')
			pos++;
		de.uuid = ((string)this.buf).substring(old, pos-old);
		old = pos = pos+1;

		while (pos < size && this.buf[pos] != '\t')
			pos++;
		de.version = ((string)this.buf).substring(old, pos-old);
		old = pos = pos+1;

		while (pos < size && this.buf[pos] != '\t')
			pos++;
		de.mode = ((string)this.buf).substring(old, pos-old).to_int();
		old = pos = pos+1;

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

	public void mkdir(string path, mode_t mode) {
		var bit = store.create_bit();
		var cb = bit.get_commit_builder();
		cb.blob = "";
		var version = cb.commit();
		var de = new DirectoryEntry();
		de.path = path;
		de.uuid = bit.uuid;
		de.version = version.version_uuid;
		de.mode = mode;
		this.add_child(de);
	}

	public void rm(string path) {
		var builder = new StringBuilder();
		foreach (var de in this)
			if (de.path != path)
				builder.append(de.as_string());

		var bit = store.open_bit(this.uuid);
		var cb = bit.get_commit_builder();
		if (bit.primary_tip != null)
			cb.add_parent(bit.primary_tip);
		cb.blob = builder.str;
		cb.commit();
	}

	public void add_child(DirectoryEntry de) {
		var builder = new StringBuilder();
		foreach (var thing in this)
			builder.append(thing.as_string());
		builder.append(de.as_string());

		var bit = store.open_bit(this.uuid);
		var cb = bit.get_commit_builder();
		if (bit.primary_tip != null)
			cb.add_parent(bit.primary_tip);
		cb.blob = builder.str;
		cb.commit();
	}

	public string as_string() {
		var builder = new StringBuilder();
		builder.append(this.path);
		builder.append_c('\t');
		builder.append(this.uuid);
		builder.append_c('\t');
		builder.append(this.version);
		builder.append_c('\t');
		builder.append(((long)this.mode).to_string());
		builder.append_c('\t');
		return builder.str;
	}

	public static DirectoryEntry root() {
		var de = new DirectoryEntry();
		de.path = "";
		de.uuid = "ROOT";
		var version = store.open_bit("ROOT").primary_tip;
		de.version = version.version_uuid;
		de.mode = S_IFDIR | 0666;
		return de;
	}

	public static DirectoryEntry find(string path) {
		var chunks = path.substring(1).split("/");
		var dirent = DirectoryEntry.root();
		foreach (var chunk in chunks) {
			dirent = dirent.find_child(chunk);
			if (dirent == null)
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

	public static void init() {
		if (!store.has_bit("ROOT")) {
			var cb = store.open_bit("ROOT").get_commit_builder();
			cb.blob = "";
			cb.commit();
		}
	}
}


