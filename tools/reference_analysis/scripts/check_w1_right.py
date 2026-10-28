import cv2
import numpy as np

w1 = cv2.imread("tools/reference_analysis/ref_frames_800x600/w1.png")
# Right half is X=370..740, Y=0..352
right = w1[:, 370:]
cv2.imwrite("tools/reference_analysis/w1_right_exact.png", right)

# Let's inspect what is on the right side of w1:
# Top: Name banner & inputs
# Middle: Preview box (Bust, R, H, Walking Sprite, <, >)
# Bottom: Navigation buttons (Return, Continue)

# Where is the Name banner?
# In Form_CreateRole_1.jpg:
form1 = cv2.imread("assets/menu/Skins/white/Form_CreateRole_1.jpg")
diff_r = np.abs(w1.astype(float) - form1.astype(float)).mean(axis=2)
# Check differences on right side
diff_right = diff_r[:, 370:]
cv2.imwrite("tools/reference_analysis/diff_right_step1.png", (diff_right * 4).clip(0, 255).astype(np.uint8))

mask = diff_right > 20
num_l, _, stats, _ = cv2.connectedComponentsWithStats(mask.astype(np.uint8))
print(f"Step 1 Right Dynamic regions ({num_l}):")
for i in range(1, num_l):
    x, y, w, h, a = stats[i]
    if a > 80:
        print(f"  Right element (rel to X=370): X={x} (abs {x+370}), Y={y}, W={w}, H={h}, Area={a}")
