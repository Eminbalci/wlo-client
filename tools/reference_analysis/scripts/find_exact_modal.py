import cv2
import numpy as np

img11 = cv2.imread("tests/ref_frames_800x600/modal_sec_011.png")
print("modal_sec_011 shape:", img11.shape)

# Let's inspect the bounding box of the modal in sec_011
f11 = cv2.imread("tests/ref_frames_800x600/sec_011.png")
f10 = cv2.imread("tests/ref_frames_800x600/sec_010.png")
diff = np.abs(f11.astype(float) - f10.astype(float)).mean(axis=2)

# Where diff > 20
y_idx, x_idx = np.where(diff > 20)
print(f"Modal in sec_011: x=[{x_idx.min()}, {x_idx.max()}], y=[{y_idx.min()}, {y_idx.max()}]")
modal_exact = f11[y_idx.min():y_idx.max()+1, x_idx.min():x_idx.max()+1]
cv2.imwrite("tests/ref_frames_800x600/modal_exact_011.png", modal_exact)

# Check modal in sec_053
f53 = cv2.imread("tests/ref_frames_800x600/sec_053.png")
f52 = cv2.imread("tests/ref_frames_800x600/sec_052.png")
diff53 = np.abs(f53.astype(float) - f52.astype(float)).mean(axis=2)
y_idx53, x_idx53 = np.where(diff53 > 20)
if len(x_idx53) > 0:
    print(f"Modal in sec_053: x=[{x_idx53.min()}, {x_idx53.max()}], y=[{y_idx53.min()}, {y_idx53.max()}]")
    cv2.imwrite("tests/ref_frames_800x600/modal_exact_053.png", f53[y_idx53.min():y_idx53.max()+1, x_idx53.min():x_idx53.max()+1])
