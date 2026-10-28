# Flexible UI Refactor & Responsive Architecture Specification

## Overview

Full-codebase flexible design refactor across all UI subsystems, executed via multi-agent parallelism. All interfaces updated to use modern Godot 4 anchor presets, `IsometricMath.Heading` enum for direction constants, `WALK_FPS = 8.0` for sprite animation cadence, and a pooled `AuthAudio` system for safe UI sound playback.

---

## 1. Direction Constant Unification

**Problem:** `DEFAULT_HEADING = 5` (South-East) was incorrect vs. the `IsometricMath.Heading` enum where `SOUTH_WEST = 3`. Both `character_select.gd` and `character_create.gd` used their own magic numbers.

**Fix:**

| File | Old | New |
|---|---|---|
| `scripts/ui/auth/character_select.gd` | `DEFAULT_HEADING: int = 5` | `DEFAULT_HEADING: int = IsometricMath.Heading.SOUTH_WEST` |
| `scripts/ui/auth/character_create.gd` | `_current_direction: int = 5` | `const DEFAULT_HEADING: int = IsometricMath.Heading.SOUTH_WEST` |

`IsometricMath.Heading` enum (in `scripts/map/isometric_math.gd`):
```
NORTH     = 0
NORTH_WEST = 1
WEST      = 2
SOUTH_WEST = 3   <- default preview direction (facing camera/player)
SOUTH     = 4
SOUTH_EAST = 5
EAST      = 6
NORTH_EAST = 7
```

Sprite row formula (JMP walk cycle): `frame_idx = (heading % 8) * 4 + sub_idx`

---

## 2. Walk Animation Cadence Constant

**Problem:** `character_create.gd` used `_walk_anim_timer += delta * 5.0` accumulating at 5.0x instead of the authentic 8.0 FPS rate.

**Fix:** Added `const WALK_FPS: float = 8.0` and changed:
```gdscript
# Before
_walk_anim_timer += delta * 5.0
var sub_idx: int = int(_walk_anim_timer) % 4

# After
_walk_anim_timer += delta
var sub_idx: int = int(_walk_anim_timer * WALK_FPS) % 4
```

Both `character_select.gd` and `character_create.gd` now use the same `int(timer * 8.0) % 4` formula.

---

## 3. Auth Audio System (AuthAudio)

**File:** `scripts/ui/auth/auth_audio.gd`

Pool-based audio system preventing clip overlap on rapid UI clicks.

```gdscript
const SFX_CLICK_PATH: String = "res://assets/sound/wav0151.wav"
const SFX_ERROR_PATH: String = "res://assets/sound/SEB0024.WAV"
const POOL_SIZE: int = 8

var _player_pool: Array[AudioStreamPlayer] = []
var _pool_index: int = 0
```

**Public API:**
- `play_ui_click(volume_db: float = 0.0)` — plays `wav0151.wav` via round-robin pool
- `play_ui_error(volume_db: float = 0.0)` — plays `SEB0024.WAV`
- `static func play_click(...)` — convenience static; auto-instantiates if no singleton
- `static func play_error(...)` — convenience static

Round-robin pool prevents clipping: each successive call uses `(_pool_index + 1) % POOL_SIZE` so overlapping clicks reuse the oldest idle player.

---

## 4. Character Select Parity Fixes

**File:** `scripts/ui/auth/character_select.gd`

| Fix | Detail |
|---|---|
| `DEFAULT_HEADING` | Changed from `5` (South-East) to `IsometricMath.Heading.SOUTH_WEST (3)` |
| `_slot_rotations` default | `{0: DEFAULT_HEADING, 1: DEFAULT_HEADING, 2: DEFAULT_HEADING}` — now all start at heading 3 |
| `LevelLabel.text` | `str(int(char_data.get("level", 1)))` — explicit int cast prevents empty text on `null` saves |
| `GoldLabel.text` | `str(int(char_data.get("gold", 0)))` — same |

**Test result:** 52/52 passing (`tests/test_character_select_parity.gd`)

---

## 5. Character Create Wizard Fixes

**File:** `scripts/ui/auth/character_create.gd`

