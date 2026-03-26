#include <bits/stdc++.h>
using namespace std;

int main() {
    string name;
    getline(cin, name);
    if (name.empty() && !cin.eof()) getline(cin, name);
    cout << "Hello, " << name << "!\n";
    return 0;
}
