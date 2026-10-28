import cv2
import numpy as np

f2 = cv2.imread("tools/reference_analysis/ref_frames_800x600/06_step2_appearance_hair.png")
# Let's crop (30, 124, 740, 352)
crop = f2[124:124+352, 30:30+740]
cv2.imwrite("tools/reference_analysis/f2_window_crop.png", crop)

# Let's also do for step 3:
f3 = cv2.imread("tools/reference_analysis/ref_frames_800x600/12_step3_element_earth.png")
crop3 = f3[124:124+352, 30:30+740]
cv2.imwrite("tools/reference_analysis/f3_window_crop.png", crop3)

print("Saved f2_window_crop.png and f3_window_crop.png")
