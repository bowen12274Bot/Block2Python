#include "testlib.h"
#include <bits/stdc++.h>
using namespace std;

string randomWord(int minLen, int maxLen) {
    int len = rnd.next(minLen, maxLen);
    string w;
    w.reserve(len);

    const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    for (int i = 0; i < len; i++) {
        w.push_back(chars[rnd.next(0, int(chars.size()) - 1)]);
    }
    return w;
}

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);

    int words = opt<int>("words", rnd.next(1, 3));
    int minLen = opt<int>("minLen", 1);
    int maxLen = opt<int>("maxLen", 10);
    ensuref(words >= 1 && words <= 3, "words must be in [1,3]");
    ensuref(minLen >= 1, "minLen must be >= 1");
    ensuref(minLen <= maxLen, "minLen must be <= maxLen");

    string codename;
    for (int i = 0; i < words; i++) {
        if (i) codename += ' ';
        codename += randomWord(minLen, maxLen);
    }

    println(codename);
    return 0;
}
