#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    long long base, delta, factor;
    if (!(cin >> base)) return 0;
    if (!(cin >> delta)) return 0;
    if (!(cin >> factor)) return 0;

    long long after = base + delta;
    cout << "after_delta=" << after << '\n';
    cout << "amplified=" << (after * factor) << '\n';
    return 0;
}