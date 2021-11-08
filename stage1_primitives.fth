:! POSTPONE  NAME FIND COMPILE ;
:! :  POSTPONE :! POSTPONE DOCOL ;

: THERE  RDI RAXXCHGQ  ;
: ALLOT  RDI RAX ADDQ  DROP ;
: 1ALLOT  RDI INCQ ;

: 1+  RAX INCQ ;

: COND  RBX RAX MOVQ  DROP  RBX RBX TESTQ ;

:! BEGIN  HERE ;
:! AHEAD  HERE 1+  HERE POSTPONE JMP$ ;
:! IF  POSTPONE COND  HERE 1+  HERE POSTPONE JZ$ ;
:! AGAIN  POSTPONE JMP$ ;
:! UNTIL  POSTPONE COND POSTPONE JZ$ ;
:! THEN  THERE  DUP REL8,  THERE DROP ;
:! ELSE  POSTPONE AHEAD  SWAP  POSTPONE THEN ;
:! WHILE  POSTPONE IF  SWAP ;

: STARTFOR  RBX POPQ  RCX PUSHQ  RBX PUSHQ  RCX RAX MOVQ  DROP ;
: ENDFOR  RBX POPQ  RCX POPQ  RBX PUSHQ ;
:! FOR  POSTPONE STARTFOR HERE ;
:! AFT  DROP POSTPONE AHEAD POSTPONE BEGIN SWAP ;
:! NEXT  POSTPONE LOOP$ POSTPONE ENDFOR ;
: I  DUP  RAX RCX MOVQ ;


: EXECUTE   RBX RAX MOVQ  DROP  RBX JMP
:! [  RDI PUSHQ  BEGIN NAME FIND EXECUTE AGAIN
:! ]  POSTPONE ;  RBX POPQ  RDI POPQ  RDI JMP

: C@  RAX RAX MOVZXB@ ;
: C!  RAX RDX MOVB!  DROP DROP ;

: 1+  RAX INCQ ;
: 1-  RAX DECQ ;

: COUNT  1+ DUP 1- C@ ;

: >R  RBX POPQ  RAX PUSHQ  RBX PUSHQ  DROP ;
: R>  DUP  RBX POPQ  RAX POPQ  RBX PUSHQ ;
: RDROP  RBX POPQ  RSP [ $ 8 ] ADDQ$  RBX PUSHQ ;

: CONTEXT>R  RBX POPQ   RCX PUSHQ RSI PUSHQ RDI PUSHQ  RBX PUSHQ ;
: R>CONTEXT  RBX POPQ   RDI POPQ  RSI POPQ  RCX POPQ   RBX PUSHQ ;

: MOVE  CONTEXT>R  RDI RAX MOVQ DROP  RCX RAX MOVQ DROP  RSI RAX MOVQ  REP MOVSB
        RAX RDI MOVQ  R>CONTEXT  RDI RAX MOVQ  DROP ;

: INLINE  R> COUNT HERE MOVE ;
:! {  POSTPONE INLINE  HERE  1ALLOT ;
:! }  DUP 1+  HERE SWAP -  SWAP C! ;

: TEST  $ 7F FOR AFT I TX THEN NEXT ;
[ TEST ]



[ BYE ] \ Comments aren't implemented yet, but this halts the compiler before it reads beyond this.

\ These are some source code fragments for words that I want to implement soon.
\ They are by no means complete or functional in their current form.

\ TODO Investigate using `[` to drive the terminal (i.e. as part of `QUIT`), allowing `]` to execute immediately.
\ TODO Figure out a good way to print '[ ' as a prompt (hinting that `]` does something).
\ TODO Add more error handling to `[`, namely printing unknown names with a question mark, skipping the line, and `QUIT`ting.

\ TODO Rewrite `{` and `}` to not forcefully exit the word they're in.

: NIP   ( what's the best way? rbp indirection is hard at the moment. primitives? )
: TUCK  ( ^ ditto )
: OVER  ( ^ ditto )

: 0=  RBX DUPXORQ  RAX RAX TESTQ  RBX SETNZB  RBX DEC  RAX RBX MOVQ ;
: =   RBX DUPXORQ  RDX RAX CMPQ   RBX SETNZB  RBX DEC  RAX RBX MOVQ  NIP ;
:! \  BEGIN TX $ A = UNTIL ;

: *  RDX MUL  NIP ;
: LITERAL  DOLIT , ;
: CHAR  NAME 1+ C@ LITERAL ;
: TYPE  FOR DUP C@ TX 1+ NEXT DROP ;
: #  $ 0 NAME  COUNT FOR  >R  $ A *  R@ C@ DIGIT +  R> 1+  NEXT DROP ;
: TX#  $ 0 >R  BEGIN  # 10 /MOD  R> 1+ >R  DUP 0= UNTIL  DROP
       R> 1- FOR  $ 30 + TX  NEXT ;
: BL  $ 20 ;
: CR  $ A EMIT ;
: REL8!  HERE OVER 1+ - SWAP C! ;
: PARSE,  HERE 1ALLOT  >R RX BEGIN DUP R@ <> WHILE C, RX REPEAT DROP
          HERE OVER 1+ - SWAP C! ;
: PARSE   HERE PARSE, THERE DROP ;
: S"  HERE POSTPONE AHEAD  CHAR " PARSE,  POSTPONE THEN  LITERAL ;
: ."  POSTPONE S" { COUNT TYPE } ;
