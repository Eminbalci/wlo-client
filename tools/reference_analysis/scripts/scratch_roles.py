with open(r'D:\Godot\WonderlandOnline\wonderland-online-client\scripts\database\game_database.gd', 'r', encoding='utf-8') as f:
    text = f.read()

import re
matches = re.findall(r'(\d+):\s*\{\s*"id":\s*(\d+),\s*"name":\s*"([^"]+)",\s*"gender":\s*"([^"]+)",\s*"body_type":\s*"([^"]+)",\s*"element":\s*"([^"]+)"', text)
for m in matches:
    print(m)
