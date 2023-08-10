:! POSTPONE  NAME FIND COMPILE ;
:! :  POSTPONE :! POSTPONE DOCOL ;

:! BPOPQ  POSTPONE RBPMOVQ@  POSTPONE RBP $ 8 POSTPONE ADDQ$ ;
:! BPUSHQ  POSTPONE RBP $ 8 POSTPONE SUBQ$  POSTPONE RBPMOVQ! ;

: COND  RBX RAX MOVQ  DROP  RBX RBX TESTQ ;
:! BEGIN  DUP  RAX RDI MOVQ ;
:! UNTIL  POSTPONE COND POSTPONE JZ$ ;

: =  RAX RDX CMPQ  RAX SETEB  RAX RAX MOVZXBL  RDX BPOPQ ;
:! \  BEGIN  KEY $ A =  UNTIL ;

\ Now that comments are supported, documentation for the high-level stuff can begin.

\ The main thing to point out before now is that there's a bit of a chicken-and-egg problem between COMPILE, POSTPONE, and CALLQ$.
\ I chose to solve this by implementing COMPILE as a regular colon word, which implements a sort of "generalized DOCOL."
\ TODO : Maybe there's a neat trick to avoid that. I would have preferred to keep ALL high level definitions in this file, but it seemed unavoidable.

\ BPOPQ and BPUSHQ are sort of pseudo-instructions, and the definitions of BEGIN and UNTIL are just temporary (but necessary) infrastructure.
\ (Fun fact - BEGIN is just an immediate HERE)

\ The first immediately useful thing to implement is primitive inlining, so it affects as much code as possible.
\ Since there aren't that many primitives to begin with, this works out nicely.

\ Inlining can be implemented easily enough by creating a parsing word that postpones every word entered after it until it hits an "end" word.
\ I choose braces for this syntax because it's the conceptual opposite of what brackets would represent in a typical Forth.
: LITERAL  DOLIT , ;
:! '  NAME FIND LITERAL ;
:! }  ; \ just a no-op to compare against
:! {  BEGIN  NAME FIND DUP COMPILE  ' } =  UNTIL ; \ Since we don't have WHILE and REPEAT, } gets postponed too - good thing it's a no-op.
\ TODO : This is good enoough, but will break if } is ever redefined due to hyperstatic scoping - would prefer to avoid this, and stop compiling no-ops.

\ This makes it act as though the user typed all those words directly into their definition, since words always get executed immediately when typed.
\ However, it won't work at all with words that parse input, because there's no way to save the input for later.
\ TODO : This is much better than copying compiled code (which breaks relative offsets), but is there an elegant way to address this final limitation?

\ Implementing the actual primitives is pretty straightforward and unexciting.
\ See the notes in kernel.asm to understand the register convention.
\ (Note that some operations are redefined to allow for a more optimized inlining implementation)

\ Stack manipulation
:! DUP  { RDX BPUSHQ  RDX RAX MOVQ } ;
:! DROP  { RAX RDX MOVQ  RDX BPOPQ } ;
:! SWAP  { RDX RAXXCHGQ } ;
:! NIP  { RDX BPOPQ } ;
:! TUCK  { RAX BPUSHQ } ;
:! OVER  { SWAP TUCK } ;
:! ROT  { RBX BPOPQ  DUP  RAX RBX MOVQ } ;
:! -ROT  { RBX RAX MOVQ  DROP  RBX BPUSHQ } ;
:! 2DUP  { RDX BPUSHQ  RAX BPUSHQ } ;
:! 2DROP  { RAX BPOPQ  RDX BPOPQ } ;

\ Memory operations
:! @  { RAX RAX MOVQ@ } ;
:! !  { RAX RDX MOVQ!  2DROP } ;
:! C@  { RAX RAX MOVZXB@ } ;
:! C!  { RAX RDX MOVB!  2DROP } ;
:! ,   { STOSQ  DROP } ;
:! C,  { STOSB  DROP } ;

\ Return stack operations
:! >R  { RAX PUSHQ  DROP } ;
:! R>  { DUP  RAX POPQ } ;
:! 2>R  { RDX PUSHQ  RAX PUSHQ  2DROP } ;
:! 2R>  { 2DUP  RDX POPQ  RAX POPQ } ;
:! R@  { DUP  RAX (SIB) MOVQ@  RSP (NONE) R*1 SIB, } ;
:! RDROP  $ 8 { RSP ADDQ$ } ;

\ Basic arithmetic
:! +  { RAX RDX ADDQ  NIP } ;
:! -  { RDX RAX SUBQ  DROP } ;
:! 1+  { RAX INCQ } ;
:! 1-  { RAX DECQ } ;
:! 2*  { RAX 1SHLQ } ;
:! 2/  { RAX 1SARQ } ;
:! NEGATE  { RAX NEGQ } ;
:! *  { RDX MULQ  NIP } ;
:! UM/MOD  { RBX RAX MOVQ  RAX RDX MOVQ  RDX RDX XORQ  RBX DIVQ } ;
:! LSHIFT  { RCX PUSHQ  RCX RAX MOVQ  RDX CLSHLQ  RCX POPQ  DROP } ;
:! RSHIFT  { RCX PUSHQ  RCX RAX MOVQ  RDX CLSHRQ  RCX POPQ  DROP } ;

