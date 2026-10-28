import cv2
import numpy as np

# Load 800x600 cropped frames
f_select_empty = cv2.imread("tests/ref_frames_800x600/01_char_select_empty.png")
f_step1 = cv2.imread("tests/ref_frames_800x600/02_step1_character_rocco.png")
f_step2 = cv2.imread("tests/ref_frames_800x600/06_step2_appearance_hair.png")
f_step3 = cv2.imread("tests/ref_frames_800x600/12_step3_element_earth.png")
f_select_done = cv2.imread("tests/ref_frames_800x600/14_char_select_done.png")

# Let's find the main window bounding box in step 1, 2, 3
# The main dialog window is centered.
# Compare step 1 with LogPic1 to find where the window is:
logpic = cv2.imread("assets/pic/LogPic1.jpg")
diff_step1 = np.abs(f_step1.astype(float) - logpic.astype(float)).mean(axis=2)
# Pixels where diff > 20
mask = diff_step1 > 20
rows = np.where(np.any(mask, axis=1))[0]
cols = np.where(np.any(mask, axis=0))[0]
print(f"Step 1 Window Bounding Box: x=[{cols[0]}, {cols[-1]}] (width={cols[-1]-cols[0]+1}), y=[{rows[0]}, {rows[-1]}] (height={rows[-1]-rows[0]+1})")

# Let's do the same for Step 2 and Step 3
diff_step2 = np.abs(f_step2.astype(float) - logpic.astype(float)).mean(axis=2)
mask2 = diff_step2 > 20
rows2 = np.where(np.any(mask2, axis=1))[0]
cols2 = np.where(np.any(mask2, axis=0))[0]
print(f"Step 2 Window Bounding Box: x=[{cols2[0]}, {cols2[-1]}] (width={cols2[-1]-cols2[0]+1}), y=[{rows2[0]}, {rows2[-1]}] (height={rows2[-1]-rows2[0]+1})")

diff_step3 = np.abs(f_step3.astype(float) - logpic.astype(float)).mean(axis=2)
mask3 = diff_step3 > 20
rows3 = np.where(np.any(mask3, axis=1))[0]
cols3 = np.where(np.any(mask3, axis=0))[0]
print(f"Step 3 Window Bounding Box: x=[{cols3[0]}, {cols3[-1]}] (width={cols3[-1]-cols3[0]+1}), y=[{rows3[0]}, {rows3[-1]}] (height={rows3[-1]-rows3[0]+1})")

# Let's check Character Select screen bounding box
diff_sel = np.abs(f_select_empty.astype(float) - logpic.astype(float)).mean(axis=2)
mask_sel = diff_sel > 20
rows_sel = np.where(np.any(mask_sel, axis=1))[0]
cols_sel = np.where(np.any(mask_sel, axis=0))[0]
print(f"Char Select Window Bounding Box: x=[{cols_sel[0]}, {cols_sel[-1]}] (width={cols_sel[-1]-cols_sel[0]+1}), y=[{rows_sel[0]}, {rows_sel[-1]}] (height={rows_sel[-1]-rows_sel[0]+1})")
