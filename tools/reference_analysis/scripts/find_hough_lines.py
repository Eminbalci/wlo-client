import cv2
import numpy as np

f2 = cv2.imread("tests/ref_frames_800x600/06_step2_appearance_hair.png")

# Let's find horizontal lines in f2
gray = cv2.cvtColor(f2, cv2.COLOR_BGR2GRAY)
edges = cv2.Canny(gray, 50, 150)
lines = cv2.HoughLinesP(edges, 1, np.pi/180, 80, minLineLength=200, maxLineGap=10)

print("Horizontal lines in Step 2:")
h_lines = []
if lines is not None:
    for line in lines:
        coords = line[0] if len(line.shape) > 1 else line
        x1, y1, x2, y2 = coords[0], coords[1], coords[2], coords[3]
        if abs(y1 - y2) <= 2:
            h_lines.append((min(y1, y2), min(x1, x2), max(x1, x2)))

h_lines.sort(key=lambda l: l[0])
for y, x1, x2 in h_lines:
    if x2 - x1 > 250:
        print(f"  y={y}, x={x1}..{x2} (len={x2-x1})")

print("\nVertical lines in Step 2:")
v_lines = []
if lines is not None:
    for line in lines:
        coords = line[0] if len(line.shape) > 1 else line
        x1, y1, x2, y2 = coords[0], coords[1], coords[2], coords[3]
        if abs(x1 - x2) <= 2:
            v_lines.append((min(x1, x2), min(y1, y2), max(y1, y2)))

v_lines.sort(key=lambda l: l[0])
for x, y1, y2 in v_lines:
    if y2 - y1 > 150:
        print(f"  x={x}, y={y1}..{y2} (len={y2-y1})")
