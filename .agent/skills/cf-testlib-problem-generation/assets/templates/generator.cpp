#include "testlib.h"
#include <bits/stdc++.h>
using namespace std;

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);

    int n = opt<int>("n", rnd.next(1, 20));
    int lo = opt<int>("lo", -100);
    int hi = opt<int>("hi", 100);

    println(n);
    for (int i = 0; i < n; i++) {
        int x = rnd.next(lo, hi);
        print(x);
        print(i + 1 == n ? '\n' : ' ');
    }
    return 0;
}
