import cv2

f_sel = cv2.imread("tests/ref_frames_800x600/01_char_select_empty.png")
# Save a thumbnail or crops
cv2.imwrite("tests/ref_frames_800x600/bg_sample.png", f_sel[:100, :100])

# What does the full 01_char_select_empty look like?
# Let's inspect some coordinates:
# Where are the windows / cards in 01_char_select_empty?
# Let's save a downscaled version so we can see where the cards are:
small_sel = cv2.resize(f_sel, (400, 300))
cv2.imwrite("tests/ref_frames_800x600/small_sel.png", small_sel)

f_step1 = cv2.imread("tests/ref_frames_800x600/02_step1_character_rocco.png")
small_step1 = cv2.resize(f_step1, (400, 300))
cv2.imwrite("tests/ref_frames_800x600/small_step1.png", small_step1)

print("Saved small_sel.png and small_step1.png")
