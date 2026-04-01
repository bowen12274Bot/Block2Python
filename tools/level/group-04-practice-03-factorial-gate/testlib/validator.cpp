#include "testlib.h"

int main() {
    registerValidation();
    inf.readInt(0, 12, "n");
    if (!inf.seekEof()) inf.readEoln();
    inf.skipBlanks();
    inf.readEof();
    return 0;
}