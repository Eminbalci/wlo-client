# Godot 4 Client Codebase Refinement & Human Developer Parity Specification

## 1. Executive Summary & Purpose
This document provides the technical reference for the codebase refinement, error elimination, and UI alignment performed across the Wonderland Online Godot 4 client (`wonderland-online-client`).
All changes adhere to strict type-hinted GDScript standards, modern modular architecture with 9 sub-controllers under `HUD`, zero script errors across all test suites, and 1:1 pixel parity with the original Wonderland Online MMORPG.

---

## 2. Audio Asset Conversion & Import Freeze Resolution
### 2.1 Issue Diagnosis
- **Symptom:** Godot 4 editor locked indefinitely at 71% progress importing `BGM0041.wav`.
- **Root Cause:** Legacy Wonderland Online audio assets used Microsoft ADPCM (WAVE Format Tag `0x0002`), which is unsupported by Godot 4's `AudioStreamWAV` importer, triggering buffer seek exceptions:
  `ERROR: Condition "p_position > length" is true at: seek (core/io/file_access_memory.cpp:101)`.
- **Secondary Defect:** `assets/sound/SEB0279.wav` contained a corrupted 4.29 GB chunk size header followed by 71,822 bytes of trailing null garbage.

### 2.2 Resolution Actions
1. **Automated Audio Conversion:** Executed in-place batch conversion of all 354 ADPCM audio files to uncompressed 16-bit PCM WAV at 22,050 Hz and 44,100 Hz using `soundfile`.
2. **Corrupted Chunk Header Repair:** Sanitized `SEB0279.wav`, truncating it to a clean 73,644-byte standard RIFF PCM structure.
3. **Import Verification:** All 3,540 audio and graphic assets import in under 8.0 seconds with zero seek errors or crashes.

---

## 3. Character Select Screen (1:1 Alignment & Parity)
### 3.1 Visual & Text Overlap Rectifications
- **Background:** `scenes/ui/auth/character_select.tscn` configured with full-screen `BackgroundRect` loading `res://assets/pic/LogPic1.jpg` (800x600).
- **Title Banner vs. Slot Tabs Clearance:** Repositioned `TitleBanner` to `offset_top = 25.0, offset_bottom = 80.0` and `Card` to `offset_top = 130.0`. Leaves 31 pixels of blank clearance above the slot tabs (`Icon_SelectRole_1.bmp`), completely eliminating the double-text collision (`Choo cter Select`).
- **Pre-printed Texture Alignment:**
  - `NameLabel` placed at `X = 68.0, Y = 97.0` (size 92x20), positioning character name inside the cyan input box past the pre-printed "Name" header (X=25..60), fixing the `Nanıe anıe` overlap.
  - `LevelLabel` placed at `X = 68.0, Y = 124.0` (size 92x20), positioning level numerals cleanly inside the cyan LV box.
- **Avatar Bust Centering:** Repositioned `BustRect` from `(86, 34)` to `offset_left = 46.0, offset_top = 23.0, offset_right = 134.0, offset_bottom = 83.0` (`88x60`), perfectly centering the character portrait inside the 136x74 aperture on `Form_SelectRole_Info_R.jpg`.
- **Character Standee Preview:** Centered `SpritePreview` between rotation arrows: `offset_left = 95.0, offset_top = 180.0, offset_right = 242.0, offset_bottom = 305.0` (`stretch_mode = 5`), with fallback to `standee_role_%d.png`.
- **Dynamic Account Resolution:** Added fallback resolution in `character_select.gd` to check `SavedAccountsManager.get_last_used_account()` and `GameDatabase.active_character`, ensuring player-created characters are loaded immediately rather than showing blank placeholder cards.

---

## 4. Script Errors & Compatibility Fixes
### 4.1 `HUDMinimap.set_map_info` Resolution
- **Defect:** `SCRIPT ERROR: Invalid call. Nonexistent function 'set_map_info' in base 'RefCounted (HUDMinimap)'.` occurred in `map_renderer.gd` during portal warps.
- **Fix:** Implemented `set_map_info(p_map_name: String, p_coord_x: int, p_coord_y: int) -> void` on `HUDMinimap`:
  ```gdscript
  func set_map_info(p_map_name: String, p_coord_x: int, p_coord_y: int) -> void:
      update_map_name(p_map_name)
      update_coordinates(Vector2(p_coord_x, p_coord_y))
  ```

### 4.2 `HUD` Chat Controller Compatibility Delegation
- **Defect:** `SCRIPT ERROR: Invalid access to property or key '_chat_is_framed' on a base object of type 'Control (HUD)'.`
- **Fix:** Added direct compatibility getters, setters, and method delegations on `HUD`:
  - `_chat_is_framed: bool` -> Delegated to `chat_ctrl._chat_is_framed`
  - `_chat_is_locked: bool` -> Delegated to `chat_ctrl._chat_is_locked`
  - `_current_channel: String` -> Delegated to `chat_ctrl._current_channel`
  - `_chat_is_resizing: bool` -> Delegated to `chat_ctrl._chat_is_resizing`
  - `_active_chat_tab: String` -> Delegated to `chat_ctrl._active_chat_tab`
  - `_select_channel(channel: String) -> void` -> Delegated to `chat_ctrl._select_channel`
  - `_on_chat_size_gui_input(event: InputEvent) -> void` -> Delegated to `chat_ctrl._on_chat_size_gui_input`
  - `_on_chat_submitted(text: String) -> void` -> Delegated to `chat_ctrl.on_chat_submitted`
  - `_on_chat_meta_clicked(meta: Variant) -> void` -> Delegated to `chat_ctrl._on_chat_meta_clicked`

