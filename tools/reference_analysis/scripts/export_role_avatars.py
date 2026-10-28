import struct, os
from PIL import Image

jma_dir = r'D:\GitHub\WLRI\jma'
if not os.path.exists(jma_dir):
    jma_dir = r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\jma'

out_dir = r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud'

mapping = {
    1: '8005.jmp',
    2: '8016.jmp',
    3: '8004.jmp',
    4: '8029.jmp',
    5: '8028.jmp',
    6: '8027.jmp',
    7: '8082.jmp',
    8: '8050.jmp',
    9: '8046.jmp',
    10: '8044.jmp',
    11: '8042.jmp',
    12: '8055.jmp',
    13: '8019.jmp',
    14: '8109.jmp'
}

with open(os.path.join(jma_dir, '008.jma'), 'rb') as f:
    data = f.read()

file_count = struct.unpack_from('<I', data, 10)[0]
ptr = 14
entries = {}
for i in range(file_count):
    nlen = data[ptr]; ptr += 1
    name = data[ptr:ptr+19][:nlen].split(b'\x00')[0].decode('ascii', errors='ignore').strip().lower()
    ptr += 19
    size, offset = struct.unpack_from('<II', data, ptr); ptr += 8
    entries[name] = (offset, size)

for role_id, jmp_name in mapping.items():
    if jmp_name.lower() not in entries:
        print('Not found:', jmp_name)
        continue
    offset, size = entries[jmp_name.lower()]
    jmp = data[offset : offset + size]
    frame_count = struct.unpack_from('<I', jmp, 10)[0]
    entries_end = 14 + frame_count * 40
    raw_pal = jmp[entries_end : entries_end + 1024]
    pal = []
    for c in range(256):
        b = raw_pal[c*4 + 0]
        g = raw_pal[c*4 + 1]
        r = raw_pal[c*4 + 2]
        a = 0 if (c == 0 or (r == 0 and g == 255 and b == 0)) else 255
        pal.append((r, g, b, a))
    
    for f_idx in range(min(frame_count, 2)):
        pf = 14 + f_idx * 40
        nlen = jmp[pf]; pf += 1
        fname = jmp[pf:pf+11][:nlen].split(b'\x00')[0].decode('ascii', errors='ignore').strip()
        pf += 11
        bw, bh, px, py = struct.unpack_from('<hhhh', jmp, pf); pf += 8
        fsize, foff, w, h, bpp = struct.unpack_from('<IIIII', jmp, pf)
        
        canvas_w = max(bw, w, 72)
        canvas_h = max(bh, h, 72)
        img = Image.new('RGBA', (canvas_w, canvas_h), (0, 0, 0, 0))
        stride = (w + 3) & ~3
        for y in range(h):
            src_row = foff + y * stride
            for x in range(w):
                p_idx = jmp[src_row + x]
                rgba = pal[p_idx]
                if rgba[3] > 0:
                    dx = max(0, min(canvas_w-1, px + x if px >= 0 else x))
                    dy = max(0, min(canvas_h-1, py + y if py >= 0 else y))
                    img.putpixel((dx, dy), rgba)
        
        # Save authentic role avatar frames
        out_fn = f'avatar_role_{role_id}_{f_idx}.png'
        img.save(os.path.join(out_dir, out_fn))
        if role_id == 2 and f_idx == 0:
            img.save(os.path.join(out_dir, 'betty_avatar.png'))
        if role_id == 6 and f_idx == 0:
            img.save(os.path.join(out_dir, 'daniel_avatar.png'))
            img.save(os.path.join(out_dir, 'portraits', 'daniel_portrait.png'))
    print(f'Exported Role {role_id} ({jmp_name}) 2 frames')

print('All 14 role avatars updated!')
