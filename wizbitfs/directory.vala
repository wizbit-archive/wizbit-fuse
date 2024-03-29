using Fuse;
using Posix;
using Wiz;

public class DirectoryEntryIterator {
	Wiz.Commit commit;
	MappedFile mf;
	char *buf;
	long size;
	long pos;

	public DirectoryEntryIterator(string uuid, string? version) {
		this.size = 0;
		this.pos = 0;

		if (store.has_bit(uuid)) {
			this.commit = store.open_bit(uuid).primary_tip;
			if (this.commit != null) {
				this.mf = this.commit.streams.get("data").get_mapped_file();
				this.buf = this.mf.get_contents();
				this.size = this.mf.get_length();
			}
		}
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
		var f = new Wiz.File();
		try {
			f.set_contents("");
			cb.streams.set("data", f);
			var commit = cb.commit();
			var de = new DirectoryEntry();
			de.path = path;
			de.uuid = bit.uuid;
			de.version = commit.version_uuid;
			de.mode = mode;
			this.add_child(de);
		} catch (FileError e) {
			//FIXME
			error ("error creating file %s", e.message);
		}
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
		var f = new Wiz.File();
		try {
			f.set_contents(builder.str);
			cb.streams.set("data", f);
			cb.commit();
		} catch (GLib.FileError e) {
			error ("error saving data: %s", e.message);
		}
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
		var f = new Wiz.File();
		try {
			f.set_contents(builder.str);
			cb.streams.set("data", f);
			cb.commit();
		} catch (GLib.FileError e) {
			error ("error creating file %s", e.message);
		}
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
		var commit = store.open_bit("ROOT").primary_tip;
		de.version = commit.version_uuid;
		de.mode = S_IFDIR | 0755;
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
			var f = new Wiz.File();
			try {
				f.set_contents("");
				cb.streams.set("data", f);
				cb.commit();
			} catch (GLib.FileError e) {
				error ("error creating file %s", e.message);
			}
				
		}
	}
}


