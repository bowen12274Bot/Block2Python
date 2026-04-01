#include <bits/stdc++.h>
using namespace std;

int main(){
    long long t,u;
    if(!(cin>>t>>u)) return 0;
    long long rem = 0;
    for(long long i=0;i<t-u;i++) rem++;
    cout << "remaining=" << rem << "\n";
    cout << "double_remaining=" << rem + rem << "\n";
    return 0;
}