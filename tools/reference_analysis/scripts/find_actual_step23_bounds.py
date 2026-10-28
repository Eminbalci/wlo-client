import cv2
import numpy as np

f_step2 = cv2.imread("tests/ref_frames_800x600/06_step2_appearance_hair.png")
# Let's find the bounding box of the dialog in Step 2:
# Find where the background (LogPic1) is NOT present
logpic = cv2.imread("assets/pic/LogPic1.jpg")
diff2 = np.abs(f_step2.astype(float) - logpic.astype(float)).mean(axis=2)
# Pixels where diff > 30
mask2 = diff2 > 30
ys, xs = np.where(mask2)
print(f"Step 2 Actual Dialog Window Bounds in 800x600 screen:")
print(f"  X: [{xs.min()}, {xs.max()}] -> Width = {xs.max() - xs.min() + 1}")
print(f"  Y: [{ys.min()}, {ys.max()}] -> Height = {ys.max() - ys.min() + 1}")

crop_step2 = f_step2[ys.min():ys.max()+1, xs.min():xs.max()+1]
cv2.imwrite("tests/ref_frames_800x600/step2_actual_window.png", crop_step2)
print(f"Saved step2_actual_window.png with shape {crop_step2.shape}")

# Also check Step 3!
f_step3 = cv2.imread("tests/ref_frames_800x600/12_step3_element_earth.png")
diff3 = np.abs(f_step3.astype(float) - logpic.astype(float)).mean(axis=2)
mask3 = diff3 > 30
ys3, xs3 = np.where(mask3)
print(f"\nStep 3 Actual Dialog Window Bounds in 800x600 screen:")
print(f"  X: [{xs3.min()}, {xs3.max()}] -> Width = {xs3.max() - xs3.min() + 1}")
print(f"  Y: [{ys3.min()}, {ys3.max()}] -> Height = {ys3.max() - ys3.min() + 1}")

crop_step3 = f_step3[ys3.min():ys3.max()+1, xs3.min():xs3.max()+1]
cv2.imwrite("tests/ref_frames_800x600/step3_actual_window.png", crop_step3)
print(f"Saved step3_actual_window.png with shape {crop_step3.shape}")
