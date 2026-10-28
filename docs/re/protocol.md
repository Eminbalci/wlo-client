# Protocol notes
See `docs/network_manager.md` for framing (0xF4 0x44 magic, uint16 length, XOR 0xAD) and the login sequence.

## Dispatcher (decoded, aLogin.exe)
`0x2de1d4` switches on the action code over 0..0xC7 (91 codes have handlers). Full handler table and all action-0 notice texts:
[dispatch_table.md](dispatch_table.md) (generated from the exe by capstone). Godot's copy of the notice texts:
`scripts/network/server_notice.gd` (`ServerNotice.TEXTS`, sub code -> text).

- Action 0 = server notice / disconnect reason, sub code = second byte (0..0x52). Examples: 3 Wrong Pwd, 15 Delete Successful (not an error),
  17 Update Game Files, 19 Repeated Login, 36 Invalid ID, 45 Account Banned, 53 Server Not Open Yet, 62 Incorrect Password,
  64/65 Wrong Version, 75 Max Logins Reached, 79 Routing Error, Wait, 80 Acct Locked.
- Godot handles actions 0x01, 0x3F, 0x00, 0x14/0x05/0x03/0x04, ping 0xBA/0x10, walk 0x06/0x01, chat 0x23/0x0C; the other ~80 real
  handlers are not implemented yet (see dispatch_table.md for their addresses; decode them one by one).
- "Login/Pwd error" text (0x2f19c8) is referenced from the action 0x15 (21) handler at 0x2e5886 (reference at 0x2e593e), not from the action-0 switch.
