"""Defringe and sanitize green chroma-key edges on HUD PNG assets.

Wonderland Online original assets used bright green (0, 255, 0) as transparent chroma key.
During slicing and extraction, pure green background pixels and 1-2px green halo fringe
pixels may remain on sprite borders. This script cleans them cleanly while preserving
anti-aliasing and legitimate sprite colors.
"""

import os
import sys
import numpy as np
from PIL import Image

SKIP_EXACT = {
    "hud_minimap_terrain.png",
    "icon_element_4.png",
    "all_role_pics.png",
}

def should_skip(filename: str) -> bool:
    if filename in SKIP_EXACT:
        return True
    if filename.startswith("avatar_role_") or filename.startswith("role_pic_") or filename.startswith("contact_sheet_") or filename.startswith("test_avatar_role_") or filename.startswith("icon_element_"):
        return True
    return False

def defringe_png(path: str) -> dict:
    im = Image.open(path).convert("RGBA")
    arr = np.array(im)
    orig_arr = arr.copy()
    H, W, _ = arr.shape
    
    # 1. Pure green chroma key bleed (unkeyed background pixels) -> alpha = 0
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
    
    # Strong bleed at edge -> alpha = 0
    strong_bleed = halo & (G > 140) & (R < 90) & (B < 90)
    arr[strong_bleed, 3] = 0
    
    # Mild halo on anti-aliased edge -> clamp G to max(R, B)
    clamp_halo = halo & (~strong_bleed)
    arr[clamp_halo, 1] = np.maximum(arr[clamp_halo, 0], arr[clamp_halo, 2])
    
    pg_count = int(np.sum(pure_green))
    sb_count = int(np.sum(strong_bleed))
    ch_count = int(np.sum(clamp_halo))
    
    has_changes = (pg_count > 0 or sb_count > 0 or ch_count > 0)
    if has_changes:
        cleaned_im = Image.fromarray(arr)
        cleaned_im.save(path, format="PNG")
        
    return {
        "file": os.path.basename(path),
        "changed": has_changes,
        "pure_green": pg_count,
        "strong_bleed": sb_count,
        "clamped_halo": ch_count,
    }

def main():
    hud_dir = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "hud")
    hud_dir = os.path.abspath(hud_dir)
    print(f"Scanning HUD directory: {hud_dir}")
    
    files = sorted([f for f in os.listdir(hud_dir) if f.endswith(".png")])
    total_scanned = 0
    total_cleaned = 0
    total_pg = 0
    total_sb = 0
    total_ch = 0
    
    cleaned_list = []
    
    for f in files:
        if should_skip(f):
            continue
        total_scanned += 1
        path = os.path.join(hud_dir, f)
        res = defringe_png(path)
        if res["changed"]:
            total_cleaned += 1
            total_pg += res["pure_green"]
            total_sb += res["strong_bleed"]
            total_ch += res["clamped_halo"]
            cleaned_list.append(res)
            print(f"  [CLEANED] {f}: {res['pure_green']} pure green, {res['strong_bleed']} bleed removed, {res['clamped_halo']} halo clamped")
            
    print(f"\nCompleted! Scanned {total_scanned} files, cleaned {total_cleaned} files.")
    print(f"Total: {total_pg} pure green pixels -> alpha=0, {total_sb} strong bleed pixels -> alpha=0, {total_ch} border halo pixels clamped.")

if __name__ == "__main__":
    main()
