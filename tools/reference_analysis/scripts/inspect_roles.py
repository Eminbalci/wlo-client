import re

with open('D:/Godot/WonderlandOnline/wonderland-online-client/scripts/database/game_database.gd', 'r', encoding='utf-8') as f:
    text = f.read()

start = text.find('const ROLES: Dictionary = {')
end = text.find('}\n\nvar items', start)
if end == -1:
    end = start + 12000
role_block = text[start:end]

blocks = role_block.split('\n\t},\n')
for b in blocks:
    m_id = re.search(r'(\d+):\s*\{', b)
    if not m_id:
        continue
    rid = m_id.group(1)
    def get_f(k):
        m = re.search(r'"' + k + r'":\s*"([^"]*)"', b)
        if not m:
            m = re.search(r'"' + k + r'":\s*(\d+)', b)
        return m.group(1) if m else '?'
    print(f"Role {rid}: {get_f('name')} | body={get_f('body_archive')}:{get_f('body_jmp')} | hair={get_f('hair_archive')}:{get_f('hair_jmp')} | clothes={get_f('default_clothes_archive')}:{get_f('default_clothes_jmp')} (item {get_f('default_clothes_item_id')}) | shoes={get_f('default_shoes_archive')}:{get_f('default_shoes_jmp')} | portrait={get_f('portrait_bmp')}")
