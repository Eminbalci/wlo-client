import cv2
import numpy as np

for fname in ["02_step1_character_rocco.png", "03_step1_character_daniel.png", "06_step2_appearance_hair.png", "12_step3_element_earth.png", "14_char_select_done.png"]:
    img = cv2.imread(f"tools/reference_analysis/ref_frames_800x600/{fname}")
    # In Wonderland Online, the main background outside the window is the dark blue/green login ocean/grass scene
    # The modal window has an outer dark border or drop shadow.
    # Let's find the outer rectangle of the window:
    # Look at the window border:
    print(f"=== {fname} ===")
    # Let's save a thumbnail
    thumb = cv2.resize(img, (200, 150))
    cv2.imwrite(f"tools/reference_analysis/thumb_{fname}", thumb)
