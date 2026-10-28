import cv2
import numpy as np

img = cv2.imread("tests/ref_frames/sec_000.png")
# Let's search for 800x600 inside 874x700
# Look at edges or find where the LogPic1 matches or where the black/blue borders are
# Usually x=37, y=50 or similar
for y in range(0, 100):
    for x in range(0, 80):
        # check if 800x600 slice has consistent content
        pass

# Let's inspect rows and columns to find the window frame
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
# print standard deviation across rows and columns
print("Gray shape:", gray.shape)
# Find corners
edges = cv2.Canny(gray, 50, 150)
lines = cv2.HoughLinesP(edges, 1, np.pi/180, 100, minLineLength=500, maxLineGap=10)
if lines is not None:
    for line in lines:
        x1, y1, x2, y2 = line[0]
        if y1 == y2: # horizontal
            print(f"Horizontal line at y={y1}, x: {x1}..{x2}")
        elif x1 == x2: # vertical
            print(f"Vertical line at x={x1}, y: {y1}..{y2}")
