# World map window (TGlobaForm / TMagicMap)

Godot: `scripts/ui/hud/world_map_window.gd`, `scenes/ui/hud/world_map_window.tscn`, test `tests/test_world_map_window.gd`.

## Which form is "Form_World"
- The string `Form_World` in the exe is the tail of the class name `CH_TMiniMapForm_World` (VMT 0x3247f0, created at
  0x16084f, constructor 0x327f9c, which only builds 4 buttons). That is a minimap variant, **not** the world map.
- The world map is **TGlobaForm** (VMT 0x13a408, constructor **0x13f5d8**, created in the main form init 0x15bee0 at
  0x15e8a5, instance stored through 0x4c9350). The magic-map item variant is **TMagicMap** (VMT 0x20ff38, constructor
  **0x22193c**, created at 0x15e5fd). Class names come from VMT-0x2c.

## Controls (verified, constructor 0x13f5d8)
Button Init is the virtual `[vmt+8]`: `edx` = bitmap name, `ecx` = left, stack = top, width, height, 1, 0, 0, w, h.

| control | left | top | w x h |
|---|---|---|---|
| form `GlobaMap` | 30 | 30 | 667 x 538 (0x29b x 0x21a) |
| `Btn_Close_s_3` | W-20 = 647 | 3 | 18 x 18 |
| `GlobaBtn` x41 | Round(x/sx)+146 | Round(y/sy)+17 | 18 x 17 |

- `sx = 12000.0 / (W - 167)`, `sy = 12000.0 / (H - 38)` (float 12000.0 at 0x13f8c8) -> both 24.
- Marker table **0x4b8944**, 28-byte records `{x, y, hidden, hint_x, hint_y, med_sea, 0}`, 41 entries; names from the
  pointer table **0x4b8880** (record i uses name i-1). If `hidden != 0` the button is hidden (all 0 in this build).
- Hint = `name + " " + "(" + ("Med. Sea" if med_sea==1) + hint_x + "," + hint_y + ")"` (LStrCatN with 9 parts), e.g.
  `Rome (Med. Sea2635,2242)` - no space after "Med. Sea" in the literal.
- TGlobaForm sets no OnClick on markers (hints only). TMagicMap uses table **0x4bbf10** / names **0x4bbe50** (40 entries,
  adds "Small Hawaii", "Lost Jungle", "Chang'an"; drops the fleets, Avignon...). Its use-checks ("Unable in party",
  "Item locked, can't use", ...) follow the constructor at 0x221d35.. (not reconstructed).

## Assets (`assets/hud/`)
`world_globa_map.png` (white skin GlobaMap.bmp keyed), `world_globa_btn_{normal,hover}.png` (2 frames 18x17),
`world_btn_close_s_3_{normal,hover,pressed}.png`.

## Godot behaviour (additions, not from the binary)
- Clicking a marker emits `location_selected(index, location)`; in magic-map mode also `teleport_requested`.
- Window is draggable by its background.
