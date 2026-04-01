#include "testlib.h"

int main(int argc, char* argv[]) {
    registerTestlibCmd(argc, argv);

    int tokenIndex = 1;
    while (!ans.seekEof()) {
        std::string jury = ans.readWord();
        if (ouf.seekEof()) {
            quitf(_wa, "Output ended early at token %d", tokenIndex);
        }
        std::string part = ouf.readWord();
        if (jury != part) {
            quitf(_wa, "Mismatch at token %d: expected '%s', found '%s'", tokenIndex, jury.c_str(), part.c_str());
        }
        tokenIndex++;
    }

    ouf.skipBlanks();
    ouf.readEof();
    quitf(_ok, "Correct output");
}