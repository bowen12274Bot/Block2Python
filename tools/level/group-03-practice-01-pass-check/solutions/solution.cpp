#include <iostream>
using namespace std;

int main() {
    int score;
    if (!(cin >> score)) return 0;
    if (score >= 60) cout << "PASS\n";
    else cout << "FAIL\n";
    return 0;
}