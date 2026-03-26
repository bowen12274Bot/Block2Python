#include <bits/stdc++.h>
using namespace std;

int main() {
    int n;
    cin >> n;
    long long sum = 0;
    int cnt = 0;
    for (int i = 0; i < n; i++) {
        long long x;
        cin >> x;
        sum += x;
        if (x >= 0) cnt++;
    }
    cout << cnt << " " << sum << "\n";
    return 0;
}
