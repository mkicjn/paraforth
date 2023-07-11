:! POSTPONE  NAME FIND COMPILE ;
:! :  POSTPONE :! POSTPONE DOCOL ;

:! DPOPQ  POSTPONE RBPMOVQ@  POSTPONE RBP $ 8 POSTPONE ADDQ$ ;
:! DPUSHQ  POSTPONE RBP $ 8 POSTPONE SUBQ$  POSTPONE RBPMOVQ! ;

: NIP  RDX DPOPQ ;

: COND  RBX RAX MOVQ  DROP  RBX RBX TESTQ ;
:! BEGIN  HERE ;
:! UNTIL  POSTPONE COND POSTPONE JZ$ ;

: =  RBX DUPXORQ  RAX RDX CMPQ  RBX SETNZB  RBX DECQ  RAX RBX MOVQ  NIP ;
:! \  BEGIN  KEY $ A =  UNTIL ;

\ Comments are now enabled!

\ Stack manipulation
: TUCK  RAX DPUSHQ ;
: OVER  SWAP TUCK ;
: ROT  RBX DPOPQ  DUP  RAX RBX MOVQ ;
: -ROT  RBX RAX MOVQ  DROP  RBX DPUSHQ ;
: 2DUP  RDX DPUSHQ  RAX DPUSHQ ;
: 2DROP  RAX DPOPQ  RDX DPOPQ ;

\ Pointer manipulation
: @  RAX RAX MOVQ@ ;
: !  RAX RDX MOVQ! 2DROP ;
: C@  RAX RAX MOVZXB@ ;
: C!  RAX RDX MOVB!  2DROP ;

\ Literal compilation
: LITERAL  DOLIT , ;
: 2LITERAL  SWAP LITERAL LITERAL ;

\ Basic arithmetic
: 1+  RAX INCQ ;
: 1-  RAX DECQ ;
: 2*  RAX 1SHLQ ;
: 2/  RAX 1SARQ ;
: *  RDX MULQ  NIP ;
: UM/MOD  RBX RAX MOVQ  RAX RDX MOVQ  RDX DUPXORQ  RBX DIVQ ;
:! INVERT  POSTPONE RAX POSTPONE NOTQ ;
:! NEGATE  POSTPONE RAX POSTPONE NEGQ ;

\ Parenthesis comments
:! CHAR  NAME 1+ C@ LITERAL ;
:! (  BEGIN KEY CHAR ) = UNTIL ;

\ Data pointer manipulation
: THERE  RDI RAXXCHGQ  ;
: ALLOT  RDI RAX ADDQ  DROP ;
: 1ALLOT  RDI INCQ ;

\ Control structures
:! AHEAD  HERE 1+  HERE POSTPONE JMP$ ;
:! IF  POSTPONE COND  HERE 1+  HERE POSTPONE JZ$ ;
:! AGAIN  POSTPONE JMP$ ;
:! THEN  THERE  DUP REL8,  THERE DROP ;
:! ELSE  POSTPONE AHEAD  SWAP  POSTPONE THEN ;
:! WHILE  POSTPONE IF  SWAP ;
:! REPEAT  POSTPONE AGAIN  POSTPONE THEN ;
: STARTFOR  RBX POPQ  RCX PUSHQ  RBX PUSHQ  RCX RAX MOVQ  DROP ;
: ENDFOR  RBX POPQ  RCX POPQ  RBX PUSHQ ;
:! FOR  POSTPONE STARTFOR HERE ;
:! AFT  DROP POSTPONE AHEAD POSTPONE BEGIN SWAP ;
:! NEXT  POSTPONE LOOP$ POSTPONE ENDFOR ;
: I  DUP  RAX RCX MOVQ ;

\ Word manipulation
: COUNT  1+ DUP 1- C@ ;
: TYPE  FOR DUP C@ EMIT 1+ NEXT DROP ;

\ Character constants
: CR  $ A EMIT ;
:! BL  $ 20 LITERAL ;

\ "Interpreter"
: EXECUTE  RBX RAX MOVQ  DROP  RBX JMP
\ This is another interesting place where this Forth differs from tradition.
\ This compiler doesn't have an "interpreter" mode, so instead, I create a new compiler loop called `[` which is allowed to call itself,
\ and supplement that with a corresponding word `]` that exits the running compiler and immediately runs the compiled code.
\ Using `[` and `]`, one can simply compile and run arbitrary code at compile time, circumventing the need for a proper interpreter.
: NOT-FOUND  COUNT TYPE CHAR ? EMIT CR POSTPONE \
\ ^ TODO Consider replacing POSTPONE \ with QUIT
:! [  RDI PUSHQ  BEGIN  NAME DUP FIND  DUP
                 IF  NIP EXECUTE
                 ELSE  DROP NOT-FOUND
                 THEN AGAIN ;
:! ]  POSTPONE ;  RBX POPQ  RDI POPQ  RDI JMP

