# Delphi VCL & Binary Resource Reverse Engineering Specification

## 1. Executive Summary

This document specifies the low-level reverse engineering findings extracted from `aLogin.exe` (PE x86, 5,382,656 bytes, MD5: `02860c4da96245c381c15f9ee6ff3d6a`, SHA256: `959659ae7e9fbfd9ff64e1b927256fce40327d6ec666f002fca7997f7cc89115`) and associated binary assets using PE resource inspection (`pefile`), Delphi form binary decompilation (`TPF0` parser), IDR KB6 symbol signatures, and Ghidra disassembly.

---

## 2. Delphi Form Resources (`RT_RCDATA`)

Extraction of `RT_RCDATA` from `aLogin.exe` reveals the compiled forms:

| Resource Name | Size (Bytes) | Magic | Delphi Class | Functional Purpose |
|---|---|---|---|---|
| `TFORM1` | 12,898 | `TPF0` | `TForm1` | Primary game window hosting `TDXDraw` (800x600 DirectDraw canvas) |
| `TFORM2` | 521 | `TPF0` | `TForm2` | Modal confirmation / message prompt |
| `TFORM3` | 7,251 | `TPF0` | `TForm3` | Patch / update status dialog |
| `TFORM4` | 652 | `TPF0` | `TForm4` | Error alert modal |
| `TFORM5` | 7,422 | `TPF0` | `TForm5` | Server selection & network status panel |
| `TDELPHIXDXPLAYFORM` | 8,431 | `TPF0` | `TDXPlayForm` | DirectPlay / network lobby configuration |
| `TGMFORM` | 12,781 | `TPF0` | `TGMForm` | GameMaster administration studio |
| `TNMSHOW` | 7,654 | `TPF0` | `TNMShow` | NetMeeting / chat broadcast window |

---

## 3. Main Window Architecture (`TForm1`)

Decompiled `TForm1` properties:

```pascal
object Form1: TForm1
  Left = 1028
  Top = 400
  BorderStyle = bsSingle
  Caption = 'Form1'
  ClientHeight = 600
  ClientWidth = 800
  Constraints.MaxHeight = 639
  Constraints.MaxWidth = 816
  Constraints.MinHeight = 450
  Constraints.MinWidth = 638
  Color = clBtnFace
  Visible = True

  object DXDraw1: TDXDraw
    Left = 0
    Top = 8
    Width = 464
    Height = 456
    Display.BitCount = 16
    Display.FixedBitCount = True
    Display.FixedRatio = True
    Display.FixedSize = False
    Display.Height = 600
    Display.Width = 800
    Options = [doAllowReboot, doWaitVBlank, doCenter, doRetainedMode, doHardware, doSelectDriver]
  end
end
```

### Architectural Implications:
1. **Window Size**: Strictly fixed 800x600 (`BorderStyle = bsSingle`). It is not dynamically resizable.
2. **Display**: 16-bit double-buffered DirectDraw 7 surface blitted to 800x600 primary display.
3. **Godot Configuration**: Viewport width 800, viewport height 600, `window/size/resizable=false`, `window/stretch/mode="canvas_items"`, `window/stretch/aspect="keep"`.

---

## 4. Login Authentication Form (`FUN_00419a5c` & `Form_IdPassword_1`)

`aLogin.exe` constructs the login dialog through `FUN_00419a5c` by blitting `Menu\Skins\White\Form_IdPassword_1.jpg` (259x352 px) and binding the following controls:

| Control | Class / Texture | Geometry ($W \times H$) | Relative Form $(X, Y)$ | Screen $(X, Y)$ | Delphi Routine |
|---|---|---|---|---|---|
| **Form Canvas** | `Form_IdPassword_1.jpg` | $259 \times 352$ | $(0, 0)$ | $(270, 145)$ | `FUN_00419a5c` |
| **Server Select** | `Panel26` (Option) | $110 \times 24$ | $(98, 78)$ | $(368, 223)$ | `FUN_0049f3c8` |
| **ID Field** | `IDField` (`Panel26`) | $110 \times 20$ | $(98, 112)$ | $(368, 257)$ | `LAB_0041a08c` ($Y = 0x110 = 272$) |
| **Password Field** | `Panel26` | $110 \times 20$ | $(98, 144)$ | $(368, 289)$ | `LAB_0041a2b0` ($Y = 0x130 = 304$) |
| **Remember ID** | `btn_UnCheck_1` | $16 \times 16$ | $(58, 185)$ | $(328, 330)$ | `LAB_0041a624` ($Y = 0x14a = 330$) |
| **Login Button** | `Btn_Login_L.bmp` | $143 \times 20$ | $(58, 215)$ | $(328, 360)$ | `FUN_0041a2bc` ($Y = 0x168 = 360$) |
| **Cancel Button** | `Btn_Prev_L.bmp` | $143 \times 20$ | $(58, 245)$ | $(328, 390)$ | `FUN_0041a00c` ($Y = 0x186 = 390$) |
| **Apply ID** | `Btn_applyID_1.bmp` | $143 \times 20$ | $(58, 275)$ | $(328, 420)$ | `LAB_0041a614` ($Y = 0x1a4 = 420$) |
| **About Button** | `Btn_About_L.bmp` | $143 \times 20$ | $(58, 305)$ | $(328, 450)$ | `FUN_00419fd8` ($Y = 0x1c2 = 450$) |

