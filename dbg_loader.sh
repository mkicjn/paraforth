#!/bin/sh

if [ $# = 0 ]; then
	echo "Usage: $0 load_order.lst"
	exit 1
fi

if [ ! -e core ]; then
	make core
fi

gdb ./core -ex "r < <(cat $(cat $@ | tr '\n' ' '))"
