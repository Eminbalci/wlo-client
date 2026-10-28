"""Slice and defringe skill window skin and tab button assets.

Converts:
  D:/GitHub/wlridecode/menu/Skins/white/form_skill_1.bmp -> assets/hud/form_skill_1.png
  D:/GitHub/wlridecode/menu/Skins/white/form_skill_2.bmp -> assets/hud/form_skill_2.png
  D:/GitHub/wlridecode/menu/Skins/default/Btn_SkillIcon_1..5.bmp -> assets/hud/btn_skill_icon_1..5.png
    + sliced frames (normal, hover, pressed)
"""

import os
import numpy as np
from PIL import Image

def process_image(im_path: str) -> np.ndarray:
    im = Image.open(im_path).convert("RGBA")
    arr = np.array(im)
    H, W, _ = arr.shape
    
    # Pure green chroma key [0, 255, 0]
    pure_green = (arr[:, :, 3] > 0) & (arr[:, :, 1] >= 180) & (arr[:, :, 0] <= 70) & (arr[:, :, 2] <= 70)
    arr[pure_green, 3] = 0
    
    # 2. Transparent mask
    is_trans = (arr[:, :, 3] == 0)
    
    # 3. Find border within 2 px of transparency
    border = np.zeros((H, W), dtype=bool)
    for dy in range(-2, 3):
        for dx in range(-2, 3):
            if dy == 0 and dx == 0:
                continue
            y_s, y_e = max(0, -dy), min(H, H - dy)
            y_d, y_e_d = max(0, dy), min(H, H + dy)
            x_s, x_e = max(0, -dx), min(W, W - dx)
            x_d, x_e_d = max(0, dx), min(W, W + dx)
            border[y_d:y_e_d, x_d:x_e_d] |= is_trans[y_s:y_e, x_s:x_e]
            
    border &= (~is_trans)
    
    # 4. Green halo on border
    R = arr[:, :, 0].astype(float)
    G = arr[:, :, 1].astype(float)
    B = arr[:, :, 2].astype(float)
    
    halo = border & (arr[:, :, 3] > 0) & (G > R * 1.15) & (G > B * 1.15) & (G > 70)
    strong_bleed = halo & (G > 140) & (R < 90) & (B < 90)
    arr[strong_bleed, 3] = 0
    
    clamp_halo = halo & (~strong_bleed)
    arr[clamp_halo, 1] = np.maximum(arr[clamp_halo, 0], arr[clamp_halo, 2])
    
    return arr

def main():
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    hud_dir = os.path.join(repo_root, "assets", "hud")
    os.makedirs(hud_dir, exist_ok=True)
    
    src_skins = r"D:\GitHub\wlridecode\menu\Skins"
    
    # 1. form_skill_1.bmp & form_skill_2.bmp
    for fname in ["form_skill_1.bmp", "form_skill_2.bmp"]:
        src_path = os.path.join(src_skins, "white", fname)
        if not os.path.exists(src_path):
            print(f"Warning: {src_path} not found")
            continue
        arr = process_image(src_path)
        out_name = os.path.splitext(fname)[0].lower() + ".png"
        out_path = os.path.join(hud_dir, out_name)
        Image.fromarray(arr).save(out_path, format="PNG")
        print(f"Created: {out_path} ({arr.shape[1]}x{arr.shape[0]})")
        
    # 2. Btn_SkillIcon_1..5.bmp
    for i in range(1, 6):
        src_path = os.path.join(src_skins, "default", f"Btn_SkillIcon_{i}.bmp")
        if not os.path.exists(src_path):
            print(f"Warning: {src_path} not found")
            continue
        arr = process_image(src_path)
        
        # Save full 38x63 strip
        full_out = os.path.join(hud_dir, f"btn_skill_icon_{i}.png")
        Image.fromarray(arr).save(full_out, format="PNG")
        print(f"Created: {full_out} ({arr.shape[1]}x{arr.shape[0]})")
        
        # Slice into 3 states: normal (0..21), hover (21..42), pressed (42..63)
        h = arr.shape[0] // 3
        states = ["normal", "hover", "pressed"]
        for s_idx, s_name in enumerate(states):
            sub_arr = arr[s_idx * h : (s_idx + 1) * h, :, :]
            sub_out = os.path.join(hud_dir, f"btn_skill_icon_{i}_{s_name}.png")
            Image.fromarray(sub_arr).save(sub_out, format="PNG")
            print(f"  Created: {sub_out} ({sub_arr.shape[1]}x{sub_arr.shape[0]})")

if __name__ == "__main__":
    main()
