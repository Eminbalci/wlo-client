import cv2
import os

video_path = r"D:\Godot\WonderlandOnline\wonderland-online-client\tests\char_create_ref.mp4"
output_dir = r"D:\Godot\WonderlandOnline\wonderland-online-client\tests\ref_frames"
os.makedirs(output_dir, exist_ok=True)

cap = cv2.VideoCapture(video_path)
fps = cap.get(cv2.CAP_PROP_FPS)
print(f"Video FPS: {fps}, Total frames: {cap.get(cv2.CAP_PROP_FRAME_COUNT)}")

# Key timestamps in seconds to extract
timestamps = [
    (9.5, "01_char_select_empty.png"),
    (11.5, "02_step1_character_rocco.png"),
    (13.5, "03_step1_character_daniel.png"),
    (17.5, "04_step1_character_sid.png"),
    (20.5, "05_step1_named_satoru_gojo.png"),
    (23.0, "06_step2_appearance_hair.png"),
    (27.0, "07_step2_hair_pink.png"),
    (31.5, "08_step2_appearance_body.png"),
    (35.5, "09_step2_appearance_eyes.png"),
    (44.0, "10_step2_appearance_wear.png"),
    (50.0, "11_step2_wear_underwear.png"),
    (53.0, "12_step3_element_earth.png"),
    (54.5, "13_step3_element_water.png"),
    (58.5, "14_char_select_done.png"),
]

for sec, filename in timestamps:
    target_frame = int(sec * fps)
    cap.set(cv2.CAP_PROP_POS_FRAMES, target_frame)
    ret, frame = cap.read()
    if ret:
        out_path = os.path.join(output_dir, filename)
        cv2.imwrite(out_path, frame)
        print(f"Saved {filename} at {sec}s (frame {target_frame})")

cap.release()
print("Done extracting reference frames.")
