rm test.vala
touch test.vala
src/gtkamlc  test.gtkaml --save-temps --pkg gtk+-2.0 --dump-tree test.tree
#gcc test.c test.h -I `pkg-config --cflags gtk+-2.0` -o test -L `pkg-config --libs gtk+-2.0` &2>1
#cat test.vala
