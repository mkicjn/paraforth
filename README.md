# paraforth
### A subroutine-threaded Forth focused on independence and extreme minimalism

All documentation and design notes are inside the assembly file as inline comments.

## State of the Project (11/2/2021)

The experimental reimplementation was a success, and I find this version of the project more interesting, hence the rename.
The goal of this new implementation is to avoid relying on other people's software as much as possible,
eventually resulting in a completely custom software stack.
(In fact, I originally conceived of the new name as being short for "paranoid Forth,"
but the other definitions of the para- prefix seem to apply here as well.)

To maximize independence, the core must be extremely minimal, and as much of the language as possible should be written in itself.
However, I don't want to be forced to sacrifice any performance.
Therefore, I've written an extremely basic assembler in Forth, and am using its dependencies as my minimal set of primitives.
Most efforts to develop off of a minimal core (a la eForth) are more theoretical in nature,
and are willing to sacrifice performance for the sake of minimalism.
My approach is motivated more by pragmatism, and still results in what I think is a similar (if not greater) level of minimalism,
at the expense of some initial platform dependence.
For instance, my implementation has (at the time of writing) 22 primitives, as opposed to eForth's 31.
There are other major differences as well with my implementation, such as the complete lack of variables (including `STATE`).
(Those are to be implemented later using subroutine stubs.)

Hopefully there will eventually be a bootstrapping and metacompilation stage, as I described before.
I like the idea of inlining all primitives, but the core is smaller and simpler without this feature.
Thus, the size and simplicity benefits are very appealing in the short term.
With a proper metacompiler, however, I should be able to generate a new version with higher performance "out-of-the-box."
In addition, this step would (in a way) break the project free from all its dependencies.
Of course, to actually do that would require a custom OS kernel, which is a whole project in and of itself.

These are lofty goals, and only time will tell if I ever reach these accomplishments.
I have the knowledge, but alas, I have little time.

## State of the Project (10/23/2021)

I've been experimenting with a potential reimplementation of this project, hence the lack of recent commits.
This new version would reframe the project as a self-bootstrapping assembler and metacompiler.
So far, there are a few internal differences, but resulting language should turn out roughly the same.

The "experimental" branch will contain the files associated with these efforts.

## State of the Project (9/13/2021)

It really *has* been difficult to make progress on this outside of work and life obligations.
In fact, the second commit before today was while I was still at my parents' house.
Now, I own my own home!

Anyway, I had an epiphany last night that has given me some renewed motivation:

> The generation of executables doesn't need to be built into the compiler at all.
> In theory, I should be able to write a program which outputs a valid ELF header and dumps its own code section.
> At that point, I could simply redirect the output into a file.

Here's the kicker: the compiler only needs a few more things to make this possible.

So today, after a 5-week hiatus, I have finally returned to this project.

It was surprisingly easy to get back into, actually; I think this is a sign that I've done well documenting everything.
At any rate, I definitely forgot some details about the execution model and dictionary structure in that time,
and I was able to figure it out again pretty quickly after reading some of my notes.

I think the compiler really is closer to finished than I have given myself credit for in the past.
Once I can generate executables, I will be comfortable declaring this project a success.
Not that it will be finished, but that I'll be free to polish it, add more features, and actually use it for things.

For instance, after I write the executable generator, I want to write a small assembler for it.
These things will probably be structured as "libraries" that you include by prepending.
That's the preliminary plan, at least.

## State of the Project (6/6/2021)

This repo was created today to reflect my confidence that this project is viable.

Currently, there is a simple Forth prompt which supports very few words, but serves as a proof of concept.
There are no printing words, but the top stack item is returned in the form of the process' exit status.

Hopefully soon there will be compiling words and a more complete vocabulary.
For now, though, it really is just a proof of concept.

To anyone reading this, be aware that I'm developing this project in my spare time outside of work.
Progress will be very slow.
