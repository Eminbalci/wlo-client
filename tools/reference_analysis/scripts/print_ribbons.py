import cv2

for name, path in [("Step 1", "tests/ref_frames_800x600/f1_ribbon.png"), 
                   ("Step 2", "tests/ref_frames_800x600/f2_ribbon.png"), 
                   ("Step 3", "tests/ref_frames_800x600/f3_ribbon.png")]:
    img = cv2.imread(path)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    _, thresh = cv2.threshold(gray, 100, 255, cv2.THRESH_BINARY_INV)
    print(f"\n=== {name} Ribbon ===")
    for y in range(0, thresh.shape[0], 2):
        line = "".join(["#" if thresh[y, x] > 0 else " " for x in range(0, thresh.shape[1], 2)])
        if "#" in line:
            print(line)
