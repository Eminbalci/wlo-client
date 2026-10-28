import cv2
import numpy as np

c = cv2.imread("tools/reference_analysis/check_name_inputs_rendered.png")
r = cv2.imread("tools/reference_analysis/ref_name_crop.png")
n = cv2.imread("tools/reference_analysis/named_satoru_ref_crop.png")

print("Rendered mean color:", c.mean(axis=(0, 1)))
print("Ref unnamed mean color:", r.mean(axis=(0, 1)))
print("Ref named mean color:", n.mean(axis=(0, 1)))

# Let's save a visual side-by-side
comp = np.hstack([c, r, n])
cv2.imwrite("tools/reference_analysis/name_inputs_side_by_side.png", comp)
print("Saved name_inputs_side_by_side.png")
