import cv2
import numpy as np

# We know the 3 steps have distinct title ribbons at (250..550, 110..150):
# Step 1: Ribbon says "Character"
# Step 2: Ribbon says "Appearance"
# Step 3: Ribbon says "Element"
# Character Select: Shows 2 cards (Slot 1 and Slot 2)

for sec in range(0, 61):
    img = cv2.imread(f"tests/ref_frames_800x600/sec_{sec:03d}.png")
    if img is None: continue
    
    # Check ribbon text area around (350..450, 120..145)
    ribbon = img[120:145, 350:450]
    # Check whether main window is visible
    win_center = img[300:350, 380:420]
    
    # Identify state:
    # Character select screen has slot 1 card at x: 40..390 and slot 2 at 410..760
    # or centered card
    card_l = img[200:300, 100:200]
    card_r = img[200:300, 600:700]
    
    print(f"Sec {sec:02d}: Ribbon mean={ribbon.mean():.1f}, Center mean={win_center.mean():.1f}, L={card_l.mean():.1f}, R={card_r.mean():.1f}")
