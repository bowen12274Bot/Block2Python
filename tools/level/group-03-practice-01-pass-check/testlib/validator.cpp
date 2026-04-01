#include "testlib.h"

int main() {
    registerValidation();
    inf.readInt(0, 100, "score");
    if (!inf.seekEof()) inf.readEoln();
    inf.skipBlanks();
    inf.readEof();
    return 0;
}