\ Side note: I think it's very interesting that this level of sophistication is achievable at all, let alone so quickly, given how simple the kernel is.
\ Upon reflection, I guess it's ultimately a consequence of allowing immediate words, which compile code, to be defined and composed immediately at runtime.
\ This idea starts to feel like it's approaching a distillation of some kind of fundamental concept - is it abstraction?
\ I guess the practical requirements are to be able to manipulate words and the dictionary. Some serious parallels with LISP, but Forth is even simpler.
\ To be able to assemble arbitrary machine code, some basic arithmetic is also apparently necessary.
\ How much further can it be realistically taken? What's the core concept to all this? "Metaprogramming" doesn't quite capture it.

[
\ TODO ^ Maybe this should be replaced by QUIT later.
\ : QUIT  BEGIN CHAR [ EMIT BL EMIT POSTPONE [ AGAIN ;
\ ^ This definition almost works, but needs to reset registers
\ Another problem: These definitions would rely on each other.

\ Comparison words
: 0<  RAX [ $ 3F ] SARQ$ ;
: 0=  RBX DUPXORQ  RAX RAX TESTQ  RBX SETNZB  RBX DECQ  RAX RBX MOVQ ;
: <>  RBX DUPXORQ  RAX RDX CMPQ  RBX SETZB  RBX DECQ  RAX RBX MOVQ  NIP ;
: MIN  RDX RAX CMPQ  RAX RDX CMOVLQ  DROP ;
: MAX  RDX RAX CMPQ  RAX RDX CMOVGQ  DROP ;

\ Return stack manipulation
: >R  RBX POPQ  RAX PUSHQ  RBX PUSHQ  DROP ;
: R>  DUP  RBX POPQ  RAX POPQ  RBX PUSHQ ;
: R@  DUP  RBX POPQ  RAX POPQ  RAX PUSHQ RBX PUSHQ ;
\ TODO fix ^ Like RBP, MOVQ! doesn't work as intended with RSP due to SIB encoding
: RDROP  RBX POPQ  RSP [ $ 8 ] ADDQ$  RBX PUSHQ ;

\ Memory copying
: CONTEXT@   DUP RAX RSI MOVQ  DUP RAX RDI MOVQ  DUP RAX RCX MOVQ ; \ i.e., string instruction context
: CONTEXT!   RCX RAX MOVQ DROP  RDI RAX MOVQ DROP  RSI RAX MOVQ DROP ;
: 3>R  R>  SWAP >R SWAP >R SWAP >R  >R ;
: 3R>  R>  R> SWAP R> SWAP R> SWAP  >R ;
: MOVE  CONTEXT@ 3>R  CONTEXT!  REP MOVSB  3R> CONTEXT! ;

\ Unsigned decimal integer I/O
:! #  $ 0 NAME COUNT  FOR  >R  $ A *  R@ C@ DIGIT +  R> 1+  NEXT DROP LITERAL ;
: .#  $ 0  BEGIN >R  # 10 UM/MOD  R> 1+  OVER 0= UNTIL  NIP  FOR  CHAR 0 + EMIT  NEXT ;
\ TODO Add signed decimal I/O

\ Strings
: PARSE,  ( delim -- ) KEY BEGIN 2DUP <> WHILE C, KEY REPEAT 2DROP ; \ Read keys into memory until delimiter
: PARSE  ( delim -- str cnt ) HERE SWAP PARSE, DUP THERE OVER - ;  \ PARSE, but temporary (reset data pointer)
:! S"  POSTPONE AHEAD  HERE CHAR " PARSE,  HERE OVER -  ROT POSTPONE THEN  2LITERAL ;
\ TODO Check stack depth after definitions to ensure correctness.
\ Perhaps : can put the current stack pointer on the stack, and ; can try to check for it and QUIT if it fails to match.
:! ."  POSTPONE S"  POSTPONE TYPE ;

\ Memory comparison
: SIGN  DUP IF  0< ( -1|0 ) 1+ ( 0|1 ) 2* ( 0|2 ) 1- ( -1|1 ) THEN ;
: COMPARE  CONTEXT@ 3>R  ROT SWAP  2DUP - SIGN >R  MIN  CONTEXT!
           R> DUP  RAX DUPXORQ  RBX DUPXORQ  REP CMPSB
           RAX SETNZB  RBX SETLB  RBX NEGQ  RAX RBX ORQ
           DUP IF NIP ELSE DROP THEN  3R> CONTEXT! ;

\ Dictionary manipulation
: LATEST  DUP  RAX RSI MOVQ ;
: >NAME  $ 8 + ; \ Skip 8 byte pointer
: >XT  >NAME COUNT + ; \ Skip length of string
: >BODY  >XT $ 5 + ; \ Skip length of call instruction

\ Data structures
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

\ TODO Conditional compilation idea:
\      : SKIPTIL  HERE NAME, BEGIN NAME COUNT OVER COUNT COMPARE UNTIL THERE DROP ;
\      :! }}{{  SKIPTIL }} ;
\      :! X86?{{ ARCH COUNT S" X86" COMPARE 0= IF SKIPTIL }}{{ THEN ;
\      ...
\      : THERE  X86?{{ RDI RAXXCHGQ }}{{ DUP HERE - ALLOT }} ;
