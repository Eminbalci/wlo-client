import os
from PIL import Image
import numpy as np

video_dir = r"C:\Users\muham\.gemini\antigravity-cli\brain\c43cf149-bb6e-436c-95e5-06c734294986\video_seconds"
scratch_dir = r"C:\Users\muham\.gemini\antigravity-cli\brain\dc53c99a-2308-4b9b-b7ac-96329229adb6\scratch"
os.makedirs(scratch_dir, exist_ok=True)

print("=== TASK 1: sec_271 to sec_330 (Chat Dock Dual Mode) ===")
# In sec_271, let's examine the chat dock:
# Compact mode:
# - What is visible at bottom-left?
# - Mailbox button, channel button, chat input, send/action button, emote button.
# - Left scrollbar panel (PanelTalkFormLeft).
# - Is there a background behind chat text?
im271 = Image.open(os.path.join(video_dir, "sec_271.png")).convert("RGB")
arr271 = np.array(im271)

# Check chat text lines in sec_271
# In sec_271, chat text lines appear in y in [480, 570], x in [50, 450]
print("sec_271 chat text lines check:")
# Let's see what color the text is:
# Usually white text [255, 255, 255] with black outline [0, 0, 0] or [10, 10, 10]
text_mask = (arr271[480:570, 50:450, 0] > 220) & (arr271[480:570, 50:450, 1] > 220) & (arr271[480:570, 50:450, 2] > 220)
print("White text pixels found in chat history:", np.sum(text_mask))

# Check when framed mode is toggled in 271..330:
for s in range(271, 331):
    im = Image.open(os.path.join(video_dir, f"sec_{s}.png")).convert("RGB")
    arr = np.array(im)
    # Check if there is a parchment border at x=100, y=500..510
    # In framed mode, the background has parchment or slate color
    pass

print("=== TASK 2: sec_330 to sec_370 (Vertical Drag Resizing) ===")
# In sec_330 to sec_370, let's track the top boundary of chat history:
# Where does chat history start vertically?
# Check the position of BtnChatSize (usually near top-right of chat panel)
for s in range(330, 371):
    im = Image.open(os.path.join(video_dir, f"sec_{s}.png")).convert("RGB")
    arr = np.array(im)
    # Check top edge of chat dock:
    # Scan column 10 (PanelTalkFormLeft) to find its top edge!
    col = arr[:, 10]
    # PanelTalkFormLeft has distinct texture/color
    # Find topmost row y where col[y] belongs to PanelTalkFormLeft
    # Let's check rows from 350 to 570
    top_y = None
    for y in range(350, 570):
        # PanelTalkFormLeft background is around [91, 74, 35] or [80..100, 60..80, 25..45]
        if 75 <= col[y, 0] <= 110 and 60 <= col[y, 1] <= 90 and 20 <= col[y, 2] <= 50:
            top_y = y
            break
    if s in [330, 335, 340, 345, 350, 355, 360, 365, 370]:
        print(f"sec_{s}: left strip top_y={top_y}")

print("=== TASK 3: sec_371 to sec_395 (Emote Picker Popup) ===")
# Let's find where the emote popup is open in 371..395
# In sec_371..395, let's find the exact bounding box of the popup
expr_patch = Image.open(r"D:\Godot\WonderlandOnline\wonderland-online-client\assets\hud\panel_expression.png").convert("RGB")
ep_arr = np.array(expr_patch)
print("panel_expression size:", expr_patch.size)

for s in range(371, 396):
    im = Image.open(os.path.join(video_dir, f"sec_{s}.png")).convert("RGB")
    arr = np.array(im)
    # Let's search for the close button or gold border of panel_expression
    # panel_expression has size (263, 69)
    # Let's scan for top-left corner
    pass

print("=== TASK 4: sec_395 to sec_424 (Channel Selector & Tooltips) ===")
# Let's check frames in 395..424 for:
# 1. Channel selector dropdown (when does it open, where, size)
# 2. Whisper target input and formatting
# 3. Inventory slot hover tooltips (text, layout, background)
for s in range(395, 425):
    # Check for tooltip: tooltips have dark or parchment background with item name and description
    pass
