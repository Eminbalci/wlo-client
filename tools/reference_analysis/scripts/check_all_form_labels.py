import cv2
import numpy as np

# In Form_CreateRole_2, 3, 4:
# Let's check what labels exist across the whole image:
for idx in [2, 3, 4]:
    img = cv2.imread(f"assets/menu/Skins/white/Form_CreateRole_{idx}.jpg")
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    # Find text characters (dark pixels < 90)
    dark = gray < 90
    num_l, _, stats, _ = cv2.connectedComponentsWithStats(dark.astype(np.uint8))
    print(f"Form_CreateRole_{idx} dark components: {num_l}")
    # Print components on the left side
    left_comps = [s for s in stats if s[0] < 350 and 8 < s[2] < 120 and 8 < s[3] < 30]
    for s in sorted(left_comps, key=lambda x: (x[1]//15, x[0])):
        print(f"  F{idx} text at X={s[0]}, Y={s[1]}, W={s[2]}, H={s[3]}")
