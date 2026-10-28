import cv2
import numpy as np

img = cv2.imread("tools/reference_analysis/f1_name_rows.png")
# Find text or labels:
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
# In img (shape 90x200), find the text characters (dark pixels < 90)
dark = gray < 90
num_l, _, stats, _ = cv2.connectedComponentsWithStats(dark.astype(np.uint8))
print(f"Components in f1_name_rows ({num_l}):")
for i in range(1, num_l):
    x, y, w, h, a = stats[i]
    if a > 8:
        print(f"  Dark text at X={x} (window {x+500}), Y={y} (window {y+20}), W={w}, H={h}, Area={a}")
