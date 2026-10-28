import cv2
import numpy as np

f1 = cv2.imread("assets/menu/Skins/white/Form_CreateRole_1.jpg")
w1 = cv2.imread("tools/reference_analysis/ref_frames_800x600/w1.png")

diff1 = np.abs(w1.astype(float) - f1.astype(float)).mean(axis=2)
mask1 = diff1 > 25
num_labels, labels, stats, centroids = cv2.connectedComponentsWithStats(mask1.astype(np.uint8))
print(f"Step 1 Dynamic Elements (found {num_labels}):")
for i in range(1, num_labels):
    x, y, w, h, area = stats[i]
    if area > 100:
        print(f"  Dynamic element: X={x}, Y={y}, W={w}, H={h}, Area={area}")

f2 = cv2.imread("assets/menu/Skins/white/Form_CreateRole_2.jpg")
w2 = cv2.imread("tools/reference_analysis/ref_frames_800x600/w2.png")
diff2 = np.abs(w2.astype(float) - f2.astype(float)).mean(axis=2)
mask2 = diff2 > 25
num_labels2, labels2, stats2, centroids2 = cv2.connectedComponentsWithStats(mask2.astype(np.uint8))
print(f"\nStep 2 Dynamic Elements vs Form_CreateRole_2 (found {num_labels2}):")
for i in range(1, num_labels2):
    x, y, w, h, area = stats2[i]
    if area > 100:
        print(f"  Dynamic element: X={x}, Y={y}, W={w}, H={h}, Area={area}")

# Also compare w2 against Form_CreateRole_4 (which is 536x352) or check what w2 is!
print(f"\nWhat is in w2 vs w1?")
diff_w1_w2 = np.abs(w2.astype(float) - w1.astype(float)).mean(axis=2)
mask_w = diff_w1_w2 > 25
num_lw, _, stats_w, _ = cv2.connectedComponentsWithStats(mask_w.astype(np.uint8))
print(f"w2 vs w1 differences count: {num_lw}")
for i in range(1, num_lw):
    x, y, w, h, area = stats_w[i]
    if area > 100:
        print(f"  Diff area: X={x}, Y={y}, W={w}, H={h}, Area={area}")
