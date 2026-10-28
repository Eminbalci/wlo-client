import cv2
import numpy as np

f2 = cv2.imread("tools/reference_analysis/ref_frames_800x600/06_step2_appearance_hair.png")
# Find horizontal lines and vertical lines
gray = cv2.cvtColor(f2, cv2.COLOR_BGR2GRAY)
edges = cv2.Canny(gray, 30, 100)

# Check bounding box of the main central dialog
contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
boxes = []
for c in contours:
    x, y, w, h = cv2.boundingRect(c)
    if w > 200 and h > 150:
        boxes.append((x, y, w, h, w*h))

boxes.sort(key=lambda b: b[4], reverse=True)
print("Largest boxes in f2:")
for b in boxes[:5]:
    print(f"  X={b[0]}, Y={b[1]}, W={b[2]}, H={b[3]}")
