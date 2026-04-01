#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    string callsign;
    long long charge;
    if (!(cin >> callsign)) return 0;
    if (!(cin >> charge)) return 0;

    cout << "callsign=" << callsign << '\n';
    cout << "charge=" << charge << '\n';
    return 0;
}