# HUD Emotes, Whisper System, Overhead Bubbles, and Radar Minimap Specification

## Overview
This document specifies the technical architecture and parity implementation of the **31 Animated Emoticons Popup**, **Overhead Speech & Emote Bubble System**, **Whisper Targeting System**, **Ground Click & Radar Waypoint Markers**, and **Radar Minimap Controls** in Wonderland Online Client (`scenes/ui/hud.tscn`, `scripts/ui/hud.gd`, `scripts/world/player.gd`), matching video analysis frames (`sec_321.png` to `sec_424.png`).

---

## 1. 31 Animated Emoticons Popup & Overhead Bubble System
- **Trigger**: Activated via the Emote toggle button (`btn_emote`) on the HUD chat dock.
- **Layout**: Floating multi-column popup grid (`panel_expression.png`, $263 \times 69$) containing exactly **31 authentic animated emoticons** (`#01` to `#31`) extracted from `assets/hud/icon_expre_*.png`.
- **Chat Input Insertion**: Clicking any emoticon icon inserts its code (`#01` .. `#31`) directly into `ChatInput` and restores focus.
- **Overhead Bubble Display**:
  - Selecting an emoticon emits `overhead_bubble_emitted(code)` and triggers `player.show_speech_bubble(code)` on the player entity.
  - Submitting chat text also displays the message in an overhead speech bubble above the player's head.
  - Emote bubbles render the authentic 16x16 icon centered in a parchment panel; text messages display word-wrapped dark text inside a rounded parchment speech bubble.
  - Bubbles feature scale pop-in animation, linger for the specified duration, and smoothly fade out.

---

## 2. Channel Selector & Whisper Targeting System
- **Channel Dropdown**: Supports Local, Team, Guild, World, and Whisper channels via `btn_channel` and `channel_dropdown`.
- **Channel Tabs**: 6 filtering tabs (`BtnTabAll`, `BtnTabCurrent`, `BtnTabTeam`, `BtnTabGuild`, `BtnTabWhisper`, `BtnTabSystem`) allow instantaneous message filtering by category.
- **`/target` Syntax**:
  - Typing `/target <PlayerName> [Message]` or `/w <PlayerName> [Message]` parses the target player, sets `WhisperTarget`, switches channel to `Whisper`, and immediately dispatches private text.
- **Click-to-Whisper**:
  - Sender names in chat are rendered with rich metadata `[url=whisper:<PlayerName>]`.
  - Clicking any player name in `ChatHistory` automatically routes to `whisper_to_player()`, setting target and focusing input.

---

## 3. Destination Click & Radar Minimap Waypoint Markers
- **Terrain Ground Click**:
  - Left-clicking on the terrain instantiates an animated destination marker ring (`click_ripple.tscn`) at target world coordinates.
  - Plays 4 authentic $64 \times 64$ animation frames at 10 FPS before auto-freeing.
- **Radar Minimap Waypoint Marker**:
  - Clicking anywhere inside `MinimapView` sets a pulsing radar waypoint marker (`MinimapWaypoint`).
  - Renders a cyan core, dark contrast drop shadow, and pulsing radar outer ring (`_pulse_scale` oscillation).
  - Automatically clears upon arrival or via `clear_minimap_waypoint()`.

---

## 4. Radar Minimap Controls & Player Indicator
- **Map Thumbnail**: 212x131 in-memory bilinear downscale from full-resolution `map.JMG` textures via `ArchiveLoader.get_minimap_texture()`.
- **Blinking Green Indicator**: `MinimapMarker` blinks between neon green `Color(0.15, 0.98, 0.2, 1.0)` and golden yellow `Color(1.0, 0.92, 0.1, 1.0)` every 0.25s.
- **Zoom In (+) Button (`BtnZoomIn`)**: Increments minimap zoom scale by $+0.25\times$ up to $2.5\times$, pivoting on the player indicator.
- **Zoom Out (-) Button (`BtnZoomOut`)**: Decrements minimap zoom scale by $-0.25\times$ down to $0.75\times$.
- **Style Collapse Toggle (`BtnMinimapToggle`)**: Toggles between expanded full radar frame and compact collapsed title bar mode.

---

## 5. Verification & Test Suites
All features verified via headless Godot 4 execution:
```powershell
& "C:\Godot\godot_console.exe" --headless --path "D:\Godot\WonderlandOnline\wonderland-online-client" -s res://tests/test_radar_minimap.gd
& "C:\Godot\godot_console.exe" --headless --path "D:\Godot\WonderlandOnline\wonderland-online-client" -s res://tests/test_hud_chat_and_status_features.gd
& "C:\Godot\godot_console.exe" --headless --path "D:\Godot\WonderlandOnline\wonderland-online-client" scenes/tests/test_hud_runner.tscn
```
- Test Results:
  - `[PASS] Initial minimap_view texture loaded: size=(212.0, 131.0)`
  - `[PASS] PlayerMarker verified inside MinimapView`
  - `[PASS] Minimap click-to-move input handler and waypoint marker verified`
  - `[PASS] Minimap Zoom In (+) verified (zoom=1.250000)`
  - `[PASS] Minimap Zoom Out (-) verified (zoom=1.000000)`
  - `[PASS] Minimap toggle style collapse verified`
  - `[PASS] Real-time player marker position updates verified during movement`
  - `[PASS] Emote popup with 31 authentic emotes verified, inserting code and emitting overhead bubble`
  - `[PASS] Vertical draggable resizer handle verified`
  - `[PASS] Channel tabs (All, Current, Team, Guild, Whisper, System) filtering verified`
  - `[PASS] /target syntax correctly sets whisper target and dispatches private message`
  - `[PASS] Clicking player name in chat automatically routes to whisper targeting`
  - `--- ALL VERIFICATIONS PASSED WITH ZERO ERRORS ---`
