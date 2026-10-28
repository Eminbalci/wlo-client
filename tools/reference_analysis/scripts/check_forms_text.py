import cv2

f2 = cv2.imread("assets/menu/Skins/white/Form_CreateRole_2.jpg")
f3 = cv2.imread("assets/menu/Skins/white/Form_CreateRole_3.jpg")
f4 = cv2.imread("assets/menu/Skins/white/Form_CreateRole_4.jpg")

cv2.imwrite("tools/reference_analysis/f2_left_bg.png", f2[:250, :370])
cv2.imwrite("tools/reference_analysis/f3_left_bg.png", f3[:250, :370])
cv2.imwrite("tools/reference_analysis/f4_left_bg.png", f4[:250, :370])

print("Saved left backgrounds for f2, f3, f4.")
