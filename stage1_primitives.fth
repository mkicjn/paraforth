:! POSTPONE  NAME FIND COMPILE ;
:! :  POSTPONE :! POSTPONE DOCOL ;

:! DPOPQ  POSTPONE RBPMOVQ@  POSTPONE RBP $ 8 POSTPONE ADDQ$ ;
:! DPUSHQ  POSTPONE RBP $ 8 POSTPONE SUBQ$  POSTPONE RBPMOVQ! ;

: NIP  RDX DPOPQ ;
: TUCK  RAX DPUSHQ ;
: OVER  SWAP TUCK ;
: ROT  RBX DPOPQ  DUP  RAX RBX MOVQ ;
: -ROT  RBX RAX MOVQ  DROP  RBX DPUSHQ ;

: 2DUP  RDX DPUSHQ  RAX DPUSHQ ;
: 2DROP  RAX DPOPQ  RDX DPOPQ ;

: LITERAL  DOLIT , ;
: 2LITERAL  SWAP LITERAL LITERAL ;

: THERE  RDI RAXXCHGQ  ;
: ALLOT  RDI RAX ADDQ  DROP ;
: 1ALLOT  RDI INCQ ;

: 1+  RAX INCQ ;
: 1-  RAX DECQ ;
: 2*  RAX 1SHLQ ;
: 2/  RAX 1SARQ ;

: COND  RBX RAX MOVQ  DROP  RBX RBX TESTQ ;

:! BEGIN  HERE ;
:! AHEAD  HERE 1+  HERE POSTPONE JMP$ ;
:! IF  POSTPONE COND  HERE 1+  HERE POSTPONE JZ$ ;
:! AGAIN  POSTPONE JMP$ ;
:! UNTIL  POSTPONE COND POSTPONE JZ$ ;
:! THEN  THERE  DUP REL8,  THERE DROP ;
:! ELSE  POSTPONE AHEAD  SWAP  POSTPONE THEN ;
:! WHILE  POSTPONE IF  SWAP ;
:! REPEAT  POSTPONE AGAIN  POSTPONE THEN ;

: =  RBX DUPXORQ  RDX RAX CMPQ  RBX SETNZB  RBX DECQ  RAX RBX MOVQ  NIP ;
:! \  BEGIN  RX $ A =  UNTIL ;

\ Comments are now enabled!

\ TODO Try to reorganize the the words defined here into groups

: STARTFOR  RBX POPQ  RCX PUSHQ  RBX PUSHQ  RCX RAX MOVQ  DROP ;
: ENDFOR  RBX POPQ  RCX POPQ  RBX PUSHQ ;
:! FOR  POSTPONE STARTFOR HERE ;
:! AFT  DROP POSTPONE AHEAD POSTPONE BEGIN SWAP ;
:! NEXT  POSTPONE LOOP$ POSTPONE ENDFOR ;
: I  DUP  RAX RCX MOVQ ;

: @  RAX RAX MOVQ@ ;
: !  RAX RDX MOVQ! 2DROP ;
: C@  RAX RAX MOVZXB@ ;
: C!  RAX RDX MOVB!  2DROP ;

: COUNT  1+ DUP 1- C@ ;
: TYPE  FOR DUP C@ TX 1+ NEXT DROP ;

: CR  $ A TX ;
: BL  $ 20 ;
:! CHAR  NAME 1+ C@ LITERAL ;

