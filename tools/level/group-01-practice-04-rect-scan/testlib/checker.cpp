#include "testlib.h"

int main(int argc, char* argv[]) {
    registerTestlibCmd(argc, argv);

    long long juryArea = ans.readLong();
    long long juryPerimeter = ans.readLong();

    long long participantArea = ouf.readLong();
    long long participantPerimeter = ouf.readLong();
    ouf.skipBlanks();
    ouf.readEof();

    if (juryArea != participantArea || juryPerimeter != participantPerimeter) {
        quitf(
            _wa,
            "Expected '%lld %lld', found '%lld %lld'",
            juryArea,
            juryPerimeter,
            participantArea,
            participantPerimeter
        );
    }

    quitf(_ok, "Correct area and perimeter");
}
