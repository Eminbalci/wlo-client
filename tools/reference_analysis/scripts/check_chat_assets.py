import os
from PIL import Image

skin_dir = r'D:\GitHub\WLRI\menu\Skins\default'

names = [
    'Panel_TalkForm.bmp',
    'Panel_TalkForm2_1.bmp',
    'Btn_MsgLock_1.bmp',
    'Btn_MsgLock_2.bmp',
    'Btn_mail_1.bmp',
    'Btn_mail_gray_1.bmp',
    'Btn_expression_1.bmp',
    'Btn_CountenanceIcon_1.bmp',
    'Btn_CountenanceIcon_1a.bmp',
    'icon_Channelframe_1.bmp',
    'Btn_Resize_1.bmp',
    'panel_expression_1.bmp'
]

for n in names:
    p = os.path.join(skin_dir, n)
    if os.path.exists(p):
        im = Image.open(p)
        print(f'{n}: size={im.size}, mode={im.mode}')
    else:
        print(f'{n}: NOT FOUND')

# Check SizeUp / SizeDn
for f in os.listdir(skin_dir):
    if 'size' in f.lower() or 'resize' in f.lower():
        print('Found size/resize:', f)
