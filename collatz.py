#!/usr/bin/env python

import sys
import time
import math

def collatz(n):
    step = 0

    while n != 4:
        is_even = (n % 2 == 0)
        n = n//2 if is_even else 3*n + 1
        step += 1
        print("[{:>6}] {}".format(step, n))
        # time.sleep(0.005)


if __name__ == '__main__':
    start = int(sys.argv[1])
    collatz(start)

