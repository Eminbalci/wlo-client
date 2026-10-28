import cv2

img = cv2.imread("tools/reference_analysis/f1_name_rows.png")
# Save 4x upscaled
upscaled = cv2.resize(img, (img.shape[1]*4, img.shape[0]*4), interpolation=cv2.INTER_NEAREST)
cv2.imwrite("tools/reference_analysis/f1_name_rows_4x.png", upscaled)
print("Saved f1_name_rows_4x.png")
