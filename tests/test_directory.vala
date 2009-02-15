using Fuse;
using Posix;
using Wiz;

class WizbitFuseTest {
	private string olddir;
	protected string directory;

	void assertIterSize(DirectoryEntry iter, int size) {
		int i = 0;
		foreach (var child in iter) {
			GLib.assert(child != null);
			i++;
		}
		GLib.assert(i == size);
	}

	public void setup(void *fixture) {
		this.olddir = Environment.get_current_dir();
		this.directory = DirUtils.mkdtemp(Path.build_filename(Environment.get_tmp_dir(), "XXXXXX"));
		stdout.printf("%s\n", this.directory);
		Environment.set_current_dir(this.directory);

		store = new Wiz.Store("", ".");
		DirectoryEntry.init();
	}

	public void teardown(void *fixture) {
		Environment.set_current_dir(this.olddir);
		DirUtils.remove(this.directory);
	}

	public void test_iter_empty_root(void *fixture) {
		var root = DirectoryEntry.root();
		assertIterSize(DirectoryEntry.root(), 0);
	}
	
	public void test_iter_root(void *fixture) {
		var n = new DirectoryEntry();
		n.path = "badger";
		var root = DirectoryEntry.root();
		root.add_child(n);
		assertIterSize(DirectoryEntry.root(), 1);
	}

	public void test_iter_root_with_dir(void *fixture) {
		DirectoryEntry.root().mkdir("badger", 0);
		assertIterSize(DirectoryEntry.find("/"), 1);
	}

	public void test_add_child(void *fixture) {
		var de = new DirectoryEntry();
		de.path = Path.get_basename("/badger");
		de.mode = S_IFREG;
		DirectoryEntry.find_containing("/badger").add_child(de);
	}

	public void test_find(void *fixture) {
		this.test_add_child(fixture);
		var de = DirectoryEntry.find("/badger");
	}

	public void test_find_missing_node(void *fixture) {
		DirectoryEntry.root().mkdir("badger", S_IFDIR);
		var de = DirectoryEntry.find("/badger/foobar");
		GLib.assert(de == null);
	}

	public void test_find_multiple_missing_node(void *fixture) {
		DirectoryEntry.root().mkdir("badger", S_IFDIR);
		var de = DirectoryEntry.find("/badger/foobar/sausage");
		GLib.assert(de == null);
	}

	public void test_iter_missing(void *fixture) {
		DirectoryEntry.root().mkdir("badger", S_IFDIR);
		var de = DirectoryEntry.find("/badger");
		GLib.assert(de != null);
		assertIterSize(de, 0);
	}

	public void test_iter_child(void *fixture) {
		DirectoryEntry.root().mkdir("badger", 0);
		DirectoryEntry.find("/badger").mkdir("sausage", S_IFDIR);
		assertIterSize(DirectoryEntry.find("/badger/sausage"), 0);

		var de = DirectoryEntry.find("/badger/sausage");
		GLib.assert(de.path=="sausage");
		GLib.assert(S_ISDIR(de.mode));
	}

	public void test_remove_dirent(void *fixture) {
		GLib.assert(DirectoryEntry.find("/badger") == null);
		DirectoryEntry.root().mkdir("badger", 0);
		GLib.assert(DirectoryEntry.find("/badger") != null);
		DirectoryEntry.root().rm("badger");
		GLib.assert(DirectoryEntry.find("/badger") == null);
	}

	public void test_remove_dirent_child(void *fixture) {
		DirectoryEntry.root().mkdir("badger", 0);
		DirectoryEntry.find("/badger").mkdir("sausage", 0);
		GLib.assert(DirectoryEntry.find("/badger/sausage") != null);
		DirectoryEntry.find_containing("/badger/sausage").rm("sausage");
		GLib.assert(DirectoryEntry.find("/badger/sausage") == null);
	}
}

static Wiz.Store store = null;

static int main(string [] args)
{
	Test.init(ref args);
	var me = new WizbitFuseTest();
	var ts = new TestSuite("directory");
	ts.add(new TestCase("test_iter_empty_root", 0, me.setup, me.test_iter_empty_root, me.teardown));
	ts.add(new TestCase("test_iter_root", 0, me.setup, me.test_iter_empty_root, me.teardown));
	ts.add(new TestCase("test_iter_root_with_dir", 0, me.setup, me.test_iter_root_with_dir, me.teardown));
	ts.add(new TestCase("test_add_child", 0, me.setup, me.test_add_child, me.teardown));
	ts.add(new TestCase("test_find", 0, me.setup, me.test_add_child, me.teardown));
	ts.add(new TestCase("test_find_missing_node", 0, me.setup, me.test_find_missing_node, me.teardown));
	ts.add(new TestCase("test_find_multiple_missing_node", 0, me.setup, me.test_find_multiple_missing_node, me.teardown));
	ts.add(new TestCase("test_iter_missing", 0, me.setup, me.test_iter_missing, me.teardown));
	ts.add(new TestCase("test_iter_child", 0, me.setup, me.test_iter_missing, me.teardown));
	ts.add(new TestCase("test_remove_dirent", 0, me.setup, me.test_remove_dirent, me.teardown));
	ts.add(new TestCase("test_remove_dirent_child", 0, me.setup, me.test_remove_dirent_child, me.teardown));
	TestSuite.get_root().add_suite(ts);
	Test.run();

	return 0;
}

