#include "testlib.h"

int main(int argc, char* argv[]) {
    registerTestlibCmd(argc, argv);
    std::string jury = ans.readWord();
    std::string part = ouf.readWord();
    ouf.skipBlanks();
    ouf.readEof();
    if (jury != part) {
        quitf(_wa, "Expected '%s', found '%s'", jury.c_str(), part.c_str());
    }
    quitf(_ok, "Correct gate decision");
}