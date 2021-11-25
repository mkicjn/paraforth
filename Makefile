ALL = kernel out

all: $(ALL)

kernel: kernel.asm
	fasm kernel.asm
	chmod +x $@

out: kernel stage*
	cat stage* | ./kernel > $@
	chmod +x $@

.PHONY: clean

clean:
	rm -f $(ALL)
