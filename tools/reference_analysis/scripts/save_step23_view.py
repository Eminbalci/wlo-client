import cv2

f2 = cv2.imread("tests/ref_frames_800x600/06_step2_appearance_hair.png")
f3 = cv2.imread("tests/ref_frames_800x600/12_step3_element_earth.png")

# Let's save the region x: 100..700, y: 80..520
cv2.imwrite("tests/ref_frames_800x600/view_step2_center.png", f2[80:520, 100:700])
cv2.imwrite("tests/ref_frames_800x600/view_step3_center.png", f3[80:520, 100:700])

print("Saved view_step2_center.png and view_step3_center.png")
