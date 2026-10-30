# Form_PetStatus (pet Rest / Battle / Ride popup)

Godot: `scripts/ui/hud/pet_status_window.gd`, `scenes/ui/hud/pet_status_window.tscn`,
test `tests/test_pet_status_window.gd`.

Disassembled with capstone (`d2.py` plus a helper that annotates Delphi string literals). VA = image base 0x10000.

## Skin
- `menu/Skins/white/Form_PetStatus.bmp`, 49x65. It is not in the default set: buttons load from `default/`,
  forms from `white/`. The bitmap has no green key pixels; it is a plain lined panel.
- Sliced to `assets/hud/form_pet_status.png`. The buttons reuse the existing
  `assets/hud/btn_assign_{rest,fight,ride}_{normal,hover,pressed}.png` (43x20 frames of 43x60 sheets).

## Skin-load call (applies to all three windows)
`TSe_FixedButton` VMT 0x47f63c, slot +8 = 0x4805c0 = `Load(Name: edx, Left: ecx, Top, Width, Height,
UseSrcRect, SrcX, SrcY, SrcW, SrcH)`. The stack args are pushed left to right (`ret 0x20`). It stores Left at +0x18,
Top +0x1c, Width +0x20 and Height +0x24. **Verified:** the placement code below writes Left/Top through the
same +0x18/+0x1c fields. Button sheets are drawn with Height = bitmap height / 3 (3 stacked states).

## Constructor 0x327a20 (called once from 0x15fb3d; instance stored in global 0x4c9574)
| control | skin | Left,Top | size | hint (0x480ae4) |
|---|---|---|---|---|
| form | Form_PetStatus | 0,0 | bitmap size | - |
| button 1 (tag 1) | Btn_AssignRest_1 | 3,3 | 43x20 | "Rest" |
| button 2 (tag 2) | Btn_AssignFight_1 | 3,22 | 43x20 | "Battle" |
| button 3 (tag 3) | Btn_AssignRide_1 | 3,42 | 43x20 | "Ride" |

The buttons are created in a loop (esi = 1..3, `[edi+esi*4+0x134]`). Each gets tag `[+0xb0]` = esi and OnClick
`[+0x70]` = 0x327d9c. A fourth object is created at `[+0x134]` (index 0) with no skin; its purpose is **unknown**.
`Label11p` is listed for this function in alogin_functions.md, but no use of it was found in the constructor.

## OnClick 0x327d9c
- The owner is the form at global 0x4c887c. It is created by 0x284c14, the function that uses `Btn_AssignLeave_1`,
  `Icon_Career`, `icon_offline_1`: that is the **team form** (Form_Team_2). The slot is byte `[self+0x131]`.
- Refusal 1: "Can't replace, pet in training". Shown when two ids at `[0x4c9900]+4` and `[0x4c9918]+4` are equal and the
  team entry chosen by `[player+0x20ee]` has template `[+0xe8]` 0x98c1 (39105) or 0x98bc (39100). **The meaning of
  these ids is a guess** (event or training pets).
- Refusal 2: "Can't mount" (tag 3 only). Shown when word `[player+0x235c]` == 0x2765 (10085). **This is a guess:**
  0x235c may be a map id.
- Otherwise it writes `team[+0xd20+slot]` = 0 (Rest) / 1 (Battle) / 2 (Ride), calls 0x291828(team, slot) (it checks
  slot 1..4 and probably sends the change; **not decoded further**), then calls `self.vmt[+0x24]` (hide, by analogy
  with the other forms).

## Placement 0x327f50 (virtual, probably Show)
`Left = team.Left + 0xf7 - 3` (= +244), `Top = team.Top + 0x4d - self.Height + (slot-1)*0x22` (= +77-65+34*(slot-1)).
So the popup sits just right of the team window's pet row `slot`. Godot: `PetStatusWindow.popup_position()`.

## Godot mapping
`pet_mode_selected(slot, mode, pet)`: mode 0/1/2 as in the original. `team_action_for_mode()` maps 0/1/2 to
TeamWindow `_on_pet_row_button` actions `"dismiss"`/`"battle"`/`"ride"`.
