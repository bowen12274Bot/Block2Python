#include "testlib.h"

int main() {
    registerValidation();

    inf.readLong(1, 1000000000LL, "w");
    inf.readEoln();
    inf.readLong(1, 1000000000LL, "h");
    if (!inf.seekEof()) {
        inf.readEoln();
    }
    inf.skipBlanks();
    inf.readEof();
    return 0;
}
