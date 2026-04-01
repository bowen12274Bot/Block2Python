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

    int answer = 1;
    for (int i = 1; i <= n; ++i) {
        bool hasGreater = false;
        for (int j = 1; j <= n; ++j) {
            if (values[j] > values[i]) {
                hasGreater = true;
                break;
            }
        }
        if (!hasGreater) {
            answer = i;
            break;
        }
    }

    cout << answer << "\n";
    return 0;
}