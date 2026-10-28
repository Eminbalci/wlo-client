import cv2
import numpy as np

img = cv2.imread("tests/ref_frames_800x600/modal_sec_011.png")
# Text is around y=110..150, let's crop x=50..270
crop = img[110:150, 50:270]
gray = cv2.cvtColor(crop, cv2.COLOR_BGR2GRAY)
# Threshold
_, thresh = cv2.threshold(gray, 120, 255, cv2.THRESH_BINARY_INV)

# Print ascii art (scaled down 2x horizontally)
ascii_str = ""
for y in range(0, thresh.shape[0], 2):
    line = ""
    for x in range(0, thresh.shape[1], 2):
        line += "#" if thresh[y, x] > 0 else " "
    ascii_str += line + "\n"

print(ascii_str)
