# flatforth
### A subroutine-threaded Forth focused on staying brutally simple and facilitating binary generation

(Work in progress; name not yet permanent)

All documentation and design notes are inside the assembly file as inline comments.

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
