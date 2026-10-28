import cv2
import numpy as np

# Load windows
w1 = cv2.imread("tests/ref_frames_800x600/step1_window.png")
w2 = cv2.imread("tests/ref_frames_800x600/step2_window.png")
w3 = cv2.imread("tests/ref_frames_800x600/step3_window.png")
f_done = cv2.imread("tests/ref_frames_800x600/14_char_select_done.png")
f_empty = cv2.imread("tests/ref_frames_800x600/01_char_select_empty.png")

# Let's search for buttons using edge detection / contours:
def find_boxes(crop, min_w=15, max_w=200, min_h=10, max_h=100):
    gray = cv2.cvtColor(crop, cv2.COLOR_BGR2GRAY)
    edges = cv2.Canny(gray, 50, 150)
    contours, _ = cv2.findContours(edges, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
    boxes = []
    for c in contours:
        x, y, w, h = cv2.boundingRect(c)
        if min_w <= w <= max_w and min_h <= h <= max_h:
            boxes.append((x, y, w, h))
    return boxes

# In w1, navigation buttons (Return, Continue) are in bottom right (x: 520..730, y: 300..348)
print("--- Step 1 Navigation Buttons (relative to window 740x352) ---")
crop_nav1 = w1[300:348, 520:730]
boxes_nav1 = find_boxes(crop_nav1, min_w=40, max_w=100, min_h=15, max_h=30)
for x, y, w, h in sorted(boxes_nav1, key=lambda b: b[0]):
    print(f"  Button at window (X={x+520}, Y={y+300}, W={w}, H={h})")

# In w1, Name and Family inputs in (x: 380..720, y: 40..100)
print("\n--- Step 1 Name Inputs ---")
crop_name = w1[40:100, 380:720]
boxes_name = find_boxes(crop_name, min_w=80, max_w=200, min_h=15, max_h=30)
for x, y, w, h in sorted(boxes_name, key=lambda b: b[0]):
    print(f"  Input box at window (X={x+380}, Y={y+40}, W={w}, H={h})")

# In w1, Preview box (Bust, Turn buttons, [R], [H]) in (x: 380..720, y: 90..300)
print("\n--- Step 1 Preview Box & Controls ---")
crop_prev = w1[90:300, 380:720]
boxes_prev = find_boxes(crop_prev, min_w=12, max_w=150, min_h=12, max_h=150)
for x, y, w, h in sorted(boxes_prev, key=lambda b: (b[1], b[0])):
    if w in [18, 19, 20, 21, 22] or (w > 50 and h > 50):
        print(f"  Preview element at window (X={x+380}, Y={y+90}, W={w}, H={h})")

# In w1, Left Card Role header `< [Role] >` and profile
print("\n--- Step 1 Left Card ---")
crop_left = w1[10:60, 20:370]
boxes_left = find_boxes(crop_left, min_w=15, max_w=150, min_h=15, max_h=40)
for x, y, w, h in sorted(boxes_left, key=lambda b: b[0]):
    print(f"  Left role element at window (X={x+20}, Y={y+10}, W={w}, H={h})")

# In w2, 4 Tabs (Hair, Body, Eyes, Wear) in (x: 30..380, y: 40..90)
print("\n--- Step 2 Tabs ---")
crop_tabs = w2[40:90, 30:380]
boxes_tabs = find_boxes(crop_tabs, min_w=40, max_w=90, min_h=15, max_h=35)
for x, y, w, h in sorted(boxes_tabs, key=lambda b: b[0]):
    print(f"  Tab at window (X={x+30}, Y={y+40}, W={w}, H={h})")

# In w3, Elements (Earth, Water, Fire, Wind) in (x: 30..380, y: 40..150)
print("\n--- Step 3 Elements ---")
crop_elem = w3[40:150, 30:380]
boxes_elem = find_boxes(crop_elem, min_w=50, max_w=100, min_h=20, max_h=40)
for x, y, w, h in sorted(boxes_elem, key=lambda b: (b[1], b[0])):
    print(f"  Element at window (X={x+30}, Y={y+40}, W={w}, H={h})")
