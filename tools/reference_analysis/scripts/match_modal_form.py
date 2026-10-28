import cv2
import numpy as np
import os

img = cv2.imread("tests/ref_frames_800x600/modal_sec_011.png")
# Let's save a clean zoomed crop of the text area
# y=100..160, x=30..290
crop = img[100:160, 30:290]
cv2.imwrite("tests/ref_frames_800x600/modal_text_clean.png", crop)

# Let's inspect the colors of text pixels
# Text pixels are dark:
b, g, r = cv2.split(crop)
print(f"Text crop size: {crop.shape}")

# Let's check the size of the modal box in sec_011:
# The modal box has a header or border
# In WLO, what form is it?
# Let's search all BMP files in assets/menu/Skins for a match with this modal box!
f11 = cv2.imread("tests/ref_frames_800x600/sec_011.png")
for root, dirs, files in os.walk("assets/menu/Skins"):
    for f in files:
        if f.lower().endswith(".bmp") or f.lower().endswith(".jpg"):
            path = os.path.join(root, f)
            t_img = cv2.imread(path)
            if t_img is not None:
                h, w = t_img.shape[:2]
                if 120 <= w <= 400 and 60 <= h <= 300:
                    res = cv2.matchTemplate(f11, t_img, cv2.TM_CCOEFF_NORMED)
                    min_v, max_v, min_l, max_l = cv2.minMaxLoc(res)
                    if max_v > 0.70:
                        print(f"Match found: {path} (size {w}x{h}), score = {max_v:.4f} at {max_l}")
