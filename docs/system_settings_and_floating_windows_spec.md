# Authentic Floating Window Close Buttons & Functional System Settings Specification

## Executive Summary
This document specifies the reverse engineering, visual alignment, and functional architecture of the floating window close button system and the **System Settings Window** (`Form_System_2`, 388x451) in the Wonderland Online Godot 4 client.

All 8 floating VCL windows (`CharacterWindow`, `InventoryWindow`, `FightWindow`, `FriendsWindow`, `SkillWindow`, `TeamWindow`, `QuestWindow`, `SystemWindow`) are equipped with authentic 18x18 three-state close buttons, replacing synthetic text labels. The System Settings Window provides full runtime and persistent controls for BGM and SFX volume sliders, audio bus mute toggles, Fullscreen/Windowed display mode switching, Resume, Logout to Character Select, and Exit Game actions.

---

## 1. Floating Window Close Buttons Parity

### 1.1 Geometry & Alignment
In the original 32-bit Borland Delphi client (`aLogin.exe`), all floating window skins contain pre-rendered titlebars and a designated 18x18 pixel aperture in the upper-right corner.

- **Button Size:** Exactly `Vector2(18.0, 18.0)` (`custom_minimum_size = Vector2(18, 18)`).
- **Position Offset:** Aligned to `Vector2(window.size.x - 30.0, 8.0)`:
  - Leaves an exact 12px right margin (`window.size.x - (30 + 18) = 12px`) and 8px top padding.
  - Consistent across all floating windows:
    - `InventoryWindow` (width 209): X = 179.0, Y = 8.0
    - `CharacterWindow` (width 386): X = 356.0, Y = 8.0
    - `FightWindow` (width 153): X = 123.0, Y = 8.0
    - `FriendsWindow` (width 356): X = 326.0, Y = 8.0
    - `SkillWindow` (width 285): X = 255.0, Y = 8.0
    - `TeamWindow` (width 371): X = 341.0, Y = 8.0
    - `QuestWindow` (width 432): X = 402.0, Y = 8.0
    - `SystemWindow` (width 388): X = 358.0, Y = 8.0

### 1.2 Texture Overrides & Styling
- **Normal Texture:** `res://assets/hud/btn_close_normal.png` (18x18 PNG)
- **Hover Texture:** `res://assets/hud/btn_close_hover.png` (18x18 PNG)
- **Pressed Texture:** `res://assets/hud/btn_close_pressed.png` (18x18 PNG)
- **Focus StyleBox:** `StyleBoxEmpty` (eliminates focus box rects)
- **Button Text:** Strictly set to empty string (`close_btn.text = ""`) to eliminate synthetic white "X" glyphs.
- **Cursor Shape:** `Control.CURSOR_POINTING_HAND` (2).
- **Click Audio:** Triggers authentic UI click sound via `AuthAudio.play_click()` (`wav0151.wav`).
- **Signal Flow:** Closes the target window (`win.close_window()` or `win.visible = false`) and emits `window_toggled(win.name, false)` through `HUDWindowManager`.

---

## 2. System Settings Window (`SystemWindow`) Architecture

### 2.1 Window Dimensions & Background Skin
- **Scene:** `scenes/ui/hud/system_window.tscn` and embedded in `scenes/ui/hud.tscn` under `FloatingWindows/SystemWindow`.
- **Dimensions:** `388 x 451` pixels (`WINDOW_WIDTH = 388.0`, `WINDOW_HEIGHT = 451.0`).
- **Background Skin:** `menu/Skins/white/Form_System_2.bmp` decoded via `ArchiveLoader` with transparent chroma keying or `assets/hud/form_system_2.png`.

### 2.2 Audio Control Subsystem
Wonderland Online client utilizes two dedicated audio channels routed through the `Master` bus:
1. **BGM Bus:** Background music playback (`MapView.bgm_player`).
2. **SFX Bus:** Sound effects and UI feedback (`AuthAudio._player_pool`, combat SFX).

