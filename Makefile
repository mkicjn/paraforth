ALL = kernel

all: $(ALL)

kernel: kernel.asm
	fasm kernel.asm
	chmod +x kernel

.PHONY: clean

clean:
	rm -f $(ALL)
