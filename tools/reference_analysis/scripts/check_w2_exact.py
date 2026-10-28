import cv2
import numpy as np

w2 = cv2.imread("tools/reference_analysis/ref_frames_800x600/w2.png")
# Let's find tabs in w2:
# Tabs are at the top left of w2:
crop_tabs = w2[20:70, 20:360]
cv2.imwrite("tools/reference_analysis/w2_tabs_exact.png", crop_tabs)

# Let's inspect each tab position:
gray = cv2.cvtColor(crop_tabs, cv2.COLOR_BGR2GRAY)
edges = cv2.Canny(gray, 30, 100)
contours, _ = cv2.findContours(edges, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
for c in contours:
    x, y, w, h = cv2.boundingRect(c)
    if 40 <= w <= 80 and 15 <= h <= 30:
        print(f"Tab at window: X={x+20}, Y={y+20}, W={w}, H={h}")

# Style variant selector (v, ^ or <, >) in w2:
# Sliders R, G, B in w2:
# Let's inspect X: 150..350, Y: 150..280:
crop_sliders = w2[150:280, 150:350]
cv2.imwrite("tools/reference_analysis/w2_sliders_exact.png", crop_sliders)

# Right side of w2: Preview (Bust, Sprite, Full Name)
crop_w2_r = w2[:, 370:]
cv2.imwrite("tools/reference_analysis/w2_right_exact.png", crop_w2_r)

print("Saved w2 exact crops.")
