#include "testlib.h"

int main() {
    registerValidation();

    int n = inf.readInt(1, 30, "n");
    inf.readSpace();
    inf.readInt(1, 500000, "x");
    inf.readEoln();

    for (int i = 0; i < n; i++) {
        inf.readInt(1, 100000, "bag_i");
        if (i + 1 < n) inf.readSpace();
    }
    inf.readEoln();

    inf.readEof();
    return 0;
}
