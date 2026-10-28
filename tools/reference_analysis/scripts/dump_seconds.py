import cv2
import numpy as np

cap = cv2.VideoCapture("tests/char_create_ref.mp4")
fps = cap.get(cv2.CAP_PROP_FPS)
total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

# Sample 1 frame every 1 second (every 30 frames)
print(f"Total duration: {total_frames / fps:.2f}s ({total_frames} frames)")
for sec in range(0, int(total_frames / fps) + 1):
    frame_idx = int(sec * fps)
    if frame_idx >= total_frames:
        break
    cap.set(cv2.CAP_PROP_POS_FRAMES, frame_idx)
    ret, frame = cap.read()
    if ret:
        cv2.imwrite(f"tests/ref_frames/sec_{sec:03d}.png", frame)

cap.release()
print("Saved second-by-second frames.")
