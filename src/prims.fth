:! FIND  DOCOL  SEEK  $ 8 +  RBX RAX MOVZXB@  RAX RBX ADDQ  RAX INCQ ;
:! POSTPONE  NAME FIND COMPILE ;
:! :  POSTPONE :! POSTPONE DOCOL ;

: COND  RBX RAX MOVQ  DROP  RBX RBX TESTQ ;
:! BEGIN  DUP  RAX RDI MOVQ ;
:! UNTIL  POSTPONE COND POSTPONE JZ$ ;

: =  RAX RDX CMPQ  RAX SETEB  RAX RAX MOVZXBL  SWAP DROP ;
:! \  BEGIN  KEY $ A =  UNTIL ;


\ Now that comments are supported, documentation for the high-level stuff can begin.

\ The main thing to point out before now is that there's a bit of a chicken-and-egg problem between COMPILE, POSTPONE, and CALL$.
\ I chose to solve this by implementing COMPILE as a regular colon word, which implements a sort of "generalized DOCOL."
\ Most of the above definitions in this file are just temporary infrastructure and will be redefined later.

\ TODO  Maybe there are some neat tricks to avoid some of these. I would prefer to keep ALL high level definitions in this file, and reduce those above this line.


\ Inlining

\ The first immediately useful thing to implement is primitive inlining, so it affects as much code as possible.
\ Since there aren't that many primitives to begin with, this works out nicely.

\ Inlining can be implemented easily enough by creating a parsing word that postpones every word entered after it until it hits an "end" word.
\ I choose braces for this syntax because it's the conceptual opposite of what brackets would represent in a typical Forth.
: LITERAL  DOLIT , ;
:! '  NAME FIND LITERAL ;
:! }  ; \ just a no-op to compare against
:! {  BEGIN  NAME FIND DUP COMPILE  ' } =  UNTIL ; \ Since we don't have WHILE and REPEAT, } gets postponed too - good thing it's a no-op.

\ This makes it act as though the user typed all those words directly into their definition, since words always get executed immediately when typed.
\ However, it won't work at all with words that parse input, because there's no way to save the input for later.
\ TODO  This is much better than copying compiled code, but will also break if } is ever redefined due to hyperstatic scoping - would prefer to avoid this, and stop compiling no-ops.


\ Implementing the actual primitives is pretty straightforward and unexciting.
\ See the notes in core.asm to understand the register convention.
\ (Note that some operations are redefined to allow for a more optimized inlining implementation)

\ DPOPQ and DPUSHQ are pseudo-instructions corresponding to the data stack
:! DPOPQ   { RBPMOVQ@  RBP } $ 8 { ADDQ$ } ;
:! DPUSHQ  { RBP } $ 8 { SUBQ$  RBPMOVQ! } ;

\ Stack manipulation
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

\ Return stack operations
:! >R  { RAX PUSHQ  DROP } ;
:! R>  { DUP  RAX POPQ } ;
:! 2>R  { RDX PUSHQ  RAX PUSHQ  2DROP } ;
:! 2R>  { 2DUP  RDX POPQ  RAX POPQ } ;
:! R@  { DUP  RAX (SIB) MOVQ@  RSP (NONE) R*1 SIB, } ;
:! RDROP  { RSP } $ 8 { ADDQ$ } ;

\ Basic arithmetic
:! +  { RAX RDX ADDQ  NIP } ;
:! -  { RDX RAX SUBQ  DROP } ;
:! 1+  { RAX INCQ } ;
:! 1-  { RAX DECQ } ;
:! 2*  { RAX 1SHLQ } ;
:! 2/  { RAX 1SARQ } ;
:! NEGATE  { RAX NEGQ } ;
:! LSHIFT  { RCX PUSHQ  RCX RAX MOVQ  RDX CLSHLQ  RCX POPQ  DROP } ;
:! RSHIFT  { RCX PUSHQ  RCX RAX MOVQ  RDX CLSHRQ  RCX POPQ  DROP } ;
:! *     { RDX MULQ  NIP } ;
:! /MOD  { RBX RAX MOVQ  RAX RDX MOVQ  RDX RDX XORQ  RBX DIVQ } ;
:! /     { /MOD NIP } ;
:! MOD   { /MOD DROP } ;

\ Bitwise arithmetic
:! INVERT  { RAX NOTQ } ;
:! AND  { RAX RDX ANDQ  NIP } ;
:! OR  { RAX RDX ORQ  NIP } ;
:! XOR  { RAX RDX XORQ  NIP } ;

\ Comparisons
\ The repeated MOVZXBLs are ugly, but it's easier than clearing RBX
:! 0=   { RAX RAX TESTQ  RAX SETZB   RAX RAX MOVZXBL } ;
:! 0<>  { RAX RAX TESTQ  RAX SETNZB  RAX RAX MOVZXBL } ;
:! 0<   { RAX RAX TESTQ  RAX SETLB   RAX RAX MOVZXBL } ;
:! 0>   { RAX RAX TESTQ  RAX SETGB   RAX RAX MOVZXBL } ;
:! 0<=  { RAX RAX TESTQ  RAX SETLEB  RAX RAX MOVZXBL } ;
:! 0>=  { RAX RAX TESTQ  RAX SETGEB  RAX RAX MOVZXBL } ;
:! =   { RAX RDX CMPQ  RAX SETEB   RAX RAX MOVZXBL  NIP } ;
:! <>  { RAX RDX CMPQ  RAX SETNEB  RAX RAX MOVZXBL  NIP } ;
:! <   { RAX RDX CMPQ  RAX SETLB   RAX RAX MOVZXBL  NIP } ;
:! >   { RAX RDX CMPQ  RAX SETGB   RAX RAX MOVZXBL  NIP } ;
:! <=  { RAX RDX CMPQ  RAX SETLEB  RAX RAX MOVZXBL  NIP } ;
:! >=  { RAX RDX CMPQ  RAX SETGEB  RAX RAX MOVZXBL  NIP } ;
:! MIN  { RAX RDX CMPQ  RAX RDX CMOVLQ  NIP } ;
:! MAX  { RAX RDX CMPQ  RAX RDX CMOVGQ  NIP } ;

