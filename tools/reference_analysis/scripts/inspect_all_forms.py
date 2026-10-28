import cv2

for i in [1, 2, 3, 4]:
    img = cv2.imread(f"assets/menu/Skins/white/Form_CreateRole_{i}.jpg")
    if img is not None:
        print(f"Form_CreateRole_{i}.jpg: {img.shape}")
        # Save a crop of the title area (top 50px)
        cv2.imwrite(f"tests/ref_frames_800x600/form_{i}_header.png", img[:50, :])
