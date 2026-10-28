import cv2
import numpy as np

# Load modal_sec_011.png
img = cv2.imread("tests/ref_frames_800x600/modal_sec_011.png")
# Let's upscale and enhance contrast to read what text is printed inside:
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
# Resize 3x with bicubic
big = cv2.resize(gray, (img.shape[1]*3, img.shape[0]*3), interpolation=cv2.INTER_CUBIC)
cv2.imwrite("tests/ref_frames_800x600/modal_big.png", big)
print("Saved modal_big.png")
