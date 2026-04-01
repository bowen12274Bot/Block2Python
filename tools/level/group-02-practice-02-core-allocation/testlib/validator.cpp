#include "testlib.h"

int main() {
    registerValidation();

    long long total = inf.readLong(0LL, 1000000000LL, "total");
    inf.readEoln();
    inf.readLong(0LL, total, "used");
    if (!inf.seekEof()) {
        inf.readEoln();
    }
    inf.skipBlanks();
    inf.readEof();
    return 0;
}