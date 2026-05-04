\ x86_64 support - specific to core implementation, but not operating system


\ Forth defining words

\ Believe it or not, the usual : ... ; is not implemented by the core - it doesn't really need to be.
\ They are trivially described as follows.

link :!  enter  { link  enter }  exit \ :! used instead of : for defining immediate words
:! ;  { exit }  exit
:! :  { link  docol enter } ;


\ Basic assembler words

\ This is the most basic subset of x86_64 needed to implement some basic words that will let us go further.

\ Debug traps
:! int3   $ cc c, ;
:! int3!  int3 ;

\ Register codes
:! rax  $ 0 ;
:! rcx  $ 1 ;
:! rdx  $ 2 ;
:! rbx  $ 3 ;
:! rsp  $ 4 ;
:! rbp  $ 5 ;
:! rsi  $ 6 ;
:! rdi  $ 7 ;

\ ModR/M byte construction
:  mem      $ 0 ;
:  mem+8    $ 1 ;
:  mem+32   $ 2 ;
:  reg      $ 3 ;
:  modr/m,  $ 3 << + $ 3 << + c, ;

\ Stack instructions
:! pushq  $ 50 + c, ;
:! popq   $ 58 + c, ;

\ REX.W prefix and basic register instructions
:  rex.w,          $ 48 c, ;
:! addq    rex.w,  $ 01 c,  reg modr/m, ;
:! subq    rex.w,  $ 29 c,  reg modr/m, ;
:! movq    rex.w,  $ 89 c,  reg modr/m, ;

\ String store instructions
:! stosb            $ aa c, ;
:! stosd            $ ab c, ;
:! stosw   $ 66 c,  $ ab c, ;
:! stosq   rex.w,   $ ab c, ;


\ Basic Forth primitives

\ These are implemented with inlining via { ... }, so it affects as much code as possible.
\ I chose braces for this syntax because it's the conceptual opposite of what brackets would represent in a typical Forth.

\ The brace words actually used to be implemented at runtime, but are now included in the core to reduce boilerplate.

\ Implementing the remaining assembly and Forth primitives is pretty straightforward and unexciting.
\ See the notes in core.asm to understand the register convention.
\ (Note that some operations will get redefined to implement inlining, which is not done by the core.)

\ Basic stack operations
:! dup   { rax pushq } ;
:! drop  { rax popq } ;
:! swap  { rdx popq  rax pushq  rax rdx movq } ;

\ Subtraction and inlined +
:! +     { rdx popq  rax rdx addq } ;
:! -     { rdx rax movq  rax popq  rax rdx subq } ;

\ Compilation-related words and inlined c,
:! c,      { stosb drop } ;
:! w,      { stosw drop } ;
:! d,      { stosd drop } ;
:!  ,      { stosq drop } ;
:! here    { rax pushq  rax rdi movq } ;


\ More assembler words

:  rel32,   here -  $ 4 - d, ;

