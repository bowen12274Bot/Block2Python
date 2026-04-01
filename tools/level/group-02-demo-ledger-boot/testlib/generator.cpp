#include "testlib.h"
#include <string>

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);

    int len = opt<int>("len", rnd.next(1, 20));
    long long low = opt<long long>("low", -1000000000LL);
    long long high = opt<long long>("high", 1000000000LL);

    std::string s;
    for (int i = 0; i < len; ++i) {
        s.push_back(char('A' + rnd.next(0, 25)));
    }
    long long charge = rnd.next(low, high);

    println(s);
    println(charge);
    return 0;
}