from PIL import Image

for name in ['btn_arrow_left_normal.png', 'btn_arrow_left_hover.png', 'btn_arrow_left_pressed.png',
             'btn_arrow_right_normal.png', 'btn_arrow_right_hover.png', 'btn_arrow_right_pressed.png',
             'btn_arrow_left_carousel.png', 'btn_arrow_right_carousel.png']:
    p = 'assets/auth/' + name
    img = Image.open(p)
    print(f"{name}: size={img.size}")
