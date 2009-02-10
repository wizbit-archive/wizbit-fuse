
noinst_PROGRAMS=wizbit-fuse

BUILT_SOURCES = wizbit-fuse.vala.stamp

wizbit_fuse_VALASOURCES = \
	posix.vapi \
	fuse.vapi \
	wizbit.vapi \
	wizbit-fuse.vala \
	$(NULL)

wizbit_fuse_SOURCES = \
	$(wizbit_fuse_VALASOURCES:.vala=.c) \
	$(wizbit_fuse_VALASOURCES:.vala=.h) \
	$(NULL)

wizbit-fuse.vala.stamp: $(wizbit_fuse_VALASOURCES)
	$(VALAC) -C --basedir $(top_srcdir) --pkg gio-2.0 $^
	touch $@

wizbit_fuse_CFLAGS=@WIZBIT_CFLAGS@ -I$(top_srcdir) -D_FILE_OFFSET_BITS=64 -DFUSE_USE_VERSION=26
wizbit_fuse_LDADD=@WIZBIT_LIBS@

EXTRA_DIST = \
	$(wizbit_fuse_VALASOURCES) \
	wizbit-fuse.vala.stamp \
	$(NULL)
