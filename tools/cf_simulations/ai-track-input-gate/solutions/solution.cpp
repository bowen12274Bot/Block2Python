#include <bits/stdc++.h>
using namespace std;

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    string name;
    getline(cin, name);
    if (name.empty() && !cin.eof()) getline(cin, name);
    cout << "Hello, " << name << "!\n";
    return 0;
}
