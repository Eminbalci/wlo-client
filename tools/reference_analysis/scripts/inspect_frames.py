import cv2
import numpy as np

# Let's inspect sec_000, sec_003, sec_005, sec_011, sec_015, sec_023, sec_031, sec_040, sec_050, sec_058
# We want to check:
# 1. Screen size and inner game window bounds
# 2. What windows appear and their title ribbons
# 3. What buttons are clicked
# 4. What messages/alerts pop up (e.g. around sec_011 or empty name)

import glob
files = sorted(glob.glob("tests/ref_frames/sec_*.png"))
print(f"Total frame files: {len(files)}")

# Let's check frame 0 (Character Select initial state)
img0 = cv2.imread("tests/ref_frames/sec_000.png")
h, w, _ = img0.shape
print(f"Frame resolution: {w}x{h}")
