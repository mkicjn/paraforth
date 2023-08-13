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
* Fewer primitives than eForth (20 vs. 31)
  * Some aren't even technically necessary to expose, but are provided for reuse (i.e., `NAME` and `DIGIT`)
* Compile-only Forth, with no `STATE` variable and no interpreter buffer
  * Code can still be "interpreted" (i.e., compiled and then run immediately) using `[` and `]`
* An assembler for a useful subset of x86-64 implemented as a runtime extension of the compiler
* Subroutine-threaded code, with inlined primitives also implemented at runtime as a compiler extension
  * Neat syntax for this - opposite to `[` and `]`, blocks of code can be *postponed* using `{` and `}`
* No built-in number syntax (parsing words like `$` and `#` used for integer literals of different bases)
* No internalized concept of "immediate" words - all words execute immediately when typed
  * (The trick is, non-immediate words simply compile a call instruction to their runtime code and return)
* Basic ELF executable generator demo (but no metacompiled version yet)
* All I/O through a basic serial interface - `KEY` and `EMIT` are the only OS primitives in the kernel
  * The `syscall` instruction can be used to implement more (such as `BYE`)
  * *(TODO: Scripts to set up the terminal and make it easier to run & debug with a source code load order file)*

#### Current Dependencies:

* FASM (to assemble the kernel)
* Linux-based OS (only to host `read()` and `write()` syscalls)

My hope for this project is it will eventually become fully self-hosting, even down to the OS level in the distant future.

#### Usage Notes:

* Compile with `make`
* Run with `cat input | ./kernel > output`
* Debug with `gdb kernel -ex 'r < <(input)'` and an `int3` somewhere
* Disassemble using `objdump -b binary -m i386:x86-64 -D kernel`
