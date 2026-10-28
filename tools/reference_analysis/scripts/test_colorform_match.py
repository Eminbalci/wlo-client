import cv2
import numpy as np

f_step2 = cv2.imread("tests/ref_frames_800x600/06_step2_appearance_hair.png")
cform = cv2.imread("assets/upimg/colorform.bmp")
print("colorform shape:", cform.shape if cform is not None else None)

if cform is not None:
    res = cv2.matchTemplate(f_step2, cform, cv2.TM_CCOEFF_NORMED)
    min_v, max_v, min_l, max_l = cv2.minMaxLoc(res)
    print(f"Match of colorform.bmp in Step 2: score={max_v:.4f} at {max_l}")

# Also check colorforms.bmp
cforms = cv2.imread("assets/upimg/colorforms.bmp")
if cforms is not None:
    res2 = cv2.matchTemplate(f_step2, cforms, cv2.TM_CCOEFF_NORMED)
    min_v2, max_v2, min_l2, max_l2 = cv2.minMaxLoc(res2)
    print(f"Match of colorforms.bmp in Step 2: score={max_v2:.4f} at {max_l2}")
