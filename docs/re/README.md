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
| [original_repo.md](original_repo.md) | What is in `D:\GitHub\WLRI` (105 specs, data files, Formula.dat decoded) |
| [battle.md](battle.md) | Real battle screen, command ring, pet turn, countdown, live battle packets |
| [dispatch_table.md](dispatch_table.md) | Generated: every action code -> handler address, action-0 notice texts |

Reference screenshots of the live client: `docs/reference/real_client/*.png` (806x629 form, 800x600 view).
