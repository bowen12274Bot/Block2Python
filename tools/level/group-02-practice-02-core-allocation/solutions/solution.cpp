#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    long long total, used;
    if (!(cin >> total)) return 0;
    if (!(cin >> used)) return 0;

    long long rem = total - used;
    cout << "remaining=" << rem << '\n';
    cout << "double_remaining=" << (2LL * rem) << '\n';
    return 0;
}