#include <iostream>
using namespace std;

int main() {
    int year;
    if (!(cin >> year)) return 0;
    bool leap = (year % 400 == 0) || (year % 4 == 0 && year % 100 != 0);
    cout << (leap ? "LEAP\n" : "COMMON\n");
    return 0;
}