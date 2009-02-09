using GLib;
using Posix;

[CCode (cprefix="fuse_", cheader_filename="fuse/fuse.h")]
namespace Fuse {
	[CCode (cname="struct fuse_file_info")]
	public struct FileInfo {
		public int flags;
		public ulong fh_old;
		public int writepage;
		public uint direct_io;
		public uint keep_cache;
		public uint flush;
		public uint padding;
		public uint64 fh;
		public uint64 lock_owner;
	}

	[CCode (cname="fuse_fill_dir_t")]
	public static delegate int FillDir(void *buf, string name, stat? st, int offset);

	public static delegate int GetAttr(string path, stat *st);
	public static delegate int ReadDir(string path, void *buf, FillDir filler, int offset, FileInfo fi);
	public static delegate int Open(string path, FileInfo fi);
	public static delegate int Read(string path, char *buf, size_t size, int offset, FileInfo fi);

	[CCode (cname="struct fuse_operations")]
	public struct Operations {
		public GetAttr getattr;
		public ReadDir readdir;
		public Open open;
		public Read read;
	}

	public int main([CCode (array_length_pos = 0.9)] ref weak string[] args, Operations oper, void *user_data);
}

