:! INT3  $ CC C, ;
:! INT3!  INT3 ;

:! W, DOCOL  DUP C,  $  8 RSHIFT C, ;
:! D, DOCOL  DUP W,  $ 10 RSHIFT W, ;
:!  , DOCOL  DUP D,  $ 20 RSHIFT D, ;

:! RAX  $ 0 ;
:! RCX  $ 1 ;
:! RDX  $ 2 ;
:! RBX  $ 3 ;
:! RSP  $ 4 ;
:! RBP  $ 5 ;
:! RSI  $ 6 ;
:! RDI  $ 7 ;

:! REX.W, DOCOL  $ 48 C, ;
:! MODR/M, DOCOL  $ 3 LSHIFT + $ 3 LSHIFT + C, ;

:! MOVQ  REX.W,  $ 89 C,  $ 3 MODR/M, ;
:! INCQ  REX.W, $ FF C, $ 0 $ 3 MODR/M, ;
:! DECQ  REX.W, $ FF C, $ 1 $ 3 MODR/M, ;

:! HERE   DOCOL  DUP  RAX RDI MOVQ ;
:! REL32, DOCOL  HERE $ 4 + - D, ;
:! REL8,  DOCOL  HERE $ 1 + - C, ;

:! MOVQ!  REX.W,  $ 89 C,  $ 0 MODR/M, ;
:! MOVQ@  REX.W,  $ 8B C,  $ 0 MODR/M, ;
:! MOVQ$  REX.W,  SWAP $ B8 + C,  , ;

:! MOVB!  $ 88 C, $ 0 MODR/M, ;
:! MOVZXB@  REX.W, $ B60F W, SWAP $ 0 MODR/M, ;

:! RAXXCHGQ  REX.W, $ 90 + C, ;

:! COMPILE DOCOL  $ E8 C, REL32, ;
:! CALLQ$  COMPILE ;
:! CALL  $ FF C, $ 2 $ 3 MODR/M, ;

:! ADDQ   REX.W, $ 01 C, $ 3 MODR/M, ;
:! SUBQ   REX.W, $ 29 C, $ 3 MODR/M, ;
:! ADDQ$  REX.W, $ 81 C, SWAP $ 0 $ 3 MODR/M, D, ;
:! SUBQ$  REX.W, $ 81 C, SWAP $ 5 $ 3 MODR/M, D, ;
:! MULQ   REX.W, $ F7 C, $ 4 $ 3 MODR/M, ;
:! DIVQ   REX.W, $ F7 C, $ 6 $ 3 MODR/M, ;

:! PUSHQ  $ 50 + C, ;
:! POPQ   $ 58 + C, ;

:! ANDQ  REX.W, $ 21 C, $ 3 MODR/M, ;
:!  ORQ  REX.W, $ 09 C, $ 3 MODR/M, ;
:! XORQ  REX.W, $ 31 C, $ 3 MODR/M, ;
:! NOTQ  REX.W, $ F7 C, $ 2 $ 3 MODR/M, ;
:! NEGQ  REX.W, $ F7 C, $ 3 $ 3 MODR/M, ;

:! CMPQ   REX.W, $ 39 C, $ 3 MODR/M, ;
:! TESTQ  REX.W, $ 85 C, $ 3 MODR/M, ;

:! JMP$  $ EB C, REL8, ;
:! LOOP$  $ E2 C, REL8, ;
:! JZ$   $ 74 C, REL8, ;
:! JNZ$   $ 75 C, REL8, ;

:! JMP   $ FF C, $ 4 $ 3 MODR/M, ;
:! JMPQ$  $ E9 C, REL32, ;
:! JZQ$   $ 840F W, REL32, ;
:! JNZQ$  $ 850F W, REL32, ;

:! REP    $ F3 C, ;
:! REPE   $ F3 C, ;
:! CMPSB  $ A6 C, ;
:! MOVSB  $ A4 C, ;
:! STOSB  $ AA C, ;
:! STOSQ  REX.W, $ AB C, ;
