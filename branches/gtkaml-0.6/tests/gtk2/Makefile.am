ALL = basic_container_add_test test6 test7 test8 test9


all: $(ALL)

basic_container_add_test : $@.gtkaml
	$(top_srcdir)/src/gtkamlc $(VALAFLAGS) --pkg gtk+-2.0 $@.gtkaml --dump-tree $@.vala

test6 : $@.gtkaml
	$(top_srcdir)/src/gtkamlc $(VALAFLAGS) --pkg gtk+-2.0 $@.gtkaml --dump-tree $@.vala

test7 : $@.gtkaml
	$(top_srcdir)/src/gtkamlc $(VALAFLAGS) --pkg gtk+-2.0 $@.gtkaml --dump-tree $@.vala

test8 : $@.gtkaml
	$(top_srcdir)/src/gtkamlc $(VALAFLAGS) --pkg gtk+-2.0 $@.gtkaml --dump-tree $@.vala

test9 : $@.gtkaml
	$(top_srcdir)/src/gtkamlc $(VALAFLAGS) --pkg gtk+-2.0 $@.gtkaml --dump-tree $@.vala


clean:
	rm $(ALL)
