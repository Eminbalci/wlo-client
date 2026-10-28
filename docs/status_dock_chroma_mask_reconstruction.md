# Authentic Top-Left Status Dock Chroma Mask Reconstruction

## Overview
This document details the architecture and implementation of the authentic 1:1 top-left player status dock (`PlayerStatusDock`) in the Wonderland Online Godot 4 client.
The implementation resolves the visual conflict where horizontal bars previously overlapped the gold vine framework by introducing a 3-layer chroma/mask composite architecture and vertical stat readout underneath the frame, exactly matching the authentic Wonderland Online interface (`video_frames/frame_01s.png`).

---

## Architecture & Layer Hierarchy

`PlayerStatusDock` (`res://scenes/ui/hud.tscn`) is anchored at $(X=0, Y=0)$ with bounds $(241 \times 185)$ and contains the following layered node hierarchy (ordered from back to front):

```
PlayerStatusDock (Control, 241x185, mouse_filter=IGNORE)
├── AvatarRect (TextureRect, pos=(22, 0), size=(92, 92), Betty Role 2 bust portrait)
├── ElementIcon (TextureRect, pos=(107, 7), size=(25, 25), Wind/Fire/Water/Earth orb)
├── HpChannelUnder (TextureRect, pos=(32, 37), size=(93, 38), dark HP empty groove)
├── SpChannelUnder (TextureRect, pos=(21, 38), size=(110, 47), dark SP empty groove)
├── HpBar (TextureProgressBar, pos=(32, 37), size=(93, 38), fill_mode=LEFT_TO_RIGHT)
├── SpBar (TextureProgressBar, pos=(21, 38), size=(110, 47), fill_mode=LEFT_TO_RIGHT)
├── StatusBackground (TextureRect, pos=(0, 0), size=(241, 116), gold vine bevel frame)
├── NameLabel (Label, hidden placeholder for API stability)
├── LevelLabel (Label, pos=(6, 8), size=(54, 16), text="LV <N>")
├── HpLabel (Label, pos=(8, 112), size=(112, 16), text="HP   <hp>/<max_hp>")
├── SpLabel (Label, pos=(8, 128), size=(112, 16), text="SP   <sp>/<max_sp>")
├── ExpTitleLabel (Label, pos=(8, 144), size=(28, 16), text="EXP")
├── ExpBar (TextureProgressBar, pos=(38, 148), size=(47, 8), fill_mode=LEFT_TO_RIGHT)
├── ExpLabel (Label, pos=(89, 144), size=(41, 16), text="<pct>%")
└── GoldLabel (Label, pos=(8, 160), size=(112, 16), text="Gold <amount>")
```

---

## 3-Layer Chroma/Mask Composite Mechanism

1. **Layer 1: Backplates & Avatar**
   - `AvatarRect`: Displays Betty (Role 2) cropped head bust (`res://assets/hud/betty_avatar.png`, $92 \times 92$), positioned so that her face center aligns at $(X=68, Y=45)$ directly inside the gold oval aperture.
   - `HpChannelUnder` & `SpChannelUnder`: Dark channel textures (`hud_bar_hp_under.png`, $93 \times 38$ and `hud_bar_sp_under.png`, $110 \times 47$) that render the empty, unlit channel groove when HP or SP is depleted.

2. **Layer 2: Progress Bars (TextureProgressBar)**
   - `HpBar`: `TextureProgressBar` using `Main_Hp.png` ($93 \times 38$, RGB $\approx [250, 92, 53]$) with `fill_mode = FILL_LEFT_TO_RIGHT`. Clamped to $[0, \text{max\_hp}]$, scaling progress smoothly from left to right along the curved channel.
   - `SpBar`: `TextureProgressBar` using `Main_Sp.png` ($110 \times 47$, RGB $\approx [103, 154, 216]$) with `fill_mode = FILL_LEFT_TO_RIGHT`. Clamped to $[0, \text{max\_sp}]$, scaling progress smoothly from left to right along the outer curved channel.
   - `ExpBar`: `TextureProgressBar` ($47 \times 8$) using `main_exp_under.png` as background and `main_exp.png` ($47 \times 8$) as progress fill.

