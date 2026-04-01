#include <iostream>
using namespace std;

int main() {
    long long a, b;
    if (!(cin >> a >> b)) return 0;
    if (a > b) cout << "A\n";
    else if (a < b) cout << "B\n";
    else cout << "EQUAL\n";
    return 0;
}