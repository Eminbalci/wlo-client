import cv2
import numpy as np

f_step2 = cv2.imread("tests/ref_frames_800x600/06_step2_appearance_hair.png")
print("Top-left 5x5 BGR in f_step2:")
print(f_step2[:5, :5])

# Let's search all JPGs and BMPs in assets/pic and assets/menu for a match with f_step2[:50, :50]
import os
for root, dirs, files in os.walk("assets"):
    for f in files:
        if f.lower().endswith(".jpg") or f.lower().endswith(".bmp") or f.lower().endswith(".png"):
            path = os.path.join(root, f)
            t = cv2.imread(path)
            if t is not None and t.shape[0] >= 50 and t.shape[1] >= 50:
                diff = np.mean(np.abs(t[:50, :50].astype(float) - f_step2[:50, :50].astype(float)))
                if diff < 15.0:
                    print(f"Background match candidate: {path} (diff={diff:.2f}, size={t.shape})")
