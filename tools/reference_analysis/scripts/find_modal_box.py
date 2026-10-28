import cv2
import numpy as np

img = cv2.imread("tests/ref_frames_800x600/modal_sec_011.png")
# Let's find the rectangular border of the modal inside this crop
# The crop was from y: 180..420, x: 240..560
# Look at Canny edges
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
edges = cv2.Canny(gray, 50, 150)
cv2.imwrite("tests/ref_frames_800x600/modal_edges.png", edges)

# Find contours
contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
for c in contours:
    x, y, w, h = cv2.boundingRect(c)
    if w > 100 and h > 50:
        print(f"Found rectangular contour: x={x+240}, y={y+180}, w={w}, h={h}")
        cv2.imwrite("tests/ref_frames_800x600/modal_box.png", img[y:y+h, x:x+w])
