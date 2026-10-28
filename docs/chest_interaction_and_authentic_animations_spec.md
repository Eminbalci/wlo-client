# Chest Interaction, Paperdoll Stance & Animation System Specification

## Overview
This technical specification outlines the architecture, state flow, and mathematical calibrations implemented to resolve interactive container loot handling, Paperdoll Character stance and breathing animation, Status Dock avatar position, in-world kinematics, and Bottom Action Dock presentation.

## 1. Container Interaction System (`scripts/map/map_view.gd`)

### Architecture
Interactive containers (such as Treasure Chests, Casks, Barrels, Crates, and Urns) bypass normal dialogue boxes (`hud.show_dialogue()`), directly granting inventory items, gold, and experience points to the player.

### Methods & Signatures
```gdscript
func is_container_npc(npc: Node2D) -> bool
```
- **Parameters:** `npc: Node2D` (candidate NPC instance).
- **Return Type:** `bool`.
- **Classification Rules:**
  - `npc_id` within `[19034, 19035, 19036, 19037, 19038]` (washed-up beach casks).
  - `npc_id` or `template_id` within range `[16000..16015]` (authentic WLO wooden/bronze/gold chests).
  - `npc_name` contains (case-insensitive): `"chest"`, `"sandik"`, `"cask"`, `"barrel"`, `"box"`, `"treas"`, or `"crate"`.
  - 2-frame interactive sprite models where frame 0 is closed and frame 1 is opened (`is_broken = true`).

```gdscript
func _handle_container_npc_interaction(npc: Node2D) -> void
```
- **Parameters:** `npc: Node2D` (verified container entity).
- **Execution Flow:**
  1. Checks if container has already been opened (`npc.is_broken == true` or tracked in `_opened_containers`).
  2. If opened:
     - Triggers speech bubble: `"The [Name] is empty."` via `npc.show_speech_bubble(msg, 2.0)`.
     - Logs system chat message: `[System] The [Name] is empty.`.
     - Plays empty container SFX (`wav0151`).
     - Returns immediately without opening dialogue.
  3. If unopened:
     - Sets `npc.is_broken = true` and updates visual frame to frame 1.
     - Records opened state in persistent map tracking `_opened_containers[map_id * 100000 + npc_id] = true`.
     - Resolves reward profile from authentic `Item.dat` database:
       - 19034, 19035 (Beach Chests): Tao Rice Ball (ID `34014`, icon `1859`, count 5, +100 Gold).
       - 19036, 19037 (Beach Casks): Danish Bread (ID `32015`, icon `1015`, count 5, +150 Gold).
       - 19038 (Beach Supplies Chest): Protective EXP Pill (ID `34026`, icon `1768`, count 2, +200 Gold).
       - 19039 (Fallen Coconut): Coconut (ID `41066`, icon `1379`, count 3, +50 Gold).
       - 16000, 16001 (Wooden Boxes): White Rice (ID `32001`, icon `1290`, count 5, +250 Gold, +12% EXP).
       - 16002 (Footwear Chest): Moppet's Shoes (ID `24002`, icon `1092`, count 1, +200 Gold, +12% EXP).
       - 16003 (Bronze Chest): 2 Holy EXP Potion (ID `34146`, icon `1995`, count 2, +350 Gold, +20% EXP).
       - 16004 (Darkness Box): 4 Holy EXP Potion (ID `34143`, icon `1999`, count 1, +500 Gold, +25% EXP).
       - 16005 (Bottle): Magic Potion (ID `30253`, icon `3199`, count 3, +100 Gold).
       - 16006..16008 (Urns): Cure Potion (ID `33023`, icon `1077`, count 5, +150 Gold).
     - Calls `hud.add_inventory_item(item_id, count, item_name, icon_id)`.
     - Calls `hud.add_gold(gold_amount)` and updates `player.gold`.
     - Awards experience points to `player.exp_percent`.
     - Displays gold-bordered center loot banner via `hud.show_center_notification()`.
     - Shows speech bubble above container: `"[Item Name] x[Count] obtained! +[Gold] Gold"`.
     - Plays reward fanfare audio (`wav9911`).
     - Returns immediately without opening `hud.show_dialogue()`.

## 2. Character Paperdoll 3/4 Isometric Stance & Breathing (`scripts/ui/hud/hud_character_status.gd`)

### Heading & Frame Geometry
- **Stance Heading:** `IsometricMath.Heading.SOUTH_WEST` (Heading 3).
- **Base Frame Calculation:** `32 + 3 * 4 = 44`.
- **Breathing Frames:** 44, 45, 46, 47.
- **Cadence:** 3.0 FPS (~0.33s per frame, 1.33s total breathing cycle).

