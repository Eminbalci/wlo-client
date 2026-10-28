import cv2
import numpy as np

f1 = cv2.imread("assets/menu/Skins/white/Form_CreateRole_1.jpg")
crop = f1[20:80, 500:720]
# Find inner boxes with white/light fill or bordered rectangles
gray = cv2.cvtColor(crop, cv2.COLOR_BGR2GRAY)
edges = cv2.Canny(gray, 30, 100)
contours, _ = cv2.findContours(edges, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
for c in contours:
    x, y, w, h = cv2.boundingRect(c)
    if w > 40 and h > 15:
        print(f"Name box relative to (X=500, Y=20): X={x} (abs {x+500}), Y={y} (abs {y+20}), W={w}, H={h}")
