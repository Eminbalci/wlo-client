from PIL import Image

bg = Image.open(r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud\preview_main_Status_1.png').copy()
wind = Image.open(r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud\icon_element_4.png')
betty = Image.open(r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud\avatar_role_2_0.png')
daniel = Image.open(r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud\avatar_role_6_0.png')

# Let's inspect the orange orb in bg
# The socket in main_Status_1.bmp has an inner circular opening
# Let's see the socket center:
# In bg, filigree ring is roughly center (120, 20), radius ~12
# Let's clear out the orange orb pixels from bg inside circle (120, 20, r=12)
pix = bg.load()
for y in range(5, 36):
    for x in range(106, 136):
        dx = x - 120
        dy = y - 20
        if dx*dx + dy*dy <= 12*12:
            # If it's orange/yellow orb, make it transparent
            r, g, b, a = pix[x, y]
            # orb has high red/yellow, low blue
            if r > 180 and g > 80 and b < 80:
                pix[x, y] = (0, 0, 0, 0)

bg.save(r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud\status_frame_clean_socket.png')

# Now composite with wind at (108, 8)
comp = Image.new('RGBA', bg.size, (0, 0, 0, 0))
# Avatar
comp.paste(betty, (36, 14), betty)
# Frame
comp.paste(bg, (0, 0), bg)
# Element icon
comp.paste(wind, (108, 8), wind)
comp.save(r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud\test_tuned_betty.png')

# Daniel test
comp_d = Image.new('RGBA', bg.size, (0, 0, 0, 0))
fire = Image.open(r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud\icon_element_3.png')
comp_d.paste(daniel, (34, 12), daniel)
comp_d.paste(bg, (0, 0), bg)
comp_d.paste(fire, (108, 8), fire)
comp_d.save(r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud\test_tuned_daniel.png')

print('Tuned composites saved!')
