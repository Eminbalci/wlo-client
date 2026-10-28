from PIL import Image
import os

skin_dir = r'D:\GitHub\WLRI\menu\Skins\default'
for ele in [1, 2, 3, 4]:
    im = Image.open(os.path.join(skin_dir, f'Icon_Element_{ele}_1.bmp')).convert('RGBA')
    pix = im.load()
    for y in range(im.height):
        for x in range(im.width):
            if pix[x, y][:3] == (0, 255, 0):
                pix[x, y] = (0, 0, 0, 0)
    out_p = f'D:/Godot/WonderlandOnline/wonderland-online-client/assets/hud/icon_element_{ele}.png'
    im.save(out_p)
    print(f'Saved {out_p}, size={im.size}')
