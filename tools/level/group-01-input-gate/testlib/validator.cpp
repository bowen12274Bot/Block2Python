#include "testlib.h"

int main() {
    registerValidation();

    std::string name;
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
        name.push_back(c);
    }

    ensuref(!name.empty(), "name must not be empty");
    ensuref(name.size() <= 64, "name length must be <= 64");
    for (char c : name) {
        ensuref(c >= 32 && c <= 126, "name must contain printable ASCII only");
    }

    inf.readEof();
    return 0;
}