#### Audio Bus Initialization & Volume Formulas
- `SystemWindow.ensure_audio_buses()` checks `AudioServer.get_bus_index("BGM")` and `AudioServer.get_bus_index("SFX")`. If missing, creates and routes them to `Master`.
- **Linear to Decibel Conversion:**
  $$\text{dB} = \begin{cases} -80.0 & \text{if } \text{percentage} \le 0 \\ 20 \log_{10}\left(\frac{\text{percentage}}{100.0}\right) & \text{if } \text{percentage} > 0 \end{cases}$$
- **Decibel to Linear Conversion:**
  $$\text{percentage} = \begin{cases} 0 & \text{if } \text{dB} \le -79.0 \\ \text{round}\left(10^{ \frac{\text{dB}}{20} } \times 100.0\right) & \text{otherwise} \end{cases}$$

#### UI Controls:
- **BGM Volume:**
  - Label: `BgmLabel` (`"BGM Volume: %d%%"`, position `(40, 90)`).
  - HSlider: `BgmSlider` (Range `0.0 .. 100.0`, step `1.0`, default `80.0`, position `(40, 112)`, size `(210, 20)`).
  - Mute CheckBox: `BgmMuteCheck` (Position `(265, 110)`, size `(85, 24)`, text `"Mute"`).
- **SFX Volume:**
  - Label: `SfxLabel` (`"SFX Volume: %d%%"`, position `(40, 142)`).
  - HSlider: `SfxSlider` (Range `0.0 .. 100.0`, step `1.0`, default `80.0`, position `(40, 164)`, size `(210, 20)`).
  - Mute CheckBox: `SfxMuteCheck` (Position `(265, 162)`, size `(85, 24)`, text `"Mute"`).

### 2.3 Display Mode Subsystem
- **Fullscreen CheckBox:** `FullscreenCheck` (Position `(40, 246)`, size `(260, 24)`, text `"Fullscreen Mode (Tam Ekran)"`).
  - Calls `DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)` when checked.
  - Calls `DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)` when unchecked.
- **Info Label:** `DisplayInfoLabel` (Position `(40, 276)`, size `(310, 40)`):
  `"Resolution: 1280x720 (Unscaled 1:1 Pixel Parity)\nAspect: Responsive Dynamic HUD"`.

### 2.4 Bottom Action Buttons
Placed at `Y = 396.0` (451px height - 55px margin):
1. **Resume / Return Button (`BtnResume`):**
   - Position: `Vector2(28, 396)`, size: `Vector2(100, 28)`. Text: `"Resume"`.
   - Tooltip: `"Return to Game [Esc]"`.
   - Action: Plays click audio, closes `SystemWindow`, emits `window_closed`.
2. **Character Select / Logout Button (`BtnLogout`):**
   - Position: `Vector2(136, 396)`, size: `Vector2(120, 28)`. Text: `"Character Select"`.
   - Tooltip: `"Return to Character Selection Screen"`.
   - Action: Plays click audio, closes `SystemWindow`, emits `logout_requested`, transitions scene to `res://scenes/ui/login_screen.tscn`.
3. **Exit Game Button (`BtnExit`):**
   - Position: `Vector2(264, 396)`, size: `Vector2(96, 28)`. Text: `"Exit Game"`.
   - Tooltip: `"Quit Wonderland Online"`.
   - Action: Plays click audio, calls `get_tree().quit()`.

---

## 3. Configuration Persistence (`user://system_settings.json`)

Settings are saved automatically upon user interaction and restored during `_ready()`:

```json
{
	"bgm_volume": 80,
	"bgm_muted": false,
	"sfx_volume": 80,
	"sfx_muted": false,
	"fullscreen": false
}
```

- **File Path:** `user://system_settings.json` (`SETTINGS_FILE_PATH`).
- **Load Flow:**
  1. Checks `FileAccess.file_exists(SETTINGS_FILE_PATH)`.
  2. Parses JSON safely via `JSON.parse_string()`.
  3. Falls back to default values (`80`, `false`) if file or individual keys are absent.
  4. Applies volume and mute to `AudioServer` buses and window mode to `DisplayServer` without triggering disk writes.

---

## 4. Technical API Reference (`SystemWindow`)

### 4.1 Signals
- `settings_changed(settings: Dictionary)`: Emitted whenever settings are saved.
- `logout_requested()`: Emitted when player clicks Character Select button.
- `window_closed()`: Emitted when SystemWindow is closed via close button or Resume.

