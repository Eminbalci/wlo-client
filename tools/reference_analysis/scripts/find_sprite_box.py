import cv2
import numpy as np

w1 = cv2.imread("tests/ref_frames_800x600/step1_window.png")
# Let's inspect the right side of the window (x: 350..740)
# Look at color variations
cv2.imwrite("tests/ref_frames_800x600/w1_right_half.png", w1[:, 350:])
print("Saved w1_right_half.png (height 352, width 390)")

# Also inspect w2_right_half
w2 = cv2.imread("tests/ref_frames_800x600/step2_window.png")
cv2.imwrite("tests/ref_frames_800x600/w2_right_half.png", w2[:, 350:])

# Also inspect Character Select empty and done cards
sel_empty = cv2.imread("tests/ref_frames_800x600/01_char_select_empty.png")
cv2.imwrite("tests/ref_frames_800x600/sel_empty_center.png", sel_empty[100:500, 50:750])

sel_done = cv2.imread("tests/ref_frames_800x600/14_char_select_done.png")
cv2.imwrite("tests/ref_frames_800x600/sel_done_center.png", sel_done[100:500, 50:750])

print("Crops saved.")
