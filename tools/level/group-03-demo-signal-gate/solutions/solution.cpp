#include <iostream>
using namespace std;

int main() {
    long long signal;
    if (!(cin >> signal)) return 0;
    if (signal >= 0) cout << "OPEN\n";
    else cout << "BLOCK\n";
    return 0;
}