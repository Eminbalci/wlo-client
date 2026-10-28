import cv2
import numpy as np

img = cv2.imread("tests/ref_frames/01_char_select_empty.png")
# Let's inspect rows from top to bottom
# The window has a title bar. Let's find where the 800x600 game canvas begins.
# In WLO, the client is 800x600.
# In a typical Windows window of 800x600 client area:
# Total width is 800 + 2*8 (borders) = 816 or 800 + 2*16 = 832, or here 874.
# Let's check where the 800x600 background texture is:
# Search for LogPic1.jpg in the image!
logpic = cv2.imread("assets/pic/LogPic1.jpg")
if logpic is not None:
    print("LogPic1 size:", logpic.shape)
    res = cv2.matchTemplate(img, logpic, cv2.TM_CCOEFF_NORMED)
    min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(res)
    print(f"LogPic1 match: score={max_val:.4f} at {max_loc}")
else:
    print("LogPic1 not found in assets/pic/LogPic1.jpg")
