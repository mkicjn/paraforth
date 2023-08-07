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
:! (SIB)  $ 4 ;
:! (NONE) $ 4 ;

:! MEM     DOCOL  $ 0 ;
:! MEM+8   DOCOL  $ 1 ;
:! MEM+32  DOCOL  $ 2 ;
:! REG     DOCOL  $ 3 ;
:! MODR/M, DOCOL  $ 3 LSHIFT + $ 3 LSHIFT + C, ;

:! R*1  $ 0 ;
:! R*2  $ 1 ;
:! R*4  $ 2 ;
:! R*8  $ 3 ;
:! SIB, MODR/M, ;

:! REX.W, DOCOL  $ 48 C, ;

:! ADDQ   REX.W, $ 01 C, REG MODR/M, ;
:! SUBQ   REX.W, $ 29 C, REG MODR/M, ;
:! ADDQ$  REX.W, $ 81 C, SWAP $ 0 REG MODR/M, D, ;
:! SUBQ$  REX.W, $ 81 C, SWAP $ 5 REG MODR/M, D, ;
:! MULQ   REX.W, $ F7 C, $ 4 REG MODR/M, ;
:! DIVQ   REX.W, $ F7 C, $ 6 REG MODR/M, ;
:! INCQ   REX.W, $ FF C, $ 0 REG MODR/M, ;
:! DECQ   REX.W, $ FF C, $ 1 REG MODR/M, ;

:! REL32, DOCOL  RAX RDI SUBQ  $ 4 - D, ;
:! REL8,  DOCOL  RAX RDI SUBQ  $ 1 - C, ;

:! MOVQ   REX.W,  $ 89 C,  REG MODR/M, ;
:! MOVQ!  REX.W,  $ 89 C,  MEM MODR/M, ;
:! MOVQ@  REX.W,  SWAP $ 8B   C,  MEM MODR/M, ;
:! MOVQ$  REX.W,  SWAP $ B8 + C,  , ;
:! RBPMOVQ@  $ 5 SWAP  REX.W, $ 8B C, $ 1 MODR/M, $ 0 C, ;
:! RBPMOVQ!  $ 5 SWAP  REX.W, $ 89 C, $ 1 MODR/M, $ 0 C, ;

:! MOVB!  $ 88 C, MEM MODR/M, ;
:! MOVZXB@  REX.W, $ B60F W, SWAP MEM MODR/M, ;
:! MOVZXBL  $ B60F W, REG MODR/M, ;

:! RAXXCHGQ  REX.W, $ 90 + C, ;

:! COMPILE  DOCOL  $ E8 C, REL32, ;
:! CALLQ$  COMPILE ;
:! CALL  $ FF C, $ 2 REG MODR/M, ;

:! PUSHQ  $ 50 + C, ;
:! POPQ   $ 58 + C, ;

:! ANDQ  REX.W, $ 21 C, REG MODR/M, ;
:!  ORQ  REX.W, $ 09 C, REG MODR/M, ;
:! XORQ  REX.W, $ 31 C, REG MODR/M, ;
:! NOTQ  REX.W, $ F7 C, $ 2 REG MODR/M, ;
:! NEGQ  REX.W, $ F7 C, $ 3 REG MODR/M, ;

:! SHRQ$  SWAP REX.W, $ C1 C, $ 5 REG MODR/M, C, ;
:! SHLQ$  SWAP REX.W, $ C1 C, $ 6 REG MODR/M, C, ;
:! SARQ$  SWAP REX.W, $ C1 C, $ 7 REG MODR/M, C, ;
:! 1SHRQ  REX.W, $ D1 C, $ 5 REG MODR/M, ;
:! 1SHLQ  REX.W, $ D1 C, $ 6 REG MODR/M, ;
:! 1SARQ  REX.W, $ D1 C, $ 7 REG MODR/M, ;
:! CLSHRQ  REX.W, $ D3 C, $ 5 REG MODR/M, ;
:! CLSHLQ  REX.W, $ D3 C, $ 6 REG MODR/M, ;
:! CLSARQ  REX.W, $ D3 C, $ 7 REG MODR/M, ;

:! CMPQ   SWAP REX.W, $ 39 C, REG MODR/M, ;
:! TESTQ  REX.W, $ 85 C, REG MODR/M, ;

:! SETZB   $ 940F W, $ 0 REG MODR/M, ;
:! SETEB   $ 940F W, $ 0 REG MODR/M, ;
:! SETNZB  $ 950F W, $ 0 REG MODR/M, ;
:! SETNEB  $ 950F W, $ 0 REG MODR/M, ;
:! SETLB   $ 9C0F W, $ 0 REG MODR/M, ;
:! SETGEB  $ 9D0F W, $ 0 REG MODR/M, ;
:! SETLEB  $ 9E0F W, $ 0 REG MODR/M, ;
:! SETGB   $ 9F0F W, $ 0 REG MODR/M, ;

:! CMOVAQ  SWAP REX.W, $ 470F W, REG MODR/M, ;
:! CMOVBQ  SWAP REX.W, $ 420F W, REG MODR/M, ;
:! CMOVGQ  SWAP REX.W, $ 4F0F W, REG MODR/M, ;
:! CMOVLQ  SWAP REX.W, $ 4C0F W, REG MODR/M, ;

:! JMP   $ FF C, $ 4 REG MODR/M, ;
:! JMP$  $ EB C, REL8, ;
:! JZ$   $ 74 C, REL8, ;
:! JNZ$   $ 75 C, REL8, ;
:! LOOP$  $ E2 C, REL8, ;
:! JMPL$  $ E9 C, REL32, ;
:! JZL$   $ 840F W, REL32, ;
:! JNZL$  $ 850F W, REL32, ;

:! REP    $ F3 C, ;
:! REPE   $ F3 C, ;
:! CMPSB  $ A6 C, ;
:! MOVSB  $ A4 C, ;
:! STOSB  $ AA C, ;
:! STOSQ  REX.W, $ AB C, ;

:! SYSCALLQ  $ 050F W, ;
