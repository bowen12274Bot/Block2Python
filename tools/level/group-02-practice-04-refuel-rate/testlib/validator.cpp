#include "testlib.h"

int main() {
    registerValidation();

    inf.readLong(0LL, 1000000000LL, "fuel");
    inf.readEoln();
    inf.readLong(1LL, 1000000LL, "hours");
    if (!inf.seekEof()) {
        inf.readEoln();
    }
    inf.skipBlanks();
    inf.readEof();
    return 0;
}