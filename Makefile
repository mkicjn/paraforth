ALL = fth

all: $(ALL)

fth: fth.asm
	fasm $^
	chmod +x $@

.PHONY: clean
clean:
	rm -f $(ALL)
