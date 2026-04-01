#include "testlib.h"

int main() {
    registerValidation();

    std::string s = inf.readToken("[A-Za-z]{1,20}", "callsign");
    inf.readEoln();
    inf.readLong(-1000000000LL, 1000000000LL, "charge");
    if (!inf.seekEof()) {
        inf.readEoln();
    }
    inf.skipBlanks();
    inf.readEof();
    return 0;
}