# Battle Round Timer, Dynamic Backdrop, & Pet Ring Specification

## Overview
This specification details the authentic battle system parity improvements implemented in Wonderland Online client, addressing real client findings from `docs/re/battle.md` and itemized discrepancy points in `docs/real_game_fidelity_gap_analysis.md`.

## 1. Dynamic Environmental Battle Backdrops & Ground Tinting
- **Source Files:** `scripts/battle/battle_view.gd`, `scripts/map/map_view.gd`
- **Asset Directory:** `assets/battle/`
  - `forest_battle_bg.png` (800x600 authentic forest arena)
  - `beach_battle_bg.png` (800x600 coastal shore with azure sky, ocean horizon, golden sand)
  - `cave_battle_bg.png` (800x600 subterranean cavern with stalactites and stone floor)
  - `deck_battle_bg.png` (800x600 passenger ship deck with railings, open ocean, and plank flooring)
- **Map Resolution Engine:**
  - `BattleView.resolve_environment_for_map(map_id, map_name)` maps overworld scenes to authentic environments:
    - Forest: North Island overland, forests, plains, grasslands (`Color(0.18, 0.38, 0.12, 1.0)` grass base).
    - Beach: Kelan Beach, South Island shores, coastal maps (`Color(0.82, 0.76, 0.58, 1.0)` sand base).
    - Cave: Kelan Underground Cave, Caverns, Mines (`Color(0.24, 0.22, 0.26, 1.0)` slate floor).
    - Deck: Ocean Star ship, cabins, decks (`Color(0.44, 0.30, 0.18, 1.0)` wood floor).
  - `MapView.start_battle()` dynamically queries scene database records to resolve the environment and triggers `_battle_view.set_environment(env_type)`.

## 2. Centered Digital Cyan Round Countdown Timer
- **Node:** `CountdownLabel` in `scripts/battle/battle_view.gd`
- **Visual Presentation:**
  - Centered horizontally at `get_field_offset().y + 240.0` with font size 42.
  - Digital cyan color `Color(0.25, 0.92, 1.0, 1.0)` with dark cyan outline `Color(0.02, 0.2, 0.3, 1.0)` (outline size 4).
  - Warning color transition: when remaining time <= 5 seconds, switches to warning red `Color(1.0, 0.25, 0.25, 1.0)`.
  - Configurable turn limit: `BattleManager.set_turn_time_limit(limit_sec)` (supports 20s or 30s limits per protocol specifications).
  - Automatically hides during round execution, victory, defeat, and escape.

## 3. 2-Phase Player to Pet Radial Ring Step
- **Interaction Sequencing:**
  - Phase 1 (Player): Turn begins at `current_player_slot = 0` (player character). 7-icon radial command ring is positioned around the player's feet at `(658, 425)`. Catch and Item actions are enabled.
  - Action Commitment: When player commits an action and selects target, `BattleView` spawns a floating action icon over the player's head and scans for living party members (e.g. summoned companion in Slot 1).
  - Phase 2 (Pet): Ring automatically jumps to the pet's feet at `(592, 417)` (`PLAYER_FRONT_START + PLAYER_STEP * 1.0`). Catch and Item buttons are disabled (pets cannot capture wild monsters or use inventory bags), while Attack, Defend, Skill, Escape, and Auto remain fully interactive.
  - Round Execution: When pet commits its action, floating action icon appears over the pet's head, the ring hides, and round execution begins.

## 4. Dynamic Combat Camera Attack Zoom & Lunges
- **Method:** `play_camera_attack_zoom(focus_point: Vector2)`
- **Behavior:**
  - Sets `actors_layer.pivot_offset` to the target actor's screen position.
  - Smoothly tweens `scale` from 1.0 to 1.06 over 0.12s (quad out) during physical attack lunges and skill strikes, then eases back to 1.0 over 0.18s (quad in).
  - Coincides with caster physical step-forward lunges and golden slash ring effects (`anim_id = 60022`).

## 5. Verification & Test Suite
- `tests/test_battle_round_timer_and_backdrop_parity.gd`: 100% zero-error pass rate across environment backdrop resolution, countdown timer parity, 2-phase player to pet ring step, and camera attack zoom.
- `tests/test_battle_view.gd`: 11/11 tests passed (100%).
- `tests/test_encounters_and_battle_flow.gd`: 23/23 tests passed (100%).
- `tests/test_fight_window_and_combat_settings.gd`: 8/8 tests passed (100%).
