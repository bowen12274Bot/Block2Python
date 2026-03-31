#include "testlib.h"

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);

    long long low = opt<long long>("low", 1);
    long long high = opt<long long>("high", 1000000000LL);
    ensuref(low >= 1, "low must be >= 1");
    ensuref(low <= high, "low must be <= high");

    long long w = rnd.next(low, high);
    long long h = rnd.next(low, high);
    println(w);
    println(h);
    return 0;
}
