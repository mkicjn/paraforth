:! POSTPONE  NAME FIND COMPILE ;
:! :  POSTPONE :! POSTPONE DOCOL ;

:! DPOPQ  POSTPONE RBPMOVQ@  POSTPONE RBP $ 8 POSTPONE ADDQ$ ;
:! DPUSHQ  POSTPONE RBP $ 8 POSTPONE SUBQ$  POSTPONE RBPMOVQ! ;

: NIP  RDX DPOPQ ;
: TUCK  RAX DPUSHQ ;
: OVER  SWAP TUCK ;
: 2DUP  RDX DPUSHQ  RAX DPUSHQ ;
: 2DROP  RAX DPOPQ  RDX DPOPQ ;

: THERE  RDI RAXXCHGQ  ;
: ALLOT  RDI RAX ADDQ  DROP ;
: 1ALLOT  RDI INCQ ;

: 1+  RAX INCQ ;
: 1-  RAX DECQ ;

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

:! 0<  POSTPONE RAX  $ 3F POSTPONE SARQ$ ;
: 0=  RBX DUPXORQ  RAX RAX TESTQ  RBX SETNZB  RBX DECQ  RAX RBX MOVQ ;
: =  RBX DUPXORQ  RDX RAX CMPQ  RBX SETNZB  RBX DECQ  RAX RBX MOVQ  NIP ;
: <>  RBX DUPXORQ  RDX RAX CMPQ  RBX SETZB  RBX DECQ  RAX RBX MOVQ  NIP ;
:! \  BEGIN  RX $ A =  UNTIL ;

\ Comments are now enabled!

: STARTFOR  RBX POPQ  RCX PUSHQ  RBX PUSHQ  RCX RAX MOVQ  DROP ;
: ENDFOR  RBX POPQ  RCX POPQ  RBX PUSHQ ;
:! FOR  POSTPONE STARTFOR HERE ;
:! AFT  DROP POSTPONE AHEAD POSTPONE BEGIN SWAP ;
:! NEXT  POSTPONE LOOP$ POSTPONE ENDFOR ;
: I  DUP  RAX RCX MOVQ ;

: C@  RAX RAX MOVZXB@ ;
: C!  RAX RDX MOVB!  DROP DROP ;

: COUNT  1+ DUP 1- C@ ;
: TYPE  FOR DUP C@ TX 1+ NEXT DROP ;

: CR  $ A TX ;
: BL  $ 20 ;
: LITERAL  DOLIT , ;
:! CHAR  NAME 1+ C@ LITERAL ;

: EXECUTE  RBX RAX MOVQ  DROP  RBX JMP
:! [  RDI PUSHQ  BEGIN  NAME DUP FIND  DUP
                 IF  NIP EXECUTE
                 ELSE  DROP  COUNT TYPE  CHAR ? TX  CR  POSTPONE \
\ TODO ^ POSTPONE \ should be replaced by QUIT later.
                 THEN AGAIN
:! ]  POSTPONE ;  RBX POPQ  RDI POPQ  RDI JMP
[
\ TODO ^ This should also be replaced by QUIT later.
\ : QUIT  BEGIN CHAR [ TX BL TX POSTPONE [ AGAIN ;
\ ^ This definition almost works, but needs to reset registers
\ Another problem: These definitions rely on each other.

: >R  RBX POPQ  RAX PUSHQ  RBX PUSHQ  DROP ;
: R>  DUP  RBX POPQ  RAX POPQ  RBX PUSHQ ;
: R@  DUP  RBX POPQ  RAX POPQ  RAX PUSHQ RBX PUSHQ ;
\ TODO fix ^ Like RBP, MOVQ! doesn't work as intended with RSP due to SIB encoding
: RDROP  RBX POPQ  RSP [ $ 8 ] ADDQ$  RBX PUSHQ ;

: CONTEXT>R  RBX POPQ  RCX PUSHQ RSI PUSHQ RDI PUSHQ  RBX PUSHQ ;
: R>CONTEXT  RBX POPQ  RDI POPQ  RSI POPQ  RCX POPQ   RBX PUSHQ ;
: MOVE  CONTEXT>R  RDI RAX MOVQ DROP  RCX RAX MOVQ DROP  RSI RAX MOVQ  REP MOVSB
        RAX RDI MOVQ  R>CONTEXT  RDI RAX MOVQ  DROP ;
\ TODO ^ Refactor

: INLINE  R> COUNT HERE MOVE ;
:! {  POSTPONE INLINE  HERE  1ALLOT ;
:! }  DUP 1+  HERE SWAP -  SWAP C! ;
\ ^ Hopefully these can be used later for metacompilation.
\ Right now they are of limited usefulness, since the kernel is committed to mostly pure subroutine-threaded code for simplicity.

: *  RDX MULQ  NIP ;
: UM/MOD  RBX RAX MOVQ  RAX RDX MOVQ  RDX DUPXORQ  RBX DIVQ ;

:! #  $ 0 NAME  COUNT FOR  >R  $ A *  R@ C@ DIGIT +  R> 1+  NEXT DROP  LITERAL ;
: .#  $ 0  BEGIN >R  # 10 UM/MOD  R> 1+  OVER 0= UNTIL  NIP
       FOR  CHAR 0 + TX  NEXT ;
\ TODO ^ Refactor words like these that are hard to read

: PARSE,  HERE SWAP 1ALLOT
          RX BEGIN 2DUP <> WHILE C, RX REPEAT 2DROP
          HERE OVER 1+ - SWAP C! ;
\ TODO Might help to have words for generating counted strings
: PARSE  HERE SWAP PARSE, THERE DROP ;
:! S"  POSTPONE AHEAD  HERE CHAR " PARSE,  SWAP POSTPONE THEN  LITERAL ;
\ TODO The bug where I forgot the SWAP before POSTPONE THEN was hard to catch; I need words that will check stack depth after a definition to ensure correctness.
\ Perhaps : can put the current stack pointer on the stack, and ; can try to check for it and QUIT if it fails to match.
:! ."  POSTPONE S"  POSTPONE COUNT  POSTPONE TYPE ;

[ ." Hello, world!" CR ]



[ BYE ]

\ These are some source code fragments for words that I want to implement soon.
\ They are by no means complete or functional in their current form.

\ TODO Investigate using `[` to drive the terminal (i.e. as part of `QUIT`), allowing `]` to execute immediately.
\ TODO Figure out a good way to print '[ ' as a prompt (hinting that `]` does something).
\ TODO Add more error handling to `[`, namely printing unknown names with a question mark, skipping the line, and `QUIT`ting.

\ TODO Rewrite `{` and `}` to not forcefully exit the word they're in.
