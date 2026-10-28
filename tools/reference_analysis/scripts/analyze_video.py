import cv2
import wave
import sys

cap = cv2.VideoCapture("tests/char_create_ref.mp4")
fps = cap.get(cv2.CAP_PROP_FPS)
count = cap.get(cv2.CAP_PROP_FRAME_COUNT)
duration = count / fps
w = cap.get(cv2.CAP_PROP_FRAME_WIDTH)
h = cap.get(cv2.CAP_PROP_FRAME_HEIGHT)
print(f"Video: {w}x{h}, FPS: {fps}, Total frames: {count}, Duration: {duration:.2f}s")
cap.release()
