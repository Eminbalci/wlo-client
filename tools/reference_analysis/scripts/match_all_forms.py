import cv2
import numpy as np

f_step1 = cv2.imread("tests/ref_frames_800x600/02_step1_character_rocco.png")
f_step2 = cv2.imread("tests/ref_frames_800x600/06_step2_appearance_hair.png")
f_step3 = cv2.imread("tests/ref_frames_800x600/12_step3_element_earth.png")

steps = [("Step 1", f_step1), ("Step 2", f_step2), ("Step 3", f_step3)]

for sname, sframe in steps:
    print(f"\n--- Matching {sname} against Form_CreateRole_1..4 ---")
    for i in [1, 2, 3, 4]:
        form = cv2.imread(f"assets/menu/Skins/white/Form_CreateRole_{i}.jpg")
        if form is None: continue
        res = cv2.matchTemplate(sframe, form, cv2.TM_CCOEFF_NORMED)
        min_v, max_v, min_l, max_l = cv2.minMaxLoc(res)
        print(f"  Form {i} ({form.shape[1]}x{form.shape[0]}): score={max_v:.4f} at {max_l}")
