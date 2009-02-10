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
	public static delegate int FillDir(void *buf, string name, stat? st, off_t offset);

	public static delegate int GetAttr(string path, stat *st);
	public static delegate int Access(string path, int mask);
	public static delegate int ReadLink(string path, char *buf, size_t size);
	public static delegate int ReadDir(string path, void *buf, FillDir filler, off_t offset, FileInfo fi);
	public static delegate int MkNod(string path, mode_t mode, dev_t rdev);
	public static delegate int MkDir(string path, mode_t mode);
	public static delegate int Unlink(string path);
	public static delegate int RmDir(string path);
	public static delegate int Symlink(string from, string to);
	public static delegate int Rename(string from, string to);
	public static delegate int Link(string from, string to);
	public static delegate int Chmod(string path, mode_t mode);
	public static delegate int Chown(string path, uid_t uid, gid_t gid);
	public static delegate int Truncate(string path, off_t size);
	public static delegate int Utimens(string path, timespec[2] ts);
	public static delegate int Open(string path, FileInfo fi);
	public static delegate int Read(string path, char *buf, size_t size, off_t offset, FileInfo fi);
	public static delegate int Write(string path, char *buf, size_t size, off_t offset, FileInfo fi);
	public static delegate int StatFs(string path, statvfs *stbuf);
	public static delegate int Release(string path, FileInfo fi);
	public static delegate int Fsync(string path, int isdatasync, FileInfo fi);

	public static delegate int SetXAttr(string path, string name, char *value, size_t size, int flags);
	public static delegate int GetXAttr(string path, string name, char *value, size_t size);
	public static delegate int ListXAttr(string path, char *list, size_t size);
	public static delegate int RemoveXAttr(string path, string name);


	[CCode (cname="struct fuse_operations")]
	public struct Operations {
		public GetAttr getattr;
		public Access access;
		public ReadLink readlink;
		public ReadDir readdir;
		public MkNod mknod;
		public MkDir mkdir;
		public Symlink symlink;
		public Unlink unlink;
		public RmDir rmdir;
		public Rename rename;
		public Link link;
		public Chmod chmod;
		public Chown chown;
		public Truncate truncate;
		public Utimens utimens;
		public Open open;
		public Read read;
		public Write write;
		public StatFs statfs;
		public Release release;
		public Fsync fsync;
		public SetXAttr setxattr;
		public GetXAttr getxattr;
		public ListXAttr listxattr;
		public RemoveXAttr removexattr;
	}

	public int main([CCode (array_length_pos = 0.9)] string[] args, Operations oper, void *user_data);
}

