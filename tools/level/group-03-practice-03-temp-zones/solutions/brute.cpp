#include <iostream>
using namespace std;

int main() {
    int temp;
    if (!(cin >> temp)) return 0;
    if (temp < 0) cout << "ICE\n";
    else if (temp <= 30) cout << "OK\n";
    else cout << "HEAT\n";
    return 0;
}