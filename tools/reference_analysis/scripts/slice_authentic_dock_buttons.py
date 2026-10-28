from PIL import Image
import os

skin_dir = r'D:\GitHub\WLRI\menu\Skins\default'
out_dir = r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud'

# Btn_11 -> Dock 1 (Status/Inventory)
# Btn_12 -> Dock 2 (Skill)
# Btn_13 -> Dock 3 (Quest)
# Btn_14 -> Dock 4 (Team)
# Btn_15 -> Dock 5 (Friends)
# Btn_16 -> Dock 6 (System)

files = [
    ('Btn_11.bmp', 1),
    ('Btn_12.bmp', 2),
    ('Btn_13.bmp', 3),
    ('Btn_14.bmp', 4),
    ('Btn_15.bmp', 5),
    ('Btn_16.bmp', 6)
]

for fname, idx in files:
    im = Image.open(os.path.join(skin_dir, fname)).convert('RGBA')
    w = im.width
    total_h = im.height
    frame_h = total_h // 3
    pix = im.load()
    for y in range(total_h):
        for x in range(w):
            if pix[x, y][:3] == (0, 255, 0):
                pix[x, y] = (0, 0, 0, 0)
    
    normal = im.crop((0, 0, w, frame_h))
    hover = im.crop((0, frame_h, w, frame_h * 2))
    pressed = im.crop((0, frame_h * 2, w, frame_h * 3))
    
    # Save with authentic names
    normal.save(os.path.join(out_dir, f'btn_dock_{idx}_normal.png'))
    hover.save(os.path.join(out_dir, f'btn_dock_{idx}_hover.png'))
    pressed.save(os.path.join(out_dir, f'btn_dock_{idx}_pressed.png'))
    print(f'Sliced btn_dock_{idx}: w={w}, h={frame_h}')
