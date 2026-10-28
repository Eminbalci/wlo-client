import cv2

# Let's inspect view_step2_center.png
f2_center = cv2.imread("tests/ref_frames_800x600/view_step2_center.png")
# Save the top ribbon of the window in Step 2:
# In f2 (800x600), where is the ribbon?
f2 = cv2.imread("tests/ref_frames_800x600/06_step2_appearance_hair.png")
cv2.imwrite("tests/ref_frames_800x600/f2_ribbon.png", f2[110:160, 250:550])

# And in Step 3:
f3 = cv2.imread("tests/ref_frames_800x600/12_step3_element_earth.png")
cv2.imwrite("tests/ref_frames_800x600/f3_ribbon.png", f3[110:160, 250:550])

# And in Step 1:
f1 = cv2.imread("tests/ref_frames_800x600/02_step1_character_rocco.png")
cv2.imwrite("tests/ref_frames_800x600/f1_ribbon.png", f1[110:160, 250:550])

print("Saved ribbons.")
