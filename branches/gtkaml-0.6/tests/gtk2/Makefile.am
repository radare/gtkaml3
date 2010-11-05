AM_CFLAGS = \
	 -Wall \
	 -g \
	 $(EXTRA_CFLAGS) \
	 $(GTK_CFLAGS)

BUILT_SOURCES = basic_container_add_test.stamp 
noinst_PROGRAMS = basic_container_add_test 


CLEANFILES = basic_container_add_test.h basic_container_add_test.c basic_container_add_test.stamp basic_container_add_test.vala

## Basic feature test: container adds, expressions in properties and signals
basic_container_add_test_GTKAMLSOURCES = \
	basic_container_add_test.gtkaml

nodist_basic_container_add_test_SOURCES = \
	$(basic_container_add_test_GTKAMLSOURCES:.gtkaml=.c) \
	$(basic_container_add_test_GTKAMLSOURCES:.gtkaml=.h) \
	basic_container_add_test.stamp	

basic_container_add_test_LDADD = \
	$(GTK_LIBS) \
	$(EXTRA_LDFLAGS)

basic_container_add_test.stamp : $(basic_container_add_test_GTKAMLSOURCES)
	$(top_srcdir)/src/gtkamlc -C $(VALAFLAGS) --pkg gtk+-2.0 $^ --dump-tree basic_container_add_test.vala


EXTRA_DIST = \
	$(basic_container_add_test_GTKAMLSOURCES)
