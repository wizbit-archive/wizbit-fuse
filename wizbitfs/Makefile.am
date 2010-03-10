
bin_PROGRAMS=wizbit-fuse

BUILT_SOURCES = wizbit-fuse.vala.stamp

wizbit_fuse_VALASOURCES = \
	fuse.vapi \
	posix.vapi \
	directory.vala \
	wizbit-fuse.vala \
	$(NULL)

wizbit_fuse_SOURCES = \
	$(wizbit_fuse_VALASOURCES:.vala=.c) \
	$(NULL)

wizbit-fuse.vala.stamp: $(wizbit_fuse_VALASOURCES)
	$(VALAC) -C --basedir $(top_srcdir) --pkg gee-1.0 --pkg gio-2.0 --pkg wizbit $^
	touch $@

wizbit_fuse_CFLAGS=@WIZBIT_CFLAGS@ -I$(top_srcdir) -D_FILE_OFFSET_BITS=64 -DFUSE_USE_VERSION=26
wizbit_fuse_LDADD=@WIZBIT_LIBS@

EXTRA_DIST = \
	$(wizbit_fuse_VALASOURCES) \
	wizbit-fuse.vala.stamp \
	$(NULL)
