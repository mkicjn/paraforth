\ Words using Linux system calls

: bye  rdi rax movq  rax [ # 60 ] movq$  syscall ;

\ rcx, rdx, rdi, and rsi are clobbered by syscalls and must be preserved
:! pusha  { rcx pushq  rdx pushq  rdi pushq  rsi pushq } ;
:! popa   { rsi popq   rdi popq   rdx popq   rcx popq  } ;

: time  dup  pusha  rdi rdi xorq  rax [ # 201 ] movq$  syscall  popa ;
