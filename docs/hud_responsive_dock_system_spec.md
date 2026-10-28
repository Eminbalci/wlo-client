# Modern Responsive HUD & Dock System Specification

## Overview
This document specifies the modular architecture, API signatures, responsive anchor presets, and layout collision avoidance algorithms for the Wonderland Online client HUD & Dock System (`D:\Godot\WonderlandOnline\wonderland-online-client`).

The refactored HUD replaces monolithic inline code with isolated, modern Godot 4 components that support arbitrary viewport aspect ratios (4:3, 16:9, 16:10, 21:9 ultrawide, 32:9) without overlapping, clipping, or distorting UI elements.

---

## Architecture & Component Hierarchy

```
HUDManager (Control, PRESET_FULL_RECT)
│
├── StatusDock (Control, PRESET_TOP_LEFT)
│   ├── AvatarBg (ColorRect)
│   ├── StatusBackground (TextureRect)
│   ├── AvatarRect (TextureRect)
│   ├── ElementIcon (TextureRect)
│   ├── HpChannelUnder / SpChannelUnder (TextureRect)
│   ├── HpBar / SpBar / ExpBar (TextureProgressBar with ChromaMask Shader)
│   ├── NameLabel / LevelLabel / HpLabel / SpLabel / ExpLabel / GoldLabel
│   └── BuffContainer (HFlowContainer: Wrapping Active Buffs)
│
├── RadarMinimap (Control, PRESET_TOP_RIGHT)
│   ├── MinimapView (TextureRect with clip_contents)
│   │   ├── PlayerMarker (Control, Blinking Indicator)
│   │   ├── WaypointMarker (Control, Pulse Wave Indicator)
│   │   └── PortalsContainer (Control, Overlay Portal Dots)
│   ├── MinimapFrame (TextureRect)
│   ├── MapNameLabel / CoordinatesLabel
│   └── BtnZoomIn / BtnZoomOut / BtnMinimapToggle
│
├── ChatDock (Control, PRESET_BOTTOM_LEFT)
│   ├── ChannelTabs (HBoxContainer: All, Current, Team, Guild, Whisper, System)
│   ├── ChatHistoryPanel (PanelContainer, Resizable Offset)
│   │   ├── ChatResizeHandle (Control, Mouse Cursor Shape 9)
│   │   ├── ChatFrameNinePatch (NinePatchRect, Switchable Mode)
│   │   ├── PanelTalkFormLeft (BtnMsgLock, BtnChatSwitch)
│   │   ├── BtnChatSize (Cycle Preset Heights)
│   │   └── ChatHistory (RichTextLabel, BBCode Enabled, Smooth Scroll)
│   ├── ChatInputBackground (TextureRect)
│   ├── BtnMail / BtnChannel
│   ├── WhisperTarget (LineEdit, Auto-Fitting)
│   ├── ChatInput (LineEdit, Responsive Auto-Fitting)
│   ├── BtnEmote / EmotePopup (GridContainer, 31 Authentic Emotes)
│   └── ChannelDropdown (PanelContainer)
│
└── BottomActionDock (Control, PRESET_BOTTOM_RIGHT / PRESET_CENTER_BOTTOM)
    ├── LocationLabel (Label)
    ├── ActionBackground (TextureRect)
    └── ButtonContainer (HBoxContainer)
        ├── BtnStatus (Status & Inventory [C/I])
        ├── BtnSkill (Skills [S])
        ├── BtnQuest (Compound / Quests [C/Q])
        ├── BtnTeam (Team & Party [T])
        ├── BtnFriends (Friends & Community [F])
        └── BtnSystem (System Settings [Esc])
```

---

## 1. StatusDock (`scripts/ui/hud/status_dock.gd`)

### Properties & Exported Nodes
- `anchors_preset`: `Control.PRESET_TOP_LEFT` (0)
- `current_hp`: `int` (default: 245)
- `max_hp`: `int` (default: 245)
- `current_sp`: `int` (default: 180)
- `max_sp`: `int` (default: 180)
- `current_exp`: `int` (default: 4500)
- `max_exp`: `int` (default: 10000)
- `current_role_id`: `int` (1..14, default: 6 - Daniel)
- `current_element`: `Variant` ("Earth"=1, "Water"=2, "Fire"=3, "Wind"=4)

### Public Methods & Signatures
```gdscript
func set_hp(p_hp: int, p_max: int, smooth: bool = true) -> void
```
- Interpolates `hp_bar.value` using `Tween` (`TRANS_CUBIC`, `EASE_OUT`) over 0.3 seconds.
- Updates `HpLabel.text` to `"HP %d/%d"`.

```gdscript
func set_sp(p_sp: int, p_max: int, smooth: bool = true) -> void
```
- Interpolates `sp_bar.value` using `Tween` over 0.3 seconds.
- Updates `SpLabel.text` to `"SP %d/%d"`.

```gdscript
func set_exp(p_exp: int, p_max: int, smooth: bool = true) -> void
```
- Interpolates `exp_bar.value` to percentage $[0.0, 100.0]$.
- Updates `ExpLabel.text` to `"%d%%"`.

```gdscript
func add_buff(id: String, icon: Texture2D, duration: float = -1.0, tooltip: String = "") -> void
```
- Adds or updates buff icon inside `BuffContainer` (`HFlowContainer`).
- Automatically wraps icons when multiple buffs/debuffs are active.
- If `duration > 0.0`, automatically removes buff upon expiration.

```gdscript
func remove_buff(id: String) -> void
func clear_buffs() -> void
func get_buff_count() -> int
```

