
AM_CFLAGS = \
	$(GLIB_CFLAGS) \
	$(GIO_CFLAGS) \
	$(VALA_CFLAGS) \
	$(LIBXML2_CFLAGS) \
	-I$(top_srcdir)/libgtkaml

bin_PROGRAMS = gtkamlc

BUILT_SOURCES = gtkamlc.stamp

gtkamlc_VALASOURCES = gtkamlcompiler.vala

nodist_gtkamlc_SOURCES = \
	gtkamlc.stamp \
	$(gtkamlc_VALASOURCES:.vala=.c) 

gtkamlc.stamp : $(gtkamlc_VALASOURCES)
	$(VALAC) -C $(VALAFLAGS) --vapidir ../libgtkaml --pkg gtkaml-1.0 --pkg libxml-2.0 --pkg libvala-$(VALA_VERSION) --pkg glib-2.0 --pkg gio-2.0 --pkg config $^
	touch $@

gtkamlc_LDADD = \
	$(GLIB_LIBS) \
	$(GIO_LIBS) \
	$(VALA_LIBS) \
	$(LIBXML2_LIBS) \
	$(top_srcdir)/libgtkaml/libgtkaml.la

EXTRA_DIST = $(gtkamlc_VALASOURCES)

