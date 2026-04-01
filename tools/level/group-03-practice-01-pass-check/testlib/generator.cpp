#include "testlib.h"

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);
    int score = rnd.next(0, 100);
    println(score);
    return 0;
}