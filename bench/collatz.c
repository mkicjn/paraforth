#include <stdio.h>
#include <stdint.h>

uint64_t collatz(uint64_t n)
{
	return n & 1 ? n + (n << 1) + 1 : n >> 1;
}

uint64_t collatz_len(uint64_t n)
{
	uint64_t i = 0;
	while (n > 1) {
		n = collatz(n);
		i++;
	}
	return i;
}

int main()
{
	uint64_t max = 0;
	for (uint64_t i = 0; ; i++) {
		uint64_t len = collatz_len(i);
		if (len > max) {
			max = len;
			printf("%lu %lu\n", i, len);
		}
	}
}