### 4.2 Methods
| Method | Parameters | Return Type | Description |
|---|---|---|---|
| `setup` | `hud: Control = null` | `void` | Initializes buses, builds UI if necessary, loads settings. |
| `ensure_audio_buses` | *None* (static) | `void` | Ensures "BGM" and "SFX" buses exist and route to Master. |
| `get_bgm_bus` | *None* (static) | `int` | Returns bus index for BGM (or Master index fallback). |
| `get_sfx_bus` | *None* (static) | `int` | Returns bus index for SFX (or Master index fallback). |
| `linear_to_bus_db` | `percentage: int` | `float` | Converts integer 0..100 volume to decibels (-80.0 to 0.0 dB). |
| `bus_db_to_linear` | `db: float` | `int` | Converts decibels to integer 0..100 volume percentage. |
| `set_bgm_volume` | `val: int, save: bool = true` | `void` | Sets BGM volume, updates slider & label, optionally saves. |
| `get_bgm_volume` | *None* | `int` | Returns current BGM volume percentage. |
| `set_bgm_muted` | `muted: bool, save: bool = true` | `void` | Mutes or unmutes BGM bus. |
| `is_bgm_muted` | *None* | `bool` | Returns current BGM mute state. |
| `set_sfx_volume` | `val: int, save: bool = true` | `void` | Sets SFX volume, updates slider & label, optionally saves. |
| `get_sfx_volume` | *None* | `int` | Returns current SFX volume percentage. |
| `set_sfx_muted` | `muted: bool, save: bool = true` | `void` | Mutes or unmutes SFX bus. |
| `is_sfx_muted` | *None* | `bool` | Returns current SFX mute state. |
| `set_fullscreen` | `enabled: bool, save: bool = true` | `void` | Sets window mode via DisplayServer. |
| `is_fullscreen` | *None* | `bool` | Returns current fullscreen mode state. |
| `toggle_fullscreen` | *None* | `void` | Inverts current fullscreen mode. |
| `get_settings_data` | *None* | `Dictionary` | Returns serialized settings dictionary. |
| `save_settings` | *None* | `void` | Writes dictionary to `user://system_settings.json`. |
| `load_settings` | *None* | `void` | Reads from disk and applies settings to engine. |
| `open_window` | *None* | `void` | Plays click SFX, reloads settings, sets visible = true. |
| `close_window` | *None* | `void` | Plays click SFX, sets visible = false, emits `window_closed`. |
| `toggle_window` | *None* | `void` | Toggles window visibility between open and closed. |

---

## 5. Verification Matrix

The test suite `tests/test_floating_windows_and_system_settings.gd` executes headlessly on `godot_console.exe` verifying 139 assertions with 100% pass rate:

1. **Floating Window Close Buttons:**
   - [x] All 8 windows verified for node existence.
   - [x] Empty text verified (`text == ""`, no "X").
   - [x] Exact 18x18 size verified (`size == (18, 18)`).
   - [x] Corner alignment verified (`position == Vector2(win.size.x - 30, 8)`).
   - [x] StyleBoxTexture normal/hover/pressed overrides verified.
   - [x] Clean close on click verified (`win.visible == false`, `window_toggled(false)` emitted).
2. **System Settings Audio & Display:**
   - [x] 388x451 form dimensions verified.
   - [x] Background TextureRect verified.
   - [x] BGM slider range, values, and AudioServer bus volume tracking verified.
   - [x] BGM mute checkbox and AudioServer bus mute tracking verified.
   - [x] SFX slider range, values, and AudioServer bus volume tracking verified.
   - [x] SFX mute checkbox and AudioServer bus mute tracking verified.
   - [x] Fullscreen mode toggle and CheckBox state verified.
   - [x] Resume button closes window and emits `window_closed`.
   - [x] Logout button emits `logout_requested`.
3. **Persistence:**
   - [x] File creation at `user://system_settings.json` verified.
   - [x] JSON key/value serialization verified.
   - [x] Clean deserialization on second instance verified.
4. **Standalone Scene:**
   - [x] `scenes/ui/hud/system_window.tscn` instantiation verified.
