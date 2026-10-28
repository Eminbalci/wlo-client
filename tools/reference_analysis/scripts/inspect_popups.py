import cv2
import numpy as np

for sec in range(9, 23):
    img = cv2.imread(f"tests/ref_frames_800x600/sec_{sec:03d}.png")
    if img is None:
        continue
    # Check if there is a dialog/popup box in the center or anywhere
    # Let's save a crop around the center (e.g. 200..400, 250..550)
    center_crop = img[200:400, 250:550]
    cv2.imwrite(f"tests/ref_frames_800x600/center_sec_{sec:03d}.png", center_crop)

print("Center crops saved for sec 9..22.")
