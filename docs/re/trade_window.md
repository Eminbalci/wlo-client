# Trade windows (Form_Trade, Form_TradeItem_1, Form_TradePet_1)

aLogin.exe (image base 0x10000, sha 959659ae). Disassembled with capstone (`d2.py`); strings resolved from the Delphi
length-prefixed literals. Evidence levels: **decoded** = read from the code, **guess** = inferred.

## Control constructor convention (decoded)
Every skin control is built by `call [vmt+8]` with `EAX=self, EDX=skin name, ECX=x`, then pushed `y, w, h, 1, 0, 0, w', h'`.
Verified on Form_Repair (pushes 175x183, skin 171x183), Form_TradePet_1 (463x455 = skin), Btn_OK_2 (39x20 frame of a 39x60 sheet),
Btn_Close_s_1 (17/18 px). Forms that centre themselves compute `x = (screen.w - w)/2`, `y = (screen.h - h)/2` (`[edi+0x38]/[edi+0x3c]`).
Classes: button VMT `[0x47f5f0]` (ctor 0x485788), label/edit `[0x47f6d4]` (ctor 0x4828a0), item slot `[0x368af4]` (ctor 0x371074),
picture `[0x3ed944]`. `0x480670(dl)` = SetVisible. `0x2d6ad8(dl=action, cl=sub)` = send packet.

## Form_Trade — constructor 0x333e30 (legacy, **no skin ships**)
`Form_Trade.bmp` is not in `menu/Skins/{default,white}` nor in any `pic/*.BMg` (checked both D:\GitHub\WLRI and C:\Games\WLRI),
and the button skins `btn_BothOk`, `btn_Trade`, `btn_Cancel` are missing too, so this form cannot render in the live client.
Not rebuilt; layout kept here for reference (all decoded):
- form 418x321 (ctor default position 360,450); drag/title area call `[vmt+0x70](0x40,0x26,0xe,0x2c)`.
- Btn_Close_s_1 at (w-20, 5) 17x17, hint `[ESC]`.
- two 50-slot grids, 5 per row, 36 px pitch, 32x32 image: left x=20+36c, right x=223+36c, y=60+36r (only 5 rows fit above the
  gold labels, the rest presumably hidden/paged — guess).
- name labels (20,35) and (220,35) 160x20; gold labels (45,242) and (248,242) 128x24.
- buttons y=281, 70x25: btn_BothOk x=79, btn_Trade x=177, btn_Cancel x=275.
- handler strings: "Not enough Gold", "Close Stall first", "Can trade only in Guild", "Unable to trade", "Already changed".

## Form_TradeItem_1 — constructor 0x37f744 (the live item trade) → `scripts/ui/trade/trade_window.gd`
Skin `white/Form_TradeItem_1.bmp` 401x481, centred. Captions baked: "Trade props", "money earned", "money paid".
| control | field | rect (decoded) |
|---|---|---|
| bag grid (own inventory, pre-made cells) | [esi+0xe8+i*4], 10 rows x 5 | (206+34c, 68+34r) 32x32 |
| OtherSafeTradeItem | [esi+0x1c0+i*4], 4x5 | (24+34c, 69+34r) 32x32 |
| MySafeTradeItem (click 0x381044 / 0x381468) | [esi+0x3dc+i*4], 4x5 | (24+34c, 250+34r) 32x32 |
| partner name label | [0x474] | (92,43) 160x20 |
| money earned (partner gold) | [0x478] | (92,213) 100x24, text "0" |
| money paid (my gold, editable, max len 9, onchange 0x3818d4) | [0x47c] | (92,390) 100x24, text "0" |
| Btn_ArrowL_5 / Btn_ArrowR_5 (hidden) | [0x430]/[0x434] | (200,335) / (201,288) 17x17 |
| Btn_Close_s_1 → 0x381c98 | [0x43c] | (352,25) 18x18 |
| Btn_Cancel_1 → 0x381c98 | [0x438] | (250,445) 56x20 |
| Btn_Trade_2 (hidden at start) → 0x381e9c | [0x440] | (174,445) 56x20 |
| icon_trade_1 (picture) | [0x444] | (174,445) 56x20 |
| Btn_confirm_1 → 0x381f90 | [0x448] | (100,445) 56x20 |
| icon_Confirm_1 (picture) | [0x44c] | (100,445) 56x20 |
Also loads Num_Vip_1 / Num_SVip_1 / Num_VVip_1 (VIP badges, not rebuilt).

