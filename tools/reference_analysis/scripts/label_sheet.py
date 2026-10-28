from PIL import Image, ImageDraw, ImageFont
import os

decoded_dir = r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud\decoded_008'
files = sorted([f for f in os.listdir(decoded_dir) if f.endswith('.png')])

cols = 10
cell_w = 90
cell_h = 100
rows = (len(files) + cols - 1) // cols
sheet = Image.new('RGBA', (cols * cell_w, rows * cell_h), (30, 30, 30, 255))
draw = ImageDraw.Draw(sheet)

for idx, f in enumerate(files):
    im = Image.open(os.path.join(decoded_dir, f))
    c = idx % cols
    r = idx // cols
    x = c * cell_w
    y = r * cell_h
    sheet.paste(im, (x + 5, y + 5), im)
    num = f.replace('.png', '')
    draw.text((x + 10, y + 82), num, fill=(255, 255, 255, 255))

sheet.save(r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud\contact_sheet_labeled.png')
print('Saved contact_sheet_labeled.png')
