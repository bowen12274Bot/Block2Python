#include <iostream>
using namespace std;

int main() {
    int hp, key, alarm;
    if (!(cin >> hp >> key >> alarm)) return 0;
    if (key == 1 && alarm == 0) cout << "OPEN\n";
    else if (hp >= 80 && alarm == 0) cout << "OVERRIDE\n";
    else cout << "LOCKDOWN\n";
    return 0;
}