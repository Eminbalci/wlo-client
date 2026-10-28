import cv2
import numpy as np

c2 = cv2.imread("tools/reference_analysis/f2_window_crop.png")
print("c2 shape:", c2.shape)
print("c2 top-left 10x10 BGR:\n", c2[:5, :5])
print("c2 center 5x5 BGR:\n", c2[170:175, 365:370])

# Where in 06_step2_appearance_hair.png is the window really?
full = cv2.imread("tools/reference_analysis/ref_frames_800x600/06_step2_appearance_hair.png")
print("full shape:", full.shape)
# Find parchment color: parchment is roughly B=170..230, G=190..245, R=210..255 (cream)
# Check where this color is:
is_parchment = (full[:, :, 0] > 140) & (full[:, :, 1] > 160) & (full[:, :, 2] > 180)
coords = np.argwhere(is_parchment)
print(f"Parchment bounds: Y=[{coords[:, 0].min()}, {coords[:, 0].max()}], X=[{coords[:, 1].min()}, {coords[:, 1].max()}]")
