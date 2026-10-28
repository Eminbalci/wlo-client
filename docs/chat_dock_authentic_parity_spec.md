# Wonderland Online HUD Chat Dock Technical Specification

## Overview
This document specifies the technical architecture, layout coordinates, styling components, and behavioral contracts of the HUD Chat Dock (`scripts/ui/hud/chat_dock.gd` and `scripts/ui/hud/hud_chat.gd`) in the Wonderland Online Godot 4 client.

---

## 1. Geometry & Coordinate Alignments

The chat dock is anchored at the bottom-left viewport corner (`anchors_preset = Control.PRESET_BOTTOM_LEFT`, $X=0, Y=\text{Viewport Height}-25$).

| Component | Node Name | Bounds $(X, Y, W, H)$ | Visual Styling / Assets | Behavioral Contract |
|---|---|---|---|---|
| Input Background | `ChatInputBackground` | $(0, 0, \text{Width}, 25)$ | `assets/hud/chat_input_bg.png` (`main_input_1.bmp`) | Expands horizontally to `_dock_width`. |
| Mailbox Button | `BtnMail` | $(3, 2, 26, 21)$ | `btn_mail_normal.png`, `btn_mail_hover.png`, `btn_mail_pressed.png` | Opens mailbox, triggers unread message banner. |
| Channel Button | `BtnChannel` | $(30, 2, 42, 21)$ | `StyleBoxFlat` with dynamic channel border tint | Toggles `ChannelDropdown`. Reflects active channel. |
| Target Input | `WhisperTarget` | $(74, 2, 86, 21)$ | Translucent slate `StyleBoxFlat`, gold border | Visible only when active channel is Whisper or `/target` is invoked. |
| Chat Input | `ChatInput` | $(74 \text{ or } 163, 2, \text{Width}-102, 21)$ | Transparent `StyleBoxFlat`, gold blinking caret | Handles message entry, enter-to-send, `/target` parsing. |
| Emote Button | `BtnEmote` | $(\text{Width}-27, 1, 25, 23)$ | `btn_expression_normal.png`, hover, pressed | Toggles the 31-emoticon popup grid. |
| Emote Popup | `EmotePopup` | $(\text{Width}-265, -75, 263, 71)$ | `assets/hud/panel_expression.png` | Hosts 31-emote `GridContainer` (`#01`..`#31`). |
| Channel Dropdown | `ChannelDropdown` | $(30, -118, 44, 114)$ | `StyleBoxFlat` parchment with gold border | Selects Guild, Team, Whisper, World, or Local. |
| Channel Tabs Bar | `ChannelTabs` | $(0, \text{Panel Top}-21, 320, 21)$ | Seamless tab bar with custom `StyleBoxFlat` | Filters chat history by selected channel. |
| Chat History Panel| `ChatHistoryPanel` | $(0, \text{Panel Top}, \text{Width}, \text{Abs}(\text{Panel Top}))$| Semi-translucent dark parchment `StyleBoxFlat` | Houses rich message history and drag resizer. |
| History Text | `ChatHistory` | Inside `ChatHistoryPanel` | 12px normal font, drop shadows, 6px custom scrollbar | RichTextLabel rendering BBCode channel streams. |
| Drag Handle | `ChatResizeHandle` | $(0, 0, \text{Width}, 8)$ | Top margin, cursor: `CURSOR_VSIZE` | Smooth vertical resizing from -60px to -350px. |

---

## 2. Channel Tabs Styling Architecture

Channel tabs are styled dynamically via dedicated `StyleBoxFlat` instances avoiding engine-default button rendering:

- **Inactive State (`_style_tab_inactive`)**:
  - Background: `Color(0.04, 0.06, 0.09, 0.75)`
  - Border: `Color(0.50, 0.42, 0.28, 0.60)` (Top 1px, Left 1px, Right 1px, Bottom 0px)
  - Corner Radii: Top-Left 3px, Top-Right 3px
  - Font Color: `Color(0.82, 0.82, 0.80, 0.85)` with 1px dark outline
