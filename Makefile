ALL = paraforth

all: $(ALL)

paraforth: src/core.asm
	fasm $< $@
	chmod +x $@

.PHONY: clean

clean:
	rm -f $(ALL)
