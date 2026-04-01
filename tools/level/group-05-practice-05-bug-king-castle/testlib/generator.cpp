#include "testlib.h"

#include <set>
#include <vector>

int main(int argc, char* argv[]) {
    registerGen(argc, argv, 1);

    int n = rnd.next(1, 200);
    println(n);

    int maxValue = rnd.next(0, 1000000);
    int maxCount = rnd.next(1, std::min(n, 5));
    std::vector<int> values(n);
    for (int i = 0; i < n; ++i) {
        values[i] = rnd.next(-1000000, maxValue);
    }

    std::set<int> usedPositions;
    while ((int)usedPositions.size() < maxCount) {
        usedPositions.insert(rnd.next(0, n - 1));
    }
    for (int pos : usedPositions) {
        values[pos] = maxValue;
    }

    for (int i = 0; i < n; ++i) {
        println(values[i]);
    }

    return 0;
}