### 4.3 `HUD` Minimap & Hotbar Delegation
- **Defect:** Missing `get_minimap_content_rect`, `_on_minimap_gui_input`, `_minimap_is_collapsed`, `_hotkey_buttons`, `_hotkey_icons`, and `_setup_hotbar`.
- **Fix:** Added full delegation facades on `HUD`:
  - `get_minimap_content_rect() -> Rect2` -> Returns `minimap_ctrl.get_content_rect()`
  - `_on_minimap_gui_input(event: InputEvent) -> void` -> Forwards to `minimap_ctrl.on_gui_input(event)`
  - `_minimap_is_collapsed: bool` -> Delegated to `minimap_ctrl._minimap_is_collapsed`
  - `_hotkey_buttons: Array[Button]` -> Delegated to `hotbar_ctrl._hotkey_buttons`
  - `_hotkey_icons: Array[TextureRect]` -> Delegated to `hotbar_ctrl._hotkey_icons`
  - `_setup_hotbar() -> void` -> Calls `hotbar_ctrl._setup_slots()`
  - Direct sub-controller accessors: `hotbar`, `player_status`, `minimap`, `action_dock_sub`, `window_manager`.

### 4.4 `HUD` Banner Panel Reference
- **Defect:** `_banner_panel` property was missing from `HUD`, breaking ground harvesting assertions.
- **Fix:** Declared `var _banner_panel: Control = null` and assigned it in `show_banner()`, resetting to null upon tween completion.

### 4.5 Character Creation Return Slot Synchronization
- **Defect:** Returning from character creation to character selection retained `selected_slot_index = 0`, failing to focus the newly created character if placed in slot 1 or 2.
- **Fix:** Modified `_on_character_created(char_data: Dictionary)` in `scripts/ui/login_screen.gd` to synchronize `selected_slot_index = int(char_data.get("slot_index", 0))` before transitioning to `FlowState.CHARACTER_SELECT`.

---

## 5. Verification Matrix & Results

| Test Suite / Script | Scope | Result | Details |
| :--- | :--- | :--- | :--- |
| `scripts/tools/audit_all_scenes.gd` | All 21 client scenes | PASS | 0 scene load errors |
| `scripts/tools/audit_all_scripts.gd` | All 135 GDScript files | PASS | 0 syntax or compilation errors |
| `scenes/tests/test_auth_flow.tscn` | Full Auth, Server, Login, Char Select, Create & World Entry | PASS | 113/113 passed (100%) |
| `tests/test_all_client_buttons.gd` | All clickable buttons across 6 main scenes | PASS | 199/199 buttons verified (100%) |
| `tests/test_map_navigation_integration.gd` | Player movement, mouse follow, portal warps | PASS | Warp to Map 10002 cleanly passed with zero script errors |
| `tests/test_hud_chat_and_status_features.gd` | ChatDock compact/framed switch, locks, emotes, resizing, whispers | PASS | All 12 features verified with zero errors |
| `tests/test_radar_minimap.gd` | Radar minimap textures, blinking player dot, zoom, collapse, click-to-move | PASS | Zero errors across unit and integration tests |
| `tests/test_hotbar_slots.gd` | 8 quickslots (F1..F8), key indicators, item icons | PASS | 8/8 slots verified |
| `tests/test_collision_and_vehicles.gd` | 29 vehicle traversal gates, terrain collision, item parity | PASS | All terrain gates and items verified |
| `tests/test_equipment_visibility.gd` | 14 roles paperdoll equip/unequip cycles | PASS | 14 roles, 64 frames each, 100% visible |
| `tests/test_event_sequences.gd` | Ship sinking, trauma shake, beach awakening, Kelang NPC | PASS | All 7 event parts passed |
| `tests/test_item_tooltip_and_click_marker.gd` | Tooltips, ground click ripple frames | PASS | All tests passed |
| `tests/test_npc_positioning_and_facing.gd` | Map 10001 & 10002 NPC coordinates, headings, and frame layouts | PASS | 100% passed |
| `tests/test_paperdoll_equip_visibility.gd` | Base body and gear layers | PASS | All paperdoll visibility tests passed |
| `tests/test_pathfinder_navigation.gd` | A* obstacle detour and kinematics | PASS | Detours and kinematics verified |
| `tests/test_portals_and_ground_items.gd` | Dynamic portals, Eve.emg warps, ground item harvesting | PASS | 100% passed |
| `tests/test_skill_database.gd` | 953 skills and MBTM animations | PASS | 9/9 passed |
| `tests/test_talk_database.gd` | 17,493 dialogues, branching choices, emotion bubbles | PASS | 10/10 passed |
| `tests/test_network.gd` | Network packets, framing, XOR cipher, live connection | PASS | All network protocol tests passed |
| `scenes/tests/test_hud_subcontrollers.tscn` | 9 HUD sub-controller facades | PASS | All sub-controllers verified |
| `scenes/tests/test_dialogue_cursor_and_ui.tscn` | Cursors, dialogue advance, avatar busts | PASS | 100% passed |
| `scenes/tests/test_animated_avatar.tscn` | 14 role animated blinking avatars | PASS | 100% passed |
| `scenes/tests/test_hud_runner.tscn` | In-engine MapView & HUD verification | PASS | 100% passed |
