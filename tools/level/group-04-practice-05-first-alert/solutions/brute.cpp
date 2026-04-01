#include <iostream>
using namespace std;

int main() {
    int n;
    if (!(cin >> n)) return 0;
    int answer = 0;
    for (int i = 1; i <= n; ++i) {
        int x;
        cin >> x;
        if (answer == 0 && x < 0) {
            answer = i;
        }
    }
    cout << answer << "\n";
    return 0;
}