import cv2
import numpy as np

w1 = cv2.imread("tests/ref_frames_800x600/step1_window.png")
w2 = cv2.imread("tests/ref_frames_800x600/step2_window.png")
w3 = cv2.imread("tests/ref_frames_800x600/step3_window.png")

print(f"Windows size: {w1.shape}")

# Let's inspect Step 1:
# In w1, where are the buttons Return and Continue?
# Look at bottom-right (y: 300..345, x: 500..730)
btn_area = w1[300:345, 520:730]
# Save high-res crop
cv2.imwrite("tests/ref_frames_800x600/measure_step1_nav_btns.png", btn_area)

# In w1, where is Name and Family inputs?
# Look at top-right (y: 40..100, x: 380..720)
name_area = w1[40:100, 380:720]
cv2.imwrite("tests/ref_frames_800x600/measure_step1_name.png", name_area)

# In w1, where is the preview box?
# Look at y: 90..300, x: 380..720
preview_area = w1[90:300, 380:720]
cv2.imwrite("tests/ref_frames_800x600/measure_step1_preview.png", preview_area)

# In w1, where is the left card?
# Look at y: 10..345, x: 20..370
left_card = w1[10:345, 20:370]
cv2.imwrite("tests/ref_frames_800x600/measure_step1_left_card.png", left_card)

# In w2, where are the 4 tabs?
# Look at y: 40..90, x: 30..380
tabs_area = w2[40:90, 30:380]
cv2.imwrite("tests/ref_frames_800x600/measure_step2_tabs.png", tabs_area)

# In w2, where are the RGB sliders?
sliders_area = w2[90:340, 30:380]
cv2.imwrite("tests/ref_frames_800x600/measure_step2_sliders.png", sliders_area)

# In w3, where are the 4 element buttons?
elem_area = w3[40:140, 30:380]
cv2.imwrite("tests/ref_frames_800x600/measure_step3_elements.png", elem_area)

elem_desc = w3[140:340, 30:380]
cv2.imwrite("tests/ref_frames_800x600/measure_step3_desc.png", elem_desc)

print("Measurement crops saved.")
