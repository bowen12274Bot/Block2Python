#include "testlib.h"

int main() {
    registerValidation();
    inf.readInt(1, 100000, "n");
    inf.readEoln();
    inf.readEof();
    return 0;
}
