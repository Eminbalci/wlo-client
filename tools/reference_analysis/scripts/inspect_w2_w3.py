from PIL import Image
import numpy as np

# Let's inspect w2.png and rendered_w2.png
w2_ref = Image.open('tools/reference_analysis/ref_frames_800x600/w2.png').convert('RGB')
w2_rend = Image.open('tools/reference_analysis/rendered_w2.png').convert('RGB')

# Let's check the left half and right half of w2
left_ref = w2_ref.crop((0, 0, 370, 352))
left_rend = w2_rend.crop((0, 0, 370, 352))
left_ref.save('tools/reference_analysis/debug_w2_ref_left.png')
left_rend.save('tools/reference_analysis/debug_w2_rend_left.png')

# Let's check w3 as well
w3_ref = Image.open('tools/reference_analysis/ref_frames_800x600/w3.png').convert('RGB')
w3_rend = Image.open('tools/reference_analysis/rendered_w3.png').convert('RGB')
left_ref3 = w3_ref.crop((0, 0, 370, 352))
left_rend3 = w3_rend.crop((0, 0, 370, 352))
left_ref3.save('tools/reference_analysis/debug_w3_ref_left.png')
left_rend3.save('tools/reference_analysis/debug_w3_rend_left.png')

print("Saved left crops for w2 and w3.")
