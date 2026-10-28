# Chat Visual Cleanup & Background Image Removal Specification

## Executive Summary
This document specifies the removal of the cropped background image (`assets/hud/chat_input_bg.png`) and legacy skin bitmap artifacts from the chat subsystem (`scripts/ui/hud/hud_chat.gd` and `scripts/ui/hud/chat_dock.gd`) in the Wonderland Online Godot 4 client.

## Problem Description & Root Cause
1. **Chat Input Bar Screenshot Background (`chat_input_bg.png`):**
   - `ChatInputBackground` was assigned `assets/hud/chat_input_bg.png` at runtime.
   - `chat_input_bg.png` was an authentic client screenshot crop with hard-baked English text (`"channel"`), a static mail square, and frame scrollwork.
   - Real interactive Godot controls (`BtnMail`, `BtnChannel`, `ChatInput`, `WhisperTarget`, `BtnEmote`) were rendered directly on top of this screenshot, causing doubled text ("channel" under "Local"), misalignment, and visual clashing.
2. **Chat History Overworld Transparency vs Frame Mode:**
   - In authentic WLO, chat text floats directly over the game world with a strong black font outline (`outline_size = 4`), without an artificial dark box in normal state.
   - When focused to type, it transitions to a clean framed presentation.
3. **Sender Character Avatar Portraits:**
   - In authentic WLO, character speech lines (e.g. `[World]`, `[Local]`) feature the sender's character face portrait icon, whereas system notifications (`[System]`) do not.

## Solutions Implemented

### 1. Removal of `chat_input_bg.png` Background Image
- In both [hud_chat.gd](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/ui/hud/hud_chat.gd) and [chat_dock.gd](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/ui/hud/chat_dock.gd):
  - Set `chat_input_bg.texture = null`.
  - Removed all runtime assignment of `assets/hud/chat_input_bg.png`.
- Procedural styling for `ChatInput`:
  - Background: `Color(0.04, 0.06, 0.09, 0.90)` (normal) / `Color(0.03, 0.05, 0.08, 0.98)` (focus).
  - Authentic gold border: 1px `Color(0.70, 0.58, 0.35, 0.85)` (normal) / `Color(0.95, 0.82, 0.42, 1.0)` (focus).
  - Corner radius: 2px with clean internal text padding.
- `BtnMail`, `BtnChannel`, `WhisperTarget`, and `BtnEmote` now render crisply with zero ghost text or background artifacts underneath.

### 2. Authentic Overworld Text Floating & Focus Highlighting
- When unfocused (normal exploration): `ChatHistoryPanel` has `bg_color = Color(0, 0, 0, 0)` with no border, matching original WLO client behavior where text floats over the world.
- When focused (user typing): Transitions to a subtle semi-opaque dark slate fill (`Color(0.04, 0.06, 0.10, 0.88)`) with a 1px border (`Color(0.35, 0.50, 0.65, 0.80)`).

### 3. Preserved Sender Avatar Portraits
- `_append_chat_entry()` checks `face_path`:
  - Player/companion messages with valid avatars render the 16x16 face portrait icon on the left column.
  - System messages render purely as clean text without dummy placeholder boxes.

## Verification & Automated Tests
- `tests/test_hud_chat_and_status_features.gd`: Passed 100% (0 errors).
- `tests/test_hud_dock_system.gd`: Passed 100% (0 errors).
- `tests/test_battle_view_scene.gd`: Passed 100% (11/11).
- `tests/test_encounters_and_battle_flow.gd`: Passed 100% (23/23).
