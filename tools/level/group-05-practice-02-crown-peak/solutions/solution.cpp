#include <iostream>
using namespace std;

int main() {
    int n;
    if (!(cin >> n)) return 0;

    int best = 0;
    for (int i = 0; i < n; ++i) {
        int x;
        cin >> x;
        if (i == 0 || x > best) best = x;
    }

    cout << best << "\n";
    return 0;
}
