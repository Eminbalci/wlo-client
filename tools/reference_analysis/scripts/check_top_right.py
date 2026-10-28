import cv2

f1 = cv2.imread("assets/menu/Skins/white/Form_CreateRole_1.jpg")
cv2.imwrite("tools/reference_analysis/f1_top_right.png", f1[0:150, 450:730])
print("Saved f1_top_right.png")
