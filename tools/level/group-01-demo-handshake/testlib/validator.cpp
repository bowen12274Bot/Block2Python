#include "testlib.h"

int main() {
    registerValidation();

    std::string codename;
    while (!inf.seekEof()) {
        char c = inf.readChar();
        if (c == '\n') {
            break;
        }
        if (c == '\r') {
            if (!inf.seekEof()) {
                inf.readChar('\n');
            }
            break;
        }
        codename.push_back(c);
    }

    ensuref(!codename.empty(), "codename must not be empty");
    ensuref(codename.size() <= 64, "codename length must be <= 64");
    for (char c : codename) {
        ensuref(c >= 32 && c <= 126, "codename must use printable ASCII only");
    }

    inf.readEof();
    return 0;
}
