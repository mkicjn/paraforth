ALL = core elf_demo

all: $(ALL)

core: core.asm
	fasm core.asm
	chmod +x $@

elf_demo: core stage*
	cat stage* | ./core > $@
	chmod +x $@

.PHONY: clean

clean:
	rm -f $(ALL)
