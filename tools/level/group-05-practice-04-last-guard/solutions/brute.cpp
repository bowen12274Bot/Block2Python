#include <iostream>
#include <vector>
using namespace std;

int main() {
    int n;
    if (!(cin >> n)) return 0;

    vector<int> values(n + 1);
    for (int i = 1; i <= n; ++i) {
        cin >> values[i];
    }

    int answer = 0;
    for (int i = n; i >= 1; --i) {
        if (values[i] % 2 == 0) {
            answer = i;
            break;
        }
    }

    cout << answer << "\n";
    return 0;
}
