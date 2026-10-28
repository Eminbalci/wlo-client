import cv2
import numpy as np

c3 = cv2.imread("tools/reference_analysis/w3_coin_area.png")
c1 = cv2.imread("tools/reference_analysis/w1_coin_area.png")

diff = np.abs(c3.astype(float) - c1.astype(float)).mean(axis=2)
# Find max diff location
mask = diff > 25
num_l, _, stats, _ = cv2.connectedComponentsWithStats(mask.astype(np.uint8))
print(f"Diffs in coin area ({num_l}):")
for i in range(1, num_l):
    x, y, w, h, a = stats[i]
    if a > 30:
        print(f"  Coin diff: X={x} (window {x+500}), Y={y} (window {y+130}), W={w}, H={h}, Area={a}")
