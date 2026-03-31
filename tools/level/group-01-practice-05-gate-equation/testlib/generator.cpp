#include "testlib.h"

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);

    long long low = opt<long long>("low", -1000000000LL);
    long long high = opt<long long>("high", 1000000000LL);
    ensuref(low <= high, "low must be <= high");

    long long a = rnd.next(low, high);
    long long b = rnd.next(low, high);
    long long x = rnd.next(low, high);
    println(a);
    println(b);
    println(x);
    return 0;
}
