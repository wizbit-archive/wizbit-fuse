using Fuse;
using Posix;
using Wiz;

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

		var old = pos;

		while (pos < size && this.buf[pos] != '\0')
			pos++;
		de.path = ((string)this.buf).substring(pos, old-pos);
		old = pos = pos+1;

		while (pos < size && this.buf[pos] != '\0')
			pos++;
		de.uuid = ((string)this.buf).substring(pos, old-pos);
		old = pos = pos+1;

		while (pos < size && this.buf[pos] != '\0')
			pos++;
		de.version = ((string)this.buf).substring(pos, old-pos);
		old = pos+1;

		while (pos < size && this.buf[pos] != '\0')
			pos++;
		de.mode = ((string)this.buf).substring(pos, old-pos).to_int();
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


