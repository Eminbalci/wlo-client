import cv2
import numpy as np

f2 = cv2.imread("tools/reference_analysis/ref_frames_800x600/06_step2_appearance_hair.png")
# Look at row y=140 across all x (0..800):
# Find where the window background (cream/parchment) is:
row = f2[160, :]
# LogPic1 is dark blue/black. The window is cream/parchment (RGB > 180).
is_window = (row[:, 0] > 100) & (row[:, 1] > 100) & (row[:, 2] > 100)
x_window = np.where(is_window)[0]
print(f"Step 2 Window X at y=160: [{x_window.min()}, {x_window.max()}], width = {x_window.max() - x_window.min() + 1}")

# Check column at x=400 (center of window) across y:
col = f2[:, 400]
is_window_y = (col[:, 0] > 100) & (col[:, 1] > 100) & (col[:, 2] > 100)
y_window = np.where(is_window_y)[0]
print(f"Step 2 Window Y at x=400: [{y_window.min()}, {y_window.max()}], height = {y_window.max() - y_window.min() + 1}")

# Check Step 3
f3 = cv2.imread("tools/reference_analysis/ref_frames_800x600/12_step3_element_earth.png")
row3 = f3[160, :]
x_win3 = np.where((row3[:, 0] > 100) & (row3[:, 1] > 100) & (row3[:, 2] > 100))[0]
print(f"Step 3 Window X at y=160: [{x_win3.min()}, {x_win3.max()}], width = {x_win3.max() - x_win3.min() + 1}")

col3 = f3[:, 400]
y_win3 = np.where((col3[:, 0] > 100) & (col3[:, 1] > 100) & (col3[:, 2] > 100))[0]
print(f"Step 3 Window Y at x=400: [{y_win3.min()}, {y_win3.max()}], height = {y_win3.max() - y_win3.min() + 1}")
