AC_INIT([wizbit-fuse], [0.1.0], [john.carr@unrouted.co.uk], [wizbit])
AC_CONFIG_SRCDIR([Makefile.am])

AM_INIT_AUTOMAKE([dist-bzip2])
AM_MAINTAINER_MODE

AC_PROG_CC
AM_PROG_CC_C_O
AC_PATH_PROG(VALAC, valac, valac)

GLIB_REQUIRED=2.12.0

PKG_CHECK_MODULES(WIZBIT, glib-2.0 >= $GLIB_REQUIRED gobject-2.0 >= $GLIB_REQUIRED fuse)
AC_SUBST(WIZBIT_CFLAGS)
AC_SUBST(WIZBIT_LIBS)

AC_CONFIG_FILES([
	Makefile
	wizbitfs/Makefile
])

AC_OUTPUT
