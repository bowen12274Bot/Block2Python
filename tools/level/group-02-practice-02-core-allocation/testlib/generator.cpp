#include "testlib.h"

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);

    long long maxTotal = opt<long long>("maxTotal", 1000000000LL);
    ensuref(maxTotal >= 0, "maxTotal must be non-negative");

    long long total = rnd.next(0LL, maxTotal);
    long long used = rnd.next(0LL, total);

    println(total);
    println(used);
    return 0;
}