#include "testlib.h"

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);
    int temp = rnd.next(-100, 100);
    println(temp);
    return 0;
}