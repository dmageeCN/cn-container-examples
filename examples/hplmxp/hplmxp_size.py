#!/usr/bin/env python3
"""
HPLMXP size calculator.

Usage:
    hplmxp.py <nprocs> <nperg>

Example:
    hplmxp.py 64 100000
"""
import argparse
import math
import sys


def log2(x):
    return math.log2(x)

def round_n(n, nround):
    return round(n / nround) * nround


def hplmxp_size(nps, nperg):
    factor = 1.4
    exponent = log2(nps)
    return nperg * (factor ** exponent)


def main():
    parser = argparse.ArgumentParser(description="Compute HPLMXP size from nprocs.")
    parser.add_argument("nprocs", type=float, help="Number of processes")
    parser.add_argument("nperg", type=float, help="Base size (nperg)")
    parser.add_argument("-nr", "--nround", type=int, help="Rounding base for n", default=1000)
    args = parser.parse_args()

    size = hplmxp_size(args.nprocs, args.nperg)
    print(round_n(size, args.nround))


if __name__ == "__main__":
    main()