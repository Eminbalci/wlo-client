from PIL import Image

# Clean out the orange orb from preview_main_Status_1.png
im = Image.open(r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud\preview_main_Status_1.png').convert('RGBA')
pix = im.load()

# Center of socket is around (120, 19)
for y in range(im.height):
    for x in range(im.width):
        dx = x - 120
        dy = y - 19
        if dx*dx + dy*dy <= 13*13:
            r, g, b, a = pix[x, y]
            # If not golden rim (gold has r>150, g>120, b<80 but darker shadows)
            # The orb is orange/yellow/white
            if (r > 160 and g > 60 and b < 80) or (r > 200 and g > 200 and b > 150):
                pix[x, y] = (0, 0, 0, 0)

im.save(r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud\hud_status_frame_transparent_channels.png')
print('Updated hud_status_frame_transparent_channels.png with clear socket!')

# Test composite
fire = Image.open(r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud\icon_element_3.png')
comp = Image.new('RGBA', im.size, (0, 0, 0, 0))
comp.paste(fire, (108, 7), fire)
comp.paste(im, (0, 0), im)
comp.save(r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud\test_socket_fit.png')
print('Saved test_socket_fit.png')
