#include<bits/stdc++.h>
using namespace std;
using ll = long long int;
int arr[35]={},n,x;
int ans = 0;
void sol(int dep,long long int v){
    if(v > x){
        return;
    }
    else if(dep == n){
        ans ++;
        return;
    }
    else{
        sol(dep+1,arr[dep]+v);
        sol(dep+1,v);
    }
    return;
}
int main(){
    cin>>n>>x;
    for(int i=0;i<n;i++){
        cin>>arr[i];
    }
    sol(0,0);
    cout<<ans<<endl;
}
