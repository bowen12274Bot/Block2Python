#include "testlib.h"

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);
    int n = rnd.next(1, 100);
    println(n);
    for (int i = 0; i < n; ++i) {
        println(rnd.next(-1000000, 1000000));
    }
    return 0;
}