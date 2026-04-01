#include <iostream>
using namespace std;

int main() {
    int n;
    if (!(cin >> n)) return 0;
    long long ans = 1;
    for (int i = 2; i <= n; ++i) {
        ans *= i;
    }
    cout << ans << "\n";
    return 0;
}