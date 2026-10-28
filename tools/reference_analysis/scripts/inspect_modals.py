import cv2
import numpy as np

# In sec 11, the user pressed Continue without entering a name!
# What popup appeared?
# Let's crop the center of sec_011.png
f11 = cv2.imread("tests/ref_frames_800x600/sec_011.png")
# Popup modal is typically centered, e.g., 200..400 y, 200..600 x
# Let's find the exact modal rectangle in f11
# Look for a modal dialog box:
cv2.imwrite("tests/ref_frames_800x600/modal_sec_011.png", f11[180:420, 240:560])
print("Saved modal_sec_011.png")

# What about at sec 22? That's when transitioning to Step 2
# What about at sec 50..58? That's Step 3 -> Finish -> Return to Character Select!
f51 = cv2.imread("tests/ref_frames_800x600/sec_051.png")
f53 = cv2.imread("tests/ref_frames_800x600/sec_053.png")
f54 = cv2.imread("tests/ref_frames_800x600/sec_054.png")
f55 = cv2.imread("tests/ref_frames_800x600/sec_055.png")
f57 = cv2.imread("tests/ref_frames_800x600/sec_057.png")
f58 = cv2.imread("tests/ref_frames_800x600/sec_058.png")

cv2.imwrite("tests/ref_frames_800x600/modal_sec_053.png", f53[180:420, 240:560])
cv2.imwrite("tests/ref_frames_800x600/modal_sec_055.png", f55[180:420, 240:560])
print("Saved modal crops.")
