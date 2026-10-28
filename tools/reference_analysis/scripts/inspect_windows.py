import cv2

# Let's inspect the buttons in Step 1
f1 = cv2.imread("tests/ref_frames_800x600/02_step1_character_rocco.png")
# The window is from (30, 124) to (770, 476)
crop_w1 = f1[124:476, 30:770]
cv2.imwrite("tests/ref_frames_800x600/step1_window.png", crop_w1)

f2 = cv2.imread("tests/ref_frames_800x600/06_step2_appearance_hair.png")
crop_w2 = f2[124:476, 30:770]
cv2.imwrite("tests/ref_frames_800x600/step2_window.png", crop_w2)

f3 = cv2.imread("tests/ref_frames_800x600/12_step3_element_earth.png")
crop_w3 = f3[124:476, 30:770]
cv2.imwrite("tests/ref_frames_800x600/step3_window.png", crop_w3)

f_done = cv2.imread("tests/ref_frames_800x600/14_char_select_done.png")
cv2.imwrite("tests/ref_frames_800x600/char_select_done_window.png", f_done[124:476, 30:770])

print("Saved step1_window.png, step2_window.png, step3_window.png, char_select_done_window.png")
