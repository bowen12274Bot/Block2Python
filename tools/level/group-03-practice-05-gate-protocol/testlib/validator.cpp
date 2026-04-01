#include "testlib.h"

int main() {
    registerValidation();
    inf.readInt(0, 100, "hp");
    inf.readEoln();
    inf.readInt(0, 1, "key");
    inf.readEoln();
    inf.readInt(0, 1, "alarm");
    if (!inf.seekEof()) inf.readEoln();
    inf.skipBlanks();
    inf.readEof();
    return 0;
}