#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int n;
    long long x;
    cin >> n >> x;
    vector<long long> a(n);
    for (int i = 0; i < n; i++) {
        cin >> a[i];
    }

    int m = n / 2;
    int k = n - m;

    vector<long long> left;
    vector<long long> right;

    left.reserve(1 << m);
    right.reserve(1 << k);

    for (int mask = 0; mask < (1 << m); mask++) {
        long long s = 0;
        for (int i = 0; i < m; i++) {
            if (mask & (1 << i)) s += a[i];
        }
        if (s <= x) left.push_back(s);
    }

    for (int mask = 0; mask < (1 << k); mask++) {
        long long s = 0;
        for (int i = 0; i < k; i++) {
            if (mask & (1 << i)) s += a[m + i];
        }
        if (s <= x) right.push_back(s);
    }

    sort(right.begin(), right.end());

    long long ans = 0;
    for (long long lv : left) {
        ans += upper_bound(right.begin(), right.end(), x - lv) - right.begin();
    }

    cout << ans << '\n';
    return 0;
}
