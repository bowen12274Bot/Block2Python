#include "testlib.h"

int main() {
    registerValidation();
    int n = inf.readInt(1, 100, "n");
    inf.readEoln();
    for (int i = 0; i < n; ++i) {
        inf.readInt(-1000000, 1000000, "value");
        if (i + 1 < n) inf.readEoln();
    }
    if (!inf.seekEof()) inf.readEoln();
    inf.skipBlanks();
    inf.readEof();
    return 0;
}