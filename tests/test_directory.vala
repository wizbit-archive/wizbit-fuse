using Fuse;
using Posix;
using Wiz;

class WizbitFuseTest {
	private string olddir;
	protected string directory;

	public void setup(void *fixture) {
		this.olddir = Environment.get_current_dir();
		this.directory = DirUtils.mkdtemp(Path.build_filename(Environment.get_tmp_dir(), "XXXXXX"));
		Environment.set_current_dir(this.directory);

		store = new Wiz.Store("", ".");
	}

	public void teardown(void *fixture) {
		Environment.set_current_dir(this.olddir);
		DirUtils.remove(this.directory);
	}

	public void test_iter_empty_root(void *fixture) {
		int i = 0;
		var root = DirectoryEntry.root();
		foreach (var child in root)
			i++;
		GLib.assert(i ==0);
	}
	
	public void test_iter_root(void *fixture) {
		var n = new DirectoryEntry();
		n.path = "badger";
		var root = DirectoryEntry.root();
		root.add_child(n);
		int i = 0;
		foreach (var child in root)
			i++;
		GLib.assert(i==1);
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
		this.test_add_child(fixture);
		var de = DirectoryEntry.find("/badger/foobar");
		GLib.assert(de == null);
	}

	public void test_find_multiple_missing_node(void *fixture) {
		this.test_add_child(fixture);
		var de = DirectoryEntry.find("/badger/foobar/sausage");
		GLib.assert(de == null);
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
	ts.add(new TestCase("test_add_child", 0, me.setup, me.test_add_child, me.teardown));
	ts.add(new TestCase("test_find", 0, me.setup, me.test_add_child, me.teardown));
	ts.add(new TestCase("test_find_missing_mode", 0, me.setup, me.test_find_missing_node, me.teardown));
	ts.add(new TestCase("test_find_multiple_missing_node", 0, me.setup, me.test_find_multiple_missing_node, me.teardown));
	TestSuite.get_root().add_suite(ts);
	Test.run();

	return 0;
}

