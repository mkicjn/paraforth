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
:! jz$     $ e9 c,  rel32, ;

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

\ TODO - Explore even more extreme minimalism above and with core2
