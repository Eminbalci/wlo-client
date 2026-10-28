import os
from PIL import Image

decoded_dir = r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud\decoded_009'
files = sorted([f for f in os.listdir(decoded_dir) if f.endswith('.png')])

cols = 8
rows = (len(files) + cols - 1) // cols
sheet = Image.new('RGBA', (cols * 80, rows * 80), (40, 40, 40, 255))

for idx, f in enumerate(files):
    im = Image.open(os.path.join(decoded_dir, f))
    c = idx % cols
    r = idx // cols
    sheet.paste(im, (c * 80, r * 80), im)

sheet.save(r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud\contact_sheet_009.png')
print('Saved contact_sheet_009.png')
