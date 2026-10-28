from PIL import Image
import numpy as np

# Load our rendered test screenshots
s1 = Image.open('test_screenshots/char_create_step1.png')
s2 = Image.open('test_screenshots/char_create_step2.png')
s3 = Image.open('test_screenshots/char_create_step3.png')

print("Rendered screenshot sizes:", s1.size, s2.size, s3.size)

# Crop the window area from our rendered screenshot (offset 30, 124, 740x352)
crop1 = s1.crop((30, 124, 30+740, 124+352))
crop2 = s2.crop((30, 124, 30+740, 124+352))
crop3 = s3.crop((30, 124, 30+740, 124+352))

crop1.save('tools/reference_analysis/rendered_w1.png')
crop2.save('tools/reference_analysis/rendered_w2.png')
crop3.save('tools/reference_analysis/rendered_w3.png')

# Load reference w1, w2, w3
ref1 = Image.open('tools/reference_analysis/ref_frames_800x600/w1.png').convert('RGB')
ref2 = Image.open('tools/reference_analysis/ref_frames_800x600/w2.png').convert('RGB')
ref3 = Image.open('tools/reference_analysis/ref_frames_800x600/w3.png').convert('RGB')

# Let's compute difference maps
for idx, (c, r) in enumerate([(crop1, ref1), (crop2, ref2), (crop3, ref3)], 1):
    c_arr = np.array(c.convert('RGB'), dtype=np.int16)
    r_arr = np.array(r, dtype=np.int16)
    diff = np.abs(c_arr - r_arr)
    mean_diff = np.mean(diff)
    print(f"Step {idx} window mean diff: {mean_diff:.2f}")
    
    # Save diff image highlighting differences
    diff_vis = Image.fromarray(np.clip(diff * 3, 0, 255).astype(np.uint8))
    diff_vis.save(f'tools/reference_analysis/step{idx}_diff_vis.png')

print("Saved difference visualizations.")
