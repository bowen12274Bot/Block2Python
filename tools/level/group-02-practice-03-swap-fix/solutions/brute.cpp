#include <bits/stdc++.h>
using namespace std;

int main(){
    long long a,b;
    if(!(cin>>a>>b)) return 0;
    long long t=a; a=b; b=t;
    cout << "left=" << a << "\n";
    cout << "right=" << b << "\n";
    return 0;
}