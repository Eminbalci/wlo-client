import cv2
import numpy as np

c = cv2.imread("tools/reference_analysis/check_name_inputs_rendered.png")
n = cv2.imread("tools/reference_analysis/named_satoru_ref_crop.png")

# Find the input boxes in c and n:
# Input boxes have light fill with border
diff = np.abs(c.astype(float) - n.astype(float)).mean(axis=2)
print("Mean diff between rendered and named:", diff.mean())
# Find where diff > 40:
mask = diff > 40
num_l, _, stats, _ = cv2.connectedComponentsWithStats(mask.astype(np.uint8))
print(f"Diff clusters: {num_l}")
for i in range(1, num_l):
    x, y, w, h, a = stats[i]
    if a > 50:
        print(f"  Cluster at X={x}, Y={y}, W={w}, H={h}, Area={a}")
