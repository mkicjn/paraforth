\ Parenthesis comments
:! CHAR  NAME 1+ C@ LITERAL ;
:! (  BEGIN KEY CHAR ) = UNTIL ;

\ Word manipulation
: COUNT  1+ DUP 1- C@ ;
: TYPE  FOR DUP C@ EMIT 1+ NEXT DROP ;

\ Character constants
: CR  $ A EMIT ;
:! BL  $ 20 LITERAL ;

\ Memory copying
\ TODO  Move optimized x86-64 version somewhere else
: CONTEXT@   DUP RAX RSI MOVQ  DUP RAX RDI MOVQ  DUP RAX RCX MOVQ ; \ i.e., string instruction context
: CONTEXT!   RCX RAX MOVQ DROP  RDI RAX MOVQ DROP  RSI RAX MOVQ DROP ;
: 3>R  R>  SWAP >R SWAP >R SWAP >R  >R ;
: 3R>  R>  R> SWAP R> SWAP R> SWAP  >R ;
: CMOVE  CONTEXT@ 3>R  CONTEXT!  REP MOVSB  3R> CONTEXT! ;

\ Unsigned decimal integer I/O
:! #  $ 0 NAME COUNT  FOR  >R  $ A *  R@ C@ DIGIT +  R> 1+  NEXT DROP LITERAL ;
: .#  $ 0  BEGIN >R  # 10 /MOD  R> 1+  OVER 0= UNTIL  NIP  FOR  CHAR 0 + EMIT  NEXT ;
\ TODO Add signed decimal I/O and hexadecimal output

\ Words for embedding data into code
:! EMBED  POSTPONE AHEAD  HERE SWAP ;
:! WITH-LENGTH  HERE SWAP  POSTPONE THEN  OVER LITERAL  SWAP - LITERAL ;
:! ALONE  POSTPONE THEN LITERAL ;

\ Strings
: PARSE,  ( DELIM -- ) KEY BEGIN 2DUP <> WHILE C, KEY REPEAT 2DROP ; \ Read keys into memory until delimiter
: PARSE  ( DELIM -- STR CNT ) HERE SWAP PARSE, DUP THERE OVER - ;  \ PARSE, but temporary (reset data pointer)
: 2LITERAL  SWAP LITERAL LITERAL ;
:! S"  POSTPONE EMBED  CHAR " PARSE,  POSTPONE WITH-LENGTH ;
\ Perhaps : can put the current stack pointer on the stack, and ; can try to check for it and QUIT if it fails to match.
:! ."  POSTPONE S"  POSTPONE TYPE ;

\ Memory comparison
\ TODO  Move optimized x86-64 version somewhere else
: SIGN  DUP IF  0< ( -1|0 ) 1+ ( 0|1 ) 2* ( 0|2 ) 1- ( -1|1 ) THEN ;
: COMPARE  CONTEXT@ 3>R  ROT SWAP  2DUP - SIGN >R  MIN  CONTEXT!
           R> DUP  RAX RAX XORQ  RBX RBX XORQ  REP CMPSB
           RAX SETNZB  RBX SETLB  RBX NEGQ  RAX RBX ORQ
           DUP IF NIP ELSE DROP THEN  3R> CONTEXT! ;

\ Dictionary manipulation
: >NAME  $ 8 + ; \ Skip 8 byte pointer
: >XT  >NAME COUNT + ; \ Skip length of string
: >BODY  >XT $ 5 + ; \ Skip length of call instruction

\ Data structures
: DOCREATE  R> LITERAL ;
: CREATE  POSTPONE :! POSTPONE DOCREATE ;
: DODOES>  DP@ >XT  THERE R> COMPILE BACK ;
:! DOES>  POSTPONE DODOES> POSTPONE R>  ;
\ Since this is a compile-only Forth, CREATE and DOES> work a little differently.
\ CREATE is not immediate, which means e.g. `CREATE _ 8 CELLS ALLOT` won't work.
\ Instead, the following definition can be used, e.g. `[ 8 CELLS ] ARRAY _ `
:! ARRAY  CREATE ALLOT ;
\ DOES> redefines the CREATEd word as immediate, giving the opportunity for some code generation.
\ TODO Find workarounds for these differences. For DOES>, can probably place DOCOL after DOES>. What about CREATE?

:! CONSTANT  CREATE , DOES> @ LITERAL ;
[ $ 0 ] CONSTANT FALSE
[ $ 1 ] CONSTANT TRUE
[ $ 8 ] CONSTANT CELL
\ TODO  Move optimized x86-64 version somewhere else
: CELLS  RAX [ $ 3 ] SHLQ$ ;

:! VARIABLE  CREATE CELL ALLOT ;

\ On/Off and conditional exit
: ON   TRUE SWAP ! ;
: OFF  FALSE SWAP ! ;
: ON?   @ 0<> ;
: OFF?  @ 0= ;
: ?EXIT  IF RDROP THEN ;
