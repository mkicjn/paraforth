\ Debug interrupt instructions
:! int3  $ cc c, ;
:! int3!  int3 ;

\ Register codes and ModR/M byte construction
:! rax  $ 0 ;
:! rcx  $ 1 ;
:! rdx  $ 2 ;
:! rbx  $ 3 ;
:! rsp  $ 4 ;
:! rbp  $ 5 ;
:! rsi  $ 6 ;
:! rdi  $ 7 ;
:! mem     docol  $ 0 ;
:! mem+8   docol  $ 1 ;
:! mem+32  docol  $ 2 ;
:! reg     docol  $ 3 ;
:! modr/m, docol  $ 3 lshift + $ 3 lshift + c, ;

\ Sized compilation words
:! rex.w,  docol  $ 48 c, ;
:! stosw  $ 66 c,  $ ab c, ;
:! stosd           $ ab c, ;
:! stosq   rex.w,  $ ab c, ;
:! w,  docol  stosw drop ;
:! d,  docol  stosd drop ;
:! ,   docol  stosq drop ;

\ Basic assembly instructions
:! pushq  $ 50 + c, ;
:! popq   $ 58 + c, ;
:! callq  $ ff c,  $ 2 reg modr/m, ;
:! xchgq  rex.w,  $ 87 c,  reg modr/m, ;
:! movq   rex.w,  $ 89 c,  reg modr/m, ;
:! addq   rex.w,  $ 01 c,  reg modr/m, ;
:! subq   rex.w,  $ 29 c,  reg modr/m, ;
:! incq   rex.w,  $ ff c,  $ 0 reg modr/m, ;
:! testq  rex.w,  $ 85 c,  reg modr/m, ;
:! seteb    $ 940f w,  $ 0 reg modr/m, ;
:! movzxbl  $ b60f w,      reg modr/m, ;

\ Useful Forth primitives for defining more assembly instructions
:! -     docol  rsp rbp xchgq  rdx rax movq  rax popq  rax rdx subq  rsp rbp xchgq ;
:! swap  docol  rsp rbp xchgq  rdx rax movq  rax popq  rdx pushq  rsp rbp xchgq ;

\ More assembly instructions
:! cmpq     rex.w,   $ 39 c,  swap  reg modr/m, ;
:! movzxb@  rex.w, $ b60f w,  swap  mem modr/m, ;
:! rel32,  docol  rax rdi subq  $ 4 - d, ;
:! jmp  $ ff c, $ 4 reg modr/m, ;
:! jmp$    $ e9 c, rel32, ;
:! jz$   $ 840f w, rel32, ;

\ Some initial foundations of a Forth system
:! compile  docol  $ e8 c,  rel32, ;
:! here  docol  dup  rax rdi movq ;
:! name  docol  here  rdi pushq  name,  rdi popq ;
:! find  docol  seek  $ 8 +  rcx rax movzxb@  rax rcx addq  rax incq ;
:! postpone  name find compile ;
:! :  postpone :!  postpone docol ;

\ Basic looping primitives
:! =     docol  rsp rbp xchgq  rdx popq  rax rdx cmpq  rax seteb  rax rax movzxbl  rsp rbp xchgq ;
: cond  rdx rax movq  drop  rdx rdx testq ;
:! begin  here ;
:! until  postpone cond  postpone jz$ ;

\ Inlining
: literal  dolit , ;
:! '  name find literal ;
:! }  ;
:! {  begin  name find dup compile  ' } =  until ;

\ Data space pointer manipulation
: allot  rdi rax addq  drop ;
: there  rdi rax xchgq ;
: back   rdi rax movq  drop ;

\ Interpretation
: execute  rdx rax movq  drop  rdx jmp ;
:! /pad  $ 100 literal ;
:! [  here  /pad allot ;
:! exit  { ; } ;
:! ]  { exit }  back  here /pad + execute ;

\ TODO - Explore even more extreme minimalism above and with core2

\ Untested stuff below
\ --------------------------------------------------------------------------------

:! again  { jmp$ } ;
:! ahead  $ 0 { jmp$ }  here $ 4 - ;
:! if   { cond }  $ 0 { jz$ }  here $ 4 - ;
:! then  there  dup rel32,  back ;
:! else  { ahead } swap { then } ;
:! while  { if } swap ;
:! repeat  { again then } ;

:! 1shlq  rex.w, $ d1 c, $ 6 reg modr/m, ;
:! 1sarq  rex.w, $ d1 c, $ 7 reg modr/m, ;
:! decq   rex.w, $ ff c, $ 1 reg modr/m, ;
: 2*  rax 1shlq ;
: 2/  rax 1sarq ;
: 1+  rax incq ;
: 1-  rax decq ;

\ :! :code  { : rsp rbp xchgq } ; \ TODO - Doesn't work for some reason, haven't debugged yet
\ :! ;code  { rsp rbp xchgq ; } ;
:! setgb  $ 9f0f w, $ 0 reg modr/m, ;
:! setzb   $ 940f w, $ 0 reg modr/m, ;
:! movzxbl  $ b60f w, reg modr/m, ;
:! andq  rex.w, $ 21 c, reg modr/m, ;
: >  rsp rbp xchgq  rdx rax movq  rax popq  rdx rax cmpq  rax setgb  rax rax movzxbl  rsp rbp xchgq ;
: and  rsp rbp xchgq  rdx popq  rax rdx andq  rsp rbp xchgq ;

: cr  $ a emit ;
[ $ 10 begin dup $ 0 > while  $ 4d emit  1- repeat  drop cr ]


:! movq@  rex.w,  swap $ 8b   c,  mem modr/m, ;
:! addq$  rex.w, $ 81 c, swap $ 0 reg modr/m, d, ;
: over  rsp rbp xchgq  rdx popq  rdx pushq  rax pushq  rax rdx movq  rsp rbp xchgq ;
: nip  rbp [ $ 8 ] addq$ ;
: tuck  rsp rbp xchgq  rdx popq  rax pushq  rdx pushq  rsp rbp xchgq ;
: 0=  rax rax testq  rax setzb   rax rax movzxbl ;
: max  over over  > if nip else drop then ; \ Temporary?

\ Basic benchmark to get an idea of the performance difference between the approaches
\ TODO - Unable to verify this is working as intended, but it's much slower if so

: collatz-step  dup $ 1 and  if  dup 2* + 1+  else  2/  then ;
: collatz-len   $ 0 swap begin  dup $ 1 > while  collatz-step  swap 1+ swap repeat drop ;
: max-collatz   $ 0 swap  begin  tuck collatz-len  max  swap 1-  dup 0= until drop ; \ Temporary
[ $ f4240 max-collatz int3 ]
