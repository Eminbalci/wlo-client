import cv2

f1 = cv2.imread("assets/menu/Skins/white/Form_CreateRole_1.jpg")
f2 = cv2.imread("assets/menu/Skins/white/Form_CreateRole_2.jpg")
f3 = cv2.imread("assets/menu/Skins/white/Form_CreateRole_3.jpg")

print("Form 1 shape:", f1.shape)
print("Form 2 shape:", f2.shape)
print("Form 3 shape:", f3.shape)

# Let's check what is pre-printed in Form 1:
# The frames, borders, boxes, parchment backgrounds
cv2.imwrite("tests/ref_frames_800x600/form1_raw.png", f1)
cv2.imwrite("tests/ref_frames_800x600/form2_raw.png", f2)
cv2.imwrite("tests/ref_frames_800x600/form3_raw.png", f3)
print("Saved raw forms.")
