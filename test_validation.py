"""Regression checks against an actual freshly linked image."""
import struct
import unittest
from pathlib import Path

from validate_firmware import validate


class ImageValidationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.image = Path(__file__).with_name("build").joinpath("final.bin").read_bytes()

    def test_fresh_image(self):
        validate(self.image)

    def test_corrupted_boot2(self):
        image = bytearray(self.image)
        image[0] ^= 1
        with self.assertRaisesRegex(ValueError, "CRC"):
            validate(image)

    def test_reset_missing_thumb_bit(self):
        image = bytearray(self.image)
        struct.pack_into("<I", image, 260, 0x10000200)
        with self.assertRaisesRegex(ValueError, "Thumb"):
            validate(image)

    def test_old_hardcoded_handler_in_padding(self):
        image = bytearray(self.image)
        struct.pack_into("<I", image, 268, 0x100001c5)
        with self.assertRaisesRegex(ValueError, "outside"):
            validate(image)

    def test_bad_stack(self):
        image = bytearray(self.image)
        struct.pack_into("<I", image, 256, 0)
        with self.assertRaisesRegex(ValueError, "stack"):
            validate(image)


if __name__ == "__main__":
    unittest.main()
