#include "testlib.h"

int main() {
    registerValidation();

    inf.readLong(-1000000000LL, 1000000000LL, "left");
    inf.readEoln();
    inf.readLong(-1000000000LL, 1000000000LL, "right");
    if (!inf.seekEof()) {
        inf.readEoln();
    }
    inf.skipBlanks();
    inf.readEof();
    return 0;
}