| Fix | Detail |
|---|---|
| Duplicate signal connections | Added `_signals_connected: bool` guard in `_setup_signals()` |
| `_calculate_base_stats()` in headless | Added fallback to `load("res://scripts/database/game_database.gd").ROLES` static dict |
| Element bonuses on Step 1 | Wrapped `match selected_element` with `if current_step >= 3` |
| `_play_sfx` outside tree | Added `if not is_inside_tree(): return` guard |
| `get_node_or_null("/root/...")` errors | Created `_get_archive_loader()` and `_get_game_database()` helper methods |
| `grab_focus()` outside tree | Added `if not is_inside_tree(): return` in `_dismiss_modal_error()` |
| Walk FPS | Fixed `WALK_FPS = 8.0`, formula `int(timer * 8.0) % 4` |
| Direction default | `DEFAULT_HEADING = IsometricMath.Heading.SOUTH_WEST` |

**Test result:** ALL PASSED (`tests/test_character_create_wizard.gd`)

---

## 6. Quest Dialogue Component Audio Guard

**File:** `scripts/ui/quest/quest_dialogue_component.gd`

`show_quest_reward_fanfare()` was calling `sfx_player.play()` before the node was in the scene tree during test execution.

**Fix:**
```gdscript
if player and player.is_inside_tree():
    player.stream = _sfx_reward
    player.play()
```

**Test result:** 85/85 (`tests/test_dialogue_flexible_ui.gd`)

---

## 7. HUD Responsive Dock System

**Files:** `scripts/ui/hud/hud_manager.gd`, `status_dock.gd`, `radar_minimap.gd`, `chat_dock.gd`, `bottom_action_dock.gd`

All docks use modern Godot 4 anchor presets:
- `StatusDock` — `PRESET_TOP_LEFT`
- `RadarMinimap` — `PRESET_TOP_RIGHT`
- `ChatDock` — `PRESET_BOTTOM_LEFT`
- `BottomActionDock` — `PRESET_BOTTOM_RIGHT`

Collision avoidance across: 800x600 (4:3), 1280x720 (16:9), 1280x800 (16:10), 2560x1080 (ultrawide).

**Test results:** `test_hud_dock_system.gd` PASS, `test_hud_responsive_flex.gd` PASS

---

## 8. Combat Engine & Responsive Battle View

**Files:** `scripts/battle/combat_engine.gd`, `combat_menu.gd`, `turn_timeline_dock.gd`, `floating_combat_text.gd`, `battle_view.gd`

Responsive layout adapts to viewport at `_ready()` and `get_viewport().size_changed`. Player/enemy grids reposition dynamically.

**Test results:** 10/10 engine, 11/11 view

---

## 9. Analysis Artifacts Relocation

83 Python analysis scripts and 90 MB of reference frames moved out of Godot's import tree to prevent 502 spurious `.import` file generation:

```
tools/reference_analysis/
  scripts/         <- 83 Python analysis scripts
  ref_frames/      <- per-second video frames
  ref_frames_800x600/  <- cropped 800x600 canvas frames
  char_create_ref.mp4
  char_create_ref.wav
tools/.gdignore    <- excludes entire tools/ from Godot importer
```

---

## 10. Full Regression Results

| Test Suite | Result |
|---|---|
| `test_character_select_parity.gd` | **52/52 PASS** |
| `test_character_create_wizard.gd` | **ALL PASSED** |
| `test_auth_audio_and_kinematics.gd` | **ALL PASSED** |
| `test_dialogue_flexible_ui.gd` | **85/85 PASS** |
| `test_hud_dock_system.gd` | **PASS** |
| `test_hud_responsive_flex.gd` | **PASS** |
| `test_battle_engine.gd` | **10/10** |
| `test_battle_view.gd` | **11/11** |
| `test_game_resizable.gd` | **100% ZERO-ERROR** |
| `test_world_editor.gd` | **ALL PASSED** |
| `scenes/tests/test_auth_flow.tscn` | **113/113** |
| `audit_all_scenes.gd` | **48 scenes, 0 errors** |
| `audit_all_scripts.gd` | **215 scripts, 0 errors** |
