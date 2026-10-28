from PIL import Image

s1 = Image.open('test_screenshots/char_create_step1.png')
# Window is at (30, 124) to (770, 476)
w1 = s1.crop((30, 124, 770, 476))

# Name inputs crop: X: 510..720, Y: 80..130
w1.crop((510, 80, 720, 130)).save('tools/reference_analysis/check_name_inputs_rendered.png')

# Preview box crop: X: 500..720, Y: 140..260
w1.crop((500, 140, 720, 260)).save('tools/reference_analysis/check_preview_rendered.png')

# Left carousel header crop: X: 20..220, Y: 10..50
w1.crop((20, 10, 220, 50)).save('tools/reference_analysis/check_carousel_rendered.png')

# Nav buttons crop: X: 490..730, Y: 295..340
w1.crop((490, 295, 730, 340)).save('tools/reference_analysis/check_nav_rendered.png')

s2 = Image.open('test_screenshots/char_create_step2.png')
w2 = s2.crop((30, 124, 770, 476))
# Step 2 tabs & sliders
w2.crop((30, 30, 360, 280)).save('tools/reference_analysis/check_step2_left_rendered.png')

s3 = Image.open('test_screenshots/char_create_step3.png')
w3 = s3.crop((30, 124, 770, 476))
# Step 3 elements
w3.crop((30, 80, 360, 280)).save('tools/reference_analysis/check_step3_left_rendered.png')
# Step 3 coin badge
w3.crop((500, 140, 720, 260)).save('tools/reference_analysis/check_step3_preview_rendered.png')

print("All inspection crops saved successfully.")
