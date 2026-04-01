#include "testlib.h"

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);

    long long maxFuel = opt<long long>("maxFuel", 1000000000LL);
    int maxHours = opt<int>("maxHours", 1000000);
    ensuref(maxFuel >= 0, "maxFuel must be non-negative");
    ensuref(maxHours >= 1, "maxHours must be >= 1");

    long long fuel = rnd.next(0LL, maxFuel);
    long long hours = rnd.next(1, maxHours);
    println(fuel);
    println(hours);
    return 0;
}