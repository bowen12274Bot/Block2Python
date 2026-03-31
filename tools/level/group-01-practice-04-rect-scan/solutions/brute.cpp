#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    long long w = 0, h = 0;
    if (!(cin >> w)) return 0;
    if (!(cin >> h)) return 0;

    cout << (w * h) << ' ' << (2LL * (w + h)) << '\n';
    return 0;
}
