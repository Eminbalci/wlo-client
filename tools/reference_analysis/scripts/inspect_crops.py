from PIL import Image

for name in ['w1_nav_btns_exact.png', 'w1_name_inputs.png', 'w1_preview_box.png', 'w1_radar.png', 'w1_standee.png', 'w2_tabs.png', 'w2_sliders_zoom.png', 'w3_elements.png']:
    p = 'tools/reference_analysis/ref_frames_800x600/' + name
    img = Image.open(p)
    print(f'{name}: size={img.size}')
