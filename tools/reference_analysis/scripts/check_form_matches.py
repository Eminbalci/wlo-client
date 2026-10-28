from PIL import Image
import numpy as np

for name in ['w1', 'w2', 'w3']:
    ref = Image.open(f'tools/reference_analysis/ref_frames_800x600/{name}.png').convert('RGB')
    for f_idx in [1, 2, 3, 4]:
        form = Image.open(f'assets/menu/Skins/white/Form_CreateRole_{f_idx}.jpg').convert('RGB')
        if form.size == ref.size:
            diff_l = np.mean(np.abs(np.array(ref.crop((0, 0, 370, 352)), dtype=float) - np.array(form.crop((0, 0, 370, 352)), dtype=float)))
            diff_r = np.mean(np.abs(np.array(ref.crop((370, 0, 740, 352)), dtype=float) - np.array(form.crop((370, 0, 740, 352)), dtype=float)))
            print(f"{name} vs Form_CreateRole_{f_idx}: Left diff={diff_l:.1f}, Right diff={diff_r:.1f}")
