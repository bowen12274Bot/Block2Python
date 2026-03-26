#include "testlib.h"
#include <bits/stdc++.h>
using namespace std;

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);

    int n = opt<int>("n", rnd.next(1, 30));
    int x = opt<int>("x", rnd.next(1, 500000));
    int lo = opt<int>("lo", 1);
    int hi = opt<int>("hi", 100000);
    string mode = opt<string>("mode", "random");

    println(n, " ", x);
    for (int i = 0; i < n; i++) {
        int v = 1;
        if (mode == "random") {
            v = rnd.next(lo, hi);
        } else if (mode == "small") {
            v = rnd.next(1, 20);
        } else if (mode == "large") {
            v = rnd.next(90000, 100000);
        } else if (mode == "ones") {
            v = 1;
        } else {
            v = rnd.next(lo, hi);
        }
        print(v);
        print(i + 1 == n ? '\n' : ' ');
    }
    return 0;
}
