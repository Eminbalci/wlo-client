import struct, os
from PIL import Image

jma_dir = r'D:\GitHub\WLRI\jma'
if not os.path.exists(jma_dir):
    jma_dir = r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\jma'

def decode_all_009(out_dir):
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(jma_dir, '009.jma'), 'rb') as f:
        data = f.read()
    
    file_count = struct.unpack_from('<I', data, 10)[0]
    ptr = 14
    entries = []
    for i in range(file_count):
        nlen = data[ptr]; ptr += 1
        name = data[ptr:ptr+19][:nlen].split(b'\x00')[0].decode('ascii', errors='ignore').strip()
        ptr += 19
        size, offset = struct.unpack_from('<II', data, ptr); ptr += 8
        entries.append((name, offset, size))
    
    for name, offset, size in entries:
        jmp = data[offset : offset + size]
        frame_count = struct.unpack_from('<I', jmp, 10)[0]
        if frame_count == 0:
            continue
        entries_end = 14 + frame_count * 40
        raw_pal = jmp[entries_end : entries_end + 1024]
        pal = []
        for c in range(256):
            b = raw_pal[c*4 + 0]
            g = raw_pal[c*4 + 1]
            r = raw_pal[c*4 + 2]
            a = 0 if (c == 0 or (r == 0 and g == 255 and b == 0)) else 255
            pal.append((r, g, b, a))
        
        # Frame 0
        p0 = 14
        nlen0 = jmp[p0]; p0 += 1
        fname0 = jmp[p0:p0+11][:nlen0].split(b'\x00')[0].decode('ascii', errors='ignore').strip()
        p0 += 11
        bw, bh, px, py = struct.unpack_from('<hhhh', jmp, p0); p0 += 8
        fsize, foff, w, h, bpp = struct.unpack_from('<IIIII', jmp, p0)
        
        canvas_w = max(bw, w, 80)
        canvas_h = max(bh, h, 80)
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
        img.save(os.path.join(out_dir, f"{name.replace('.jmp', '')}.png"))

out_dir = r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud\decoded_009'
decode_all_009(out_dir)
print('Decoded all in 009.jma')