\ Note: can't source [rsp] or [rbp] on plain @ operations due to SIB encoding
:! addq!    rex.w,         $ 01   c,      mem modr/m,    ;
:! orq      rex.w,         $ 09   c,      reg modr/m,    ;
:! andq     rex.w,         $ 21   c,      reg modr/m,    ;
:! xorq     rex.w,         $ 31   c,      reg modr/m,    ;
:! cmpq     rex.w,  swap   $ 39   c,      reg modr/m,    ;
:! addq$    rex.w,  swap   $ 81   c,  $ 0 reg modr/m, d, ;
:! cmpq$    rex.w,  swap   $ 81   c,  $ 7 reg modr/m, d, ;
:! testq    rex.w,         $ 85   c,      reg modr/m,    ;
:! xchgq    rex.w,         $ 87   c,      reg modr/m,    ;
:! movb!                   $ 88   c,      mem modr/m,    ;
:! movq!    rex.w,         $ 89   c,      mem modr/m,    ;
:! movq@    rex.w,  swap   $ 8b   c,      mem modr/m,    ;
:! movabs$  rex.w,  swap   $ b8 + c,                   , ;
:! shrq$    rex.w,  swap   $ c1   c,  $ 5 reg modr/m, c, ;
:! shlq$    rex.w,  swap   $ c1   c,  $ 6 reg modr/m, c, ;
:! sarq$    rex.w,  swap   $ c1   c,  $ 7 reg modr/m, c, ;
:! retq                    $ c3   c,                     ;
:! 1shlq    rex.w,         $ d1   c,  $ 6 reg modr/m,    ;
:! 1sarq    rex.w,         $ d1   c,  $ 7 reg modr/m,    ;
:! clshrq   rex.w,         $ d3   c,  $ 5 reg modr/m,    ;
:! clshlq   rex.w,         $ d3   c,  $ 6 reg modr/m,    ;
:! clsarq   rex.w,         $ d3   c,  $ 7 reg modr/m,    ;
:! call$                   $ e8   c,           rel32,    ;
:! jmp$                    $ e9   c,           rel32,    ;
:! notq     rex.w,         $ f7   c,  $ 2 reg modr/m,    ;
:! negq     rex.w,         $ f7   c,  $ 3 reg modr/m,    ;
:! mulq     rex.w,         $ f7   c,  $ 4 reg modr/m,    ;
:! divq     rex.w,         $ f7   c,  $ 6 reg modr/m,    ;
:! incq     rex.w,         $ ff   c,  $ 0 reg modr/m,    ;
:! decq     rex.w,         $ ff   c,  $ 1 reg modr/m,    ;
:! call                    $ ff   c,  $ 2 reg modr/m,    ;
:! call@                   $ ff   c,  $ 2 mem modr/m,    ;
:! jmp                     $ ff   c,  $ 4 reg modr/m,    ;
:! jmp@                    $ ff   c,  $ 4 mem modr/m,    ;
:! syscall               $ 050f   w,                     ;
:! cmovlq   rex.w,  swap $ 4c0f   w,      reg modr/m,    ;
:! cmovgq   rex.w,  swap $ 4f0f   w,      reg modr/m,    ;
:! jz$                   $ 840f   w,           rel32,    ;
:! jnz$                  $ 850f   w,           rel32,    ;
:! jg$                   $ 8f0f   w,           rel32,    ;
:! seteb                 $ 940f   w,  $ 0 reg modr/m,    ;
:! setneb                $ 950f   w,  $ 0 reg modr/m,    ;
:! setlb                 $ 9c0f   w,  $ 0 reg modr/m,    ;
:! setgeb                $ 9d0f   w,  $ 0 reg modr/m,    ;
:! setleb                $ 9e0f   w,  $ 0 reg modr/m,    ;
:! setgb                 $ 9f0f   w,  $ 0 reg modr/m,    ;
:! movzxb@  rex.w,  swap $ b60f   w,      mem modr/m,    ;
:! movzxbl               $ b60f   w,      reg modr/m,    ;
:! setzb   { seteb } ;
:! setnzb  { setneb } ;


\ More Forth primitives

\ Parameter stack operations
:! nip    { rdx popq } ;
:! tuck   { rdx popq  rax pushq  rdx pushq } ;
:! over   { rdx popq  rdx pushq  rax pushq  rax rdx movq } ;
:!  rot   { rcx popq  rdx popq  rcx pushq  rax pushq  rax rdx movq } ;
:! -rot   { rcx popq  rdx popq  rax pushq  rdx pushq  rax rcx movq } ;

\ Return stack operations
:! <r>    { rsp rbp xchgq } ; \ TODO  consider optimizing the words that use this
:! >r     { <r> rax pushq <r> rax popq } ;
:! r>     { rax pushq  <r> rax popq <r> } ;
:! r@     { rax pushq  <r> rax popq  rax pushq <r> } ;
:! rdrop  { <r> rdx popq <r> } ;
:! i>r    { <r> rbx pushq <r> } ;
:! r>i    { <r> rbx popq <r> } ;

\ Literals and cell operations
:   literal  { dup  rax } swap { movabs$ } ;
:  2literal  swap literal literal ;
:! cell      $ 8 literal ;
:! cells     { rax } $ 3 { shlq$ } ;
:! cell+     { rax } cell { addq$ } ;

\ Memory operations
:!  @  { rax rax movq@ } ;
:! 2@  { rdx rax movq  rdx } cell { addq$  rdx rdx movq@  rdx pushq  @ } ;
:! c@  { rax rax movzxb@ } ;
:!  !  { rdx popq  rax rdx movq!  rax popq } ;
:! 2!  { rdx popq  rax rdx movq!  rax } cell { addq$  ! } ;
:! c!  { rdx popq  rax rdx movb!  rax popq } ;
:! +!  { rdx popq  rax rdx addq!  rax popq } ;

\ Double-cell operations
:! 2dup    { rdx popq  rdx pushq  rax pushq  rdx pushq } ;
:! 2drop   { rdx popq  rax popq } ;
:! 2swap   { i>r  rbx rax movq  rcx popq  rax popq  rdx popq   rcx pushq  rbx pushq  rdx pushq  r>i } ;
:! 2over   { i>r  rbx rax movq  rcx popq  rax popq  rdx popq   rdx pushq  rax pushq  rcx pushq  rbx pushq  rdx pushq r>i } ;
:! 2nip    { rdx popq  rsp } $ 2 cells { addq$  rdx pushq } ;
:! 2tuck   { i>r  rdx popq  rbx popq  rcx popq   rdx pushq  rax pushq  rcx pushq rbx pushq  r>i } ;
:! 2>r     { rdx popq  <r> rdx pushq  rax pushq <r>  rax popq } ;
:! 2r>     { rax pushq  <r> rax popq  rdx popq <r>  rdx pushq } ;
:! 2rdrop  { <r> rdx popq  rdx popq <r> } ;

