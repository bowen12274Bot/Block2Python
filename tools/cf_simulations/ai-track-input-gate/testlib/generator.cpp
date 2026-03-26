#include "testlib.h"
#include <bits/stdc++.h>
using namespace std;

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);
    int n = opt<int>("len", rnd.next(1, 10));
    string s;
    for (int i = 0; i < n; i++) s.push_back(char('a' + rnd.next(0, 25)));
    println(s);
    return 0;
}
