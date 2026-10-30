# Warehouse / item bank (Form_Warehouse, Form_itemBank_1)

aLogin.exe, see trade_window.md for the control-constructor convention (x in ECX, then y, w, h).

## Form_Warehouse — constructor 0x24d880 (legacy, **no skin ships**)
`Form_Warehouse.bmp`, `btn_Bank_Gold_R`, `btn_Bank_Gold_L` exist in neither install nor in the BMg archives. Decoded layout only:
- form 441x299; two 50-cell grids 5 per row, pitch 36: left (22+36c, 61+36r), right (242+36c, 61+36r); slot type 8 / 9.
- Btn_Close_s_1 (w-23, 5) 17x17; Btn_Close_1 centred `x=(w-66)/2+1, y=h-44` 25x70, hint [ESC].
- btn_Bank_Gold_R (207,180) 22x27 → 0x24dc50; btn_Bank_Gold_L (206,99) 22x27 → 0x24dd0c (gold in/out, **guess**).

## Form_itemBank_1 — constructor 0x1f8850 (the bank the live client shows) → `scripts/ui/warehouse/warehouse_window.gd`
Skin `white/Form_itemBank_1.bmp` 416x481 (ctor pushes 421x481), centred. Baked captions: "bank", "store items", "items held",
and the two arrows.
| control | rect (decoded) |
|---|---|
| bag cells (own inventory) [esi+0xe8+i], 10x5 | (224+34c, 83+34r) 32x32 |
| bank cells [esi+0x1c0+i], 10x5 (click 0x1f9128 / 0x1f8ee4 / 0x1f91bc) | (20+34c, 83+34r) 32x32 |
| panel_restrainBank_1 (hidden) | (20,254) 168x168 |
| Btn_ArrowL_5 → 0x1f9758 | (199,247) 17x17 |
| Btn_ArrowR_5 → 0x1f987c | (200,200) 17x17 |
| Btn_Close_s_1 | (365,25) 18x18 |
| Btn_Close_1 | (179,437) 56x20 |
Handlers (decoded):
- ArrowL 0x1f9758: list of selected bag cells (0x1f96e8); none → "Select item on right side"; else `[0x309]=1`, send **0x1E sub 2**.
- ArrowR 0x1f987c: ignored while a request is pending (`[0x308]`/`[0x309]`); list of selected bank cells (flags `[esi+0x2bf+i]`, i=1..50,
  0x1f980c); none → "Select item on left side" + "No items selected"; else `[0x308]=1`, send **0x1E sub 1**.
- So a cell click toggles a selection flag (multi-select). "Remove contents first!" and "BankItem" appear in nearby handlers
  (not decoded). Meaning deposit = sub 2 / withdraw = sub 1 is **inferred** from which grid each arrow reads.

## Godot
- Stored items persist in `user://warehouse.json` (`{"version":1,"slots":[50 dicts]}`), path configurable via `setup(inv, path)`.
- Consumables stack; items with `durability` or an equip slot keep one cell each.
- Gold banking (Form_BankMoney_1, 0x2ce584) not rebuilt.
- Test: `tests/test_warehouse_window.gd` (21 checks).
