import cv2
import numpy as np

# Let's inspect 01_char_select_empty.png
img = cv2.imread("tests/ref_frames/01_char_select_empty.png")
print("01_char_select_empty shape:", img.shape)

# Let's check 02_step1_character_rocco.png
img1 = cv2.imread("tests/ref_frames/02_step1_character_rocco.png")
print("02_step1 shape:", img1.shape)

# Let's find the bounding box of the main dialog window in 02_step1
# The dialog is centered with a distinctive border or background
# Let's crop the center area
cv2.imwrite("tests/ref_frames/crop_dialog_02.png", img1[50:650, 50:824])
print("Saved crop_dialog_02.png")
