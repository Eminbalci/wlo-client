# HUD Chat, Emotes, and Player Status Parity Documentation

## Overview
This document details the exact parity implementation and verification of the HUD Chat system, Emoticon popup grid (31 emoticons), Channel selector menu (Whisper, Team, Guild, World, Local), automatic whisper triggering, resizable vertical chat height (140px to 450px), and Player Status Dock element icons and role avatars in `res://scripts/ui/hud.gd` matching authentic Wonderland Online client screenshots and reference videos (`video_seconds/sec_321.png` to `sec_424.png`).

---

## Key Features & Specifications

### 1. Panel_TalkForm Skin & Compact vs Framed Toggle (`btn_chat_switch`)
- **Compact Mode:** Default view featuring a clean, minimal chat history overlay without heavy framing.
- **Framed Mode (`Panel_TalkForm` / NinePatchRect):** Toggled via `btn_chat_switch`. Applies authentic decorative chat framing textures (`ui_chat_frame.png` or `frame_chat.png`).
- **Toggle State:** Handled in `scripts/ui/hud.gd` via `_on_chat_switch_pressed()`, toggling `_chat_is_framed` and updating NinePatch visibility.

### 2. Draggable Vertical Resize Bar & Size Cycling (`btn_chat_size`)
- **Vertical Height Range:** 140px to 450px.
- **Cycling Button:** Clicking `btn_chat_size` cycles through standard heights (-86px compact, -140px medium, -200px tall).
- **Draggable Handle:** Supports smooth vertical dragging to dynamically adjust chat height between 140px and 450px.

### 3. Emoticon Grid Popup (31 Emoticons) & Animated Insertion
- **Emoticon Popup:** Accessible via `BtnEmote` (`btn_emote`). Opens a popup grid containing exactly **31 emoticons** (`#01` through `#31`).
- **Insertion:** Clicking any emoticon button appends its corresponding code (e.g. `#01`) into `ChatInput` at the cursor position and closes the popup.

### 4. Channel Selector Menu & Active Indicators
- **Channels:** Local, Whisper, Team, Guild, World.
- **Selector Button (`BtnChannel`):** Displays current channel and opens a drop-down/popup menu to switch channels instantly.
- **Active Indicators:** Visually highlights the active channel in the menu.

### 5. Automatic Whisper Mode Triggering
- **Whisper Target Input (`WhisperTarget`):** Typing a player name into the target field automatically switches the active chat channel to **Whisper** and formats outgoing messages as `To <PlayerName>`.

### 6. Ground Click Destination Marker Ring Animation
- **Map Interaction:** Clicking on the ground in the game world instantiates an animated destination marker ring at the target coordinates, playing a pulsing expansion/fade animation before freeing itself.

### 7. Player Status Dock & Chroma Mask Bars
- **Element Icons:** Dynamically maps element IDs/names (1: Earth, 2: Water, 3: Fire, 4: Wind) to `icon_element_1.png` through `icon_element_4.png`.
- **Role Avatars:** Supports role portrait switching (Daniel, Betty, Nina, etc.).
- **Chroma Mask Bars:** Authentic 3-layer chroma mask bars for HP, SP, and EXP.

---

## Test Execution & Verification

All HUD chat and status features are fully verified via automated in-engine test suites with **0 errors**:

```bash
godot --headless --path D:\Godot\WonderlandOnline\wonderland-online-client -s tests/test_hud_chat_and_status_features.gd
```
