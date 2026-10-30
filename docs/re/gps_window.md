# GPS window (TGPSForm)

Godot: `scripts/ui/hud/gps_window.gd`, `scenes/ui/hud/gps_window.tscn`, test `tests/test_gps_window.gd`.

The original "GPS" is a **save-point / recall device**, not a live coordinate readout: it shows a stored map + X/Y and
can teleport there.

## Addresses (verified)
- Class TGPSForm, VMT 0x13a304, constructor **0x13df70** (created at 0x15e87d, instance via 0x4c895c).
- Show(mode) 0x13e3dc, Paint **0x13eaec**, ArrowL 0x13eda0, ArrowR 0x13ee0c, button refresh 0x13ee78,
  SetPoint click 0x13e448 ("Can't use now", "Can't save here", "Vehicle in use, can't use", then confirm dialog
  "Confirm Save Point here?" -> 0x13e378), Transmi click 0x13e694 (checks: "Can't teleport", "Unavailable in event",
  "Stall is being used", "Can't do from a transport", "Currently fishing", "Can't do when collecting",
  "Can't do in trading", "Can't do in team").

## Controls (constructor 0x13df70)
| control | left | top | w x h |
|---|---|---|---|
| form `Form_GPS` | 290 | 200 | 223 x 223 |
| `Btn_Close_s_1` | W-50 = 173 | 25 | 17 x 17 |
| `Btn_SetPoint` | 82 | 120 | 56 x 20 |
| `Btn_Transmi` | 82 | 145 | 56 x 20 |
| `btn_close_1` | 82 | 170 | 56 x 20 |
| `Btn_ArrowL_7` | 22 | 80 | 14 x 13 |
| `Btn_ArrowR_7` | 188 | 80 | 14 x 13 |

## Paint 0x13eaec
- Slot byte `+0x14b`; record = 6 bytes at player struct `+0x2358 + slot*6`: word map_id, word x (`+0x235a`), word y (`+0x235c`).
- Map name: SceneData record (0x83 = 131 bytes, Pascal string at +8, same as `SceneDatabase` record size), drawn at
  `x = W/2 - (len/2)*8`, `y = top + 70`.
- `"X："+x` at (40, 90), `"Y："+y` at (120, 90) (Big5 full-width colon). Text routine 0x4a33a8, colour arg 0xFFE0 (RGB565
  yellow - which argument is the colour is inferred, not proven).
- Empty slot: Big5 "無紀錄場景" ("no recorded scene") centred at y=70.
- Arrows: only for item ids 0x8593 / 0x8645 (34195 / 34373). Left decrements while slot >= 2, right increments while
  slot - 1 <= 3, i.e. slots 1..5 (5-slot GPS). Otherwise slot is forced to 1.

## Assets
`gps_form.png`, `gps_btn_set_point_*`, `gps_btn_transmi_*`, `gps_btn_close_*`, `gps_btn_arrow_l_*`, `gps_btn_arrow_r_*`,
`skin_btn_close_s_1_*`.

## Godot simplifications / guesses
- The modal confirm dialog is replaced by "press Save Point twice" (inline hint label).
- Map name falls back to `GameDatabase.scenes.get_scene(map_id).name`. Text positions are approximated with Labels.
- Offline persistence: `user://gps_points.json`. Teleport is only signalled (`teleport_requested`); the move checks above are
  not reproduced.
- `Icon_GPS` (function 0x32e034, with `panel17` and 8-direction `Btn_Arrow_n*`) belongs to another UI (not examined).