: EXECUTE  RBX RAX MOVQ  DROP  RBX JMP
: NOT-FOUND  COUNT TYPE CHAR ? TX CR POSTPONE \
\ TODO ^ POSTPONE \ should be replaced by QUIT later.
:! [  RDI PUSHQ  BEGIN  NAME DUP FIND  DUP
                 IF  NIP EXECUTE
                 ELSE  DROP NOT-FOUND
                 THEN AGAIN ;
:! ]  POSTPONE ;  RBX POPQ  RDI POPQ  RDI JMP
[
\ TODO ^ This should also be replaced by QUIT later.
\ : QUIT  BEGIN CHAR [ TX BL TX POSTPONE [ AGAIN ;
\ ^ This definition almost works, but needs to reset registers
\ Another problem: These definitions rely on each other.

: *  RDX MULQ  NIP ;
: UM/MOD  RBX RAX MOVQ  RAX RDX MOVQ  RDX DUPXORQ  RBX DIVQ ;
:! INVERT  POSTPONE RAX POSTPONE NOTQ ;
:! NEGATE  POSTPONE RAX POSTPONE NEGQ ;

: 0<  RAX [ $ 3F ] SARQ$ ;
: 0=  RBX DUPXORQ  RAX RAX TESTQ  RBX SETNZB  RBX DECQ  RAX RBX MOVQ ;
: <>  RBX DUPXORQ  RDX RAX CMPQ  RBX SETZB  RBX DECQ  RAX RBX MOVQ  NIP ;
: MIN  RAX RDX CMPQ  RAX RDX CMOVLQ  DROP ;
: MAX  RAX RDX CMPQ  RAX RDX CMOVGQ  DROP ;

: >R  RBX POPQ  RAX PUSHQ  RBX PUSHQ  DROP ;
: R>  DUP  RBX POPQ  RAX POPQ  RBX PUSHQ ;
: R@  DUP  RBX POPQ  RAX POPQ  RAX PUSHQ RBX PUSHQ ;
\ TODO fix ^ Like RBP, MOVQ! doesn't work as intended with RSP due to SIB encoding
: RDROP  RBX POPQ  RSP [ $ 8 ] ADDQ$  RBX PUSHQ ;

: CONTEXT@   DUP RAX RSI MOVQ  DUP RAX RDI MOVQ  DUP RAX RCX MOVQ ;
: CONTEXT!   RCX RAX MOVQ DROP  RDI RAX MOVQ DROP  RSI RAX MOVQ DROP ;
\ TODO Is there a better word than "context" for this?
: 3>R  R>  SWAP >R SWAP >R SWAP >R  >R ;
: 3R>  R>  R> SWAP R> SWAP R> SWAP  >R ;
\ TODO ^ Refactor

: MOVE  CONTEXT@ 3>R  CONTEXT!  REP MOVSB  3R> CONTEXT! ;

:! #  $ 0 NAME  COUNT FOR  >R  $ A *  R@ C@ DIGIT +  R> 1+  NEXT DROP  LITERAL ;
: .#  $ 0  BEGIN >R  # 10 UM/MOD  R> 1+  OVER 0= UNTIL  NIP  FOR  CHAR 0 + TX  NEXT ;
\ TODO ^ Refactor words like these that are hard to read
\ TODO Might help to have words for generating counted strings
\ TODO Add signed decimal I/O

: PARSE,  RX BEGIN 2DUP <> WHILE C, RX REPEAT 2DROP ;
: PARSE  HERE SWAP PARSE, DUP THERE OVER - ;
:! S"  POSTPONE AHEAD  HERE CHAR " PARSE,  HERE OVER -  ROT POSTPONE THEN  2LITERAL ;
\ TODO Check stack depth after definitions to ensure correctness.
\ Perhaps : can put the current stack pointer on the stack, and ; can try to check for it and QUIT if it fails to match.
:! ."  POSTPONE S"  POSTPONE TYPE ;
:! (  CHAR ) PARSE 2DROP ;
( Parenthesis commments are now allowed, too! )

: SIGN  DUP IF  0< ( -1|0 ) 1+ ( 0|1 ) 2* ( 0|2 ) 1- ( -1|1 ) THEN ;
: COMPARE  CONTEXT@ 3>R  ROT SWAP  2DUP - SIGN >R  MIN  CONTEXT!
           R> DUP  RAX DUPXORQ  RBX DUPXORQ  REP CMPSB
           RAX SETNZB  RBX SETLB  RBX NEGQ  RAX RBX ORQ
           DUP IF NIP ELSE DROP THEN  3R> CONTEXT! ;

: LATEST  DUP  RAX RSI MOVQ ;
: >NAME  $ 2 + ; \ Skip 16 bit offset
: >XT  >NAME COUNT + ; \ Skip length of string
: >BODY  >XT $ 5 + ; \ Skip length of call instruction

: DOCREATE  R> LITERAL ;
: CREATE  POSTPONE :! POSTPONE DOCREATE ;
: DODOES>  LATEST >XT THERE R> COMPILE THERE DROP ;
:! DOES>  POSTPONE DODOES> POSTPONE R>  ;
\ Since this is a compile-only Forth, CREATE and DOES> works a little differently.
\ CREATE is not immediate, which means e.g. `CREATE _ 8 CELLS ALLOT` won't work.
\ Instead, the following definition can be used, e.g. `[ 8 CELLS ] ARRAY _ `
:! ARRAY  CREATE ALLOT ;
\ DOES> redefines the CREATEd word as immediate, giving the opportunity for some code generation.
\ TODO Find workarounds for these differences. For DOES>, can probably place DOCOL after DOES>. What about CREATE?
:! CONSTANT  CREATE , DOES> @ LITERAL ;
[ $ 8 ] CONSTANT CELL
:! VARIABLE  CREATE CELL ALLOT ;
: CELLS  RAX [ $ 3 ] SHLQ$ ;

\ TODO Investigate using `[` to drive the terminal (i.e. as part of `QUIT`), allowing `]` to execute immediately.
\ TODO Figure out a good way to print '[ ' as a prompt (hinting that `]` does something).
\ TODO Add more error handling to `[`, namely printing unknown names with a question mark, skipping the line, and `QUIT`ting.

\ TODO Rewrite `{` and `}` to not forcefully exit the word they're in.

\ TODO Conditional compilation idea:
\      : SKIPTIL  HERE NAME, BEGIN NAME COUNT OVER COUNT COMPARE UNTIL THERE DROP ;
\      :! }}{{  SKIPTIL }} ;
\      :! X86?{{ ARCH COUNT S" X86" COMPARE 0= IF SKIPTIL }}{{ THEN ;
\      ...
\      : THERE  X86?{{ RDI RAXXCHGQ }}{{ DUP HERE - ALLOT }} ;
