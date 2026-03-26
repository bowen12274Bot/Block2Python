#include "testlib.h"

int main(int argc, char* argv[]) {
    registerTestlibCmd(argc, argv);

    long long jury = ans.readLong(-1, (long long)2e9, "jury_answer");
    long long participant = ouf.readLong(-1, (long long)2e9, "participant_answer");

    if (jury != participant) {
        quitf(_wa, "Expected %lld, found %lld", jury, participant);
    }

    quitf(_ok, "Correct answer");
}
