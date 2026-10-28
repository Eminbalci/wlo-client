import cv2
import numpy as np

# Compare step1_window.png with Form_CreateRole_1.jpg
form1 = cv2.imread("assets/menu/Skins/white/Form_CreateRole_1.jpg")
w1 = cv2.imread("tests/ref_frames_800x600/step1_window.png")

print("Form_CreateRole_1 shape:", form1.shape if form1 is not None else "Not found")
print("step1_window shape:", w1.shape)

if form1 is not None:
    diff = np.abs(form1.astype(float) - w1.astype(float)).mean()
    print("Mean diff between step1_window and Form_CreateRole_1:", diff)

# Let's check Form_CreateRole_2, 3, 4
for i in [1, 2, 3, 4]:
    form = cv2.imread(f"assets/menu/Skins/white/Form_CreateRole_{i}.jpg")
    print(f"Form_CreateRole_{i} shape:", form.shape if form is not None else "Not found")
