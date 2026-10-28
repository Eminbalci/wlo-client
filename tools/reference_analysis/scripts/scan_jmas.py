import re
import os

for jma_name in ['001.jma', '002.jma', '003.jma', '008.jma', '009.jma']:
    p = os.path.join(r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\jma', jma_name)
    if os.path.exists(p):
        with open(p, 'rb') as f:
            data = f.read()
        names = sorted(list(set(n.decode('latin1') for n in re.findall(b'[a-zA-Z0-9_]+\\.jmp', data))))
        print(f'{jma_name}: count={len(names)}, range={names[0]} to {names[-1]}')
