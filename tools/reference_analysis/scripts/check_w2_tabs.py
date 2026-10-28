import cv2
import numpy as np

img = cv2.imread("tools/reference_analysis/w2_tabs_exact.png")
# Let's inspect the text / buttons inside img (shape 50x340)
# Look at color variations across X
# Tab headers usually have text Hair, Body, Eyes, Wear
# Let's find columns where tabs divide:
# Let's inspect horizontal gradient or lines
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
# Find vertical separator lines
edges = cv2.Canny(gray, 30, 80)
cv2.imwrite("tools/reference_analysis/w2_tabs_edges.png", edges)

# Check average brightness per column
col_bright = gray.mean(axis=0)
for x in range(0, img.shape[1], 10):
    print(f"X={x+20}: {col_bright[x]:.1f}")
