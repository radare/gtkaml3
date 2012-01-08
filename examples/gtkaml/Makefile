all: gtk-hello search-dialog sync-sample treeview-liststore-sample

gtk-hello:gtk-hello.gtkaml
	../../src/gtkamlc --pkg gtk+-2.0 --vapidir ../../markuphints $@.gtkaml

search-dialog:search-dialog.gtkaml
	../../src/gtkamlc --pkg gtk+-2.0 --vapidir ../../markuphints $@.gtkaml

sync-sample:sync-sample.gtkaml
	../../src/gtkamlc --pkg gtk+-2.0 --vapidir ../../markuphints $@.gtkaml

treeview-liststore-sample:treeview-liststore-sample.gtkaml
	../../src/gtkamlc --pkg gtk+-2.0 --vapidir ../../markuphints $@.gtkaml

clean:
	rm -f gtk-hello search-dialog sync-sample treeview-liststore-sample
