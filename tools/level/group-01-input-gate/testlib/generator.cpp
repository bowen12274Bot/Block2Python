#include "testlib.h"
#include <bits/stdc++.h>
using namespace std;

string randomWord(int minLen, int maxLen) {
    int len = rnd.next(minLen, maxLen);
    string w;
    w.reserve(len);
    w.push_back(char('A' + rnd.next(0, 25)));
    for (int i = 1; i < len; i++) {
        w.push_back(char('a' + rnd.next(0, 25)));
    }
    return w;
}

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);

    int words = opt<int>("words", rnd.next(1, 3));
    int minLen = opt<int>("minLen", 2);
    int maxLen = opt<int>("maxLen", 8);

    string name;
    for (int i = 0; i < words; i++) {
        if (i) name += ' ';
        name += randomWord(minLen, maxLen);
    }

    println(name);
    return 0;
}
