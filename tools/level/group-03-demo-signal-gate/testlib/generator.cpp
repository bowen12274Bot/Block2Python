#include "testlib.h"

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);
    long long signal = rnd.next(-1000000000LL, 1000000000LL);
    println(signal);
    return 0;
}