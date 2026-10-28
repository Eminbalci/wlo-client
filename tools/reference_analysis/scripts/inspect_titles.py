import cv2
import numpy as np

for name in ["f2", "f3", "f4"]:
    img = cv2.imread(f"tools/reference_analysis/{name}_left_bg.png")
    # Top ribbon title area: Y: 10..40, X: 40..250
    title = img[10:45, 40:250]
    cv2.imwrite(f"tools/reference_analysis/{name}_title.png", title)
    print(f"Saved {name}_title.png")
