import cv2
import numpy as np

f2 = cv2.imread("tools/reference_analysis/ref_frames_800x600/06_step2_appearance_hair.png")
f4_form = cv2.imread("assets/menu/Skins/white/Form_CreateRole_4.jpg")

print("Form_CreateRole_4 shape:", f4_form.shape)

# Let's search for f4_form inside f2 using matchTemplate!
res = cv2.matchTemplate(f2, f4_form, cv2.TM_CCOEFF_NORMED)
min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(res)
print(f"Match of Form_CreateRole_4 in f2: max_val={max_val:.4f} at {max_loc}")

# Also test in step 1, step 3:
f1 = cv2.imread("tools/reference_analysis/ref_frames_800x600/03_step1_character_daniel.png")
f3 = cv2.imread("tools/reference_analysis/ref_frames_800x600/12_step3_element_earth.png")

for name, img in [("step1", f1), ("step2", f2), ("step3", f3)]:
    for i in [1, 2, 3, 4]:
        form = cv2.imread(f"assets/menu/Skins/white/Form_CreateRole_{i}.jpg")
        res = cv2.matchTemplate(img, form, cv2.TM_CCOEFF_NORMED)
        _, mv, _, ml = cv2.minMaxLoc(res)
        print(f"{name} vs Form_CreateRole_{i}: score={mv:.4f} at loc={ml}")
