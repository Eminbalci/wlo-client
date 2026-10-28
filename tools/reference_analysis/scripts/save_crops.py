import cv2
import numpy as np

# Load the frames
f_step1 = cv2.imread("tests/ref_frames_800x600/02_step1_character_rocco.png")
f_step2 = cv2.imread("tests/ref_frames_800x600/06_step2_appearance_hair.png")
f_step3 = cv2.imread("tests/ref_frames_800x600/12_step3_element_earth.png")
f_sel_empty = cv2.imread("tests/ref_frames_800x600/01_char_select_empty.png")
f_sel_done = cv2.imread("tests/ref_frames_800x600/14_char_select_done.png")

# Let's save crops of each screen:
# Window headers/ribbons
cv2.imwrite("tests/ref_frames_800x600/crop_step1_header.png", f_step1[100:180, 200:600])
cv2.imwrite("tests/ref_frames_800x600/crop_step1_left.png", f_step1[120:500, 100:450])
cv2.imwrite("tests/ref_frames_800x600/crop_step1_right.png", f_step1[120:500, 450:720])
cv2.imwrite("tests/ref_frames_800x600/crop_step1_buttons.png", f_step1[480:550, 450:720])

cv2.imwrite("tests/ref_frames_800x600/crop_step2_left.png", f_step2[120:500, 100:450])
cv2.imwrite("tests/ref_frames_800x600/crop_step2_right.png", f_step2[120:500, 450:720])

cv2.imwrite("tests/ref_frames_800x600/crop_step3_left.png", f_step3[120:500, 100:450])
cv2.imwrite("tests/ref_frames_800x600/crop_step3_right.png", f_step3[120:500, 450:720])

cv2.imwrite("tests/ref_frames_800x600/crop_sel_empty.png", f_sel_empty[100:500, 100:700])
cv2.imwrite("tests/ref_frames_800x600/crop_sel_done.png", f_sel_done[100:500, 100:700])

print("Crops saved successfully.")
