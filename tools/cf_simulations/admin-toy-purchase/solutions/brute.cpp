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

    long long ans = 0;
    function<void(int, long long)> dfs = [&](int idx, long long sum) {
        if (sum > x) return;
        if (idx == n) {
            ans++;
            return;
        }
        dfs(idx + 1, sum + a[idx]);
        dfs(idx + 1, sum);
    };

    dfs(0, 0);
    cout << ans << '\n';
    return 0;
}
