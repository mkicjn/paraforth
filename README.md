# paraforth
**A sub-1KB, self-hosting, native code Forth without compromise**

At the core of paraforth is a very small assembly program - just an association list of names to subroutines, and an input loop for invoking them.
By pre-populating the list with *just* enough functionality to build a macro assembler, a self-extensible language kernel is born.

This project is a long-running exercise in building the smallest self-sufficient Forth possible, without **ANY** sacrifices in speed or usability.
No inputting pre-assembled machine code at runtime, and no cobbling together logic operations from NAND.

The entire language, save for just 15 words and 756 bytes of machine code, is implemented in itself - legibly - and builds in place on startup.

*Author's note: It's worth acknowledging that this definition of "self-hosting" is admittedly a little weak.
It's self-hosting in the sense that it assembles a better version of itself in memory at runtime, but not in the sense that it is fully bootstrapped yet.
Some progress has been made towards this (see examples/elf_demo.fth), but until I find the time and interest, it remains a future goal.*

### Quirks and Features:

* Tiny binary executable size - under one kilobyte
* Fast - a simplistic benchmark task demonstrates ~4x speedup over `gforth-fast` on author's machine
* Fewer primitives than eForth - 15 vs. 31 - with one spent just to enable line comments out of the box
* Subroutine-threaded code with primitive inlining - works by postponing blocks of code with `{` and `}`
* Compile-only Forth - code can still be "interpreted" (compiled and executed immediately) with `[` and `]`
* All words technically `immediate` - non-immediates use a shim that compiles a call instruction
* No internalized number syntax - parsing words like `$` and `#` used for integer literals (at least at first)
  * Quality-of-life extensions in [repl.fth](src/repl.fth) implement `base` and automatic number parsing
* An assembler for a useful subset of x86-64 implemented at runtime as the first extension of the compiler
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
* Surround interpreted non-immediate words with brackets to execute them.
  * Example: `bye` becomes `[ bye ]`, `10 constant x` becomes `[ 10 ] constant x`
* (Optional) Precede numeric literals with a parsing word indicating the base.
  * Example: `77` becomes `# 77` or `$ 4d`
  * Note: This step is only mandatory if not using the code in [repl.fth](src/repl.fth)
 
_Friendly disclaimer: This is scratching the surface.
Although this project aims to respect established conventions, standards conformance is not a priority.
Deviations are necessary to serve design goals, constraints, and/or personal preferences._

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

#### Status / Roadmap:

As a solo project, this work has been dormant for a while, but not dead, as I explore other project ideas that might eventually feed back into this one.
In any case, I still plan to return to this project eventually <sup>_(Famous last words?)_</sup> to follow through on my original goals:

1. Produce a minimal subroutine-threaded Forth compiler capable of implementing an assembler.
   * ***(DONE)***
2. Implement a basic assembler using the compiler.
   * ***(DONE)***
3. Extend the existing Forth compiler in-place using the assembler.
   * ***(DONE)***
4. Improve usability by providing a REPL with error handling, convenient launch scripts, and library code.
   * ***(DONE?)***
5. Bootstrap the core executable and use the resulting matured system for bigger projects. (Generating UEFI executables?)
   * ***(BARELY STARTED)***

_(Anything declared "done" might still be subject to enhancements over time.)_

### Resources:

For a list of words paraforth currently offers, load the interactive file list and invoke `words` (defined in [src/repl.fth](src/repl.fth)).

To learn the system in detail, review [src/core.asm](src/core.asm) before proceeding through the files listed in [interactive.lst](interactive.lst). All source code comments in this project assume familiarity with programming in Forth, as well as typical Forth implementation techniques.

Recommended background resources:
  * Starting Forth - [Link to site with PDF and online version](https://www.forth.com/starting-forth/)
  * Thinking Forth - [Direct PDF link](https://www.forth.com/wp-content/uploads/2018/11/thinking-forth-color.pdf)
  * jonesforth - [Part 1 (assembly)](https://github.com/nornagon/jonesforth/blob/master/jonesforth.S); [Part 2 (Forth)](https://github.com/nornagon/jonesforth/blob/master/jonesforth.f)
  * Moving Forth - [Link to author's publications](https://www.bradrodriguez.com/papers/index.html)
  * eForth and Zen - [Direct PDF link](http://www.forth.org/OffeteStore/1013_eForthAndZen.pdf)

Additionally, a few notable design decisions were inspired by [FreeForth](http://christophe.lavarenne.free.fr/ff/).