\ System register manipulation
:! HERE   { DUP  RAX RDI MOVQ } ; \ data space pointer
:! THERE  { RDI RAXXCHGQ } ;
:! BACK   { RDI RAX MOVQ  DROP } ;
:! ALLOT  { RDI RAX ADDQ  DROP } ;
:! SP@  { DUP  RAX RBP MOVQ } ; \ stack pointer
:! SP!  { RBP RAX MOVQ  DROP } ;
:! RP@  { DUP  RAX RSP MOVQ } ; \ return stack pointer
:! RP!  { RSP RAX MOVQ  DROP } ;
:! LP@  { DUP  RAX RSI MOVQ } ; \ link pointer
:! LP!  { RSI RAX MOVQ  DROP } ;

\ Optimized 2LITERAL to reduce stack shuffling
: 2LITERAL  { RDX DPUSHQ  RAX DPUSHQ  RAX } SWAP { MOVQ$  RDX } SWAP { MOVQ$ } ;

\ Constants for machine-specific fixed widths

\ Cell size operations
:! CELL   $ 8 LITERAL ; \ Length of a machine register
:! CELLS  { RAX } $ 3 { SHLQ$ } ;
:! CELL+  { RAX } CELL { ADDQ$ } ;

\ Dictionary link manipulation (included here because it is an implementation-specific detail)
:! /CALL  $ 5 LITERAL ; \ Length of a call instruction
: >NAME  CELL+ ; \ Skip next link pointer
: >XT    >NAME DUP C@ + 1+ ; \ Skip pointer + counted string name
: >BODY  >XT /CALL + ; \ Skip pointer, name, and first call instruction

\ Control structures

: COND  { RBX RAX MOVQ  DROP  RBX RBX TESTQ } ; \ Compile code that sets flags based on top stack item
\ ^ Note: Not immediate
\ TODO  Consider bundling more basic branching primitives (the MARK/RESOLVE family) for use with inline assembly and define these in terms of those
:! BEGIN  HERE ; \ Leave a back reference on the stack (redundant definition here only for completeness)
:! AGAIN        { JMPL$ } ; \ Resolve a back reference on the stack (compile a backwards jump)
:! UNTIL  COND  { JZL$ } ;  \ Resolve a back reference on the stack with a conditional jump
:! AHEAD        $ 0 { JMPL$ }  HERE $ 4 - ; \ Leave a forward reference on the stack
:! IF     COND  $ 0 { JZL$ }   HERE $ 4 - ;  \ Leave a conditional forward reference on the stack
:! THEN  THERE DUP REL32, BACK ; \ Resolve a forward reference (fill in a forward jump)
:! ELSE  POSTPONE AHEAD  SWAP  POSTPONE THEN ; \ Leave a forward reference, then resolve an existing one
:! WHILE  POSTPONE IF  SWAP ; \ Leave a forward reference on the stack under an existing (back) reference
:! REPEAT  POSTPONE AGAIN  POSTPONE THEN ; \ Resolve a back reference, then resolve a forward reference

\ Definite loops
\ Notes:
\ * FOR..NEXT only supports 256 byte bodies due to rel8 encoding
\ * N FOR.. will iterate I from N-1 to 0 to support more common use cases (in a normal Forth this requires AFT)
\   * In case it becomes useful - :! AFT  DROP  POSTPONE AHEAD  POSTPONE BEGIN  SWAP ;
:! FOR  { RCX PUSHQ  RCX RAX MOVQ  DROP } HERE ;
:! NEXT  { LOOP$  RCX POPQ } ;
:! I  { DUP  RAX RCX MOVQ  RAX DECQ } ; \ Decrement since x86 likes its loop counters from N..1 instead of N-1..0
:! UNLOOP  { RCX POPQ } ;

\ TODO  Include counted loops? (DO, LOOP, +LOOP and LEAVE)


\ "Interpreter"

\ This is another interesting place where this Forth differs from tradition.
\ Since there is no distinct compile/interpret state, we can compensate quite effectively by simply allowing code to be compiled and executed "immediately".
\ The obvious limitation this has is that it's possible to accidentally compile over the code while it executes.

\ So far, though, this limitation seems difficult to run into by accident, and easy to work around if you do.
\ There are obvious modifications to try if this ever does becomes an issue, but a general solution is not clear enough to implement right away.
\ Either way, this is arguably more powerful in some ways than what is offered in a typical Forth, since it can be arbitrarily nested in interesting ways.
\ This approach also eliminates the need for a whole host of inconsistently-bracketed or state-aware words.

:! [  HERE ;
:! EXIT  POSTPONE ; ;
:! EXECUTE  { RBX RAX MOVQ  DROP  RBX CALL } ;
:! JUMP     { RBX RAX MOVQ  DROP  RBX JMP } ; \ Included as a no-return alternative to EXECUTE
:! ]  POSTPONE EXIT  BACK  HERE EXECUTE ;

\ Side note: I think it's very interesting that this level of sophistication is achievable at all, let alone so easily, given how simple the core is.
\ Upon reflection, I guess it's ultimately a consequence of allowing immediate words, which compile code, to be defined and executed immediately themselves.
\ This idea starts to feel like it's approaching some distillation of the concept of metaprogramming - can it be taken any further?
