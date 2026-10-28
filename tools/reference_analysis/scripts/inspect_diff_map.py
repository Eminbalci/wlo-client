import cv2
import numpy as np

f10 = cv2.imread("tests/ref_frames_800x600/sec_010.png")
f11 = cv2.imread("tests/ref_frames_800x600/sec_011.png")
f12 = cv2.imread("tests/ref_frames_800x600/sec_012.png")

# Let's save the diff image
diff1 = np.abs(f11.astype(float) - f10.astype(float)).astype(np.uint8)
cv2.imwrite("tests/ref_frames_800x600/diff_10_11.png", diff1 * 3)

# Let's save diff between 11 and 12
diff2 = np.abs(f12.astype(float) - f11.astype(float)).astype(np.uint8)
cv2.imwrite("tests/ref_frames_800x600/diff_11_12.png", diff2 * 3)

# Let's find clusters of high difference that are NOT the character sprite (sprite is at x ~ 400..650, y ~ 100..350)
# Is there an alert in the center or a message somewhere else?
diff_gray = cv2.cvtColor(diff1, cv2.COLOR_BGR2GRAY)
# print where diff_gray > 40
ys, xs = np.where(diff_gray > 40)
print(f"Total diff pixels > 40: {len(ys)}")
# cluster in x
for x_range in [(0, 200), (200, 400), (400, 600), (600, 800)]:
    in_range = np.sum((xs >= x_range[0]) & (xs < x_range[1]))
    print(f"  x in {x_range}: {in_range} pixels")
