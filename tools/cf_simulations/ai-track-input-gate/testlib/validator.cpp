#include "testlib.h"

int main() {
    registerValidation();
    inf.readToken("[A-Za-z]{1,32}", "name");
    inf.readEoln();
    inf.readEof();
    return 0;
}
