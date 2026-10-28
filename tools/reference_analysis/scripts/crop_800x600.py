import cv2
import numpy as np
import glob
import os

crop_dir = "tests/ref_frames_800x600"
os.makedirs(crop_dir, exist_ok=True)

# Test corner pixels on LogPic1 vs frame 01
img1 = cv2.imread("tests/ref_frames/01_char_select_empty.png")
logpic = cv2.imread("assets/pic/LogPic1.jpg")

# Fine-tune offset around (35, 69)
best_score = -1
best_offset = (35, 69)
for dy in range(65, 75):
    for dx in range(30, 42):
        crop = img1[dy:dy+600, dx:dx+800]
        if crop.shape != (600, 800, 3):
            continue
        # compare top-left corner 50x50 where there's no UI
        diff = np.mean(np.abs(crop[:50, :50].astype(float) - logpic[:50, :50].astype(float)))
        if diff < 10.0:
            print(f"Match at ({dx}, {dy}) with diff={diff:.2f}")
            best_offset = (dx, dy)
            break
    if best_offset != (35, 69):
        break

print(f"Using exact game window origin: {best_offset}")
ox, oy = best_offset

for fpath in glob.glob("tests/ref_frames/*.png"):
    fname = os.path.basename(fpath)
    if fname.startswith("sec_") or fname.startswith("0") or fname.startswith("1"):
        img = cv2.imread(fpath)
        if img.shape[0] >= oy+600 and img.shape[1] >= ox+800:
            c = img[oy:oy+600, ox:ox+800]
            cv2.imwrite(os.path.join(crop_dir, fname), c)

print(f"Cropped all frames to 800x600 in {crop_dir}")
