import cv2
import numpy as np

f1 = cv2.imread("assets/menu/Skins/white/Form_CreateRole_1.jpg")
w1 = cv2.imread("tests/ref_frames_800x600/step1_window.png")

diff1 = np.abs(w1.astype(float) - f1.astype(float)).mean(axis=2)
# Save diff map
cv2.imwrite("tests/ref_frames_800x600/diff_step1_raw.png", (diff1 * 4).clip(0, 255).astype(np.uint8))

# Find connected dynamic regions
mask1 = diff1 > 25
num_labels, labels, stats, centroids = cv2.connectedComponentsWithStats(mask1.astype(np.uint8))
print(f"Step 1 Dynamic Elements (found {num_labels}):")
for i in range(1, num_labels):
    x, y, w, h, area = stats[i]
    if area > 100:
        print(f"  Dynamic element: X={x}, Y={y}, W={w}, H={h}, Area={area}")

# Do the same for Step 2
f2 = cv2.imread("assets/menu/Skins/white/Form_CreateRole_2.jpg")
w2 = cv2.imread("tests/ref_frames_800x600/step2_window.png")
diff2 = np.abs(w2.astype(float) - f2.astype(float)).mean(axis=2)
cv2.imwrite("tests/ref_frames_800x600/diff_step2_raw.png", (diff2 * 4).clip(0, 255).astype(np.uint8))
mask2 = diff2 > 25
num_labels2, labels2, stats2, centroids2 = cv2.connectedComponentsWithStats(mask2.astype(np.uint8))
print(f"\nStep 2 Dynamic Elements (found {num_labels2}):")
for i in range(1, num_labels2):
    x, y, w, h, area = stats2[i]
    if area > 100:
        print(f"  Dynamic element: X={x}, Y={y}, W={w}, H={h}, Area={area}")

# Do the same for Step 3
f3 = cv2.imread("assets/menu/Skins/white/Form_CreateRole_3.jpg")
w3 = cv2.imread("tests/ref_frames_800x600/step3_window.png")
diff3 = np.abs(w3.astype(float) - f3.astype(float)).mean(axis=2)
cv2.imwrite("tests/ref_frames_800x600/diff_step3_raw.png", (diff3 * 4).clip(0, 255).astype(np.uint8))
mask3 = diff3 > 25
num_labels3, labels3, stats3, centroids3 = cv2.connectedComponentsWithStats(mask3.astype(np.uint8))
print(f"\nStep 3 Dynamic Elements (found {num_labels3}):")
for i in range(1, num_labels3):
    x, y, w, h, area = stats3[i]
    if area > 100:
        print(f"  Dynamic element: X={x}, Y={y}, W={w}, H={h}, Area={area}")
