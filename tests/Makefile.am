
noinst_PROGRAMS=test_directory

BUILT_SOURCES = test_directory.vala.stamp

common_sources = \
	$(top_srcdir)/wizbitfs/directory.vala \
	$(top_srcdir)/wizbitfs/posix.vapi \
	$(top_srcdir)/wizbitfs/fuse.vapi \
	$(top_srcdir)/wizbitfs/wizbit.vapi \
	$(NULL)

test_directory_VALASOURCES = \
	$(common_sources) \
	test_directory.vala \
	$(NULL)

test_directory_SOURCES = \
	$(test_directory_VALASOURCES:.vala=.c) \
	$(test_directory_VALASOURCES:.vala=.h) \
	$(NULL)

test_directory.vala.stamp: $(test_directory_VALASOURCES)
	$(VALAC) -C --basedir $(top_srcdir) --pkg gio-2.0 $^
	touch $@

test_directory_CFLAGS=@WIZBIT_CFLAGS@ -I$(top_srcdir) -D_FILE_OFFSET_BITS=64 -DFUSE_USE_VERSION=26
test_directory_LDADD=@WIZBIT_LIBS@

EXTRA_DIST = \
	$(test_directory_VALASOURCES) \
	test-directory.vala.stamp \
	$(NULL)

