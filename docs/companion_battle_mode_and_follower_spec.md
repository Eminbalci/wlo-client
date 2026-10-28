# Companion Battle Mode, Walking Follower, & Authentic NPC Portraits Specification

## Overview
This specification details the architecture, state management, overland kinematic trailing, walk animation integration, and authentic graphic asset resolution for pets/companions in Wonderland Online (Godot 4 Client).

---

## 1. Single Pet Battle Mode Enforcement

### Problem Statement
In earlier iterations, multiple pets could simultaneously show "Battle" or remain in ambiguous summon states, failing to match the official Wonderland Online client rules where only a single companion can be active in combat.

### Implementation Architecture (`scripts/ui/hud/team_window.gd`)
- **Strict Invariant:** At all times, at most **ONE** pet may possess `is_summoned == true`.
- **Dynamic Button Text & Styling:**
  - In `_refresh_real_client_controls()` and `_refresh_pet_rows()`, each pet's `BtnRowBattle_i` button dynamically evaluates `pet.get("is_summoned", false)`.
  - When `is_summoned == true`: Button text and inner `Caption` label switch to `"Rest"`, with green-highlighted text (`Color(0.1, 0.45, 0.15, 1.0)`) and an active pill stylebox.
  - When `is_summoned == false`: Button text and inner `Caption` label display `"Battle"`, with default navy text (`Color(0.24, 0.3, 0.55, 1.0)`).
- **Auto-Recall & Mutual Exclusion:**
  - In `_on_pet_row_button(row: int, to_battle: bool)`:
    - If the user clicks `"Battle"` on an inactive companion, all other summoned companions are immediately recalled (`is_summoned = false`, emitting `companion_recalled`). The selected pet is promoted to `active_companion` and set to `is_summoned = true`.
    - If the user clicks `"Rest"` on the currently active pet, that pet is recalled to rest, resulting in 0 active combat pets.
    - If the user clicks `"Dismiss"`, the target pet is returned to rest.

---

## 2. Overland Follower Kinematics, Breadcrumb Trailing & Walk Animations

### Problem Statement
In the overworld, the companion follower was previously snapping or teleporting to an instantaneous vector behind the player, rather than walking naturally. If distance exceeded small thresholds or if the player turned, the follower would snap across the terrain and remain in a static idle pose like a non-player entity. Furthermore, clicking near the follower intercepted player ground-movement clicks.

### Breadcrumb Kinematic Trailing Engine (`scripts/map/map_view.gd`)
- **Breadcrumb History Buffer (`_follower_trail: Array[Vector2]`):**
  - As the player traverses the map, player positions are recorded into a breadcrumb FIFO queue at 20px intervals.
  - The follower paths sequentially through each recorded breadcrumb point, faithfully retracing the player's exact path (around obstacles, corners, and buildings) rather than cutting directly through walls or floating sideways.
- **Continuous Walk Animation (`is_moving = true`):**
  - While traversing breadcrumb points, `_companion_follower.is_moving` remains continuously `true`, advancing `_anim_frame_timer` without micro-stutters or stopping/starting every 2 pixels.
  - Calls `_update_frame()` whenever movement state transitions between moving and stopped.
- **Dynamic Speed Catchup:**
  - Standard following speed matches the player's base movement speed (`120.0 px/s`).
  - If distance to player exceeds 80px, speed increases to 1.3x (`156.0 px/s`). If distance exceeds 160px, speed scales to 1.6x (`192.0 px/s`), allowing the companion to naturally jog and catch up.
- **Smooth Arrival & Player-Facing Idle:**
  - When the player stops moving and the follower reaches within 48px, the breadcrumb trail is cleared, `is_moving` transitions to `false` (idle standing animation), and the follower turns to face the player.
- **Zero In-Game Teleports:**
  - Removed artificial mid-screen teleport thresholds (`dist > 450.0 px`). Emergency warping is strictly reserved for whole-map transitions (`dist > 900.0 px`, such as portal teleports).
- **Dialogue Interception Prevention:**
  - `find_npc_near_world_pos` explicitly ignores `_companion_follower`, ensuring ground-movement clicks near the pet are never blocked or misrouted to dialogue handlers.
  - `ClickArea` monitoring and pickable properties on `_companion_follower` are disabled upon spawn.

---

## 3. Authentic NPC Portraits & Sprite Avatars

### Problem Statement
Companion list slots previously fell back to human player role portraits (e.g. Betty `avatar_role_2_0.png` for Roca, Daniel `avatar_role_6_0.png` for Kelang, Moritaka `avatar_role_13_0.png` for S. Monkey), displaying incorrect character faces in the Team Window.

### Resolution Hierarchy (`_resolve_companion_avatar`)
1. **Dedicated Transparent PNG Assets (`res://assets/hud/*_avatar.png`):**
   - Pre-extracted and defringed directly from authentic JMA archives:
     - `roca_avatar.png`: TID 8090 portrait decoded from `8090.jmp` in `008.jma`.
     - `kelang_avatar.png`: TID 8038 portrait decoded from `8038.jmp` in `008.jma`.
     - `robinson_avatar.png`: TID 8067 portrait decoded from `8067.jmp` in `008.jma`.
     - `niss_avatar.png`: TID 8091 portrait decoded from `8091.jmp` in `008.jma`.
     - `frederico_avatar.png`: TID 8097 portrait decoded from `8097.jmp` in `008.jma`.
     - `s_monkey_avatar.png`: Sprite ID 1103 decoded from `1103.jmp` in `001.jma`.
2. **Runtime `ArchiveLoader` Dynamic Fallback:**
   - If a companion is not pre-cached on disk, `_resolve_companion_avatar` queries `ArchiveLoader`:
     - If `talk_image > 0`: Invokes `ArchiveLoader.get_npc_portrait(talk_image)` to unpack from `008.jma`.
     - If `talk_image == 0`: Invokes `ArchiveLoader.get_npc_texture(sprite_id, 0)` to unpack from `001.jma` / `007.jma`.
   - Complete removal of human role ID fallbacks (`avatar_role_*_*.png`), guaranteeing zero visual mismatches.

---

## 4. Headless Automated Verification
All features and edge cases are verified through `tests/test_team_window_and_companions.gd`:
- **Single Battle Mode & State Machine:** 100% pass (mutual exclusion, dynamic button text switching between "Battle" and "Rest", 0-pet recall).
- **Overland Walking Animation:** Verified `is_moving = true` while following and `is_moving = false` within 16px of target.
- **Model & Avatar Integrity:** S. Monkey verified as `1103.jmp`, avatars verified using authentic NPC assets with 0 human role fallbacks.
- **Regression Suite:** `tests/test_hud_chat_and_status_features.gd` (100%), `tests/test_encounters_and_battle_flow.gd` (23/23 tests, 0 failures).
