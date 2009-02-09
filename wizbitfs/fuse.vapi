using GLib;

[CCode (cprefix="fuse_", cheader_filename="fuse/fuse.h")]
namespace Fuse {
	[CCode (cname="struct fuse_file_info")]
	public struct FileInfo {
		/* */
	}

	public static delegate int FillDir(void *buf, string name, Stat stat, int offset);

	public static delegate int GetAttr(string path, Stat stbuf);
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

	public int main([CCode (array_length_pos = 0.9)] ref weak string[] args, Operations oper);
}

