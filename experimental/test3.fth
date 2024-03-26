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

:  rex.w,  $ 48 c, ;

:! pushq  $ 50 + c, ;
:! popq   $ 58 + c, ;
:! movq   rex.w,  $ 89 c,  reg modr/m, ;
:! addq   rex.w,  $ 01 c,  reg modr/m, ;
:! subq   rex.w,  $ 29 c,  reg modr/m, ;

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

:! incq     rex.w,    $ ff c,   $ 0 reg modr/m, ;
:! decq     rex.w,    $ ff c,   $ 1 reg modr/m, ;
:! xchgq    rex.w,    $ 87 c,       reg modr/m, ;
:! testq    rex.w,    $ 85 c,       reg modr/m, ;
:! cmpq     rex.w,    $ 39 c,  swap reg modr/m, ;
:! movzxb@  rex.w,  $ b60f w,  swap mem modr/m, ;
:! movabs$          $ b848 w,                 , ;
:! jz$              $ 840f w,            rel32, ;
:! movzxbl          $ b60f w,       reg modr/m, ;
:! seteb            $ 940f w,   $ 0 reg modr/m, ;


\ More Forth primitives

:! there   { rax rdi xchgq } ;
:! back    { rdi rax movq  rax popq } ;

:! 1+    { rax incq } ;
:! 1-    { rax decq } ;

:  literal  { dup movabs$ } ;

:! begin  here ;
:! cond   { rdx rax movq  rax popq  rdx rdx testq } ;
:! until  { cond jz$ } ;

:! =      { rdx popq  rax rdx cmpq  rax seteb  rax rax movzxbl } ;

:! \  begin key $ a = until ;

:! c@  { rax rax movzxb@ } ;
:! cell  $ 8 literal ;

:  find  seek  $ 8 +  rcx rax movzxb@  rax rcx addq  rax incq ;
int3!
:  find  seek  cell +  dup c@ + 1+ ;
int3! \ ^^ Interesting case study above - almost the same code compiled


\ Most of the prototype stuff below no longer useful?
\ TODO  Separate assembler definitions from primitives

:  compile  $ e8 c, rel32, ;
:  here  rax pushq  rax rdi movq ;
:  back  rdi rax movq  rax popq ;
:  name  here name, back  here ;
:! '  name find literal ;
:! }  ;
:! {  begin  name find dup compile  ' } =  until ;
\ ^ Ideally we speedrun to this point to reduce rework

:  test  $ 1  $ 2  + ;
int3!
