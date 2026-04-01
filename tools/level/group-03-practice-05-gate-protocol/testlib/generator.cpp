#include "testlib.h"

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);
    int hp = rnd.next(0, 100);
    int key = rnd.next(0, 1);
    int alarm = rnd.next(0, 1);
    println(hp);
    println(key);
    println(alarm);
    return 0;
}