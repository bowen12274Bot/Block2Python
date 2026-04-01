#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    long long fuel, hours;
    if (!(cin >> fuel)) return 0;
    if (!(cin >> hours)) return 0;

    cout << "per_hour=" << (fuel / hours) << '\n';
    cout << "remainder=" << (fuel % hours) << '\n';
    return 0;
}