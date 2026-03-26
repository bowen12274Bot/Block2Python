#include "testlib.h"

int main() {
    registerValidation();
    inf.readInt(0, 100, "score");
    inf.readEoln();
    inf.readEof();
    return 0;
}
