#include "testlib.h"

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);
    int n = rnd.next(1, 30);
    println(n);
    for (int i = 0; i < n; i++) {
        int x = rnd.next(-1000, 1000);
        print(x);
        print(i + 1 == n ? '\n' : ' ');
    }
    return 0;
}
