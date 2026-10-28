import cv2

c1 = cv2.imread("assets/upimg/colorform.bmp")
c2 = cv2.imread("assets/upimg/colorforms.bmp")
print("colorform:", c1.shape if c1 is not None else None)
print("colorforms:", c2.shape if c2 is not None else None)
