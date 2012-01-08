all: gtk-hello sync-sample search-dialog treeview-liststore-sample

gtk-hello:gtk-hello.gtkon
	../../src/gtkamlc --pkg gtk+-2.0 --vapidir ../../markuphints $^

search-dialog:search-dialog.gtkon
	../../src/gtkamlc --pkg gtk+-2.0 --vapidir ../../markuphints $^

sync-sample:sync-sample.gtkon
	../../src/gtkamlc --pkg gtk+-2.0 --vapidir ../../markuphints $^

treeview-liststore-sample:treeview-liststore-sample.gtkon
	../../src/gtkamlc --pkg gtk+-2.0 --vapidir ../../markuphints $^

clean:
	rm -f gtk-hello search-dialog sync-sample treeview-liststore-sample
