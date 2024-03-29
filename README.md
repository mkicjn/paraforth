# paraforth
**An extremely minimal (but not limiting) native code Forth environment in <1K**

At its very core, paraforth is just an assembly program with an association list of names to subroutines, and an input loop for invoking them.
By pre-populating the list with *just* enough functionality to implement *another assembler*, a self-extensible language is born.

This project demonstrates a leap from just 19 words and 851 bytes to an interactive programming environment with hundreds of words.

While aiming to keep the core as minimal as possible, this work draws the line at having to input pre-assembled machine code.
The purpose of this is to maintain paraforth's ability to meaningfully self-host.
Anything short of that, however - including writing an assembler from scratch - is considered fair game.

_(This project is an active work in progress.)_

### Quirks and Features:

* Tiny binary executable size - under one kilobyte
* Fast - a simplistic benchmark demonstrates ~4x speedup over `gforth-fast` on author's machine
  * Benchmark task: find the longest Collatz sequence for starting values under 1 million
* Fewer primitives than eForth - 19 vs. 31 - with as many as 5 that could still be eliminated
* Subroutine-threaded code, with inlining of primitives also implemented at runtime
  * Works by enabling a neat syntax for postponing blocks of code using `{` and `}`
* Compile-only Forth, with no `STATE` variable and no interpreter buffer
  * Code can still be "interpreted" (i.e., compiled and then run immediately) using `[` and `]`
* No concept of `immediate` words, technically, since all words execute immediately when typed
  * Non-immediate words use a shim that compiles a call to the rest of their code
* No built-in number syntax - parsing words like `$` and `#` are used for integer literals (at first)
  * The `base` variable and automatic number parsing are added as quality-of-life extensions in [repl.fth](src/repl.fth)
* An assembler for a useful subset of x86-64 implemented as a runtime extension of the compiler
* All I/O through a basic serial interface - `KEY` and `EMIT` are the only OS primitives in the core
* Working but very basic demo of ELF executable generation (no metacompiler yet)
* Reasonably extensive design notes in the source code - assumes familiarity with typical Forth internals

### Getting Started:

The loader script and list files handle the tedium of concatenating and piping source code files (plus standard input, if applicable).
Running `./loader.sh interactive.lst` provides the friendliest environment available for experimentation.

From there, you can try entering the canonical Hello World example, which looks like this:

    [ ." Hello, world!" cr  bye ]

Note that due to the interaction between `cat`, standard input, and the pipe to paraforth, you will need to hit enter once paraforth terminates before returning to the terminal.
The loader script can also be run with no arguments for additional details.

More example code is available in the [examples](examples) and [src](src) directories.

As a **very** brief overview, many trivial Forth examples can be translated to paraforth in just a couple of steps:
* Precede all numeric literals with a parsing word indicating the base.
  * Example: `77` becomes `# 77` or `$ 4d`
  * **NOTE:** Avoidable if including [repl.fth](src/repl.fth)
* Surround interpreted non-immediate words with brackets to execute them correctly.
  * Example: `bye` becomes `[ bye ]`, `10 constant x` becomes `[ 10 ] constant x`
 
_Friendly disclaimer: This is just scratching the surface.
Although this project aims to respect established conventions, standards conformance is not a priority.
These deviations are necessary to serve design goals, constraints, and/or personal preferences._

<details>
<summary> (Old usage notes with some additional details) </summary>
 
* Compile with `make`
* Run manually with, e.g., `cat input | ./paraforth > output` or `cat input - | ./paraforth`
* Debug with `gdb paraforth -ex 'r < <(cat input)'` and an `int3` assembled somewhere
  * Tip: Disassemble latest word with `x/10i $rsi+9+N` where *N* is the length of its name (i.e., `x/1c $rsi+8`)
* Disassemble using `objdump -b binary -m i386:x86-64 -D paraforth`
 
</details>

#### Dependencies:

* fasm (flat assembler; used to assemble the core)
* Linux-based OS (only to host syscalls)

My hope for this project is that it will eventually become fully self-hosting, even down to the OS level in the distant future.

#### Roadmap:

1. Produce a minimal subroutine-threaded Forth compiler capable of implementing an assembler.
   * ***(DONE)***
2. Implement a basic assembler using the compiler.
   * ***(DONE)***
3. Extend the existing Forth compiler in-place using the assembler.
   * ***(DONE)***
4. Improve usability by providing a REPL with error handling, convenient launch scripts, and library code.
   * ***(IN PROGRESS)***
5. Bootstrap the core and use the resulting system for other projects.

_(Anything marked done is still subject to improvements over time.)_

### Resources:

For a list of words paraforth currently offers, invoke `words` (defined in [src/repl.fth](src/repl.fth)).

To learn the system in detail, review [src/core.asm](src/core.asm) before proceeding through the files listed in [interactive.lst](interactive.lst). All source code comments in this project assume familiarity with programming in Forth, as well as typical Forth implementation techniques.

Note that the assembler source code, [src/asm.fth](src/asm.fth), contains no documentation because support for comments is not introduced until the beginning of [src/prims.fth](src/prims.fth).
However, it can be safely skipped if understanding of the included x86-64 assembler is not desired.

Recommended background resources:
  * Starting Forth - [Link to site with PDF and online version](https://www.forth.com/starting-forth/)
  * Thinking Forth - [Direct PDF link](https://www.forth.com/wp-content/uploads/2018/11/thinking-forth-color.pdf)
  * jonesforth - [Part 1 (assembly)](https://github.com/nornagon/jonesforth/blob/master/jonesforth.S); [Part 2 (Forth)](https://github.com/nornagon/jonesforth/blob/master/jonesforth.f)
  * Moving Forth - [Link to author's publications](https://www.bradrodriguez.com/papers/index.html)
  * eForth and Zen - [Direct PDF link](http://www.forth.org/OffeteStore/1013_eForthAndZen.pdf)

Additionally, a few notable design decisions were inspired by [FreeForth](http://christophe.lavarenne.free.fr/ff/).
