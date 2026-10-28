import cv2
import numpy as np

img = cv2.imread(r"D:\Godot\WonderlandOnline\wonderland-online-client\tests\ref_frames\04_step1_character_sid.png")
h, w, c = img.shape
print(f"Full image dimensions: {w} x {h}")

# The game window has black borders around it in the video (letterboxed / 16:9 recording)
# Let's find the game screen area (non-black area)
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
# Find non-black rows and cols
rows = np.where(np.max(gray, axis=1) > 10)[0]
cols = np.where(np.max(gray, axis=0) > 10)[0]
if len(rows) > 0 and len(cols) > 0:
    min_y, max_y = rows[0], rows[-1]
    min_x, max_x = cols[0], cols[-1]
    print(f"Game content bounds: x=[{min_x}, {max_x}] (w={max_x - min_x + 1}), y=[{min_y}, {max_y}] (h={max_y - min_y + 1})")

# Let's also check the title bar if visible
# Save cropped game area
game_crop = img[min_y:max_y+1, min_x:max_x+1]
cv2.imwrite(r"D:\Godot\WonderlandOnline\wonderland-online-client\tests\ref_frames\game_window_cropped.png", game_crop)
print(f"Saved game_window_cropped.png with shape {game_crop.shape}")
