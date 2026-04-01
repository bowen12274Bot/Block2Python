#include <bits/stdc++.h>
using namespace std;

int main(){
    long long base,delta,f;
    if(!(cin>>base>>delta>>f)) return 0;
    long long after = 0;
    after += base;
    after += delta;
    long long amp = 0;
    for(long long i=0;i<f;i++) amp += after;
    cout << "after_delta=" << after << "\n";
    cout << "amplified=" << amp << "\n";
    return 0;
}