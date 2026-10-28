from PIL import Image

ref = Image.open('tools/reference_analysis/ref_frames_800x600/w1.png').crop((510, 80, 720, 130))
ref.save('tools/reference_analysis/ref_name_crop.png')

# Also check 05_step1_named_satoru_gojo.png
named = Image.open('tools/reference_analysis/ref_frames_800x600/05_step1_named_satoru_gojo.png').crop((30+510, 124+80, 30+720, 124+130))
named.save('tools/reference_analysis/named_satoru_ref_crop.png')

print("Saved ref_name_crop.png and named_satoru_ref_crop.png")
