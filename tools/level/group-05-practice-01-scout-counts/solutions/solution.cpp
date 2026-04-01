#include <iostream>
using namespace std;

int main() {
    int n;
    if (!(cin >> n)) return 0;

    int nonNegativeCount = 0;
    int oddCount = 0;

    for (int i = 0; i < n; ++i) {
        int x;
        cin >> x;
        if (x >= 0) nonNegativeCount++;
        if (x % 2 != 0) oddCount++;
    }

    cout << nonNegativeCount << " " << oddCount << "\n";
    return 0;
}
