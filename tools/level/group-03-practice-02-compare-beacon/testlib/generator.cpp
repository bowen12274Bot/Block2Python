#include "testlib.h"

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);
    long long a = rnd.next(-1000000000LL, 1000000000LL);
    long long b = rnd.next(-1000000000LL, 1000000000LL);
    println(a);
    println(b);
    return 0;
}