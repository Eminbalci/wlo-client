from PIL import Image
import numpy as np

def check_local(crop_p, ref_window_p, box):
    crop = Image.open(crop_p).convert('RGB')
    ref = Image.open(ref_window_p).convert('RGB').crop(box)
    diff = np.mean(np.abs(np.array(crop, dtype=float) - np.array(ref, dtype=float)))
    print(f"{crop_p}: local diff = {diff:.2f}")

ref_w1 = 'tools/reference_analysis/ref_frames_800x600/w1.png'
check_local('tools/reference_analysis/check_name_inputs_rendered.png', ref_w1, (510, 80, 720, 130))
check_local('tools/reference_analysis/check_preview_rendered.png', ref_w1, (500, 140, 720, 260))
check_local('tools/reference_analysis/check_carousel_rendered.png', ref_w1, (20, 10, 220, 50))
check_local('tools/reference_analysis/check_nav_rendered.png', ref_w1, (490, 295, 730, 340))
