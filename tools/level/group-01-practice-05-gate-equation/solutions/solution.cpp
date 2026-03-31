#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    long long a, b, x;
    if (!(cin >> a)) return 0;
    if (!(cin >> b)) return 0;
    if (!(cin >> x)) return 0;
    cout << (a * x + b) << '\n';
    return 0;
}
