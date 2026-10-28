# Studio Editors Responsive Layout & Overflow Resolution Specification

## 1. Overview
This specification details the structural UI hierarchy and layout modifications applied across the Wonderland Online Studio Editors to eliminate UI clipping and screen overflow on low-resolution displays (e.g., vertical height < 760px, horizontal width < 1280px).

## 2. Modified Scenes & Node Hierarchies

### 2.1 Tent & Furniture Studio (`scenes/tools/tent_editor.tscn`)
- **TopBar Toolbar:** Changed container from `HBoxContainer` to `HFlowContainer` with `h_separation = 6` and `v_separation = 4`, allowing control buttons (presets, wallpaper, flooring, JSON save/load, export) to wrap gracefully rather than pushing the window beyond 1280px.
- **Canvas Toolbar:** Converted from `HBoxContainer` to `HFlowContainer` (`h_separation = 4`, `v_separation = 4`).
- **Left Panel:** Wrapped `LeftVBox` inside `[node name="LeftScroll" type="ScrollContainer" parent="MainVBox/ContentHBox/LeftPanel"]` with `size_flags_vertical = 3` and `horizontal_scroll_mode = 0`. Set `FurnitureList` `custom_minimum_size = Vector2(0, 160)`.
- **Right Panel:** Wrapped `RightVBox` inside `[node name="RightScroll" type="ScrollContainer" parent="MainVBox/ContentHBox/RightPanel"]` with `size_flags_vertical = 3` and `horizontal_scroll_mode = 0`.
- **Root Node:** Assigned `custom_minimum_size = Vector2(800, 600)`.

### 2.2 Battle Formation & Encounter Studio (`scenes/tools/battle_editor.tscn`)
- **Inspector Tabs:** Wrapped `Slot Inspector` in a `ScrollContainer` with `horizontal_scroll_mode = 0`, containing `SlotVBox` with `size_flags_horizontal = 3` and `size_flags_vertical = 3`.
- **Root Node:** Assigned `custom_minimum_size = Vector2(800, 600)`.

### 2.3 Cutscene & Event Sequence Director (`scenes/tools/cutscene_editor.tscn`)
- **Inspector Tabs:**
  - Tab 0 (`Tracks & Keys`): Converted to a `ScrollContainer` with `horizontal_scroll_mode = 0` containing `TracksVBox`. `KeyframeItemList` configured with `custom_minimum_size = Vector2(0, 120)`.
  - Tab 1 (`Key Inspector`): Converted to a `ScrollContainer` with `horizontal_scroll_mode = 0` containing `KeyInspectorVBox` to ensure camera, actor, dialogue, audio, and screen FX parameter boxes scroll on short viewports.
- **Root Node:** Assigned `custom_minimum_size = Vector2(800, 600)`.

### 2.4 Audio Jukebox & Sound Design Studio (`scenes/tools/audio_editor.tscn`)
- **Right Pane Tabs:**
  - `TabMapBgm`: Converted to `ScrollContainer` (`horizontal_scroll_mode = 0`) containing `VBoxMap`. `TreeMapBindings` configured with `custom_minimum_size = Vector2(0, 160)`.
  - `TabCombatSkill`: Converted to `ScrollContainer` (`horizontal_scroll_mode = 0`) containing `VBoxSkill`. `TreeSkillBindings` configured with `custom_minimum_size = Vector2(0, 160)`.
  - `TabAmbience`: Converted to `ScrollContainer` (`horizontal_scroll_mode = 0`) containing `VBoxAmb`.
  - `TabLogSummary`: Converted to `ScrollContainer` (`horizontal_scroll_mode = 0`) containing `VBoxLog`. `TextLog` configured with `custom_minimum_size = Vector2(0, 160)`.
- **Root Node:** Assigned `custom_minimum_size = Vector2(800, 600)`.

### 2.5 World Editor Root Window Adapter (`scripts/tools/world_editor.gd`)
- In `_adapt_to_window_size()`:
  - Fetched `var vp_size: Vector2 = get_viewport_rect().size`.
  - Set anchors preset to `PRESET_FULL_RECT` with zero offsets (`offset_left = 0`, `offset_top = 0`, `offset_right = 0`, `offset_bottom = 0`).
  - Set `size = vp_size` to ensure edge-to-edge window coverage without letterboxing or viewport clipping.

## 3. Headless Verification Results
Executed automated test suites using `godot_console.exe --headless`:
1. `res://tests/test_tent_editor_runner.gd`: 10/10 tests PASSED (100%).
2. `res://tests/test_world_editor.gd`: 11 tabs verified, all database inspector queries, embedded map/NPC studios, and simulator life-cycle PASSED (100%).
3. `res://tests/test_battle_editor.gd`: 9/9 tests PASSED (100%).
4. `res://tests/test_cutscene_editor.gd`: 8/8 tests PASSED (100%).
5. `res://tests/test_audio_editor.gd`: 9/9 tests PASSED (100%).
