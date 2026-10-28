import os
from PIL import Image

skin_dir = r'D:\GitHub\WLRI\menu\Skins\default'
out_dir = r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud'
os.makedirs(out_dir, exist_ok=True)

def chroma(im):
    im = im.convert('RGBA')
    pix = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = pix[x, y]
            if r == 0 and g == 255 and b == 0:
                pix[x, y] = (0, 0, 0, 0)
    return im

def slice_v3(fname, base_name):
    p = os.path.join(skin_dir, fname)
    if not os.path.exists(p):
        print('Missing:', fname)
        return
    im = chroma(Image.open(p))
    w = im.width
    fh = im.height // 3
    im.crop((0, 0, w, fh)).save(os.path.join(out_dir, f'{base_name}_normal.png'))
    im.crop((0, fh, w, fh * 2)).save(os.path.join(out_dir, f'{base_name}_hover.png'))
    im.crop((0, fh * 2, w, fh * 3)).save(os.path.join(out_dir, f'{base_name}_pressed.png'))
    print(f'Sliced {base_name}: {w}x{fh}')

# 1. Mail button (43x20)
slice_v3('Btn_mail_1.bmp', 'btn_mail')

# 2. Expression button (26x25)
slice_v3('Btn_expression_1.bmp', 'btn_expression')

# 3. Msg Lock button (19x18)
slice_v3('Btn_MsgLock_1.bmp', 'btn_msg_lock')

# 4. Resize handle (20x20)
slice_v3('Btn_Resize_1.bmp', 'btn_resize')

# 5. SizeUp and SizeDn (16x12)
slice_v3('SizeUp.bmp', 'btn_size_up')
slice_v3('SizeDn.bmp', 'btn_size_dn')

# 6. Panel Talk Form (524x86)
p_talk = chroma(Image.open(os.path.join(skin_dir, 'Panel_TalkForm.bmp')))
p_talk.save(os.path.join(out_dir, 'panel_talk_form.png'))

# 7. Panel Talk Form Left (45x86)
p_talk_left = chroma(Image.open(os.path.join(skin_dir, 'Panel_TalkForm2_1.bmp')))
p_talk_left.save(os.path.join(out_dir, 'panel_talk_form_left.png'))

# 8. Expression panel (263x69)
p_expr = chroma(Image.open(os.path.join(skin_dir, 'panel_expression_1.bmp')))
p_expr.save(os.path.join(out_dir, 'panel_expression.png'))

# 9. Channel dropdown frame
p_chan = chroma(Image.open(os.path.join(skin_dir, 'icon_Channelframe_1.bmp')))
p_chan.save(os.path.join(out_dir, 'icon_channel_frame.png'))

# 10. Emote icons 1..31
for i in range(1, 32):
    fn = f'icon_expre_{i}.bmp'
    fp = os.path.join(skin_dir, fn)
    if os.path.exists(fp):
        e_im = chroma(Image.open(fp))
        e_im.save(os.path.join(out_dir, f'icon_expre_{i}.png'))

print('All chat assets converted successfully!')
