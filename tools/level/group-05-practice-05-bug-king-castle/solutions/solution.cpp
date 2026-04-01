#include <iostream>
using namespace std;

int main() {
    int n;
    if (!(cin >> n)) return 0;
    int bestValue = 0;
    int answer = 1;
    for (int i = 1; i <= n; ++i) {
        int x;
        cin >> x;
        if (i == 1 || x > bestValue) {
            bestValue = x;
            answer = i;
        }
    }
    cout << answer << "\n";
    return 0;
}