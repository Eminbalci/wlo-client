import cv2
import numpy as np

c2 = cv2.imread("tools/reference_analysis/f2_window_crop.png")
c3 = cv2.imread("tools/reference_analysis/f3_window_crop.png")

# Compare with Form_CreateRole_1, 2, 3, 4
for i in [1, 2, 3, 4]:
    form = cv2.imread(f"assets/menu/Skins/white/Form_CreateRole_{i}.jpg")
    if form.shape == c2.shape:
        diff2 = np.mean(np.abs(c2.astype(float) - form.astype(float)))
        diff3 = np.mean(np.abs(c3.astype(float) - form.astype(float)))
        print(f"Form_CreateRole_{i} vs f2_crop: {diff2:.2f}, vs f3_crop: {diff3:.2f}")

# Also compare against assets/auth/form_create_role_*.jpg
for i in [1, 2, 3, 4]:
    form = cv2.imread(f"assets/auth/form_create_role_{i}.jpg")
    if form.shape == c2.shape:
        diff2 = np.mean(np.abs(c2.astype(float) - form.astype(float)))
        diff3 = np.mean(np.abs(c3.astype(float) - form.astype(float)))
        print(f"assets/auth/form_create_role_{i} vs f2_crop: {diff2:.2f}, vs f3_crop: {diff3:.2f}")
