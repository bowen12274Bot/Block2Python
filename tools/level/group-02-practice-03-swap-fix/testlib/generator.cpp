#include "testlib.h"

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);

    long long low = opt<long long>("low", -1000000000LL);
    long long high = opt<long long>("high", 1000000000LL);

    long long left = rnd.next(low, high);
    long long right = rnd.next(low, high);
    println(left);
    println(right);
    return 0;
}