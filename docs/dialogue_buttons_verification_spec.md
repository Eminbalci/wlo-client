# Dialogue Window & Choice Buttons Verification Specification

## Overview
This document specifies the architecture, verification, and testing of the NPC Dialogue and Choice system in Wonderland Online client (`D:\Godot\WonderlandOnline\wonderland-online-client`), implemented across [`dialogue_manager.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/ui/dialogue.gd) and [`hud.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/ui/hud.gd).

## Verification Requirements & Implementation

### 1. Dialogue Window Next / Advance Button & Clickable Frame
- **Behavior**: Advances to the next line of text with authentic typewriter effect / instant skip.
- **Implementation**: Connected in `_setup_dialogue()` with `MOUSE_FILTER_STOP` on both `next_icon` and `dialogue_dock` to catch left clicks anywhere on the dialogue box or next icon, invoking `advance_dialogue()`.
- **Status**: Verified via head-less automated test `scenes/tests/test_dialogue_cursor_and_ui.tscn`.

### 2. Dialogue Choice / Option Buttons
- **Behavior**: Clicking choice buttons selects the corresponding branch in the `Talk.dat` tree and emits `dialogue_choice_selected(index, text)`.
- **Implementation**: Dynamically instantiates VCL-styled choice buttons (`Form_Talk_3` options), connecting pressed signals to trigger callback handling and tree branching.
- **Status**: Verified in automated dialogue sequence integration tests.

### 3. Close / End Button
- **Behavior**: Ends dialogue and returns control to player.
- **Implementation**: Connected to hide `dialogue_dock` and emit `dialogue_closed`.
- **Status**: Verified.

### 4. Audio Triggers & Cursors
- **Behavior**: Plays dialogue advance / choice click SFX and coordinates global `CursorManager` states.
- **Status**: Fully verified (100% test pass).
