#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    long long w, h;
    if (!(cin >> w)) return 0;
    if (!(cin >> h)) return 0;

    long long area = w * h;
    long long perimeter = 2LL * (w + h);
    cout << area << ' ' << perimeter << '\n';
    return 0;
}
