#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    long long a, b;
    if (!(cin >> a)) return 0;
    if (!(cin >> b)) return 0;

    cout << "sum=" << (a + b) << '\n';
    cout << "diff=" << (a - b) << '\n';
    return 0;
}