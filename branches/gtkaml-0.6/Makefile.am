if ENABLE_TESTS
TESTS_DIRS = tests/gtk2 tests/gtk3
endif

SUBDIRS = \
	libgtkaml \
	src \
	markuphints \
	$(TESTS_DIRS)

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = gtkaml-1.0.pc

dist_man_MANS = gtkamlc.1

EXTRA_DIST = \
	gtkaml-1.0.pc.in
