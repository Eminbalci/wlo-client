# Repair window (Form_Repair)

aLogin.exe, constructor **0x1ac9f0**; skin `menu/Skins/white/Form_Repair.bmp` 171x183 ("REPAIR" baked in). The skin loader
0x15bee0 probes `menu\skins\default\Form_Repair.bmp` to decide the skin folder (default has none, so white is used — inferred).

## Controls (decoded)
| control | rect |
|---|---|
| form | ctor (200,30), 175x183 |
| Btn_OK_2 [0x130] → 0x1b14cc | (37,142) 39x20 |
| Btn_Cancel_3 [0x134] → 0x1b14c4 | (93,142) 39x20 |
| item cell "SelectUitem" [0x138] (slot class 0x368af4) → 0x1b13d8 | (70,71) 32x32 |
No close sphere.

## Behaviour (decoded)
- 0x1b1814 copies a bag cell (icon, id `+0xdc`, flags `+0xe6/+0xe7`, …) into the repair cell; the bag cell is marked state 0xb.
- Cancel 0x1b142c: clears the cell, un-marks the bag cells, closes.
- OK 0x1b14cc:
  1. nothing selected → return;
  2. player in battle (`[player+0x1f16]`) → "Can't fix in battle";
  3. bag cell flag `+0xe6` == 0 → return (**guess:** "is repairable equipment");
  4. item id in {10062, 11098, 12069, 13064, 14063, 15051, 17066, 18062, 19055, 20039, 21120, 22125, 23105, 24090, 25044}
     → return silently. Looked up in Item.dat: Broken Knife, Broken Sword, Broken Halberd, Broken Bow, Broken Wand, Broken Claws,
     Broken Ax, Broken Gavel, Broken Fan, Broken Gun, Broken Clothes, Broken Hairwear, Broken Cuffs, Broken Shoes, Broken Adornment;
  5. send **action 0x17 sub 0x54**, message `<item name> + "Repaired"` (0x1b1758), play `sound\wav0152.wav`, clear the cell.
- The client shows no cost and no durability numbers here; cost/durability changes come from the server (action 0x17 handler
  0x2f9ee5, not decoded). "Doesn't need repairs" / "Only for Vehicles" live in 0x1dace8 (repair items, not this form).

## Godot (`scripts/ui/repair/repair_window.gd`)
- Durability: item dict `durability`/`max_durability`, else the ItemDatabase record (`ItemRecord.durability/max_durability`; note those
  are currently the default 50/50, not decoded from Item.dat).
- Equipment = non-empty `equip_slot` or record `equip_pos` 1..6. Full items → "Doesn't need repairs" (our choice; client is silent).
- `cost_per_point` (default 0) is a placeholder: the real price is server side.
- Test: `tests/test_repair_window.gd` (19 checks).
