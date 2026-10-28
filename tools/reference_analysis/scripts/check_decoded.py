import os
from PIL import Image

# Let's inspect sizes or check which ones are portraits
decoded_dir = r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud\decoded_008'
files = sorted(os.listdir(decoded_dir))
print(f'Total decoded files: {len(files)}')

# Let's see some samples
for f in files[:20]:
    im = Image.open(os.path.join(decoded_dir, f))
    print(f, im.size)