Handlers (decoded):
- Cancel/close 0x381c98: send **0x19 sub 3**, `[0x48c]=2`, clear name, gold texts back to "0", Confirm visible, Trade hidden.
- Confirm 0x381f90: empty entry → "0"; entry > player gold (`[player+0x3ab8]`) → "Not enough Gold"; collects offered slot ids,
  marks those bag cells state 2, send **0x19 sub 2**, `[0x480]=1`, hide Confirm (the greyed icon_Confirm_1 stays).
- Trade (~0x381ecb): `0x381948` capacity check, else "Inventory full, can't trade"; `[0x48c]=1`; send **0x19 sub 3**; hide Confirm
  and Trade; clears the offer index tables. So sub 3 carries the state byte 1 (accept) / 2 (cancel) — **guess** (the byte is set
  right before the send, the packet builder was not read).
- **Guess:** Btn_Trade_2 becomes visible when the server reports that both sides confirmed (incoming action 0x19 handler 0x2fd719,
  strings "Can't trade, player is below LV25", "Player online time too short"; not decoded further).

## Form_TradePet_1 — constructor 0x3351a8 → `scripts/ui/trade/trade_pet_window.gd`
Skin `white/Form_TradePet_1.bmp` 463x455 (ctor pushes exactly 463x455). Baked: "Trade pets", LV/HP/loyalty, "money earned",
"money paid". Loads `Icon_PetInCage`.
| control | rect (decoded) |
|---|---|
| Btn_Close_s_1 | (413,25) 17x17 |
| labels [0x134] / [0x130] | (31,63) / (242,63) 160x20 — **guess:** owner names |
| labels [0x198] / [0x194] | (33,230) 160x20 / (243,230) 128x24 — **guess:** pet names |
| right (mine) 5 skill cells [0x19c+i] | (247+35i, 308) 33x33 |
| right box [0x1b4] | (388,266) 33x33 |
| left (other) 5 skill cells [0x1b8+i] | (37+35i, 308) 33x33 |
| left box [0x1d0] | (178,266) 33x33 |
| cells [0x1d4] (253,450), [0x1d8] (35,300) 34x34 with text "1001" | unknown purpose, not rebuilt |
| money earned label [0x1e0] | (95,380) 128x14 |
| money paid entry | (306,380) 127x14, "0" |
| Btn_ArrowL_5 / Btn_ArrowR_5 | (255,184) / (399,184) 17x17 |
| Btn_confirm_1 + icon_Confirm_1 | (130,418) 56x20 |
| Btn_Trade_2 (hidden) + icon_trade_1 | (205,418) 56x20 |
| Btn_Cancel_1 | (280,418) 56x20 |
Value positions for LV/HP/loyalty are **guesses** (right of the baked words). Pet sprite drawing not rebuilt.

## Related (not rebuilt)
- Form_Business_1 (0x275554): chooser with btn_TradeThing_1 / Btn_TradePet_1 (Btn_TradeUtensil) = which trade to open.
- Form_TradeUtensil_1 skin (399x481) exists; constructor not decoded.

## Godot
- Skins sliced by `tools/reference_analysis/scripts/slice_trade_bank_repair.py` into `assets/hud/` (chroma key removed).
- Offline other side: `scripts/ui/trade/trade_partner_stub.gd` (confirms when the player confirms, completes on Trade).
- Test: `tests/test_trade_window.gd` (46 checks).
