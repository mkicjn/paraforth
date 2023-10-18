:! int3  $ cc c, ;
:! int3!  int3 ;

:! rex.w,  docol  $ 48 c, ;

:! rax  $ 0 ;
:! rcx  $ 1 ;
:! rdx  $ 2 ;
:! rbx  $ 3 ;
:! rsp  $ 4 ;
:! rbp  $ 5 ;
:! rsi  $ 6 ;
:! rdi  $ 7 ;
:! (sib)  $ 4 ;
:! (none) $ 4 ;

:! mem     docol  $ 0 ;
:! mem+8   docol  $ 1 ;
:! mem+32  docol  $ 2 ;
:! reg     docol  $ 3 ;
:! modr/m, docol  $ 3 lshift + $ 3 lshift + c, ;

:! r*1  $ 0 ;
:! r*2  $ 1 ;
:! r*4  $ 2 ;
:! r*8  $ 3 ;
:! sib, modr/m, ;

:! stosb           $ aa c, ;
:! stosw  $ 66 c,  $ ab c, ;
:! stosd           $ ab c, ;
:! stosq   rex.w,  $ ab c, ;

:! w,  docol  stosw drop ;
:! d,  docol  stosd drop ;
:! ,   docol  stosq drop ;

:! pushq  $ 50 + c, ;
:! popq   $ 58 + c, ;
:! xchgq  rex.w,  $ 87 c,  reg modr/m, ;
:! movq   rex.w,  $ 89 c,  reg modr/m, ;
:! subq   rex.w,  $ 29 c,  reg modr/m, ;

:! -     docol  rsp rbp xchgq  rdx rax movq  rax popq  rax rdx subq  rsp rbp xchgq ;
:! swap  docol  rsp rbp xchgq  rdx rax movq  rax popq  rdx pushq  rsp rbp xchgq ;

int3!

\ TODO - Explore even more extreme minimalism above and with core2
