from PIL import Image

im = Image.open(r'D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud\panel_talk_form.png')
w, h = im.size
print(f'Original size: {w}x{h}')

# Let's see non-transparent bounding box
bbox = im.getbbox()
print('Bounding box:', bbox)

# Check top and bottom rows
# Top filigree goes from y=0 to y=20
# Bottom filigree goes from y=66 to y=86
# Left scrollbar goes from x=0 to x=45
# Right border goes from x=480 to x=524
