import cv2
import numpy as np

img = cv2.imread("tools/reference_analysis/f1_top_right.png")
# Find rectangles in this 150x280 image (rel to X=450, Y=0):
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
edges = cv2.Canny(gray, 20, 80)
contours, _ = cv2.findContours(edges, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
for c in contours:
    x, y, w, h = cv2.boundingRect(c)
    if w > 40 and 12 < h < 40:
        print(f"Pre-drawn box at rel X={x} (window {x+450}), Y={y}, W={w}, H={h}")
