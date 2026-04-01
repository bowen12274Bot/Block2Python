#include "testlib.h"

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);
    long long n = rnd.next(1LL, 100000LL);
    println(n);
    return 0;
}