---

## 2. RadarMinimap (`scripts/ui/hud/radar_minimap.gd`)

### Properties & Exported Nodes
- `anchors_preset`: `Control.PRESET_TOP_RIGHT` (1)
- `minimap_zoom`: `float` (clamped $[0.5, 3.0]$, step: $0.25$)
- `_minimap_is_collapsed`: `bool` (default: false)
- `current_map_id`: `int`
- `current_map_pixel_size`: `Vector2`
- `current_player_norm_pos`: `Vector2`

### Public Methods & Signatures
```gdscript
func set_map(map_id: int, map_name: String, pixel_size: Vector2) -> void
```
- Updates active map thumbnail from `ArchiveLoader`, updates `MapNameLabel.text`, and clears previous portal dots.

```gdscript
func update_coordinates(world_pos: Vector2, pixel_size: Vector2) -> void
func update_coordinates_norm(norm_pos: Vector2) -> void
```
- Calculates player position on minimap using `roundi()` to avoid float precision truncation.
- Formats `CoordinatesLabel.text` as `"(X, Y)"`.

```gdscript
func set_zoom(p_zoom: float) -> void
func toggle_collapse() -> void
func add_portal_dot(portal_id: String, norm_pos: Vector2, color: Color = Color(0.2, 0.7, 1.0)) -> void
func remove_portal_dot(portal_id: String) -> void
func clear_portal_dots() -> void
```

---

## 3. ChatDock (`scripts/ui/hud/chat_dock.gd`)

### Properties & Exported Nodes
- `anchors_preset`: `Control.PRESET_BOTTOM_LEFT` (2)
- `_active_chat_tab`: `String` ("All", "Current", "Team", "Guild", "Whisper", "System")
- `_current_channel`: `String` ("Local", "World", "Team", "Guild", "Whisper", "System")
- `_dock_width`: `float` (dynamically responsive, range: $[380.0, 524.0]$)
- `_chat_is_locked`: `bool` (autoscroll toggle)
- `_chat_is_framed`: `bool` (compact parchment vs framed mode)

### Public Methods & Signatures
```gdscript
func set_dock_width(new_width: float) -> void
```
- Adjusts chat dock, history panel, and background width dynamically.
- Triggers `_update_input_bar_layout()` to preserve button alignment without clipping.

```gdscript
func set_chat_height(new_offset_top: float) -> void
```
- Cycles preset heights (`-86.0`, `-140.0`, `-200.0`) or applies continuous drag offset.
- Automatically adjusts `ChannelTabs.offset_top` to remain positioned directly above the panel.

```gdscript
func add_chat_message(sender: String, message: String, channel: String = "Local") -> void
func select_chat_tab(tab_name: String) -> void
func set_whisper_target(target_name: String) -> void
```

---

## 4. BottomActionDock (`scripts/ui/hud/bottom_action_dock.gd`)

### Properties & Exported Nodes
- `anchors_preset`: `Control.PRESET_BOTTOM_RIGHT` (3) / `Control.PRESET_CENTER_BOTTOM` (7)
- `current_anchor_mode`: `AnchorMode.ANCHOR_BOTTOM_RIGHT` or `AnchorMode.ANCHOR_CENTER_BOTTOM`

### Public Methods & Signatures
```gdscript
func set_anchor_mode(mode: AnchorMode) -> void
func trigger_hotkey(hotkey_index: int) -> void
func set_location_text(location_name: String, x: int, y: int) -> void
func set_compound_tooltip(button_id: int, title: String, hotkey: String, desc: String) -> void
func bind_slot_data(slot_idx: int, data: Dictionary) -> void
func get_slot_data(slot_idx: int) -> Dictionary
```

---

## 5. HUDManager (`scripts/ui/hud/hud_manager.gd`)

### Multi-Dock Coordination & Layout Collision Avoidance
```gdscript
func recalculate_responsive_layout(vp_size: Vector2) -> void
```
- Reads viewport dimensions ($w, h$).
- Enforces strict preset assignments on all active docks:
  1. `StatusDock`: $(x=0, y=0)$.
  2. `RadarMinimap`: $(x=w - 226, y=0)$.
  3. `HotbarDock`: $(x=w - 56, y=163)$.
  4. `BottomActionDock`: $(x=w - 282, y=h - 78)$.
  5. `ChatDock`: $(x=0, y=h - 25)$.
- **Collision Avoidance**: On narrow resolutions ($w \le 810$, e.g. $800 \times 600$ in 4:3), ChatDock default width ($524$px) plus ActionDock width ($282$px) equals $806$px, which would produce a $6$px overlap. `HUDManager` dynamically clamps `ChatDock` width to `w - 282 - 6 = 512`px, ensuring a minimum $6$px clearance and zero clipping across all screen sizes.

---

## Resolution Verification Matrix

| Resolution | Aspect Ratio | Category | Clearance Between Chat & Action | Status |
|------------|--------------|----------|----------------------------------|--------|
| $800 \times 600$ | 4:3 | Narrow Legacy | $6.0$ px | PASS |
| $1024 \times 768$ | 4:3 | Standard Legacy | $218.0$ px | PASS |
| $1280 \times 720$ | 16:9 | HD Standard | $474.0$ px | PASS |
| $1680 \times 1050$ | 16:10 | Widescreen Monitor | $874.0$ px | PASS |
| $1920 \times 1080$ | 16:9 | Full HD | $1114.0$ px | PASS |
| $2560 \times 1080$ | 21:9 | Ultrawide | $1754.0$ px | PASS |
