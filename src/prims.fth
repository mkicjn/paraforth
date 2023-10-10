:! find  docol  seek  $ 8 +  rbx rax movzxb@  rax rbx addq  rax incq ;
:! postpone  name find compile ;
:! :  postpone :! postpone docol ;

: cond  rbx rax movq  drop  rbx rbx testq ;
:! begin  dup  rax rdi movq ;
:! until  postpone cond postpone jz$ ;

: =  rax rdx cmpq  rax seteb  rax rax movzxbl  swap drop ;
:! \  begin  key $ a =  until ;


\ Now that comments are supported, documentation for the high-level stuff can begin.

\ The main thing to point out before now is that there's a bit of a chicken-and-egg problem between compile, postpone, and call$.
\ I chose to solve this by implementing compile as a regular colon word, which implements a sort of "generalized docol."
\ Most of the above definitions in this file are just temporary infrastructure and will be redefined later.

\ TODO  Maybe there are some neat tricks to avoid some of these. I would prefer to keep all high level definitions in this file, and reduce those above this line.


\ Inlining

\ The first immediately useful thing to implement is primitive inlining, so it affects as much code as possible.
\ Since there aren't that many primitives to begin with, this works out nicely.

\ Inlining can be implemented easily enough by creating a parsing word that postpones every word entered after it until it hits an "end" word.
\ I choose braces for this syntax because it's the conceptual opposite of what brackets would represent in a typical Forth.
: literal  dolit , ;
:! '  name find literal ;
:! }  ; \ just a no-op to compare against
:! {  begin  name find dup compile  ' } =  until ; \ Since we don't have while and repeat, } gets postponed too - good thing it's a no-op.

\ This makes it act as though the user typed all those words directly into their definition, since words always get executed immediately when typed.
\ However, it won't work at all with words that parse input, because there's no way to save the input for later.
\ TODO  This is much better than copying compiled code, but will also break if } is ever redefined due to hyperstatic scoping - would prefer to avoid this, and stop compiling no-ops.


\ Implementing the actual primitives is pretty straightforward and unexciting.
\ See the notes in core.asm to understand the register convention.
\ (Note that some operations are redefined to allow for a more optimized inlining implementation)

\ dpopq and dpushq are pseudo-instructions corresponding to the data stack
:! dpopq   { rbpmovq@  rbp } $ 8 { addq$ } ;
:! dpushq  { rbp } $ 8 { subq$  rbpmovq! } ;

\ Stack manipulation
:! dup  { rdx dpushq  rdx rax movq } ;
:! drop  { rax rdx movq  rdx dpopq } ;
:! swap  { rdx raxxchgq } ;
:! nip  { rdx dpopq } ;
:! tuck  { rax dpushq } ;
:! over  { swap tuck } ;
:! rot  { rbx dpopq  dup  rax rbx movq } ;
:! -rot  { rbx rax movq  drop  rbx dpushq } ;
:! 2dup  { rdx dpushq  rax dpushq } ;
:! 2drop  { rax dpopq  rdx dpopq } ;

\ Memory operations
:! @  { rax rax movq@ } ;
:! !  { rax rdx movq!  2drop } ;
:! +!  { (sib) rdx addq!  rax (none) r*1 sib,  2drop } ;
:! c@  { rax rax movzxb@ } ;
:! c!  { rax rdx movb!  2drop } ;
:! ,   { stosq  drop } ;
:! c,  { stosb  drop } ;

\ Return stack operations
:! >r  { rax pushq  drop } ;
:! r>  { dup  rax popq } ;
:! 2>r  { rdx pushq  rax pushq  2drop } ;
:! 2r>  { 2dup  rax popq  rdx popq } ;
:! r@  { dup  rax (sib) movq@  rsp (none) r*1 sib, } ;
:! 2r@  { r@  rdx dpushq  rdx (sib) movq@+8  rsp (none) r*1 sib, } $ 8 c, ;
:! rdrop  { rsp } $ 8 { addq$ } ;
:! 2rdrop  { rsp } $ 10 { addq$ } ;

\ Basic arithmetic
:! +  { rax rdx addq  nip } ;
:! -  { rdx rax subq  drop } ;
:! 1+  { rax incq } ;
:! 1-  { rax decq } ;
:! 2*  { rax 1shlq } ;
:! 2/  { rax 1sarq } ;
:! negate  { rax negq } ;
:! lshift  { rcx pushq  rcx rax movq  rdx clshlq  rcx popq  drop } ;
:! rshift  { rcx pushq  rcx rax movq  rdx clshrq  rcx popq  drop } ;
:! *     { rdx mulq  nip } ;
:! /mod  { rbx rax movq  rax rdx movq  rdx rdx xorq  rbx divq } ;
:! /     { /mod nip } ;
:! mod   { /mod drop } ;

\ Bitwise arithmetic
:! invert  { rax notq } ;
:! and  { rax rdx andq  nip } ;
:! or  { rax rdx orq  nip } ;
:! xor  { rax rdx xorq  nip } ;

