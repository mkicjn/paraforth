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

:! MOV  REX.W,  $ 89 C,  $ 3 MODR/M, ;
:! INC  REX.W, $ FF C, $ 0 $ 3 MODR/M, ;
:! DEC  REX.W, $ FF C, $ 1 $ 3 MODR/M, ;

:! HERE   DOCOL  DUP  RAX RDI MOV ;
:! REL32, DOCOL  HERE $ 4 + - D, ;
:! REL8,  DOCOL  HERE $ 1 + - D, ;

:! MOV!  REX.W,  $ 89 C,  $ 0 MODR/M, ;
:! MOV@  REX.W,  $ 8B C,  $ 0 MODR/M, ;
:! MOV$  REX.W,  SWAP $ B8 + C,  , ;

:! MOVC!  $ 88 C, $ 0 MODR/M, ;
:! MOVZX@  REX.W, $ B60F W, SWAP $ 0 MODR/M, ;

:! RAXXCHG  REX.W, $ 90 + C, ;

:! COMPILE DOCOL  $ E8 C, REL32, ;
:! CALL$  COMPILE ;
:! CALL  $ FF C, $ 2 $ 3 MODR/M, ;

:! ADD   REX.W, $ 01 C, $ 3 MODR/M, ;
:! SUB   REX.W, $ 29 C, $ 3 MODR/M, ;
:! ADD$  REX.W, $ 81 C, SWAP $ 0 $ 3 MODR/M, D, ;
:! SUB$  REX.W, $ 81 C, SWAP $ 5 $ 3 MODR/M, D, ;
:! MUL   REX.W, $ F7 C, $ 4 $ 3 MODR/M, ;
:! DIV   REX.W, $ F7 C, $ 6 $ 3 MODR/M, ;

:! PUSH  $ 50 + C, ;
:! POP   $ 58 + C, ;

:! AND  REX.W, $ 21 C, $ 3 MODR/M, ;
:!  OR  REX.W, $ 09 C, $ 3 MODR/M, ;
:! XOR  REX.W, $ 31 C, $ 3 MODR/M, ;
:! NOT  REX.W, $ F7 C, $ 2 $ 3 MODR/M, ;
:! NEG  REX.W, $ F7 C, $ 3 $ 3 MODR/M, ;

:! JMP$  $ E9 C, REL32, ;
:! JMP   $ FF C, $ 4 $ 3 MODR/M, ;
:! JZ$   $ 840F W, REL32, ;
:! JNZ$  $ 850F W, REL32, ;

:! REP    $ F3 C, ;
:! REPE   $ F3 C, ;
:! CMPSB  $ A6 C, ;
:! MOVSB  $ A4 C, ;
:! STOSB  $ AA C, ;
