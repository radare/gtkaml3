ALL = basic_container_add_test basic_tag_attribute_test basic_construct_preconstruct_test test1 test3 test4 test6 test7 test8 test9


all: $(ALL)

basic_container_add_test : $@.gtkaml
	$(top_srcdir)/src/gtkamlc $(VALAFLAGS) --pkg gtk+-2.0 $@.gtkaml --dump-tree $@.vala --vapidir ../../markuphints

basic_tag_attribute_test : $@.gtkaml
	$(top_srcdir)/src/gtkamlc $(VALAFLAGS) --pkg gtk+-2.0 $@.gtkaml --dump-tree $@.vala --vapidir ../../markuphints

basic_construct_preconstruct_test : $@.gtkaml
	$(top_srcdir)/src/gtkamlc $(VALAFLAGS) --pkg gtk+-2.0 $@.gtkaml --dump-tree $@.vala --vapidir ../../markuphints

test1 : $@.gtkaml
	$(top_srcdir)/src/gtkamlc $(VALAFLAGS) --pkg gtk+-2.0 $@.gtkaml --dump-tree $@.vala --vapidir ../../markuphints

test2 : $@.gtkaml
	$(top_srcdir)/src/gtkamlc $(VALAFLAGS) --pkg gtk+-2.0 $@.gtkaml --dump-tree $@.vala --vapidir ../../markuphints

test3 : $@.gtkaml
	$(top_srcdir)/src/gtkamlc $(VALAFLAGS) --pkg gtk+-2.0 $@.gtkaml WindowController.vala --dump-tree $@.vala --vapidir ../../markuphints

test4 : $@.gtkaml
	$(top_srcdir)/src/gtkamlc $(VALAFLAGS) --pkg gtk+-2.0 $@.gtkaml --dump-tree $@.vala --vapidir ../../markuphints

test6 : $@.gtkaml
	$(top_srcdir)/src/gtkamlc $(VALAFLAGS) --pkg gtk+-2.0 $@.gtkaml --dump-tree $@.vala --vapidir ../../markuphints

test7 : $@.gtkaml
	$(top_srcdir)/src/gtkamlc $(VALAFLAGS) --pkg gtk+-2.0 $@.gtkaml --dump-tree $@.vala --vapidir ../../markuphints

test8 : $@.gtkaml
	$(top_srcdir)/src/gtkamlc $(VALAFLAGS) --pkg gtk+-2.0 $@.gtkaml --dump-tree $@.vala --vapidir ../../markuphints

test9 : $@.gtkaml
	$(top_srcdir)/src/gtkamlc $(VALAFLAGS) --pkg gtk+-2.0 $@.gtkaml --dump-tree $@.vala --vapidir ../../markuphints


clean:
	rm $(ALL)
