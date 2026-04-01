#include "testlib.h"

int main() {
    registerValidation();
    inf.readInt(-100, 100, "temp");
    if (!inf.seekEof()) inf.readEoln();
    inf.skipBlanks();
    inf.readEof();
    return 0;
}