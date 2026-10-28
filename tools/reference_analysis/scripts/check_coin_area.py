import cv2

w3 = cv2.imread("tools/reference_analysis/ref_frames_800x600/w3.png")
crop = w3[130:270, 500:600]
cv2.imwrite("tools/reference_analysis/w3_coin_area.png", crop)

# Let's also crop w1 in the same spot to compare:
w1 = cv2.imread("tools/reference_analysis/ref_frames_800x600/w1.png")
crop1 = w1[130:270, 500:600]
cv2.imwrite("tools/reference_analysis/w1_coin_area.png", crop1)

print("Saved coin areas.")
