import cv2
import numpy as np

img = cv2.imread("tests/ref_frames_800x600/modal_text_clean.png")
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# Find unique connected components
_, thresh = cv2.threshold(gray, 120, 255, cv2.THRESH_BINARY_INV)
num_labels, labels, stats, centroids = cv2.connectedComponentsWithStats(thresh)

print(f"Detected {num_labels} connected components:")
chars = []
for i in range(1, num_labels):
    x, y, w, h, area = stats[i]
    if area > 10 and h > 6:
        chars.append((x, y, w, h, area))

chars.sort(key=lambda c: c[0])
print(f"Filtered {len(chars)} glyphs/letters:")
for c in chars:
    print(f"  x={c[0]}, y={c[1]}, w={c[2]}, h={c[3]}, area={c[4]}")
