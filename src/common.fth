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
: SPACE  BL EMIT ;

\ Unsigned decimal integer I/O
:! #  $ 0 NAME COUNT  FOR  >R  $ A *  R@ C@ DIGIT +  R> 1+  NEXT DROP LITERAL ;
: .#  $ 0  BEGIN >R  # 10 /MOD  R> 1+  OVER 0= UNTIL  NIP  FOR  CHAR 0 + EMIT  NEXT ;
\ TODO  Add signed decimal I/O and hexadecimal output

\ Words for embedding data into code
: EMBED  POSTPONE AHEAD  HERE SWAP ;
: WITH-LENGTH  HERE SWAP  POSTPONE THEN  OVER - 2LITERAL ;
: ALONE  POSTPONE THEN LITERAL ;

\ Strings
: PARSE, ( delim -- ) KEY BEGIN 2DUP <> WHILE C, KEY REPEAT 2DROP ; \ Read keys into memory until delimiter
: PARSE  ( delim -- str cnt ) HERE SWAP PARSE,  DUP THERE OVER - ;  \ PARSE, but temporary (reset data pointer)
:! S"  EMBED  CHAR " PARSE,  WITH-LENGTH ;
:! ."  POSTPONE S"  POSTPONE TYPE ;

\ Data structures
: DOCREATE  R> LITERAL ;
: CREATE  POSTPONE :! POSTPONE DOCREATE ;
: DODOES>  LP@ >XT  THERE R> COMPILE BACK ;
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

\ TODO  Find a good conditional compilation mechanism for supporting optimized versions of e.g. below

\ Dual string operations
: CSTEP  SWAP 1+ SWAP 1+ ;
: CCOPY  SWAP C@ SWAP C! ;
: 2C@    SWAP C@ SWAP C@ ;
\ Memory copying
: CMOVE  FOR  2DUP CCOPY CSTEP  NEXT 2DROP ;
\ Counted string comparisons
: ?C=  2C@ = ?EXIT  RDROP UNLOOP ;
: -MATCH  FOR  2DUP ?C= CSTEP  NEXT ; \ Find mismatch
: CSTR=  DUP C@  -MATCH  2C@ = ;

\ TODO  Implement COMPARE (reusing -MATCH)
: SIGN  DUP 0<> IF  0> 2* 1-  THEN ;
