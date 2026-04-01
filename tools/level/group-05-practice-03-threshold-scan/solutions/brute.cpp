#include <iostream>
#include <vector>
using namespace std;

int main() {
    int n, k;
    if (!(cin >> n)) return 0;
    cin >> k;

    vector<int> values(n);
    for (int i = 0; i < n; ++i) {
        cin >> values[i];
    }

    int count = 0;
    for (int v : values) {
        if (v >= k) count++;
    }

    cout << count << "\n";
    return 0;
}
