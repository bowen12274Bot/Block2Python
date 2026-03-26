#include <bits/stdc++.h>
using namespace std;

int main() {
    int n;
    cin >> n;
    vector<long long> a(n);
    for (int i = 0; i < n; i++) cin >> a[i];
    int cnt = 0;
    long long sum = 0;
    for (long long v : a) {
        if (v >= 0) cnt++;
        sum += v;
    }
    cout << cnt << " " << sum << "\n";
    return 0;
}
