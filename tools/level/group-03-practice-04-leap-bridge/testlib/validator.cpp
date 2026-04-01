#include "testlib.h"

int main() {
    registerValidation();
    inf.readInt(1, 1000000, "year");
    if (!inf.seekEof()) inf.readEoln();
    inf.skipBlanks();
    inf.readEof();
    return 0;
}