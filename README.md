# paraforth
#### An extremely minimal (but not limiting) native code Forth in <1K

_(This project is a slow work in progress.)_

### Roadmap:

1. Produce a minimal subroutine-threaded Forth compiler capable of implementing an assembler. ***(DONE)***
2. Implement a basic assembler using the compiler. ***(DONE)***
3. Extend the existing Forth compiler in-place using the assembler. ***(DONE)***
4. Improve usability by providing a REPL with error handling, convenient launch scripts, and library code. ***(IN PROGRESS)***
5. Bootstrap the core and use the resulting system for other pet projects.

_(Anything marked done is still subject to improvements over time.)_

### Quirks and Features:

* Tiny binary executable size - under one kilobyte
* Fast - a basic informal benchmark estimates approximately 2-3x speedup over `gforth-fast`
  * (Benchmark task was to find the longest Collatz sequence for starting values under 1 million)
* Fewer primitives than eForth - 20 vs. 31 - and at least 2 of those are not even strictly necessary
* Compile-only Forth, with no `STATE` variable and no interpreter buffer
  * Code can still be "interpreted" (i.e., compiled and then run immediately) using `[` and `]`
* Subroutine-threaded code, with inlining of primitives also implemented at runtime
  * Works by enabling a neat syntax for postponing blocks of code using `{` and `}`
* An assembler for a useful subset of x86-64 implemented as a runtime extension of the compiler
* No built-in number syntax (parsing words like `$` and `#` used for integer literals of different bases)
* No internalized concept of "immediate" words - all words execute immediately when typed
  * (The trick is, non-immediate words simply compile a call instruction to their runtime code and return)
* All I/O through a basic serial interface - `KEY` and `EMIT` are the only OS primitives in the core
* Working (albeit very basic) ELF executable generator demo, but no metacompiled version yet
* Reasonably extensive design notes in the source code (assumes familiarity with typical Forth internals)

### Current Dependencies:

* FASM (flat assembler; used to assemble the core)
* Linux-based OS (only to host `read()` and `write()` syscalls)

My hope for this project is that it will eventually become fully self-hosting, even down to the OS level in the distant future.

### Usage Notes:

**Experimental:** The loader script can take care of some of this tedium. Run `./loader.sh` for details.

* Compile with `make`
* Run with, e.g., `cat input | ./paraforth > output` or `cat input - | ./paraforth`
* Debug with `gdb paraforth -ex 'r < <(cat input)'` and an `int3` assembled somewhere
  * Tip: Disassemble latest word with `x/10i $rsi+9+N` where *N* is the length of its name (i.e., `x/1c $rsi+8`)
* Disassemble using `objdump -b binary -m i386:x86-64 -D paraforth`

