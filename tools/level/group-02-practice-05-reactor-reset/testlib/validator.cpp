#include "testlib.h"

int main() {
    registerValidation();

    inf.readLong(-1000000000LL, 1000000000LL, "base");
    inf.readEoln();
    inf.readLong(-1000000000LL, 1000000000LL, "delta");
    inf.readEoln();
    inf.readLong(0LL, 100000LL, "factor");
    if (!inf.seekEof()) {
        inf.readEoln();
    }
    inf.skipBlanks();
    inf.readEof();
    return 0;
}