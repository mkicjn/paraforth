\ Working but unfinished
\ I had an idea to use something like this to clean it up, but it's bugged:
\ : INTERPRET  NAME FIND EXECUTE ;
\ :! MARK< HERE ;
\ :! MARK>  HERE DUP ;
\ :! <RESOLVE  ;
\ :! >RESOLVE  THERE DUP INTERPRET THERE DROP ;

\ I also want to optimize it further as an experiment.
\ Later, when I create profiling tools, it would be interesting to try them on this example.

:! LEAQ@+8  REX.W,  SWAP $ 8D   C,  MEM+8 MODR/M, ;
: COLLATZ-STEP  
	RAX [ $ 1 ] TESTQ$
	[ HERE $ 0 ] JZ$
	RAX (SIB) LEAQ@+8  RAX RAX R*2 SIB, [ $ 1 C, ]
	[ HERE $ 0 ] JMP$
	[ SWAP THERE DUP POSTPONE JZ$ BACK ]
	RAX 1SHRQ
	[ THERE DUP POSTPONE JMP$ BACK ]
	;
: COLLATZ-LEN   $ 0 SWAP BEGIN  DUP $ 1 > WHILE  COLLATZ-STEP  SWAP 1+ SWAP REPEAT DROP ;
: MAX-COLLATZ   $ 0 SWAP FOR  I COLLATZ-LEN MAX  NEXT ;

[ # 1000000 MAX-COLLATZ .# CR BYE ]
