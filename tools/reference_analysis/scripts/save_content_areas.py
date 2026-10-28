import cv2

f2 = cv2.imread("tools/reference_analysis/ref_frames_800x600/06_step2_appearance_hair.png")
# Let's save a full crop of the area with content:
# In f2, let's see what is at Y: 100..500, X: 50..750
cv2.imwrite("tools/reference_analysis/f2_content_area.png", f2[100:500, 50:750])

f1 = cv2.imread("tools/reference_analysis/ref_frames_800x600/03_step1_character_daniel.png")
cv2.imwrite("tools/reference_analysis/f1_content_area.png", f1[100:500, 50:750])

f3 = cv2.imread("tools/reference_analysis/ref_frames_800x600/12_step3_element_earth.png")
cv2.imwrite("tools/reference_analysis/f3_content_area.png", f3[100:500, 50:750])

print("Saved content areas.")
