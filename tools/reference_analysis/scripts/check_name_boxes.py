import cv2

f1 = cv2.imread("assets/menu/Skins/white/Form_CreateRole_1.jpg")
cv2.imwrite("tools/reference_analysis/f1_name_box_bg.png", f1[20:80, 500:720])

w1 = cv2.imread("tools/reference_analysis/ref_frames_800x600/w1.png")
cv2.imwrite("tools/reference_analysis/w1_name_box_ref.png", w1[20:80, 500:720])

print("Saved name box crops.")
