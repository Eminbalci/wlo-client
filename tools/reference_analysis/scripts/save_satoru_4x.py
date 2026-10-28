import cv2

f = cv2.imread("tools/reference_analysis/ref_frames_800x600/05_step1_named_satoru_gojo.png")
# Window area is (30, 124)
crop = f[124+20:124+110, 30+500:30+700]
upscaled = cv2.resize(crop, (crop.shape[1]*4, crop.shape[0]*4), interpolation=cv2.INTER_NEAREST)
cv2.imwrite("tools/reference_analysis/named_satoru_rows_4x.png", upscaled)
print("Saved named_satoru_rows_4x.png")
