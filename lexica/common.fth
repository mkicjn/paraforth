\ TODO  Split into different files?

\ Parenthesis comments
:! CHAR  NAME 1+ C@ LITERAL ;
:! (  BEGIN KEY CHAR ) = UNTIL ;

\ Word manipulation
: COUNT  1+ DUP 1- C@ ;
: TYPE  FOR DUP C@ EMIT 1+ NEXT DROP ;

\ Character constants
: CR  $ A EMIT ;
:! BL  $ 20 LITERAL ;

\ Unsigned decimal integer I/O
:! #  $ 0 NAME COUNT  FOR  >R  $ A *  R@ C@ DIGIT +  R> 1+  NEXT DROP LITERAL ;
: .#  $ 0  BEGIN >R  # 10 /MOD  R> 1+  OVER 0= UNTIL  NIP  FOR  CHAR 0 + EMIT  NEXT ;
\ TODO  Add signed decimal I/O and hexadecimal output

\ Words for embedding data into code
:! EMBED  POSTPONE AHEAD  HERE SWAP ;
:! WITH-LENGTH  HERE SWAP  POSTPONE THEN  OVER LITERAL  SWAP - LITERAL ;
:! ALONE  POSTPONE THEN LITERAL ;

\ Strings
: PARSE,  ( DELIM -- ) KEY BEGIN 2DUP <> WHILE C, KEY REPEAT 2DROP ; \ Read keys into memory until delimiter
: PARSE  ( DELIM -- STR CNT ) HERE SWAP PARSE,  DUP THERE OVER - ;  \ PARSE, but temporary (reset data pointer)
: 2LITERAL  SWAP LITERAL LITERAL ;
:! S"  POSTPONE EMBED  CHAR " PARSE,  POSTPONE WITH-LENGTH ;
\ Perhaps : can put the current stack pointer on the stack, and ; can try to check for it and QUIT if it fails to match.
:! ."  POSTPONE S"  POSTPONE TYPE ;

\ Dictionary manipulation
\ TODO  Move implementation-specific details elsewhere
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
\ TODO  Does it really need to be immediate?
\ Instead, the following definition can be used, e.g. `[ 8 CELLS ] ARRAY _ `
:! ARRAY  CREATE ALLOT ;
\ DOES> redefines the CREATEd word as immediate, giving the opportunity for some code generation.
\ TODO  Find workarounds for these differences. For DOES>, can probably place DOCOL after DOES>. What about CREATE?

:! CONSTANT  CREATE , DOES> @ LITERAL ;
[ $ 0 ] CONSTANT FALSE
[ $ 1 ] CONSTANT TRUE
[ SP@ ] CONSTANT S0
[ RP@ ] CONSTANT R0

:! VARIABLE  CREATE CELL ALLOT ;

\ On/Off and conditional exit
: ON   TRUE SWAP ! ;
: OFF  FALSE SWAP ! ;
: ON?   @ 0<> ;
: OFF?  @ 0= ;
: ?EXIT  IF RDROP THEN ;