3. **Layer 3: Top Gold Bevel Frame Overlay**
   - `StatusBackground`: Full-resolution $241 \times 116$ RGBA texture (`hud_status_frame_transparent_channels.png`) featuring the gold vine framework, element ring, and circular badges ("HP", "SP"). The head oval and HP/SP channels are transparent ($A=0$), allowing Layers 1 & 2 to show through with the gold vines beveling cleanly over the channel boundaries.

---

## Vertical Stat Readout (Under Gold Frame)

Located underneath the $241 \times 116$ gold frame, beginning at $Y=112$:
- **HP readout** ($Y=112$): White text with black shadow ($1\text{px}$) and black outline ($2\text{px}$), formatted as `HP   <hp>/<max_hp>` (e.g., `HP   320/320`).
- **SP readout** ($Y=128$): Formatted as `SP   <sp>/<max_sp>` (e.g., `SP   150/150`).
- **EXP readout** ($Y=144$): Formatted with title `EXP`, $47 \times 8$ green bar `ExpBar` at $X=38, Y=148$, and percentage `ExpLabel` at $X=89$ (e.g., `45%`).
- **Gold readout** ($Y=160$): Formatted as `Gold <amount>` (e.g., `Gold 500`).

---

## Public Methods in `hud.gd`

### `set_player_stats`
```gdscript
func set_player_stats(p_name: String, p_lvl: int, p_hp: int, p_max_hp: int, p_sp: int, p_max_sp: int, p_exp: float) -> void
```
- **Parameters**:
  - `p_name` (`String`): Player character name.
  - `p_lvl` (`int`): Current level. Updates `LevelLabel` to `"LV %d" % p_lvl`.
  - `p_hp` (`int`): Current HP. Updates `HpLabel` to `"HP   %d/%d"` and `HpBar.value`.
  - `p_max_hp` (`int`): Maximum HP. Updates `HpBar.max_value`.
  - `p_sp` (`int`): Current SP. Updates `SpLabel` to `"SP   %d/%d"` and `SpBar.value`.
  - `p_max_sp` (`int`): Maximum SP. Updates `SpBar.max_value`.
  - `p_exp` (`float`): Current EXP percentage $[0.0, 100.0]$. Updates `ExpLabel` to `"%d%%"` and `ExpBar.value`.
- **Return Type**: `void`
- **Edge Cases**:
  - Zero or negative `p_max_hp` or `p_max_sp` handled by clamping `max_value` to $\ge 1$.
  - Missing or null node references guarded via null checks.

### `update_player_stats`
```gdscript
func update_player_stats(p_name: String, p_lvl: int, p_hp: int, p_max_hp: int, p_sp: int, p_max_sp: int, p_exp: int, p_max_exp: int = 100) -> void
```
- **Parameters**: Takes integer EXP and max EXP, computes percentage safely avoiding division-by-zero, and delegates to `set_player_stats`.
- **Return Type**: `void`

### `update_gold`
```gdscript
func update_gold(amount: int) -> void
```
- **Parameters**: `amount` (`int`): Current gold currency. Updates both `CharacterWindow/GoldLabel` (`"Gold: %d"`) and `PlayerStatusDock/GoldLabel` (`"Gold %d"`).
- **Return Type**: `void`

### `set_player_element`
```gdscript
func set_player_element(element_name: String) -> void
```
- **Parameters**: `element_name` (`String`): Case-insensitive element name (`"Fire"`, `"Water"`, `"Earth"`, `"Wind"`).
- **Behavior**: Maps to `icon_element_1.png` (Fire), `icon_element_2.png` (Water), `icon_element_3.png` (Earth), or `icon_element_4.png` (Wind) and assigns to `ElementIcon.texture`.

---

## Verification & Parity Evidence
- Verified via `scenes/tests/test_hud_runner.tscn` executing through `godot_console.exe`.
- Engine screenshot captured to `tests/test_hud_runner_screenshot.png` ($800 \times 600$).
- Compared side-by-side with original video reference (`video_frames/frame_01s.png`):
  - `LV 7` vs `LV 10` level typography, offset, and stroke match identically.
  - Head oval positioning confirms Betty Role 2 is centered at $(X=68, Y=45)$ behind vines.
  - HP and SP curved bars align with the transparent cutouts and bevels.
  - EXP bar and vertical readouts match authentic game positioning.
