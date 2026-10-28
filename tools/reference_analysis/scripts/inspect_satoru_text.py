import cv2
import numpy as np

img = cv2.imread("tools/reference_analysis/named_satoru_crop.png")
# Find dark pixels (< 80)
dark = (img[:, :, 0] < 80) & (img[:, :, 1] < 80) & (img[:, :, 2] < 80)
# Find connected components of dark pixels (characters)
num_l, _, stats, _ = cv2.connectedComponentsWithStats(dark.astype(np.uint8))
print(f"Text components in crop ({num_l}):")
for i in range(1, num_l):
    x, y, w, h, a = stats[i]
    if a > 10:
        print(f"  Char at X={x} (window {x+500}), Y={y} (window {y+70}), W={w}, H={h}, Area={a}")
