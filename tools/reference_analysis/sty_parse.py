"""Parses the original WLRI scene layout files (sty/*.sty) of the 45-byte family.

Usage: python sty_parse.py <file.sty>
Prints the map-bound records: x, y (pixels), model id (sprite in 001.jma as "<id>.jmp"), and the remaining u32 fields.

Family: 638 of 768 files (checked by byte periodicity). Record = 45 bytes, all fields u32 little-endian (11 values +1 byte
tail). Files of the other family (33-byte stride, e.g. 11005.sty) are not handled here.
"""
import struct
import sys

STRIDE = 45
MAP_SIZES = {10001: (2432, 1792), 10002: (1659, 1266), 10003: (4672, 5056), 10008: (5824, 3200)}


def records(data: bytes):
    for off in range(0, len(data) - STRIDE + 1, STRIDE):
        yield off, struct.unpack_from("<11I", data, off)


def main() -> None:
    if len(sys.argv) < 2:
        print(__doc__)
        return
    data = open(sys.argv[1], "rb").read()
    recs = list(records(data))
    print(f"records {len(recs)}")
    for off, f in recs:
        print(f"@{off:6d} x={f[0]:5d} y={f[1]:5d} model={f[2]:6d} rest={list(f[3:])}")


if __name__ == "__main__":
    main()
