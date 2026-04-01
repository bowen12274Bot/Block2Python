#include "testlib.h"

int main(int argc, char* argv[]) {
    registerTestlibCmd(argc, argv);

    std::string jury1 = ans.readWord();
    std::string jury2 = ans.readWord();

    std::string part1 = ouf.readWord();
    std::string part2 = ouf.readWord();
    ouf.skipBlanks();
    ouf.readEof();

    if (jury1 != part1 || jury2 != part2) {
        quitf(_wa, "Expected '%s %s', found '%s %s'", jury1.c_str(), jury2.c_str(), part1.c_str(), part2.c_str());
    }

    quitf(_ok, "Correct remaining values");
}