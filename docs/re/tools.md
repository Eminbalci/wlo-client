# Tools and workflow

## Real client
- `C:\Games\WLRI\aLogin.exe` (Delphi, 5.4 MB). Window class `TForm1`, title "WLO Rhodes Island", 806x629 incl. title bar.
- The user logs in themselves. **Never type account names, passwords or secret codes** (policy, even if told it is allowed).
  `tools/game_input.ps1` has no free-text command on purpose.

## tools/game_input.ps1 (PowerShell 7)
```
pwsh -NoProfile -File tools/game_input.ps1 shot <out.png>
pwsh -NoProfile -File tools/game_input.ps1 click <x> <y> [right]   # coordinates = screenshot pixels
pwsh -NoProfile -File tools/game_input.ps1 drag x1 y1 x2 y2
pwsh -NoProfile -File tools/game_input.ps1 key F1|ESC|ENTER|A..Z|0..9
```
- Capture uses PrintWindow on the DDraw presentation window, works while occluded.
- Keys: `I` did nothing in the client; windows open by clicking the bottom icon bar. ESC does not close windows (click Close).
- Bottom bar icon centres (y=603): item/compound 633, inventory 557, skill 597, team 675, social 709, system 745 (see ui_windows.md).

## Godot side
- Headless tests: `godot --headless --path . --script res://tests/X.gd`; all: `bash tools/run_all_tests.sh <logdir>`.
- Window capture: `CAPTURE_DIR=<dir> godot --path . --resolution 800x600 --script res://scripts/tools/capture_windows.gd`.
- Skin bitmaps: green (0,255,0) is the chroma key; icon sheets are 3 frames stacked (normal, hover, pressed), frame height = sheet height / 3 (99, 102 or 108 px sheets!).
- Python with PIL works outside `-I` mode (`python - <<'EOF'`), not with `python -I`.

## REA / Ghidra gotchas
- ~3,800 unnamed procedures per exe; names are `FUN_<addr>`. Search by strings, then xrefs.
- Ghidra misses some function entries (e.g. around aLogin 0x2e593d). Workaround: `scratchpad` script scanning the exe for the string's
  address bytes (imm32) and walking back to a `55 8B EC` prologue (see `find_refs.py` idea in binary_notes.md).
- Errors from REA tools dump ~10 k tokens of Ghidra log: avoid calling on addresses that are not function entries.
- procedure_pseudo_code of a big function can be moved to the background by the harness; wait for the notification.
