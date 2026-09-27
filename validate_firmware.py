#!/usr/bin/env python3
"""Validate the RP2040 flash image before producing a UF2."""
import argparse
import struct
from pathlib import Path


def validate(data):
    if len(data) < 512:
        raise ValueError("image too short for boot2 and vectors")
    # ROM CRC: MSB-first CRC-32, seed all ones, no final xor.
    crc = 0xffffffff
    for byte in data[:252]:
        crc ^= byte << 24
        for _ in range(8):
            crc = ((crc << 1) ^ (0x04c11db7 if crc & 0x80000000 else 0)) & 0xffffffff
    if struct.unpack_from("<I", data, 252)[0] != crc:
        raise ValueError("boot2 CRC mismatch")
    vectors = struct.unpack_from("<48I", data, 256)
    if vectors[0] != 0x20042000:
        raise ValueError("unexpected initial stack pointer")
    for index, pointer in enumerate(vectors[1:], 1):
        if not pointer & 1:
            raise ValueError(f"vector {index} is missing its Thumb bit")
        if not 0x10000200 <= (pointer & ~1) < 0x10000000 + len(data):
            raise ValueError(f"vector {index} points outside executable image")
    if vectors[1] != 0x10000201:
        raise ValueError("reset entry must be at 0x10000200")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("binary", type=Path)
    args = parser.parse_args()
    try:
        validate(args.binary.read_bytes())
    except (OSError, ValueError) as error:
        parser.exit(1, f"Firmware validation failed: {error}\n")
    print("Validated boot2 CRC, stack, reset address and 47 Thumb vectors.")
