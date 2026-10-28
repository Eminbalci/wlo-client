# Companion Ride Mode (Pet Mounting System) Specification

## Overview
Wonderland Online features an authentic companion mounting ("Ride") system where players can mount specific companions and beasts for traversal. Riding provides a 1.35x overland movement speed bonus (162.0 px/s vs 120.0 px/s base) and updates character visuals to lock into authentic sitting poses (animation frames 64..95) positioned atop the mount entity.

This specification details the architecture, UI controls, `AdjustRidePetPos.txt` kinematics parser, mutual exclusion rules, player attachment logic, and verification suite.

---

## 1. UI Controls & State Machine (`team_window.gd`)

### Assets
Authentic 3-state textures sliced from `menu/Skins/default/Btn_AssignRide_1.bmp` with chroma-key `(0, 255, 0)`:
- `assets/hud/btn_assign_ride_normal.png` (43x20)
- `assets/hud/btn_assign_ride_hover.png` (43x20)
- `assets/hud/btn_assign_ride_pressed.png` (43x20)

### Placement & Geometry
- Four pet row buttons added to `TeamWindow` (`row_ride_buttons[0..3]`) at position `Vector2(221, 8)` with size `Vector2(38, 18)`.
- Sits alongside the Battle/Dismiss button (`Vector2(179, 8)`).

### Mutual Exclusion State Machine
A companion strictly exists in one of three mutually exclusive states:
1. **Resting (`REST`)**: Pet is recalled, not following overland, not mounted.
2. **Battle (`BATTLE`)**: Pet is summoned as an active walking follower; participates in overworld encounters. Only one pet across the party can be in Battle mode.
3. **Riding (`RIDE`)**: Pet is mounted by the player character. Overland walking follower is despawned. Only one pet can be mounted at any time.

State Transitions:
- Pressing **Ride** on an idle pet:
  - If another pet is in Battle mode, it is recalled to Rest (`is_summoned = false`).
  - If another pet was ridden, it is dismounted.
  - Selected pet is marked `is_ridden = true`, button label becomes "Dismount".
  - Emits `companion_mounted(pet_dict)` and `companion_ride_toggled(true)`.
- Pressing **Dismount** on the ridden pet:
  - Pet state returns to Rest (`is_ridden = false`), button label reverts to "Ride".
  - Emits `companion_dismounted(pet_dict)` and `companion_ride_toggled(false)`.
- Pressing **Battle** while riding:
  - Automatically dismounts the ridden pet.
  - Activates the selected pet in Battle mode as an overland follower.

---

## 2. `AdjustRidePetPos.txt` Kinematics Parser (`scripts/world/ride_data.gd`)

Wonderland Online defines exact per-mount, per-heading, per-character-sex rider offsets in `assets/data/AdjustRidePetPos.txt`.

### Data Structure
- **NpcPic ID**: NPC sprite/model template (e.g. 1867 Beast Mount, 1767, 1879, 1446, etc.).
- **Pose**: Character pose string (`sit`, `stand`).
- **Headings (H0..H7)**: 8-directional isometric orientations (0: North, 1: North-East, 2: East, 3: South-East, 4: South, 5: South-West, 6: West, 7: North-West).
- **Sex (1..4)**:
  - `Sex 1`: Adult Male (Roles 1, 3, 5, 7, 9, 11)
  - `Sex 2`: Adult Female (Roles 2, 4, 8, 10, 12)
  - `Sex 3`: Young Boy (Role 13)
  - `Sex 4`: Young Girl (Roles 6, 14)
- **Positions**:
  - `StandPosX / StandPosY`: Pixel offset applied when mount is idle.
  - `MovePosX / MovePosY`: Pixel offset applied when mount is moving.

### Coordinate Conversion
In Godot 2D coordinates, Y is positive downwards, whereas `AdjustRidePetPos.txt` specifies vertical height above the mount ground feet. Therefore:
```gdscript
var rider_offset = Vector2(pos_x, -pos_y)
```

### Unlisted Fallbacks
For companions not listed in `AdjustRidePetPos.txt` (e.g. S. Monkey 1103):
- Heading Y offset default: `-30.0 px` (idle) / `-32.0 px` (moving).
- Heading X offset default: `0.0 px` (N/S), `±8.0 px` (E/W), `±6.0 px` (diagonals).

---

## 3. Player Entity Mount Kinematics (`scripts/world/player.gd`)

### Mount Attachment & Hierarchy
When `player.mount_pet(pet_data)` is invoked:
- A `_mount_sprite` (`Sprite2D`) child is created under `PlayerEntity` with `z_index = -1` (rendering beneath rider).
- Mount animation frames are synchronized with player heading:
  - Moving: Frames `0..31` (8 headings x 4 walk frames).
  - Idle: Frames `32..63` (8 headings x 4 stand frames).
- Mount frame duration: 0.15s per frame.

### Rider Pose Locking
- Player sprite animation is overridden to the authentic sitting pose:
  - Base sitting frame index: `64`.
  - Frame formula: `64 + heading * 4 + current_subframe`.
- Player `sprite.position` is dynamically updated every frame to `RideData.get_rider_offset(...)`.
- Player `nameplate.position` is shifted upwards to avoid obscuring the rider head.
- Player movement speed scales by `1.35x` (162.0 px/s).

### Dismount Restoration
When `player.dismount_pet()` is called:
- `_mount_sprite` is hidden.
- Player speed returns to `120.0 px/s`.
- Player `sprite.position` and `nameplate.position` reset to `Vector2.ZERO`.
- Normal walk (0..31) and stand (32..63) animation states resume.

---

## 4. MapView Integration (`scripts/map/map_view.gd`)

- MapView connects `team_window.companion_mounted` to `player.mount_pet()`.
- MapView connects `team_window.companion_dismounted` to `player.dismount_pet()`.
- Overland walking follower (`_companion_follower`) is automatically despawned upon mounting to avoid duplicate entities.
- Follower is restored if player dismounts and returns companion to Battle mode.

---

## 5. Verification & Test Coverage

Automated test suite `tests/test_companion_ride_mode.gd`:
- `test_ride_data_parser()`: Profile lookup (1867, 1767, 1879), sex mapping for all 14 roles, offset math for idle/moving headings, fallback math, and 1.35x speed bonus.
- `test_team_window_ride_ui_and_state_machine()`: 4 row buttons, button labels ("Ride" -> "Dismount"), signal emission, and mutual exclusion transitions (Ride -> Battle -> Ride -> Rest).
- `test_player_entity_mount_kinematics()`: Attachment beneath player (`z_index = -1`), sitting pose lock, offset coordinates for Heading 0 / Heading 1, speed boost (162.0 px/s), and dismount cleanup.
- `test_map_view_ride_integration()`: Signal handling, follower suppression on mount, and dismount handling.

**Execution Result:** 48/48 passed, 0 failures (100%).
