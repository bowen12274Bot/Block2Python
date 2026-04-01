#include "testlib.h"

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);
    int n = rnd.next(0, 12);
    println(n);
    return 0;
}