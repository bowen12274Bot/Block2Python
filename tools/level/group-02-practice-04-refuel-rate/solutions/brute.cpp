#include <bits/stdc++.h>
using namespace std;

int main(){
    long long fuel,hours;
    if(!(cin>>fuel>>hours)) return 0;
    long long q=0, r=fuel;
    while(r>=hours){ r-=hours; q++; }
    cout << "per_hour=" << q << "\n";
    cout << "remainder=" << r << "\n";
    return 0;
}