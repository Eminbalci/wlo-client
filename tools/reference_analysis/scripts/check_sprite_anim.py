import cv2
import numpy as np

# In Step 1, preview sprite is at x ~ 480..620, y ~ 160..300
cap = cv2.VideoCapture("tests/char_create_ref.mp4")
fps = cap.get(cv2.CAP_PROP_FPS)

# Inspect frames from 14.0s to 15.0s (30 frames)
cap.set(cv2.CAP_PROP_POS_FRAMES, int(14.0 * fps))
sprite_crops = []
for i in range(15):
    ret, frame = cap.read()
    if not ret: break
    # crop to 800x600 first
    crop_800 = frame[65:665, 30:830]
    # sprite box is around x: 500..600, y: 170..280
    sprite = crop_800[170:280, 500:600]
    sprite_crops.append(sprite)

cap.release()

# Check difference between consecutive frames of the sprite
diffs = []
for i in range(len(sprite_crops) - 1):
    d = np.mean(np.abs(sprite_crops[i+1].astype(float) - sprite_crops[i].astype(float)))
    diffs.append(d)

print("Sprite consecutive frame diffs:", [f"{d:.2f}" for d in diffs])
# Save the first 6 frames of the sprite
for i in range(min(6, len(sprite_crops))):
    cv2.imwrite(f"tests/ref_frames_800x600/sprite_anim_f{i}.png", sprite_crops[i])

print("Saved sprite_anim_f0..f5.png")
