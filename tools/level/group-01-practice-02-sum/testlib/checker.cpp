#include "testlib.h"

int main(int argc, char* argv[]) {
    registerTestlibCmd(argc, argv);

    long long jury = ans.readLong();
    long long participant = ouf.readLong();
    ouf.skipBlanks();
    ouf.readEof();

    if (jury != participant) {
        quitf(_wa, "Expected %lld, found %lld", jury, participant);
    }

    quitf(_ok, "Correct sum");
}
