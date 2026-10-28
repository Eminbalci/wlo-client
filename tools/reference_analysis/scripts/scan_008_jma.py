import struct
import os

jma_path = r'D:\GitHub\WLRI\jma\008.jma'
if not os.path.exists(jma_path):
    jma_path = r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\jma\008.jma'

with open(jma_path, 'rb') as f:
    data = f.read()

# Let's see how JMA is parsed
# In archive_loader.gd:
# The JMA header: magic (e.g. 4 bytes), count, then table of entries
print('008.jma size:', len(data))
# Search for names ending with .jmp
import re
names = re.findall(b'[a-zA-Z0-9_]+\\.jmp', data)
print(f'Total .jmp names found: {len(names)}')
unique_names = sorted(list(set(n.decode('latin1') for n in names)))
print('Sample jmp names:', unique_names[:30])
print('Highest jmp names:', unique_names[-30:])