\ System register manipulation
:! there  { rax rdi xchgq } ;
:! back   { rdi rax movq  rax popq } ;
:! allot  { rdi rax addq  rax popq } ;
:! sp@    { rax pushq  rax rsp movq } ;
:! rp@    { rax pushq  rax rbp movq } ;
:! lp@    { rax pushq  rax rsi movq } ;
:! sp!    { rsp rax movq  rax popq } ;
:! rp!    { rbp rax movq  rax popq } ;
:! lp!    { rsi rax movq  rax popq } ;

\ Signed and unsigned bit shifting
:! >>   { rcx rax movq  rax popq  rax clshrq } ;
:! <<   { rcx rax movq  rax popq  rax clshlq } ;
:! >>>  { rcx rax movq  rax popq  rax clsarq } ;
:! <<<  { << } ;

\ Arithmetic
:! 1+  { rax incq } ;
:! 1-  { rax decq } ;
:! 2*  { rax 1shlq } ;
:! 2/  { rax 1sarq } ;
:! invert  { rax notq } ;
:! negate  { rax negq } ;
:! and     { rdx popq  rax rdx andq } ;
:! or      { rdx popq  rax rdx orq } ;
:! xor     { rdx popq  rax rdx xorq } ;
:! *       { rdx popq  rdx mulq } ;
:! /       { rdx rdx xorq  rcx rax movq  rax popq  rcx divq } ;
:! mod     { /  rax rdx movq } ;
:! /mod    { /  rdx pushq } ;
:! abs     { rdx rax movq  rdx } cell cells 1- { sarq$  rax rdx xorq  rax rdx subq } ;

\ Comparison words
:! 0=   { rax rax testq  rax setzb   rax rax movzxbl } ;
:! 0<>  { rax rax testq  rax setnzb  rax rax movzxbl } ;
:! 0>   { rax rax testq  rax setgb   rax rax movzxbl } ;
:! 0<   { rax rax testq  rax setlb   rax rax movzxbl } ;
:! 0>=  { rax rax testq  rax setgeb  rax rax movzxbl } ;
:! 0<=  { rax rax testq  rax setleb  rax rax movzxbl } ;
:! =    { rdx popq  rax rdx cmpq  rax seteb   rax rax movzxbl } ;
:! <>   { rdx popq  rax rdx cmpq  rax setneb  rax rax movzxbl } ;
:! >    { rdx popq  rax rdx cmpq  rax setgb   rax rax movzxbl } ;
:! <    { rdx popq  rax rdx cmpq  rax setlb   rax rax movzxbl } ;
:! >=   { rdx popq  rax rdx cmpq  rax setgeb  rax rax movzxbl } ;
:! <=   { rdx popq  rax rdx cmpq  rax setleb  rax rax movzxbl } ;
:! max  { rdx popq  rax rdx cmpq  rax rdx cmovgq } ;
:! min  { rdx popq  rax rdx cmpq  rax rdx cmovlq } ;

\ Loops and conditionals
\ TODO  reimplement with mark/resolve pairs
:! begin   here ;
:! cond    { rax rax testq  rax popq } ;
:! until   { cond jz$ } ;
:! again   { jmp$ } ;
:! ahead   $ 0 { jmp$ }  here $ 4 - ;
:! if      { cond }  $ 0 { jz$ }  here $ 4 - ;
:! then    there  dup rel32,  back ;
:! else    { ahead } swap { then } ;
:! while   { if } swap ;
:! repeat  { again then } ;

\ Counted loops
\ TODO  consider including range checks
:! for     { i>r  rbx rax movq  rax popq }  here  { rbx decq } ;
:! i       { dup  rax rbx movq } ;
:! unloop  { r>i } ;
:! next    { rbx } $ 0 { cmpq$  jg$  unloop } ;

\ Code address operations
:  compile   { call$ } ;
:! execute   { rdx rax movq  rax popq  rdx call } ;
:! jump      { rdx rax movq  rax popq  rdx jmp } ;
:! @execute  { rdx rax movq  rax popq  rdx call@ } ;
:! @jump     { rdx rax movq  rax popq  rdx jmp@ } ;


\ Implementation-specific high-level words

\ Dictionary link manipulation
:  >name  cell+ ; \ length of link
:  >xt    >name dup c@ + 1+ ; \ length of cstr
:  >doer  >xt   $ 7 + ; \ length of enter
:  >body  >doer $ 5 + ; \ length of call$
