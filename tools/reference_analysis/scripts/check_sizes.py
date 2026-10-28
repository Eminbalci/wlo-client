from PIL import Image
import os

skin_dir = r'D:\GitHub\WLRI\menu\Skins\default'
for name in ['SizeUp.bmp', 'SizeDn.bmp', 'panel_expression_1.bmp', 'Btn_expression_1.bmp', 'Btn_Resize_1.bmp']:
    p = os.path.join(skin_dir, name)
    im = Image.open(p)
    print(name, im.size)
