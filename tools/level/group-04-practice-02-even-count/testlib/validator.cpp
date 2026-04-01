#include "testlib.h"

int main() {
    registerValidation();
    inf.readLong(1LL, 1000000000LL, "n");
    if (!inf.seekEof()) inf.readEoln();
    inf.skipBlanks();
    inf.readEof();
    return 0;
}