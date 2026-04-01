#include "testlib.h"

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);
    int n = rnd.next(1, 200);
    println(n);

    int peak = rnd.next(-1000000, 1000000);
    int peakPos = rnd.next(0, n - 1);
    for (int i = 0; i < n; ++i) {
        if (i == peakPos) {
            println(peak);
        } else {
            println(rnd.next(-1000000, peak));
        }
    }
    return 0;
}
