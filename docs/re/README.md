# Reverse-engineering library (real WLRI client)

Single place for everything learned about the original client, so later sessions do not rediscover it.
Update it whenever something is decoded or observed. Evidence level: **observed** (screenshot / bytes),
**decoded** (REA decompile), **inferred** (guess, must be verified).

| File | Content |
|------|---------|
| [tools.md](tools.md) | How to open, capture, drive and decompile the real game and the REA gotchas |
| [ui_windows.md](ui_windows.md) | Real window layouts measured from live captures (positions, controls, texts) |
| [binary_notes.md](binary_notes.md) | Addresses and findings in aLogin.exe / Main.exe |
| [protocol.md](protocol.md) | Packet framing, action codes, login error strings |
| [original_repo.md](original_repo.md) | What is in `D:\GitHub\WLRI` (105 specs, data files, Formula.dat decoded, image archive formats, extraction output) |
| [battle.md](battle.md) | Real battle screen, command ring, pet turn, countdown, live battle packets |
| [eve_events.md](eve_events.md) | Eve.emg NPC event scripts: branch rules, all condition kinds, ops (ported from the C# server) |
| [alogin_functions.md](alogin_functions.md) | aLogin.exe: 600 functions (prologue-based) with the strings they use; Ghidra times out, see binary_notes.md |
| [dispatch_table.md](dispatch_table.md) | Older build (sha 190dae51): action -> handler, action-0 notice texts |
| [dispatch_table_959659ae.md](dispatch_table_959659ae.md) | Current aLogin.exe (sha 959659ae): 91 actions -> handler VA + strings used |
| [trade_window.md](trade_window.md) | Form_Trade (legacy, no skin), Form_TradeItem_1, Form_TradePet_1: control rects, trade action 0x19 subs |
| [warehouse_window.md](warehouse_window.md) | Form_Warehouse (legacy, no skin) and Form_itemBank_1 (live bank): grids, arrows, action 0x1E |
| [repair_window.md](repair_window.md) | Form_Repair: controls, OK handler checks, unrepairable Broken-item ids, action 0x17/0x54 |

Reference screenshots of the live client: `docs/reference/real_client/*.png` (806x629 form, 800x600 view).