### Methods
```gdscript
func get_paper_doll_heading() -> int
func get_paper_doll_frame_index() -> int
func process(delta: float) -> void
```
- **Frame Index Calculation:**
  `44 + (int(_paper_doll_timer * 3.0) % 4)`
- **Cycle Execution:**
  Driven continuously from `HUD._process(delta)` when `char_window.visible` is active, updating `char_paper_doll.texture` with the active composite sprite layer.

## 3. HUD Player Status Dock Portrait Alignment (`scripts/ui/hud/hud_player_status.gd`)

### Calibration Parameters
- **Node:** `AvatarRect` inside `PlayerStatusDock`.
- **Position:** `Vector2(30, -4)` (recalibrated sweet spot to prevent vertical void under top bezel rim).
- **Size:** `Vector2(72, 72)`.
- **Z-Order Hierarchy:**
  1. `AvatarBg` (ColorRect, hidden).
  2. `StatusBackground` (TextureRect, gold filigree bezel with aperture cutout).
  3. `AvatarRect` (TextureRect, 72x72 bust cutout).
  4. `HpChannelUnder` & `HpBar` (TextureProgressBar, cradling the bust's neck).
  5. `SpChannelUnder` & `SpBar` (TextureProgressBar).

## 4. In-World Kinematics & Animation Transitions (`scripts/world/player.gd` & `scripts/world/npc.gd`)

### Player Movement Transitions
- Default spawn heading: `IsometricMath.Heading.SOUTH_WEST` (Heading 3).
- Moving from any non-prone state (`IDLE`, `SIT`, `ATTACK`, `DEFEND`, `VICTORY`) immediately transitions to `MotionState.WALK`.
- Stopping movement immediately transitions back to `MotionState.IDLE`.

### Combat Animation Auto-Recovery
- `MotionState.ATTACK`: Plays 4 frames at 8.0 FPS (0.5s duration) and auto-recovers to `MotionState.IDLE`.
- `MotionState.DEFEND`: Plays 4 frames at 6.0 FPS (0.67s duration) and auto-recovers to `MotionState.IDLE`.
- `MotionState.VICTORY`: Plays 8 steps at 4.0 FPS (2.0s duration) and auto-recovers to `MotionState.IDLE`.

### Idle Breathing Cadence
- `PlayerEntity.MotionState.IDLE`: 2.5 FPS (1.6s full breathing cycle).
- `NpcEntity._compute_frame_index()`: 2.5 FPS for standing 64-frame, 32-frame, and 16-frame models.

## 5. Bottom Action Dock Blue Cradle Presentation (`scripts/ui/hud/hud_action_dock.gd`)

### Visual Parity
- `ActionBackground` maintained visible at `Vector2(7.0, 34.0)` with size `Vector2(268.0, 37.0)` using `btn_background_2.png`.
- Cradles the circular buttons from underneath, keeping coordinate readouts completely clear and unobscured.
- `BtnQuest` default tooltip set to `"Compound [V]"` bound to hotkey `KEY_V`.
- `BtnStatus` default tooltip set to `"Character Status & Inventory [C / I]"` bound to hotkeys `KEY_C`, `KEY_E`, and `KEY_I`.

## 6. Cutscene Audio, NPC Speech & Kinematic Input Locking
- **Authentic Deserted Island BGM**: Bound `BGM0024.wav` to Map 10003 (Monkey Beach) and beach awakening event.
- **Ocean Wave Soundscapes**: Sourced authentic wave audio `wav0056.wav` and `wav1608.wav`, eliminating inappropriate alarm and hull breach sound effects from ocean ambient players.
- **Kelang Awakening Dialogue**: On beach wakeup, Kelang (NPC 14062) triggers shock emote, overhead speech bubble (`"Hey! Are you okay? You washed ashore from the shipwreck."`), and initiates dialogue chain (Talk 20305..20307).
- **Kinematic Locking**: User click-to-move pathfinding and input is strictly locked during cutscenes, wakeup sequences, dialogue boxes, and combat animation states.

## 7. Verification Test Suites
- `tests/test_chest_interaction_and_animations.gd`: 6-part test verifying container detection, loot acquisition, speech bubbles, dialogue bypass, paperdoll breathing, player transitions, and status dock position.
- `tests/test_hud_hotbar_action_and_chat_fixes.gd`: Clean bottom action dock and chat dock parity.
- `tests/test_animated_status_dock_avatar.gd`: 24-check avatar portrait aperture and blinking verification.
- `tests/test_character_normal_animations.gd`: 216-frame composite animation and motion state transitions.
- `tests/test_character_inventory_binding.gd`: Inventory slots, paperdoll compositing, and equipment synchronization.
- `tests/test_all_maps_and_npcs.gd`: Multi-map dynamic spawning, portal warps, and dialogue triggers.
