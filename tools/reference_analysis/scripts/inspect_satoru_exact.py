import cv2
import numpy as np

f = cv2.imread("tools/reference_analysis/named_satoru_rows_4x.png")
# Find text in f (which is 4x scaled, shape: 360, 800)
# Dark pixels < 100
dark = (f[:, :, 0] < 100) & (f[:, :, 1] < 100) & (f[:, :, 2] < 100)
num_l, _, stats, _ = cv2.connectedComponentsWithStats(dark.astype(np.uint8))
print(f"Components in named_satoru (scaled 4x):")
for i in range(1, num_l):
    x, y, w, h, a = stats[i]
    if a > 40:
        orig_x = x / 4.0 + 500
        orig_y = y / 4.0 + 20
        orig_w = w / 4.0
        orig_h = h / 4.0
        print(f"  Text at window X={orig_x:.1f}, Y={orig_y:.1f}, W={orig_w:.1f}, H={orig_h:.1f}")
