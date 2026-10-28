import cv2

img = cv2.imread("tools/reference_analysis/f1_top_right.png")
# Let's inspect rows around Y=30..100, X=50..250 (which corresponds to window X: 500..700, Y: 20..100)
cv2.imwrite("tools/reference_analysis/f1_name_rows.png", img[20:110, 50:250])
print("Saved f1_name_rows.png")