- **Hover State (`_style_tab_hover`)**:
  - Background: `Color(0.10, 0.14, 0.20, 0.88)`
  - Border: `Color(0.80, 0.70, 0.45, 0.88)`
  - Font Color: `Color(1.0, 0.95, 0.70, 1.0)`
- **Active State (`_style_tab_active`)**:
  - Background: `Color(0.12, 0.16, 0.24, 0.94)`
  - Border: `Color(0.96, 0.84, 0.40, 0.98)` (Top 2px gold highlight indicator)
  - Font Color: `Color(1.0, 0.92, 0.35, 1.0)` with 2px dark outline

---

## 3. Sleek Scrollbar Architecture

The standard bulky gray Godot scrollbar is replaced via programmatic styling on `chat_history.get_v_scroll_bar()`:
- `custom_minimum_size.x = 6.0`
- Track StyleBox: `Color(0.02, 0.03, 0.05, 0.25)`, corner radius 3px
- Grabber StyleBox: Antique bronze `Color(0.68, 0.56, 0.34, 0.75)`, gold border `Color(0.85, 0.72, 0.42, 0.85)` 1px, corner radius 3px
- Highlight Grabber: Radiant gold `Color(0.88, 0.76, 0.46, 0.95)`
- Pressed Grabber: Bright gold `Color(1.0, 0.88, 0.52, 1.0)`
- Stepper Arrows: Empty transparent textures eliminating unwanted arrow squares

---

## 4. Channel Color Coding & Formatting

| Channel | BBCode Tag | Tag Color | Sender Color | Body Color | Filter Criteria |
|---|---|---|---|---|---|
| `System` | `[System]` | `#ffcc33` (Gold) | None | `#ffffcc` (Cream) | `channel.to_lower() == "system"` |
| `Local` / `Current`| `[Current]` | `#42d766` (Green) | `#e8e8b0` (Gold URL) | `#ffffff` (White) | `"current"`, `"local"`, `"general"` |
| `Team` | `[Team]` | `#4ab3ff` (Cyan) | `#a0d8ff` (Light Blue URL) | `#e6f4ff` (Ice Blue) | `"team"` |
| `Guild` | `[Guild]` | `#32e070` (Emerald)| `#90ffbb` (Mint URL) | `#e8ffef` (Light Mint)| `"guild"` |
| `Whisper` | `[Whisper]`| `#ff66b2` (Magenta)| `#ffaed5` (Pink URL) | `#fff0f7` (Soft Rose)| `"whisper"` |
| `World` | `[World]` | `#ffea33` (Canary) | `#fff280` (Yellow URL) | `#fffde6` (Pale Yellow)| `"world"` |

---

## 5. Method Specifications

### `set_dock_width(new_width: float) -> void`
- **Parameters**: `new_width`: Target horizontal dock width (clamped minimum 380px).
- **Behavior**: Re-anchors history panel, tab bar, input fields, and right-aligned emote button.

### `add_chat_message(sender: String, message: String, channel: String = "Local") -> void`
- **Parameters**: `sender`: Player or system identifier; `message`: Text content; `channel`: Channel category.
- **Behavior**: Applies rate limiting (1.5s spam suppression), formats BBCode line, stores in history dictionary, appends to visible buffer if matching active tab.

### `select_chat_tab(tab_name: String) -> void`
- **Parameters**: `tab_name`: One of `"All"`, `"Current"`, `"Team"`, `"Guild"`, `"Whisper"`, `"System"`.
- **Behavior**: Clears `ChatHistory`, replays matching cached messages, updates tab visual states, emits `tab_changed`.

### `whisper_to_player(target_name: String, initial_msg: String = "") -> void`
- **Parameters**: `target_name`: Destination character name; `initial_msg`: Optional direct message text.
- **Behavior**: Populates `WhisperTarget`, switches channel to Whisper, adjusts input bar layout, focuses `ChatInput`.

---

## 6. Verification Test Suites

Automated in-engine headless tests pass with **0 errors**:
- `res://tests/test_chat_dock_polish.gd`
- `res://tests/test_hud_chat_and_status_features.gd`
- `res://tests/test_hud_hotbar_action_and_chat_fixes.gd`
