#!/bin/sh

if [ $# = 0 ]; then
	echo "Usage: $0 load_order.lst"
	echo "Where load_order.lst contains:"
	echo "#!/bin/sh loader.sh"
	echo "file1"
	echo "file2"
	echo "..."
	exit 1
fi

if [ ! -e core ]; then
	make core
fi

cat $(cat $@) | ./core
