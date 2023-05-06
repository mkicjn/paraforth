# paraforth
### A minimal native code Forth in <1K, intended to seed an independent software stack as a macro assembler

_(This project is a very slow work in progress and has seen a long pause in development - hoping to resume soon.)_

#### Approach

1. Produce a Forth compiler supporting the minimal operations necessary to write an assembler
2. Implement an assembler using the compiler
3. Extend the existing Forth compiler in-place using the assembler
4. Metacompile and bootstrap a more featureful (non-minimal) Forth
    * At a minimum, will include improved error handling and an elegant inlining system

#### Current Features:

* Compile-only Forth, with no `STATE` variable and no interpreter buffer
  * Code can still be "interpreted" (i.e. compiled and then run immediately) using `[` and `]`
* Subroutine-threaded code
  * Mostly pure at the moment for simplicity, but with support for inlining in the future
* x86-64 assembler
  * No performance compromises due to lack of primitives
* Basic ELF executable generator demo (but no metacompiled version yet)

Before this project was rewritten, an extensive set of design notes existed in the source code comments.
The current revision is somewhat deficient in this regard, and should be improved in the future.

#### Current Dependencies:

* FASM (to assemble the kernel)
* Linux (only for system calls)

My hope for this project is it will eventually become fully self-hosting, even down to the OS level in the distant future.

#### Usage Notes:

* Compile with `make`
* Run with `cat input | ./kernel > output`
* Debug with `gdb kernel -ex 'r < <(input)'` and an `int3` somewhere
* Disassemble using `objdump -b binary -m i386:x86-64 -D kernel`
