#include "testlib.h"

int main() {
    registerValidation();
    inf.readInt(-1000000000, 1000000000, "a");
    inf.readSpace();
    inf.readInt(-1000000000, 1000000000, "b");
    inf.readEoln();
    inf.readEof();
    return 0;
}
