"""Slice the skins used by the trade / pet trade / item bank (warehouse) / repair windows.

Source: the real client's menu/Skins/{white,default}/*.bmp (pure green 0,255,0 = transparent).
Button sheets stack 3 frames vertically (normal, hover, pressed).
Output: assets/hud/*.png (RGBA, chroma key removed).

Run: python tools/reference_analysis/scripts/slice_trade_bank_repair.py [WLRI_DIR]
"""
import os
import sys

from PIL import Image

WLRI = sys.argv[1] if len(sys.argv) > 1 else "D:/GitHub/WLRI"
SKINS = os.path.join(WLRI, "menu", "Skins")
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "..", "assets", "hud")

# (source relative to Skins, output stem) - whole bitmaps
WHOLE = [
    ("white/Form_TradeItem_1.bmp", "form_trade_item_1"),
    ("white/Form_TradePet_1.bmp", "form_trade_pet_1"),
    ("white/Form_itemBank_1.bmp", "form_item_bank_1"),
    ("white/Form_Repair.bmp", "form_repair"),
    ("default/panel_restrainBank_1.bmp", "panel_restrain_bank_1"),
    ("default/icon_trade_1.bmp", "icon_trade_1"),
    ("default/icon_Confirm_1.bmp", "icon_confirm_1"),
    ("default/Icon_PetInCage.bmp", "icon_pet_in_cage"),
    ("default/Item_Block.bmp", "item_block"),
]

# 3-frame button sheets
SHEETS = [
    ("default/Btn_confirm_1.bmp", "btn_confirm_1"),
    ("default/Btn_Trade_2.bmp", "btn_trade_2"),
    ("default/Btn_Cancel_1.bmp", "btn_cancel_1"),
    ("default/Btn_ArrowL_5.bmp", "btn_arrow_l_5"),
    ("default/Btn_ArrowR_5.bmp", "btn_arrow_r_5"),
    ("default/Btn_OK_2.bmp", "btn_ok_2"),
    ("default/Btn_Cancel_3.bmp", "btn_cancel_3"),
    ("default/btn_close_1.bmp", "btn_close_1"),
]
FRAMES = ("normal", "hover", "pressed")


def keyed(path: str) -> Image.Image:
    im = Image.open(path).convert("RGBA")
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, _a = px[x, y]
            if r == 0 and g == 255 and b == 0:
                px[x, y] = (0, 0, 0, 0)
    return im


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    for src, stem in WHOLE:
        im = keyed(os.path.join(SKINS, src))
        im.save(os.path.join(OUT, stem + ".png"))
        print(stem, im.size)
    for src, stem in SHEETS:
        im = keyed(os.path.join(SKINS, src))
        fh = im.height // 3
        for i, frame in enumerate(FRAMES):
            dst = os.path.join(OUT, "%s_%s.png" % (stem, frame))
            if os.path.exists(dst):  # shared with other windows (btn_close_1, btn_cancel_1): keep
                continue
            part = im.crop((0, fh * i, im.width, fh * (i + 1)))
            part.save(dst)
        print(stem, (im.width, fh), "x3")


if __name__ == "__main__":
    main()
