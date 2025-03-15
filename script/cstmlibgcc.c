#include <stdint.h>
#include <printf.h>


int __clzdi2(uint64_t x) {
    if (x == 0) return 64;
    int n = 0;
    if ((x >> 32) == 0) { n += 32; x <<= 32; }
    if ((x >> 48) == 0) { n += 16; x <<= 16; }
    if ((x >> 56) == 0) { n += 8;  x <<= 8;  }
    if ((x >> 60) == 0) { n += 4;  x <<= 4;  }
    if ((x >> 62) == 0) { n += 2;  x <<= 2;  }
    if ((x >> 63) == 0) { n += 1;  x <<= 1;  }
    return n;
}

int __ctzdi2(uint64_t x) {
    if (x == 0) return 64;
    int n = 0;
    if ((x & 0xFFFFFFFF) == 0) { n += 32; x >>= 32; }
    if ((x & 0xFFFF) == 0)     { n += 16; x >>= 16; }
    if ((x & 0xFF) == 0)       { n += 8;  x >>= 8;  }
    if ((x & 0xF) == 0)        { n += 4;  x >>= 4;  }
    if ((x & 0x3) == 0)        { n += 2;  x >>= 2;  }
    if ((x & 0x1) == 0)        { n += 1;  x >>= 1;  }
    return n;
}
