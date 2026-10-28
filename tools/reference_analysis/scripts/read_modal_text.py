import cv2
import numpy as np

img = cv2.imread("tests/ref_frames_800x600/modal_sec_011.png")
# Find text pixels (dark text on light/brown parchment background)
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
# Let's find rows with high text variation
for y in range(40, 200, 10):
    row = gray[y, :]
    min_val = np.min(row)
    max_val = np.max(row)
    if max_val - min_val > 50:
        # text row!
        print(f"y={y}: min={min_val}, max={max_val}")
