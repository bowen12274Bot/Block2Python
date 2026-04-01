#include "testlib.h"

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);

    long long low = opt<long long>("low", -1000000000LL);
    long long high = opt<long long>("high", 1000000000LL);
    int maxFactor = opt<int>("maxFactor", 100000);

    long long base = rnd.next(low, high);
    long long delta = rnd.next(low, high);
    long long factor = rnd.next(0, maxFactor);

    println(base);
    println(delta);
    println(factor);
    return 0;
}