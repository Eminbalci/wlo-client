# Form_PlayerTitle (title picker)

Godot: `scripts/ui/hud/player_title_window.gd`, `scenes/ui/hud/player_title_window.tscn`,
test `tests/test_player_title_window.gd`. The skin-load call signature is described in `pet_status_window.md`.

## Skins
- `white/Form_PlayerTitle.bmp` 250x275: title "title" and five baked blue rows at y 66,96,126,156,186 (26 high), x 17..229.
- From default: `Btn_Apply1`/`Btn_apply2` (56x60, 3 states each), `Btn_ArrowL_8`/`Btn_ArrowR_8` (21x63),
  `Btn_Close_2` (39x60), `Num_MainInfo` (11x120 = 12 glyphs of 10 px: 0-9, %, /).
- Sliced: `assets/hud/form_player_title.png`, `btn_apply_1_*`, `btn_apply_2_*`, `btn_arrow_l_8_*`, `btn_arrow_r_8_*`,
  `btn_close_2_*`, `num_main_info.png`. The title pictures `default/title_1..6.bmp` became `title_pic_1..6.png`.

## Constructor 0x2beb38
| control | skin | Left,Top | size | notes |
|---|---|---|---|---|
| form | Form_PlayerTitle | 150,100 (screen) | 250x275 | page `[+0x170]` = 1, count `[+0x16c]` = 0 |
| close | btn_close_s_1 | 200,26 | 18x18 | hint [ESC] |
| apply 1..5 | Btn_Apply1 | 165, 70+30*(i-1) | 56x20 | tag i, OnClick 0x2bef84 |
| arrow left | Btn_ArrowL_8 | 85,219 | 21x21 | OnClick 0x2bf2c4 |
| arrow right | Btn_ArrowR_8 | 144,219 | 21x21 | OnClick 0x2bf2dc |
| bottom close | Btn_Close_2 | 105,246 | Load says 56x20, but the bitmap is 39 wide | hint [ESC]; Godot uses 39x20, centred at 124.5 (window centre 125) |

`Btn_Apply2` is loaded into `[+0x17c]` beside `Btn_Apply1` `[+0x178]`. 0x2bf540 (called after each Apply) probably
swaps the applied row to Apply2. **Guess:** Godot shows Apply2 on the applied row.

## Behaviour
- Show 0x2bef30: the arrows are enabled only when count > 5 (then 0x2beff0 draws the page number).
- Painter 0x2bf308: for the rows of the current page, the title id is the byte `[+0x130][index]` with index from
  (page-1)*5+1. The name comes from 0x16f3f4 on the object at global 0x4c95dc (presumably the PlayerTitleData table).
  It is drawn at (22, 73 + 30*row) with colour $FFFF (white) and style argument 2 (**guess:** outlined).
  Index 0 of the list is therefore not shown; Godot treats it as "no title".
- Apply 0x2bef84: idx = (page-1)*5 + tag. If idx == selected `[+0x174]`, selected = 0, else selected = idx. Then it
  refreshes (0x2bf540) and calls 0x2d6ad8(dl=10, cl=5) with the title-id string, probably the packet (**not
  decoded**).
- Page number 0x2beff0: `Num_MainInfo` glyphs (cell height = height/11 = 10) at (103,225). A two-digit page starts at
  120 - glyph width.

## Data
`data/PlayerTitleData.txt` (also `assets/data/PlayerTitleData.txt`): `id,kind,name` in Big5. It has 7 entries:
0 `text` (無稱號 "no title") and 1..6 `pic` (holy-night titles, "perfect lover", "super player"). Godot reads only
the ASCII id and kind. The English names in `TITLE_GLOSSES` are **our translations**, not client text. Pic titles
draw `title_pic_<id>.png`. Skins title_27..49 exist with no data rows; they are not sliced.

## Open
- The Apply packet and the server reply.
- What fills the title list: no setter of `[+0x130]` was traced.
- The handlers of the system window's "Set Own Title" entry.
