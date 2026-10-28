import cv2
import numpy as np

f_step1 = cv2.imread("tests/ref_frames_800x600/02_step1_character_rocco.png")
# Check column x=400 from top to bottom
col = f_step1[:, 400, :]
for y in range(80, 560, 5):
    # inspect color
    print(f"y={y}: BGR={col[y]}")
