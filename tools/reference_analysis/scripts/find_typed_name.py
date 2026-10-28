import cv2
import numpy as np

f_named = cv2.imread("tools/reference_analysis/ref_frames_800x600/05_step1_named_satoru_gojo.png")
f_unnamed = cv2.imread("tools/reference_analysis/ref_frames_800x600/03_step1_character_daniel.png")

# Difference between named and unnamed shows exactly where the text was typed!
diff = np.abs(f_named.astype(float) - f_unnamed.astype(float)).mean(axis=2)
# Check window area:
mask = diff[124:124+352, 30:30+740] > 15
num_l, _, stats, _ = cv2.connectedComponentsWithStats(mask.astype(np.uint8))
print(f"Typed text regions in window ({num_l}):")
for i in range(1, num_l):
    x, y, w, h, a = stats[i]
    if a > 20:
        print(f"  Typed text at window: X={x}, Y={y}, W={w}, H={h}, Area={a}")
