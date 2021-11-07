ALL = core

all: $(ALL)

core: core.asm
	fasm core.asm
	chmod +x core

.PHONY: clean

clean:
	rm -f $(ALL)
