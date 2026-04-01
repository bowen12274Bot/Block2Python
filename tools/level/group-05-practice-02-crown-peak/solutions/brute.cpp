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

    int answer = values[0];
    for (int i = 0; i < n; ++i) {
        bool hasGreater = false;
        for (int j = 0; j < n; ++j) {
            if (values[j] > values[i]) {
                hasGreater = true;
                break;
            }
        }
        if (!hasGreater) {
            answer = values[i];
            break;
        }
    }

    cout << answer << "\n";
    return 0;
}
