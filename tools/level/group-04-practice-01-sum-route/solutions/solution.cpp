#include <iostream>
using namespace std;

int main() {
    long long n;
    if (!(cin >> n)) return 0;
    long long ans = 0;
    for (long long i = 1; i <= n; ++i) {
        ans += i;
    }
    cout << ans << "\n";
    return 0;
}