import cv2
import numpy as np
import glob

# In sec_000.png, where is the 800x600 game window inside the 874x700 image?
img0 = cv2.imread("tests/ref_frames/sec_000.png")
# Let's find the inner window border. Typically Windows title bar is at top (~30px) and borders (~8px).
# Let's find where the background LogPic1 or blue border is:
# Search for top-left of the 800x600 canvas
gray = cv2.cvtColor(img0, cv2.COLOR_BGR2GRAY)
# In sec_000, find the game area
print("Image shape:", img0.shape)

# Let's inspect changes across seconds to build a timeline of the video:
timeline = []
prev_frame = None

for fpath in sorted(glob.glob("tests/ref_frames/sec_*.png")):
    sec = int(fpath.split("sec_")[-1].replace(".png", ""))
    img = cv2.imread(fpath)
    if prev_frame is not None:
        diff = np.mean(np.abs(img.astype(float) - prev_frame.astype(float)))
    else:
        diff = 0
    prev_frame = img
    timeline.append((sec, diff))

print("Significant visual changes (sec, diff):")
for sec, diff in timeline:
    if diff > 10.0 or sec in [0, 1, 2, 3, 4, 10, 11, 12, 13, 20, 21, 22, 23, 30, 31, 32, 40, 50, 51, 52, 53, 54, 55, 58, 60]:
        print(f"  Sec {sec:02d}: diff = {diff:5.2f}")
