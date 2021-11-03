ALL = fth

all: $(ALL)

fth: fth.asm
	fasm fth.asm
	chmod +x fth

.PHONY: clean

clean:
	rm -f $(ALL)
