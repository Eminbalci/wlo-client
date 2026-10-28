import cv2
import numpy as np

f_step1 = cv2.imread("tests/ref_frames_800x600/02_step1_character_rocco.png")

# Let's find the window outline
# In WLO, the dialog has a dark golden/brown border and title ribbon
# Let's search for the window boundary
# Look at horizontal edges across y in 100..180
# Find where the window rectangle starts and ends
# Let's print the bounding box of the dialog in f_step1:
# The background is a blue/purple night sky or ocean (LogPic1)
# The window interior is parchment/brown/cream colored.
# Let's detect parchment color: BGR around (160..220, 180..240, 200..255)
hsv = cv2.cvtColor(f_step1, cv2.COLOR_BGR2HSV)
# Find parchment / window area: Saturation low to medium, Value high
# Or simply find the window frame by finding the outer brown rectangle
# In WLO, the window title ribbon is centered at the top of the dialog
# Let's find the ribbon:
# Let's inspect rows around y=120..150
for y in range(110, 160, 5):
    row = f_step1[y, :, :]
    # find where row changes from background to window border
    diffs = np.where(np.abs(row[:-1].astype(float) - row[1:].astype(float)).sum(axis=1) > 50)[0]
    print(f"y={y}: edges at x={diffs}")