### Button 3-State Slices:
Every button in `menu/Skins/default/` (e.g. `Btn_Login_L.bmp`) has dimensions $143 \times 60$, divided into 3 vertical states of 20 px:
- State 0 ($Y = 0..20$): Normal
- State 1 ($Y = 20..40$): Hover
- State 2 ($Y = 40..60$): Pressed

---

## 5. Logo & Splash Screen Layout (`FUN_00426118` & `FUN_00426264`)

- **Splash Canvas**: `pic/LogPic1.jpg` ($800 \times 600$ px) rendered at $(0, 0)$.
- **Logo Banner**: `menu/Skins/default/Icon_LoginLogo_1.bmp` ($183 \times 89$ px).
  - Centered at $(800 - 183)/2 = 308.5, Y = 18$.

---

## 6. String Sanitization & NUL Terminator Resolution

Delphi binary records in `Item.dat`, `SceneData.dat`, `Npc.dat`, `Skill.dat`, and `Talk.dat` contain fixed-width byte buffers with trailing `0x00` padding. Converting buffers with embedded `0x00` bytes to ASCII using `get_string_from_ascii()` causes Godot to trigger:
```
ERROR: Unicode parsing error, some characters were replaced with (U+FFFD): Unexpected NUL character
```

### Resolution:
Buffers are sliced at the first index of `0x00` prior to calling `get_string_from_ascii()`:

```gdscript
static func clean_ascii(bytes: PackedByteArray) -> String:
	var nul_idx := bytes.find(0)
	if nul_idx != -1:
		bytes = bytes.slice(0, nul_idx)
	return bytes.get_string_from_ascii().strip_edges()
```
This guarantees zero Unicode parsing errors and 100% clean engine logs.

---

## 7. In-Game HUD & Floating VCL Docks Architecture

In-game HUD elements correspond to Delphi floating panels and docking controls:

| Dock / Window | VCL Component / Texture | Dimensions ($W \times H$) | Screen Alignment | Key Features |
|---|---|---|---|---|
| **Player Status Dock** | `menu/Skins/white/main_Status_1.bmp` | $241 \times 116$ | Top-Left $(0, 0)$ | Name, Level, HP Bar (Red), SP Bar (Blue), EXP Bar (Gold), Avatar (32x32) |
| **Radar Minimap Dock** | `pic/MiniMap_1.bmp` | $212 \times 131$ | Top-Right $(588, 0)$ | Map title, dynamic $(X_w, Y_w)$ coordinates |
| **Chat Dock** | `menu/Skins/white/main_input_1.bmp` | $521 \times 25$ | Bottom-Left $(0, 575)$ | Channel selector, LineEdit input, send button, RichTextLabel history panel ($521 \times 140$) |
| **Hotbar Dock** | `menu/Skins/white/Form_HotKey_V.bmp` | $56 \times 274$ | Right $(744, 140)$ | 8 vertical action slots (F1..F8) with exact 27px stride ($Y = 28 + i \times 27$) |
| **Form_Talk_1 (Dialogue)** | `menu/Skins/white/Form_Talk_1.bmp` | $768 \times 169$ | Bottom $(16, 420)$ | NPC nameplate, portrait slot (94x92), dialogue text, 2-frame blinking next icon (`Icon_Nextone_1.bmp`, 25x31) |
| **Form_Talk_3 (Branching)**| `menu/Skins/white/Form_Talk_3.bmp` | $324 \times 168$ | Bottom-Right $(420, 240)$| Interactive decision choices |
| **Inventory Window** | `menu/Skins/white/Form_ThingGrid5x5_1.bmp` | $209 \times 287$ | Floating | 5x5 item grid, draggable, toggle hotkey `[I]` |
| **Character Status Window**| `menu/Skins/white/Form_RoleStatus_1.bmp` | $386 \times 461$ | Floating | Stats, equipment slots, draggable, toggle hotkey `[C]` |
| **Fight Status Window** | `menu/Skins/default/BattleStatus_1.bmp` | $124 \times 262$ | Floating | Battle actions, draggable, toggle hotkey `[F]` |

---

## 8. World Entities, Kinematics & 2:1 Axonometric Projection

### 1. Coordinate Mathematics
The game uses a 2:1 axonometric projection standard matching DirectDraw `rodraw2.dll`:
- **World to Screen**:
  $$X_s = \frac{X_w - Y_w}{2}$$
  $$Y_s = \frac{X_w + Y_w}{4}$$
- **Screen to World**:
  $$X_w = X_s + 2Y_s$$
  $$Y_w = -X_s + 2Y_s$$

### 2. Kinematics & Step Size
Discrete walking step size is fixed at $14.0$ pixels:
$$X_{\text{target}} = X_w + (dx + dy) \times 14.0$$
$$Y_{\text{target}} = Y_w + (-dx + dy) \times 14.0$$

### 3. 8-Directional Heading & Sprite Flipping
Heading enumeration (0: South, 1: South-West, 2: West, 3: North-West, 4: North, 5: North-East, 6: East, 7: South-East).
Mirrored sprites for East-facing orientations:
$$\text{flip\_h} = (\text{heading} \ge 4 \land \text{heading} \le 7)$$

### 4. Direct In-Memory Texture Streaming
All entity sprites stream directly into memory from `.jma` / `.jmp` packages (e.g., `002.jma` for Daniel, `007.jma` for Captain, `006.jma` for Crew Member) via `ArchiveLoader.get_jma_animation()` or `get_role_sprite_sheet()`. No temporary images are written to the filesystem.
