import cv2
import numpy as np

w3 = cv2.imread("tools/reference_analysis/ref_frames_800x600/w3.png")

# Left card of w3:
# Elements selection: Earth, Water, Fire, Wind
# In check_exact_layout.py:
# Element at X=105, Y=80, W=22, H=60
# Let's crop X: 20..360, Y: 40..300 of w3:
crop_w3_l = w3[40:300, 20:360]
cv2.imwrite("tools/reference_analysis/w3_left_exact.png", crop_w3_l)

# Let's inspect the elements in crop_w3_l:
gray = cv2.cvtColor(crop_w3_l, cv2.COLOR_BGR2GRAY)
edges = cv2.Canny(gray, 30, 100)
contours, _ = cv2.findContours(edges, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
for c in contours:
    x, y, w, h = cv2.boundingRect(c)
    if 25 <= w <= 80 and 25 <= h <= 80:
        print(f"Element button at window: X={x+20}, Y={y+40}, W={w}, H={h}")

# Element coin badge in PreviewBox:
# In w3, let's find the coin badge on the right side:
crop_w3_r = w3[:, 370:]
cv2.imwrite("tools/reference_analysis/w3_right_exact.png", crop_w3_r)

print("Saved w3 exact crops.")
