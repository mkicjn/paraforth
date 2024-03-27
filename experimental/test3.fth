\ Forth defining words

link :!  enter  { link  enter }  exit
:! ;  { exit }  exit
:! :  { link  docol enter } ;


\ Basic assembler words

:! int3   $ cc c, ;
:! int3!  int3 ;

:! rax  $ 0 ;
:! rcx  $ 1 ;
:! rdx  $ 2 ;
:! rbx  $ 3 ;
:! rsp  $ 4 ;
:! rbp  $ 5 ;
:! rsi  $ 6 ;
:! rdi  $ 7 ;

:  mem      $ 0 ;
:  mem+8    $ 1 ;
:  mem+32   $ 2 ;
:  reg      $ 3 ;
:  modr/m,  $ 3 << + $ 3 << + c, ;

:! pushq  $ 50 + c, ;
:! popq   $ 58 + c, ;

:  rex.w,           $ 48 c, ;
:! movq     rex.w,  $ 89 c,  reg modr/m, ;
:! addq     rex.w,  $ 01 c,  reg modr/m, ;
:! subq     rex.w,  $ 29 c,  reg modr/m, ;
:! stosb            $ aa c, ;
:! stosd            $ ab c, ;
:! stosw   $ 66 c,  $ ab c, ;
:! stosq   rex.w,   $ ab c, ;


\ Basic Forth primitives

:! dup   { rax pushq } ;
:! drop  { rax popq } ;
:! swap  { rdx popq  rax pushq  rax rdx movq } ;
:! +     { rdx popq  rax rdx addq } ;
:! -     { rdx rax movq  rax popq  rax rdx subq } ;

:! c,      { stosb drop } ;
:! w,      { stosw drop } ;
:! d,      { stosd drop } ;
:!  ,      { stosq drop } ;
:! here    { rax pushq  rax rdi movq } ;
:  rel32,   here -  $ 4 - d, ;


\ More assembler words

:! 1shlq    rex.w,    $ d1 c,   $ 6      reg modr/m, ;
:! 1sarq    rex.w,    $ d1 c,   $ 7      reg modr/m, ;
:! incq     rex.w,    $ ff c,   $ 0      reg modr/m, ;
:! decq     rex.w,    $ ff c,   $ 1      reg modr/m, ;
:! notq     rex.w,    $ f7 c,   $ 2      reg modr/m, ;
:! negq     rex.w,    $ f7 c,   $ 3      reg modr/m, ;
:! xchgq    rex.w,    $ 87 c,            reg modr/m, ;
:! testq    rex.w,    $ 85 c,            reg modr/m, ;
:! andq     rex.w,    $ 21 c,            reg modr/m, ;
:! orq      rex.w,    $ 09 c,            reg modr/m, ;
:! xorq     rex.w,    $ 31 c,            reg modr/m, ;
:! cmpq     rex.w,    $ 39 c,  swap      reg modr/m, ;
:! movq@    rex.w,    $ 8b c,  swap      mem modr/m, ;
:! addq$    rex.w,    $ 81 c,  swap  $ 0 reg modr/m, d, ;
:! cmovgq   rex.w,  $ 4f0f w,  swap      reg modr/m, ;
:! movzxb@  rex.w,  $ b60f w,  swap      mem modr/m, ;
:! movabs$          $ b848 w,                      , ;
:! jmp$               $ e9 c,                 rel32, ;
:! jz$              $ 840f w,                 rel32, ;
:! movzxbl          $ b60f w,            reg modr/m, ;
:! seteb            $ 940f w,   $ 0      reg modr/m, ;
:! setgb            $ 9f0f w,   $ 0      reg modr/m, ;
:! setzb            { seteb } ;


\ More Forth primitives

:! nip   { rdx popq } ;
:! tuck  { rdx popq  rax pushq  rdx pushq } ;
:! over  { rdx rsp movq@  rax pushq  rax rdx movq } ;

:! there  { rax rdi xchgq } ;
:! back   { rdi rax movq  rax popq } ;

:! invert  { rax notq } ;
:! negate  { rax negq } ;
:! and     { rdx popq  rax rdx andq } ;
:! or      { rdx popq  rax rdx orq } ;
:! xor     { rdx popq  rax rdx xorq } ;

:! 1+  { rax incq } ;
:! 1-  { rax decq } ;
:! 2*  { rax 1shlq } ;
:! 2/  { rax 1sarq } ;

:  literal  { dup movabs$ } ;

:! begin   here ;
:! cond    { rdx rax movq  rax popq  rdx rdx testq } ;
:! until   { cond jz$ } ;
:! again   { jmp$ } ;
:! ahead   $ 0 { jmp$ }  here $ 4 - ;
:! if      { cond }  $ 0 { jz$ }  here $ 4 - ;
:! then    there  dup rel32,  back ;
:! else    { ahead } swap { then } ;
:! while   { if } swap ;
:! repeat  { again then } ;

:! =    { rdx popq  rax rdx cmpq  rax seteb  rax rax movzxbl } ;
:! >    { rdx popq  rax rdx cmpq  rax setgb  rax rax movzxbl } ;
:! max  { rdx popq  rax rdx cmpq  rax rdx cmovgq } ;

:! c@  { rax rax movzxb@ } ;
:! cell  $ 8 literal ;


\ Benchmark

\ These are here just for feature parity; won't plan to use rel8 or loop later
:  rel8,  here -  $ 1 - c, ;
:! loop$  $ e2 c,  rel8, ;
:! for   { rcx pushq  rcx rax movq  rax popq } here ;
:! i     { dup  rax rcx movq  rax decq } ;
:! next  { loop$  rcx popq } ;

: collatz-step  dup $ 1 and  if  dup 2* + 1+  else  2/  then ;
: collatz-len   $ 0 swap begin  dup $ 1 > while  collatz-step  swap 1+ swap repeat drop ;
: max-collatz   $ 0 swap for  i collatz-len max  next ;

:! test  $ f4240 max-collatz  int3 ;
test

int3!