\ Comparisons
\ The repeated MOVZXBLs are ugly, but it's easier than clearing rbx
:! 0=   { rax rax testq  rax setzb   rax rax movzxbl } ;
:! 0<>  { rax rax testq  rax setnzb  rax rax movzxbl } ;
:! 0<   { rax rax testq  rax setlb   rax rax movzxbl } ;
:! 0>   { rax rax testq  rax setgb   rax rax movzxbl } ;
:! 0<=  { rax rax testq  rax setleb  rax rax movzxbl } ;
:! 0>=  { rax rax testq  rax setgeb  rax rax movzxbl } ;
:! =   { rax rdx cmpq  rax seteb   rax rax movzxbl  nip } ;
:! <>  { rax rdx cmpq  rax setneb  rax rax movzxbl  nip } ;
:! <   { rax rdx cmpq  rax setlb   rax rax movzxbl  nip } ;
:! >   { rax rdx cmpq  rax setgb   rax rax movzxbl  nip } ;
:! <=  { rax rdx cmpq  rax setleb  rax rax movzxbl  nip } ;
:! >=  { rax rdx cmpq  rax setgeb  rax rax movzxbl  nip } ;
:! min  { rax rdx cmpq  rax rdx cmovlq  nip } ;
:! max  { rax rdx cmpq  rax rdx cmovgq  nip } ;

\ System register manipulation
:! here   { dup  rax rdi movq } ; \ data space pointer
:! there  { rdi raxxchgq } ;
:! back   { rdi rax movq  drop } ;
:! allot  { rdi rax addq  drop } ;
:! sp@  { dup  rax rbp movq } ; \ stack pointer
:! sp!  { rbp rax movq  drop } ;
:! rp@  { dup  rax rsp movq } ; \ return stack pointer
:! rp!  { rsp rax movq  drop } ;
:! lp@  { dup  rax rsi movq } ; \ link pointer
:! lp!  { rsi rax movq  drop } ;

\ Optimized 2literal to reduce stack shuffling
: 2literal  { rdx dpushq  rax dpushq  rax } swap { movq$  rdx } swap { movq$ } ;

\ Cell size operations
:! cell   $ 8 literal ; \ Length of a machine register
:! cells  { rax } $ 3 { shlq$ } ;
:! cell+  { rax } cell { addq$ } ;

\ Dictionary link manipulation (included here because it is an implementation-specific detail)
:! /call  $ 5 literal ; \ Length of a call instruction
: >name  cell+ ; \ Skip next link pointer
: >xt    >name dup c@ + 1+ ; \ Skip pointer + counted string name
: >body  >xt /call + ; \ Skip pointer, name, and first call instruction


\ Control structures

:! execute   { rbx rax movq  drop  rbx call } ;
:! jump      { rbx rax movq  drop  rbx jmp } ;
:! @execute  { rbx rax movq  drop  rbx call@ } ;
:! @jump     { rbx rax movq  drop  rbx jmp } ;

: cond  { rbx rax movq  drop  rbx rbx testq } ; \ Compile code that sets flags based on top stack item
\ ^ Note: Not immediate
\ TODO  Consider bundling more basic branching primitives (the mark/resolve family) for use with inline assembly and define these in terms of those
:! begin  here ; \ Leave a back reference on the stack (redundant definition here only for completeness)
:! again        { jmpl$ } ; \ Resolve a back reference on the stack (compile a backwards jump)
:! until  cond  { jzl$ } ;  \ Resolve a back reference on the stack with a conditional jump
:! ahead        $ 0 { jmpl$ }  here $ 4 - ; \ Leave a forward reference on the stack
:! if     cond  $ 0 { jzl$ }   here $ 4 - ;  \ Leave a conditional forward reference on the stack
:! then  there dup rel32, back ; \ Resolve a forward reference (fill in a forward jump)
:! else  postpone ahead  swap  postpone then ; \ Leave a forward reference, then resolve an existing one
:! while  postpone if  swap ; \ Leave a forward reference on the stack under an existing (back) reference
:! repeat  postpone again  postpone then ; \ Resolve a back reference, then resolve a forward reference

\ Notes:
\ * for..next only supports 256 byte bodies due to rel8 encoding
\ * n for.. will iterate i from n-1 to 0 to support more common use cases (in a normal Forth this requires aft)
\   * In case it becomes useful - :! aft  drop  postpone ahead  postpone begin  swap ;
:! for  { rcx pushq  rcx rax movq  drop } here ;
:! next  { loop$  rcx popq } ;
:! i  { dup  rax rcx movq  rax decq } ; \ Decrement since x86 likes its loop counters from n..1 instead of n-1..0
:! unloop  { rcx popq } ;

\ TODO  Include counted loops? (do, loop, +loop and leave)


\ "Interpreter"

\ This is another interesting place where this Forth differs from tradition.
\ Since there is no distinct compile/interpret state, we can compensate quite effectively by simply allowing code to be compiled and executed "immediately".

\ The obvious limitation this has is that it's possible for code executed like this to accidentally compile over itself while it executes.
\ So far, though, this limitation seems difficult to run into by accident, and easy to work around if you do.
\ Either way, this is arguably more powerful than what is offered in a typical Forth, since it can be arbitrarily nested in interesting ways.
\ This approach also eliminates the need for a whole host of inconsistently-bracketed or state-aware words.

:! /pad  $ 100 literal ; \ This spacing isn't strictly necessary, but provides some safety in case parsing words are interpreted.
:! [  here  /pad allot ;
:! exit  postpone ; ;
:! ]  postpone exit  back  here /pad + execute ;

\ Side note: I think it's very interesting that this level of sophistication is achievable at all, let alone so easily, given how simple the core is.
\ Upon reflection, I guess it's ultimately a consequence of allowing immediate words, which compile code, to be defined and executed immediately themselves.
\ This idea starts to feel like it's approaching some distillation of the concept of metaprogramming - can it be taken any further?
