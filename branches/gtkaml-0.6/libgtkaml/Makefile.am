
if ENABLE_DOCS
    VALADOC_COMMAND=$(VALADOC) -o ../valadoc -b $(top_srcdir) --pkg libvala-$(VALA_VERSION) --pkg libxml-2.0 --force --doclet=devhelp --package-name=Gtkaml --package-version=$(PACKAGE_VERSION) $^ 
else
    VALADOC_COMMAND=
endif

AM_CPPFLAGS = \
	$(GLIB_CFLAGS) \
	$(VALA_CFLAGS) \
	$(LIBXML2_CFLAGS) \
	-DPACKAGE_DATADIR=\"$(pkgdatadir)\"

vapidir = $(datadir)/vala/vapi
dist_vapi_DATA = \
	gtkaml-1.0.vapi \
	gtkaml-1.0.deps

libgtkaml_la_LIBADD = \
	$(GLIB_LIBS) \
	$(VALA_LIBS) \
	$(LIBXML2_LIBS)

lib_LTLIBRARIES = \
	libgtkaml.la


BUILT_SOURCES = libgtkaml.stamp
CLEANFILES = libgtkaml.stamp

libgtkaml_la_VALASOURCES = \
	gtkamlcodecontext.vala \
	gtkamlmarkupparser.vala \
	gtkamlmarkupscanner.vala \
	gtkamlmarkupresolver.vala \
	gtkamlcodeparserprovider.vala \
	ast/gtkamlmarkupattribute.vala \
	ast/gtkamlmarkupcomplexattribute.vala \
	gtkamlmarkupclass.vala \
	ast/gtkamlmarkuptag.vala \
	ast/gtkamlmarkuproot.vala \
	ast/gtkamlmarkupchildtag.vala \
	ast/gtkamlmarkupunresolvedtag.vala \
	ast/gtkamlmarkupmember.vala \
	ast/gtkamlmarkuptemp.vala \
	ast/gtkamlmarkupreference.vala \
	gtkamlmarkupnamespace.vala \
	gtkamlmarkuphint.vala \
	gtkamlmarkuphintsstore.vala \
	workarounds/gtkamldatatypeparent.vala \
	workarounds/gtkamlcallable.vala \
	workarounds/gtkamlvalaparser.vala \
	workarounds/gtkamlnamespacevisitor.vala

nodist_libgtkaml_la_SOURCES = \
	libgtkaml.stamp \
	$(libgtkaml_la_VALASOURCES:.vala=.c) \
	gtkaml.h

gtkamlincludedir = $(includedir)/gtkaml-1.0

gtkamlinclude_HEADERS = \
	gtkaml.h \
	$(NULL)

gtkaml-1.0.vapi : gtkaml.vapi
	cat $^ > $@


libgtkaml.stamp: $(libgtkaml_la_VALASOURCES)
	$(VALAC) -C $(VALAFLAGS) -H gtkaml.h --library gtkaml --pkg glib-2.0 --pkg libvala-$(VALA_VERSION) --pkg libxml-2.0 $^
	$(VALADOC_COMMAND)
	touch $@

EXTRA_DIST = $(libgtkaml_la_VALASOURCES) gtkaml-1.0.deps.in

