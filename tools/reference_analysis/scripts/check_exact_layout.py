import cv2
import numpy as np

w1 = cv2.imread('tools/reference_analysis/ref_frames_800x600/w1.png')
w2 = cv2.imread('tools/reference_analysis/ref_frames_800x600/w2.png')
w3 = cv2.imread('tools/reference_analysis/ref_frames_800x600/w3.png')

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

print("=== w1 (740x352) ===")
# Navigation buttons
print("Navigation buttons:")
crop_nav1 = w1[295:345, 480:735]
boxes_nav1 = find_boxes(crop_nav1, min_w=40, max_w=120, min_h=15, max_h=35)
for x, y, w, h in sorted(boxes_nav1, key=lambda b: b[0]):
    print(f"  Nav button at X={x+480}, Y={y+295}, W={w}, H={h}")

# Name input boxes
print("\nName inputs:")
crop_name = w1[30:70, 500:735]
boxes_name = find_boxes(crop_name, min_w=60, max_w=120, min_h=15, max_h=30)
for x, y, w, h in sorted(boxes_name, key=lambda b: b[0]):
    print(f"  Name box at X={x+500}, Y={y+30}, W={w}, H={h}")

# Preview buttons (R, H, <, >)
print("\nPreview buttons:")
crop_prev = w1[80:260, 500:735]
boxes_prev = find_boxes(crop_prev, min_w=12, max_w=30, min_h=12, max_h=30)
for x, y, w, h in sorted(boxes_prev, key=lambda b: (b[1], b[0])):
    print(f"  Button at X={x+500}, Y={y+80}, W={w}, H={h}")

# Standee and Carousel arrows
print("\nLeft card elements:")
crop_left = w1[10:60, 10:370]
boxes_left = find_boxes(crop_left, min_w=15, max_w=40, min_h=15, max_h=40)
for x, y, w, h in sorted(boxes_left, key=lambda b: b[0]):
    print(f"  Arrow/elem at X={x+10}, Y={y+10}, W={w}, H={h}")

print("\n=== w2 (740x352) ===")
# Tabs
print("Appearance tabs:")
crop_tabs = w2[30:70, 30:350]
boxes_tabs = find_boxes(crop_tabs, min_w=40, max_w=100, min_h=15, max_h=35)
for x, y, w, h in sorted(boxes_tabs, key=lambda b: b[0]):
    print(f"  Tab at X={x+30}, Y={y+30}, W={w}, H={h}")

# Sliders
print("\nAppearance sliders area:")
crop_sliders = w2[160:280, 100:360]
boxes_sliders = find_boxes(crop_sliders, min_w=10, max_w=150, min_h=10, max_h=30)
for x, y, w, h in sorted(boxes_sliders, key=lambda b: (b[1], b[0])):
    print(f"  Slider elem at X={x+100}, Y={y+160}, W={w}, H={h}")

print("\n=== w3 (740x352) ===")
# Elements
print("Element buttons:")
crop_elem = w3[80:140, 100:340]
boxes_elem = find_boxes(crop_elem, min_w=20, max_w=60, min_h=20, max_h=60)
for x, y, w, h in sorted(boxes_elem, key=lambda b: (b[1], b[0])):
    print(f"  Element at X={x+100}, Y={y+80}, W={w}, H={h}")
