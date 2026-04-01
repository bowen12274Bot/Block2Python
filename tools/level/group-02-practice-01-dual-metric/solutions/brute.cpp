#include <bits/stdc++.h>
using namespace std;

int main(){
    long long a,b;
    if(!(cin>>a>>b)) return 0;
    long long s=0, d=0;
    s += a; s += b;
    d += a; d -= b;
    cout << "sum=" << s << "\n";
    cout << "diff=" << d << "\n";
    return 0;
}