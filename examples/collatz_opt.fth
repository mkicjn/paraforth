\ Working but not as much faster as it could be

\ I want to optimize this further as an experiment.
\ Later, when I create profiling tools, it would be interesting to try them on this example.

:! ?MARK>  $ 0 { JZL$ }   HERE $ 4 - ;
:!  MARK>  $ 0 { JMPL$ }  HERE $ 4 - ;
:!  >RESOLVE  THERE DUP REL32, BACK ;
\ :!  MARK<  HERE ;
\ :!  <RESOLVE  { JMPL$ } ;
\ :! ?<RESOLVE  { JZL$ } ;

:! LEAQ@+8  REX.W,  SWAP $ 8D   C,  MEM+8 MODR/M, ;
: COLLATZ-STEP
	RAX [ $ 1 ] TESTQ$
	?MARK>
	RAX (SIB) LEAQ@+8  RAX RAX R*2 SIB, [ $ 1 C, ] \ lea rax, [3*rax+1]
	MARK>
	[ SWAP ] >RESOLVE
	RAX 1SHRQ
	>RESOLVE
	;

:! ALIGN  HERE $ 4 ALIGNED  HERE - FOR { NOP } NEXT ;
: COLLATZ-LEN   $ 0 SWAP ALIGN BEGIN  DUP $ 1 > WHILE  COLLATZ-STEP  RDX INCQ  REPEAT DROP ;
: MAX-COLLATZ   $ 0 SWAP FOR  I COLLATZ-LEN MAX  NEXT ;

[ # 1000000 MAX-COLLATZ .# CR BYE ]
