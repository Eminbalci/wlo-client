import cv2
import numpy as np

w1 = cv2.imread("tests/ref_frames_800x600/step1_window.png")
w2 = cv2.imread("tests/ref_frames_800x600/step2_window.png")
w3 = cv2.imread("tests/ref_frames_800x600/step3_window.png")

# Let's save slices of w1:
# Header ribbon:
cv2.imwrite("tests/ref_frames_800x600/w1_ribbon.png", w1[0:40, 250:490])
# Left card (Character role, radar chart, standee, profile):
cv2.imwrite("tests/ref_frames_800x600/w1_left_role.png", w1[10:60, 50:280])
cv2.imwrite("tests/ref_frames_800x600/w1_radar.png", w1[60:200, 50:200])
cv2.imwrite("tests/ref_frames_800x600/w1_standee.png", w1[60:260, 180:360])
cv2.imwrite("tests/ref_frames_800x600/w1_profile.png", w1[260:340, 40:360])

# Right side:
cv2.imwrite("tests/ref_frames_800x600/w1_name_inputs.png", w1[40:100, 380:720])
cv2.imwrite("tests/ref_frames_800x600/w1_preview_box.png", w1[100:300, 380:720])
cv2.imwrite("tests/ref_frames_800x600/w1_nav_buttons.png", w1[300:348, 520:730])

# Let's inspect w2 (Appearance):
cv2.imwrite("tests/ref_frames_800x600/w2_tabs.png", w2[40:80, 40:380])
cv2.imwrite("tests/ref_frames_800x600/w2_controls.png", w2[80:340, 40:380])
cv2.imwrite("tests/ref_frames_800x600/w2_preview.png", w2[40:300, 380:720])
cv2.imwrite("tests/ref_frames_800x600/w2_nav_buttons.png", w2[300:348, 520:730])

# Let's inspect w3 (Element):
cv2.imwrite("tests/ref_frames_800x600/w3_elements.png", w3[40:150, 40:380])
cv2.imwrite("tests/ref_frames_800x600/w3_desc.png", w3[150:340, 40:380])
cv2.imwrite("tests/ref_frames_800x600/w3_preview.png", w3[40:300, 380:720])
cv2.imwrite("tests/ref_frames_800x600/w3_nav_buttons.png", w3[300:348, 520:730])

print("Sub-slices saved successfully.")
