import cv2

f_named = cv2.imread("tools/reference_analysis/ref_frames_800x600/05_step1_named_satoru_gojo.png")
# Crop name area:
crop = f_named[124+70:124+140, 30+500:30+720]
cv2.imwrite("tools/reference_analysis/named_satoru_crop.png", crop)
print("Saved named_satoru_crop.png")
