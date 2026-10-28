import cv2

# Let's save small thumbnails of sec_000 to sec_030
for sec in range(0, 61, 2):
    img = cv2.imread(f"tests/ref_frames_800x600/sec_{sec:03d}.png")
    if img is not None:
        thumb = cv2.resize(img, (200, 150))
        cv2.imwrite(f"tests/ref_frames_800x600/thumb_{sec:03d}.png", thumb)

print("Thumbnails generated.")
