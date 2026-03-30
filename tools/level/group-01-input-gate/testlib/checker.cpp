#include "testlib.h"

int main(int argc, char* argv[]) {
    registerTestlibCmd(argc, argv);

    std::string jury = ans.readLine();
    std::string participant = ouf.readLine();

    ouf.skipBlanks();
    ouf.readEof();

    if (jury != participant) {
        quitf(_wa, "Expected '%s', found '%s'", jury.c_str(), participant.c_str());
    }

    quitf(_ok, "Greeting matches expected output");
}
