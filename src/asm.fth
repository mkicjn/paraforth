:! int3  $ cc c, ;
:! int3!  int3 ;

:! w, docol  dup c,  $  8 rshift c, ;
:! d, docol  dup w,  $ 10 rshift w, ;
:!  , docol  dup d,  $ 20 rshift d, ;

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

:! rex.w, docol  $ 48 c, ;

:! addq   rex.w, $ 01 c, reg modr/m, ;
:! subq   rex.w, $ 29 c, reg modr/m, ;
:! addq$  rex.w, $ 81 c, swap $ 0 reg modr/m, d, ;
:! subq$  rex.w, $ 81 c, swap $ 5 reg modr/m, d, ;
:! mulq   rex.w, $ f7 c, $ 4 reg modr/m, ;
:! divq   rex.w, $ f7 c, $ 6 reg modr/m, ;
:! incq   rex.w, $ ff c, $ 0 reg modr/m, ;
:! decq   rex.w, $ ff c, $ 1 reg modr/m, ;

:! rel32, docol  rax rdi subq  $ 4 - d, ;
:! rel8,  docol  rax rdi subq  $ 1 - c, ;

:! movq   rex.w,  $ 89 c,  reg modr/m, ;
:! movq!  rex.w,  $ 89 c,  mem modr/m, ;
:! movq@  rex.w,  swap $ 8b   c,  mem modr/m, ;
:! movq$  rex.w,  swap $ b8 + c,  , ;
:! rbpmovq@  $ 5 swap  rex.w, $ 8b c, $ 1 modr/m, $ 0 c, ;
:! rbpmovq!  $ 5 swap  rex.w, $ 89 c, $ 1 modr/m, $ 0 c, ;

:! movb!  $ 88 c, mem modr/m, ;
:! movzxb@  rex.w, $ b60f w, swap mem modr/m, ;
:! movzxbl  $ b60f w, reg modr/m, ;

:! raxxchgq  rex.w, $ 90 + c, ;

:! compile  docol  $ e8 c, rel32, ;
:! call$  compile ;
:! call  $ ff c, $ 2 reg modr/m, ;

:! pushq  $ 50 + c, ;
:! popq   $ 58 + c, ;

:! andq  rex.w, $ 21 c, reg modr/m, ;
:!  orq  rex.w, $ 09 c, reg modr/m, ;
:! xorq  rex.w, $ 31 c, reg modr/m, ;
:! notq  rex.w, $ f7 c, $ 2 reg modr/m, ;
:! negq  rex.w, $ f7 c, $ 3 reg modr/m, ;

:! shrq$  swap rex.w, $ c1 c, $ 5 reg modr/m, c, ;
:! shlq$  swap rex.w, $ c1 c, $ 6 reg modr/m, c, ;
:! sarq$  swap rex.w, $ c1 c, $ 7 reg modr/m, c, ;
:! 1shrq  rex.w, $ d1 c, $ 5 reg modr/m, ;
:! 1shlq  rex.w, $ d1 c, $ 6 reg modr/m, ;
:! 1sarq  rex.w, $ d1 c, $ 7 reg modr/m, ;
:! clshrq  rex.w, $ d3 c, $ 5 reg modr/m, ;
:! clshlq  rex.w, $ d3 c, $ 6 reg modr/m, ;
:! clsarq  rex.w, $ d3 c, $ 7 reg modr/m, ;

:! cmpq   swap rex.w, $ 39 c, reg modr/m, ;
:! testq  rex.w, $ 85 c, reg modr/m, ;
:! testq$  rex.w, $ f7 c, swap $ 0 reg modr/m, d, ;

:! setzb   $ 940f w, $ 0 reg modr/m, ;
:! seteb   $ 940f w, $ 0 reg modr/m, ;
:! setnzb  $ 950f w, $ 0 reg modr/m, ;
:! setneb  $ 950f w, $ 0 reg modr/m, ;
:! setlb   $ 9c0f w, $ 0 reg modr/m, ;
:! setgeb  $ 9d0f w, $ 0 reg modr/m, ;
:! setleb  $ 9e0f w, $ 0 reg modr/m, ;
:! setgb   $ 9f0f w, $ 0 reg modr/m, ;

:! cmovaq  swap rex.w, $ 470f w, reg modr/m, ;
:! cmovbq  swap rex.w, $ 420f w, reg modr/m, ;
:! cmovgq  swap rex.w, $ 4f0f w, reg modr/m, ;
:! cmovlq  swap rex.w, $ 4c0f w, reg modr/m, ;

:! jmp   $ ff c, $ 4 reg modr/m, ;
:! jmp$  $ eb c, rel8, ;
:! jz$   $ 74 c, rel8, ;
:! jnz$   $ 75 c, rel8, ;
:! loop$  $ e2 c, rel8, ;
:! jmpl$  $ e9 c, rel32, ;
:! jzl$   $ 840f w, rel32, ;
:! jnzl$  $ 850f w, rel32, ;

:! rep    $ f3 c, ;
:! repe   $ f3 c, ;
:! cmpsb  $ a6 c, ;
:! movsb  $ a4 c, ;
:! stosb  $ aa c, ;
:! stosq  rex.w, $ ab c, ;

:! syscall  $ 050f w, ;
:! nop  $ 90 c, ;
