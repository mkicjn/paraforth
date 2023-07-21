:! POSTPONE  NAME FIND COMPILE ;
:! :  POSTPONE :! POSTPONE DOCOL ;

:! DPOPQ  POSTPONE RBPMOVQ@  POSTPONE RBP $ 8 POSTPONE ADDQ$ ;
:! DPUSHQ  POSTPONE RBP $ 8 POSTPONE SUBQ$  POSTPONE RBPMOVQ! ;

: COND  RBX RAX MOVQ  DROP  RBX RBX TESTQ ;
:! BEGIN  HERE ;
:! UNTIL  POSTPONE COND POSTPONE JZ$ ;

: =  RAX RDX CMPQ  RAX SETEB  RAX RAX MOVZXBL  RDX DPOPQ ;
:! \  BEGIN  KEY $ A =  UNTIL ;
\ Comments are now enabled!

\ Inlining as postponement of each word
: LITERAL  DOLIT , ;
:! '  NAME FIND LITERAL ;
:! }  ; \ no-op
:! {  BEGIN  NAME FIND DUP COMPILE  ' } =  UNTIL ;

\ Stack manipulation
\ (Some are redefined to allow for inlining)
:! DUP  { RDX DPUSHQ  RDX RAX MOVQ } ;
:! DROP  { RAX RDX MOVQ  RDX DPOPQ } ;
:! SWAP  { RDX RAXXCHGQ } ;
:! NIP  { RDX DPOPQ } ;
:! TUCK  { RAX DPUSHQ } ;
:! OVER  { SWAP TUCK } ;
:! ROT  { RBX DPOPQ  DUP  RAX RBX MOVQ } ;
:! -ROT  { RBX RAX MOVQ  DROP  RBX DPUSHQ } ;
:! 2DUP  { RDX DPUSHQ  RAX DPUSHQ } ;
:! 2DROP  { RAX DPOPQ  RDX DPOPQ } ;

\ Memory operations
:! @  { RAX RAX MOVQ@ } ;
:! !  { RAX RDX MOVQ!  2DROP } ;
:! C@  { RAX RAX MOVZXB@ } ;
:! C!  { RAX RDX MOVB!  2DROP } ;
:! ,   { STOSQ  DROP } ;
:! C,  { STOSB  DROP } ;

\ Basic arithmetic
\ (Some are redefined to allow for inlining)
:! +  { RAX RDX ADDQ  NIP } ;
:! -  { RDX RAX SUBQ  DROP } ;
:! 1+  { RAX INCQ } ;
:! 1-  { RAX DECQ } ;
:! 2*  { RAX 1SHLQ } ;
:! 2/  { RAX 1SARQ } ;
:! INVERT  { RAX NOTQ } ;
:! NEGATE  { RAX NEGQ } ;
:! *  { RDX MULQ  NIP } ;
:! UM/MOD  { RBX RAX MOVQ  RAX RDX MOVQ  RDX RDX XORQ  RBX DIVQ } ;
:! LSHIFT  { RCX PUSHQ  RCX RAX MOVQ  RDX CLSHLQ  RCX POPQ  DROP } ;
:! RSHIFT  { RCX PUSHQ  RCX RAX MOVQ  RDX CLSHRQ  RCX POPQ  DROP } ;

\ Comparisons
\ (Some are redefined to allow for inlining)
:! 0=  { RAX RAX TESTQ  RAX SETZB  RAX RAX MOVZXBL } ;
:! 0<>  { RAX RAX TESTQ  RAX SETNZB  RAX RAX MOVZXBL } ;
:! 0<  { RAX RAX TESTQ  RAX SETLB  RAX RAX MOVZXBL } ;
:! 0>  { RAX RAX TESTQ  RAX SETGB  RAX RAX MOVZXBL } ;
:! 0<=  { RAX RAX TESTQ  RAX SETLEB  RAX RAX MOVZXBL } ;
:! 0>=  { RAX RAX TESTQ  RAX SETGEB  RAX RAX MOVZXBL } ;
:! =  { RAX RDX CMPQ  RAX SETEB  RAX RAX MOVZXBL  NIP } ;
:! <>  { RAX RDX CMPQ  RAX SETNEB  RAX RAX MOVZXBL  NIP } ;
:! <  { RAX RDX CMPQ  RAX SETLB  RAX RAX MOVZXBL  NIP } ;
:! >  { RAX RDX CMPQ  RAX SETGB  RAX RAX MOVZXBL  NIP } ;
:! <=  { RAX RDX CMPQ  RAX SETLEB  RAX RAX MOVZXBL  NIP } ;
:! >=  { RAX RDX CMPQ  RAX SETGEB  RAX RAX MOVZXBL  NIP } ;
:! MIN  { RAX RDX CMPQ  RAX RDX CMOVLQ  NIP } ;
:! MAX  { RAX RDX CMPQ  RAX RDX CMOVGQ  NIP } ;

\ Data pointer manipulation
:! HERE  { DUP  RAX RDI MOVQ } ;
:! THERE  { RDI RAXXCHGQ } ;
:! ALLOT  { RDI RAX ADDQ  DROP } ;
:! 1ALLOT  { RDI INCQ } ;

\ TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO

\ Continue going through and moving improved versions of below stuff up above.
\ Two main directives:
\ * Move the complex stuff in this file (string operations, REPL-like functionality) elsewhere
\ * Focus on inlining as many primitives as possible (and merely implement the rest)
\ Goal here is to have a stable (but not sophisticated) platform on which to build

\ TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO

\ Parenthesis comments
:! CHAR  NAME 1+ C@ LITERAL ;
:! (  BEGIN KEY CHAR ) = UNTIL ;

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
: 2LITERAL  SWAP LITERAL LITERAL ;
:! S"  POSTPONE AHEAD  HERE CHAR " PARSE,  HERE OVER -  ROT POSTPONE THEN  2LITERAL ;
\ TODO Check stack depth after definitions to ensure correctness.
\ Perhaps : can put the current stack pointer on the stack, and ; can try to check for it and QUIT if it fails to match.
:! ."  POSTPONE S"  POSTPONE TYPE ;

\ Memory comparison
: SIGN  DUP IF  0< ( -1|0 ) 1+ ( 0|1 ) 2* ( 0|2 ) 1- ( -1|1 ) THEN ;
: COMPARE  CONTEXT@ 3>R  ROT SWAP  2DUP - SIGN >R  MIN  CONTEXT!
           R> DUP  RAX RAX XORQ  RBX RBX XORQ  REP CMPSB
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
