import cv2
import numpy as np

w1 = cv2.imread("tools/reference_analysis/ref_frames_800x600/w1.png")
# In w1, where is Daniel's standee?
# Left card is X=20..370, Y=10..342
# In check_exact_layout.py earlier:
# Left card elements:
# Arrow/elem at X=174, Y=31
# Name box at X=42..172
# Standee is in the middle of left card
# Let's crop X: 140..350, Y: 30..250 from w1
standee_crop = w1[30:250, 140:350]
cv2.imwrite("tools/reference_analysis/w1_standee_exact.png", standee_crop)

# Let's also check the Radar Chart in w1:
radar_crop = w1[40:190, 15:170]
cv2.imwrite("tools/reference_analysis/w1_radar_exact.png", radar_crop)

# Let's also check Role Lore in w1:
lore_crop = w1[240:330, 15:340]
cv2.imwrite("tools/reference_analysis/w1_lore_exact.png", lore_crop)

print("Saved standee, radar, lore crops.")
