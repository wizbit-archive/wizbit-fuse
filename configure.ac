AC_INIT([wizbit-fuse], [0.1.0], [john.carr@unrouted.co.uk], [wizbit])
AC_CONFIG_SRCDIR([Makefile.am])

AM_INIT_AUTOMAKE([dist-bzip2])

AC_PROG_CC
AM_PROG_CC_C_O
AC_PATH_PROG(VALAC, valac, valac)

GLIB_REQUIRED=2.12.0

PKG_CHECK_MODULES(WIZBIT, glib-2.0 >= $GLIB_REQUIRED gobject-2.0 >= $GLIB_REQUIRED gio-2.0 gio-unix-2.0 gee-1.0 fuse wizbit)
AC_SUBST(WIZBIT_CFLAGS)
AC_SUBST(WIZBIT_LIBS)

AC_CONFIG_FILES([
	Makefile
	wizbitfs/Makefile
	tests/Makefile
])

AC_OUTPUT
