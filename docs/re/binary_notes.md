# Binary notes (addresses are virtual addresses in the exe)

## aLogin.exe (SHA256 190dae51...c6cc)
- **0x2de1d4 = main packet dispatcher** (action code in `bl`, 0..0xC7; byte table 0x2de224, dword table 0x2de2ec). Action 0 handler at
  0x2de468 has a second switch (sub code 0..0x52, dword table 0x2de481) that picks the notice text. Full tables in dispatch_table.md.
  Ghidra does not create a function there; disassemble with capstone (`scratchpad/disasm.py` idea: PE parse + `Cs(CS_ARCH_X86, CS_MODE_32)`).
- "Login/Pwd error" is referenced at 0x16db8c (function ~0x16d9f4) and 0x2e593e (code Ghidra did not create a function for; it
  contains `cmp ebx,0Ch ; ja` = switch over codes 0..12).
- Other strings: "Can't reach login server" 0x4a3808, SERVER.INI 0x316110 / 0x448480, login web page `http://pl.online-game.com.cn/login_web/index.php`.
- UI strings give the system window texts (see ui_windows.md): "Log out to server list" 0x10fcac, "5 options for overhead info" 0x10fd7c.

## Main.exe (SHA256 26c72ed2...0d00) = patcher/updater
- 0x4c6f50 FUN: "Wonderland Rhodes Island Update" screen; checks `Data\Talk.Dat` size < 0xCAC24 and deletes `PackagesVersion_z.dat`
  to force re-download. Uses `Upimg\Main_Img1c.bmp` / `Main_Img2C.Bmp` for the 4x2 button sheet (120x55 frames).
- Not the game itself: gameplay lives in aLogin.exe.

## Scan helper idea (works without Ghidra functions)
Parse the PE section table, find the little-endian imm32 of a string VA inside `.text`, walk back to `55 8B EC`.
