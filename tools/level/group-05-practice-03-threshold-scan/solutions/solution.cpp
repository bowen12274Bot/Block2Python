#include <iostream>
using namespace std;

int main() {
    int n, k;
    if (!(cin >> n)) return 0;
    cin >> k;

    int count = 0;
    for (int i = 0; i < n; ++i) {
        int x;
        cin >> x;
        if (x >= k) count++;
    }

    cout << count << "\n";
    return 0;
}
