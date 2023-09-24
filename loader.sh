#!/bin/sh

if [ $# = 0 ]; then
	echo "Usage: $0 load_order.lst [option]"
	echo ""
	echo "Options available:"
	echo " debug - Run with gdb"
	# TODO: Option for non-canonical terminal
	# TODO: Option for precise runtime measurement
	exit 1
fi

[ ! -e paraforth ] && make paraforth


if [ $# = 1 ]; then
	cat $(cat $1) | ./paraforth

elif [ $2 = "debug" ]; then
	gdb ./paraforth -ex "r < <(cat $(cat $1 | tr '\n' ' '))"

else
	echo "Unrecognized option '$2'"
	exit 1
fi