\ Bitwise arithmetic
:! INVERT  { RAX NOTQ } ;
:! AND  { RAX RDX ANDQ  NIP } ;
:! OR  { RAX RDX ORQ  NIP } ;
:! XOR  { RAX RDX XORQ  NIP } ;

\ Comparisons
\ The repeated MOVZXBLs are ugly, but it's easier than clearing RBX
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
:! THERE  { RDI RAXXCHGQ } ; \ Useful for temporarily setting/resetting the data pointer
:! ALLOT  { RDI RAX ADDQ  DROP } ;

\ Control structures
: COND  { RBX RAX MOVQ  DROP  RBX RBX TESTQ } ; \ Compile code that sets flags based on top stack item
\ ^ Note: Not immediate
:! BEGIN  HERE ; \ Leave a back reference on the stack (redundant definition here only for completeness)
:! AGAIN        { JMPL$ } ; \ Resolve a back reference on the stack (compile a backwards jump)
:! UNTIL  COND  { JZL$ } ;  \ Resolve a back reference on the stack with a conditional jump
:! AHEAD        HERE 1+     HERE { JMPL$ } ; \ Leave a forward reference on the stack
:! IF     COND  HERE 1+ 1+  HERE { JZL$ } ;  \ Leave a conditional forward reference on the stack
\ ^^ Note: AHEAD and IF can both cause infinite loops if not terminated - need to check for same stack depth when compiling later
:! THEN  THERE  DUP REL32,  THERE DROP ; \ Resolve a forward reference (fill in a forward jump)
:! ELSE  POSTPONE AHEAD  SWAP  POSTPONE THEN ; \ Leave a forward reference, then resolve an existing one
:! WHILE  POSTPONE IF  SWAP ; \ Leave a forward reference on the stack under an existing (back) reference
:! REPEAT  POSTPONE AGAIN  POSTPONE THEN ; \ Resolve a back reference, then resolve a forward reference

\ Definite loops
\ Note: FOR..NEXT only supports 256 byte bodies due to rel8 encoding
:! FOR  { RCX PUSHQ  RCX RAX MOVQ  DROP } HERE ;
:! NEXT  { LOOP$  RCX POPQ } ;
:! AFT  DROP  POSTPONE AHEAD  POSTPONE BEGIN  SWAP ;
:! I  { DUP  RAX RCX MOVQ } ;
\ TODO : Include DO, LOOP, +LOOP and LEAVE?

\ "Interpreter"

\ This is another interesting place where this Forth differs from tradition.
\ Since there is no distinct compile/interpret state, we can compensate quite effectively by simply allowing code to be compiled and executed "immediately".
\ The obvious limitation this has is that it's possible to accidentally compile over the code while it executes.

\ So far, though, this limitation seems difficult to run into by accident, and easy to work around if you do.
\ TODO : There are obvious modifications to try if this ever does becomes an issue, but a general solution is not clear enough to implement right away.
\ Either way, this is arguably more powerful in some ways than what is offered in a typical Forth, since it can be arbitrarily nested in interesting ways.
\ This approach also eliminates the need for a whole host of inconsistently-bracketed or state-aware words.

:! EXECUTE  { RBX RAX MOVQ  DROP  RBX CALLQ } ;
:! [ HERE ;
:! ] POSTPONE ; DUP THERE DROP EXECUTE ;

\ Side note: I think it's very interesting that this level of sophistication is achievable at all, let alone so easily, given how simple the kernel is.
\ Upon reflection, I guess it's ultimately a consequence of allowing immediate words, which compile code, to be defined and executed immediately themselves.
\ This idea starts to feel like it's approaching some distillation of the concept of metaprogramming - can it be taken any further?


\ TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO

\ Continue going through and moving improved versions of below stuff up above.
\ Two main directives:
\ * Move/remove the complex stuff in this file (string operations, REPL-like functionality)
\ * Focus on inlining as many primitives as possible (and implement the rest normally)
\ Goal here is now to have a stable (but not sophisticated) platform on which to build
\ The sophisticated bits can and should come later.

\ Probably want to include CREATE/DOES>, VARIABLE/CONSTANT, and other standard Forth words in here
\ That is, unless I get an interesting load order mechanism sorted out
\ Question: Where to draw the line with the "primitive" distinction?

\ TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO

\ Parenthesis comments
:! CHAR  NAME 1+ C@ LITERAL ;
:! (  BEGIN KEY CHAR ) = UNTIL ;

\ Word manipulation
: COUNT  1+ DUP 1- C@ ;
: TYPE  FOR DUP C@ EMIT 1+ NEXT DROP ;

\ Character constants
: CR  $ A EMIT ;
:! BL  $ 20 LITERAL ;

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
