import os

auth_files = [
    'btn_cancel_normal.png', 'btn_cancel_hover.png', 'btn_cancel_pressed.png',
    'btn_ok_normal.png', 'btn_ok_hover.png', 'btn_ok_pressed.png',
    'btn_next_normal.png', 'btn_next_hover.png', 'btn_next_pressed.png',
    'btn_prev_small_normal.png', 'btn_prev_small_hover.png', 'btn_prev_small_pressed.png',
    'btn_arrow_left_normal.png', 'btn_arrow_left_hover.png', 'btn_arrow_left_pressed.png',
    'btn_arrow_right_normal.png', 'btn_arrow_right_hover.png', 'btn_arrow_right_pressed.png'
]

for f in auth_files:
    p = os.path.join('assets/auth', f)
    exists = os.path.exists(p)
    print(f"{f}: {exists}")
