#include <iostream>
using namespace std;

int main() {
    long long n;
    if (!(cin >> n)) return 0;
    long long cnt = 0;
    for (long long i = 2; i <= n; i += 2) {
        cnt++;
    }
    cout << cnt << "\n";
    return 0;
}