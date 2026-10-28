import cv2
import numpy as np

img = cv2.imread("tools/reference_analysis/f1_name_rows.png")
# Let's inspect the entire box around Y=74:
print("img shape:", img.shape)
# Row Y=54 (window 74):
row = img[50:60, :]
# Find where the white / parchment input field is:
is_field = (img[:, :, 0] > 230) & (img[:, :, 1] > 230) & (img[:, :, 2] > 230)
coords = np.argwhere(is_field)
if len(coords) > 0:
    print(f"White input field bounds: Y=[{coords[:, 0].min()+20}, {coords[:, 0].max()+20}], X=[{coords[:, 1].min()+500}, {coords[:, 1].max()+500}]")
else:
    print("No white field, let's check cream field (parchment):")
    # check rectangle edges
    edges = cv2.Canny(cv2.cvtColor(img, cv2.COLOR_BGR2GRAY), 30, 100)
    lines = cv2.HoughLinesP(edges, 1, np.pi/180, 20, minLineLength=30, maxLineGap=5)
    if lines is not None:
        for l in lines:
            x1, y1, x2, y2 = l[0]
            print(f"  Line: ({x1+500}, {y1+20}) -> ({x2+500}, {y2+20})")
