#include "testlib.h"
#include <bits/stdc++.h>
using namespace std;

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);

    long long low = opt<long long>("low", -1000000000LL);
    long long high = opt<long long>("high", 1000000000LL);
    ensuref(low <= high, "low must be <= high");

    long long x = rnd.next(low, high);
    println(x);
    return 0;
}
