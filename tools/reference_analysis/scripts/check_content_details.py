import cv2
import numpy as np

for name in ["f1", "f2", "f3"]:
    img = cv2.imread(f"tools/reference_analysis/{name}_content_area.png")
    print(f"=== {name} ===")
    print(f"Shape: {img.shape}")
    # Let's check unique colors or prominent color regions
    mean_bgr = img.mean(axis=(0, 1))
    print(f"Mean BGR: {mean_bgr}")
    # Check top-left corner of the content area
    print(f"Top-left 5x5 BGR:\n{img[:5, :5]}")
