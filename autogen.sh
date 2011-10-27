#!/bin/sh
# run autoreconf twice to skip missing ltmain.sh bug. #autosucks
# see http://www.redantigua.com/c-make-automake.html
autoreconf -i
autoreconf -i && ./configure $@
