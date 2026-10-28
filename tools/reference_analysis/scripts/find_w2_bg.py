import os
from PIL import Image
import numpy as np

w2 = Image.open('tools/reference_analysis/ref_frames_800x600/w2.png').convert('RGB')
w2_arr = np.array(w2, dtype=float)

best_matches = []

for root, dirs, files in os.walk('assets'):
    for f in files:
        if f.lower().endswith(('.png', '.jpg', '.bmp')):
            path = os.path.join(root, f)
            try:
                img = Image.open(path).convert('RGB')
                if img.size == (740, 352):
                    arr = np.array(img, dtype=float)
                    diff = np.mean(np.abs(w2_arr - arr))
                    best_matches.append((diff, path))
                elif img.size[0] >= 300 and img.size[1] >= 300:
                    # check if it matches a subregion or something
                    pass
            except Exception:
                pass

best_matches.sort()
print("Top 10 matches for w2.png:")
for diff, path in best_matches[:10]:
    print(f"  diff={diff:.2f}: {path}")
