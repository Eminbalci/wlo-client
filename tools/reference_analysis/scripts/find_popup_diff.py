import cv2
import numpy as np

img11 = cv2.imread("tests/ref_frames_800x600/center_sec_011.png")
img10 = cv2.imread("tests/ref_frames_800x600/center_sec_010.png")
diff = np.abs(img11.astype(float) - img10.astype(float)).mean()
print("Diff between sec 10 and sec 11 center:", diff)

# Let's find where the difference is located in the entire screen between sec 10 and sec 11
f10 = cv2.imread("tests/ref_frames_800x600/sec_010.png")
f11 = cv2.imread("tests/ref_frames_800x600/sec_011.png")
diff_full = np.abs(f11.astype(float) - f10.astype(float)).mean(axis=2)
mask = diff_full > 30
if np.any(mask):
    y_idxs, x_idxs = np.where(mask)
    print(f"Diff bbox: x=[{x_idxs.min()}, {x_idxs.max()}], y=[{y_idxs.min()}, {y_idxs.max()}]")
    cv2.imwrite("tests/ref_frames_800x600/popup_sec_011.png", f11[y_idxs.min():y_idxs.max()+1, x_idxs.min():x_idxs.max()+1])
else:
    print("No large difference found between 10 and 11")

# Also check between 11 and 12, 12 and 13
f12 = cv2.imread("tests/ref_frames_800x600/sec_012.png")
diff_12 = np.abs(f12.astype(float) - f11.astype(float)).mean(axis=2)
mask12 = diff_12 > 30
if np.any(mask12):
    y_idxs, x_idxs = np.where(mask12)
    print(f"Diff 11->12 bbox: x=[{x_idxs.min()}, {x_idxs.max()}], y=[{y_idxs.min()}, {y_idxs.max()}]")
    cv2.imwrite("tests/ref_frames_800x600/popup_sec_012.png", f12[y_idxs.min():y_idxs.max()+1, x_idxs.min():x_idxs.max()+1])
