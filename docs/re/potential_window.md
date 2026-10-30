# Form_Potential_1 / Form_Potential_2 (Potential awaken / Potential Return)

Godot: `scripts/ui/hud/potential_window.gd` (one class, `MODE_AWAKEN` = 1, `MODE_RETURN` = 2),
`scenes/ui/hud/potential_window.tscn`, test `tests/test_potential_window.gd`.
The skin-load call signature is described in `pet_status_window.md`.

## Skins (white set; buttons from default)
- `Form_Potential_1.bmp` 299x520 (title "Potential"; the baked help text is about the Potential Pill).
- `Form_Potential_2.bmp` 299x460 (title "Potential Return"; the baked red text says potential is reset to 0).
- Sliced and keyed: `assets/hud/form_potential_1.png`, `form_potential_2.png`, `icon_potential_mark_1.png` (21x21).
  The OK and Cancel buttons reuse the existing `btn_ok_1_*` and `btn_cancel_1_*`.
- `PotentialFire1` and `PotentialFire2` are loaded by name (0x47c044 then 0x47885c), but no file with those names
  exists in `menu/Skins`. They probably live in a .Bmg archive. **Not sliced; the fire animation is not built.**

## Constructors 0x1e4d48 (awaken) / 0x1e7b48 (return)
| control | awaken | return | notes |
|---|---|---|---|
| Btn_Close_s_1 | 249,26 18x18 | same | hint "[ESC]", OnClick = form vmt+0x24 (close) |
| btn_ok_1 | 87,473 56x20 | 87,414 | OnClick 0x1e68b8 (awaken) |
| Btn_Cancel_1 | 163,473 56x20 | 163,414 | hint "[ESC]" |
| team rows (class at 0x277d5c) | 5 at (32, 78+34*i) | 4 at the same | Point(10,2), Point(0,0) set at +0x1ac/+0x1b4 (meaning unknown) |
| list control (0x47f2f4) | SetBounds(32,79,233,168) | same | colour $F5BF89; 0x48cbc0(33) is probably the row height (**guess**); owner-draw 0x1e7674 |
| item slot (0x368af4) | 56,366 30x30 | 74,328 | item 0x85DD = **34269** (presumably the Potential Pill / Return Pill; the item name was not checked in Item.dat) |
| 12 marks (top-left of the 21x21 Icon_PotentialMark_1) | (201,259) (230,277) (245,305) (245,337) (230,367) (201,385) (167,385) (138,367) (123,337) (123,305) (138,277) (167,259) | each awaken mark +(6,-38) | verified against the faint circles baked in the skins |
| other images | Icon_Up_1, Icon_Down_1, icon_Confirm_1 | same | where they are used was not traced |

## Painters
- Row painter (0x1e5b06, awaken): the player name is drawn at row + (`[+0x154]`, `[+0x158]`) = Point(38,8).
  The level (`player+0x1f98`) is right-aligned at row.x + 38 + 127 = 165. `"/" + "12"` is right-aligned at
  row.x + 38 + 113 + 77 = 228. The potential (`player+0x1f9a`) is drawn just left of it in colour $F800 (red); the other
  text is $0841. The avatar is drawn at row.x + 16, row.y - 3. The maximum potential is the literal 12.
- Stat painter (awaken 0x1e6718): the 5 values (`[+0x1f8 + i*8]`) are drawn at (60, 274 + 16*i). `"+" + N` is drawn
  at x 86 in red. N comes from a word table at global 0x4c8778 indexed by `[+0x1f0]`.
- Stat painter (return ~0x1e8ae6): values at (66, 236 + 16*i); `"-" + N` at x 92 in $001F (blue).
- Colours are RGB565 words: $0841 is nearly black, $F800 red, $001F blue.

## OK handler messages (strings of 0x1e68b8; the order of the checks was not decoded)
"Not for mercenaries", "Reached max potential", "Potential is below 10!", "Failure will forget skill, sure?",
"Will make pet non-tradeable", "Confirm use". The return form's messages are at 0x1e8c9c: "No potential on this",
"Free 1 inventory slot to use", "Factory Reset Potential". "Can't use here" appears in both.
Godot implements only: mercenary refusal, max (12) refusal for awaken, and potential 0 refusal for return.
**Partial.** The confirm dialogs and the inventory check are not modelled.

## Open
- Which value "Potential is below 10!" checks.
- What the server packet is.
- How marks are lit. Godot shows N marks for potential N. **Guess:** the client probably lights them with the fire
  animation.
