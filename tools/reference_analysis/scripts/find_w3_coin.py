import cv2
import numpy as np

w3 = cv2.imread("tools/reference_analysis/ref_frames_800x600/w3.png")
w1 = cv2.imread("tools/reference_analysis/ref_frames_800x600/w1.png")

# Difference between w3 and w1 on the right side shows what Step 3 added to PreviewBox!
diff_r = np.abs(w3[:, 370:].astype(float) - w1[:, 370:].astype(float)).mean(axis=2)
mask = diff_r > 20
num_l, _, stats, _ = cv2.connectedComponentsWithStats(mask.astype(np.uint8))
print(f"Step 3 Right Added Regions ({num_l}):")
for i in range(1, num_l):
    x, y, w, h, a = stats[i]
    if a > 40:
        print(f"  Added element (rel to X=370): X={x} (abs {x+370}), Y={y}, W={w}, H={h}, Area={a}")
