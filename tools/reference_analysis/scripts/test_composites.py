from PIL import Image

bg = Image.open(r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud\preview_main_Status_1.png')
wind = Image.open(r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud\icon_element_4.png')
daniel = Image.open(r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud\avatar_role_6_0.png')
betty = Image.open(r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud\avatar_role_2_0.png')

# Composite test 1: Betty (Wind)
comp1 = Image.new('RGBA', bg.size, (0, 0, 0, 0))
# Avatar behind frame
comp1.paste(betty, (18, 14), betty)
# Frame
comp1.paste(bg, (0, 0), bg)
# Element on top of socket
comp1.paste(wind, (107, 7), wind)
comp1.save(r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud\test_composite_betty.png')

# Composite test 2: Daniel (Fire)
fire = Image.open(r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud\icon_element_3.png')
comp2 = Image.new('RGBA', bg.size, (0, 0, 0, 0))
comp2.paste(daniel, (18, 14), daniel)
comp2.paste(bg, (0, 0), bg)
comp2.paste(fire, (107, 7), fire)
comp2.save(r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud\test_composite_daniel.png')
print('Composites saved successfully!')
