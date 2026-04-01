#include <iostream>
#include <vector>
using namespace std;

int main() {
    int n;
    if (!(cin >> n)) return 0;

    vector<int> values(n);
    for (int i = 0; i < n; ++i) {
        cin >> values[i];
    }

    int nonNegativeCount = 0;
    int oddCount = 0;
    for (int v : values) {
        if (v >= 0) nonNegativeCount++;
        if (v % 2 != 0) oddCount++;
    }

    cout << nonNegativeCount << " " << oddCount << "\n";
    return 0;
}
