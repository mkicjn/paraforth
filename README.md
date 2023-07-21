# paraforth
### A minimal native code Forth in <1K, intended to seed an independent software stack as a macro assembler

_(This project is a very slow work in progress and has seen a long pause in development - hoping to resume soon.)_

#### Goals:

1. Produce a subroutine-threaded Forth compiler supporting the minimal operations necessary to write an assembler - **DONE**
2. Implement a basic assembler using the compiler - **DONE**
3. Extend the existing Forth compiler in-place using the assembler - **IN PROGRESS**
4. Use the compiler for other personal projects I have planned - **NOT STARTED**

#### Interesting Features:

* Tiny binary executable size - under one kilobyte
* Compile-only Forth, with no `STATE` variable and no interpreter buffer
  * Code can still be "interpreted" (i.e., compiled and then run immediately) using `[` and `]`
* No built-in number syntax (parsing words like `$` and `#` used for integer literals)
* No formal concept of "immediate" words, either - all words execute immediately when typed
  * (The catch is, all normal words do is compile a call instruction to the rest of their code)
* Subroutine-threaded code, with inlined primitives implemented as an extension of the compiler
* An x86-64 assembler, also implemented as an extension of the compiler
* Basic ELF executable generator demo (but no metacompiled version yet)
* All done through a basic "serial interface" - KEY, EMIT, and BYE are the only OS primitives
  * *(TODO: Scripts to make it easier to run/debug with a fixed source code load order)*

#### Current Dependencies:

* FASM (to assemble the kernel)
* Linux-based OS (only to host system calls)

My hope for this project is it will eventually become fully self-hosting, even down to the OS level in the distant future.

#### Usage Notes:

* Compile with `make`
* Run with `cat input | ./kernel > output`
* Debug with `gdb kernel -ex 'r < <(input)'` and an `int3` somewhere
* Disassemble using `objdump -b binary -m i386:x86-64 -D kernel`
