# Map 10001 (Ship Deck) Parity & Architecture Specification

## Overview
Map `10001` (Scene `10001`, titled **Ship Deck** / `Ship Deck`) serves as the introductory naval setting in Wonderland Online where players awaken after character creation. It corresponds to ground truth video seconds `049` through `115`, showcasing the cruise liner main deck, wooden floor planks, perimeter safety railings, bridge command station, staircase entrance to passenger cabins, and 11 authentic NPCs with 8-directional isometric orientations and patrol kinematics.

---

## 1. Video Ground Truth Parity (Seconds 049 - 115)

| Video Second | Ground Truth Asset / Frame | Visual & Gameplay Features Verified | Parity Status |
| :---: | :---: | :---: | :---: |
| `049 - 052` | `sec_049.png` - `sec_052.png` | Player awakening on cruise ship deck, camera centered on initial spawn, HUD radar active with map title "Ship Deck" | Verified |
| `053 - 065` | `sec_053.png` - `sec_065.png` | Isometric movement clicks, green circular pathfinding ripples, Captain Robinson greeting dialogue sequence | Verified |
| `066 - 085` | `sec_066.png` - `sec_085.png` | Exploration of forward deck, Sailor Jack and Ross at bow tip ("Titanic" pose), crewmen standing guard | Verified |
| `086 - 100` | `sec_086.png` - `sec_100.png` | Patrol movement of Deck Crew (`14001`) and Persian Cat (`11000`) along authentic coordinate paths | Verified |
| `101 - 115` | `sec_101.png` - `sec_115.png` | Approaching staircase portal to cabin interior, animated door light effects, warp trigger transition to Map `10002` | Verified |

---

## 2. Map Architecture & Geometry

### 2.1 Dimensions & Coordinate System
- **Map ID**: `10001`
- **Scene ID**: `10001`
- **Background Texture**: `10001.map` in `assets/data/Ground.MMG` / `map.JMG`
- **Pixel Resolution**: `2432 x 1792` pixels
- **Tile Grid**: `122` columns $\times$ `90` rows
- **Tile Scaling**: `20` pixels per isometric tile cell
- **BGM Track**: `BGM0007` ("Ocean Star Voyage")

### 2.2 Player Spawn Position
- **Initial Spawn Coordinate**: `Vector2(1042, 1075)` (Grid cell `[52, 53]`, walkable open deck corridor)
- **Eve.emg Warp Anchor Reference**: `Vector2(1038, 2235)` (Warp `0` destination record in `Eve.emg` Category 6 connecting ship deck to beach island path)
- **Initial Orientation**: `Heading.SOUTH_WEST` (`3`) / Down-Right facing

### 2.3 Collision Boundaries (`Ground.MMG`)
Collision boundaries are loaded from `assets/data/Ground.MMG` via `GroundParser`:
- **Storage Layout**: Column-major 1D byte array (`index = grid_x * rows + grid_y`)
- **Flags**:
  - `0x00` (`WALKABLE`): Main deck floor, walkways, companionway corridors.
  - `0x01` (`SOLID_WALL`): Ship hull perimeter railings, bridge walls, stair barriers, structural masts.
  - `0x02` (`SEA`) / `0x04` (`DEEP_OCEAN`): Surrounding ocean water tiles blocking pedestrian traversal.
- **Corner Cutting Prevention**: Diagonal traversal strictly prohibited when either adjacent orthogonal tile is non-walkable.

---

## 3. NPCs on Deck (Authentic Parity)

According to authoritative binary event tables in `Eve.emg` (Category 0) and template data in `Npc.dat`:

| Index | Click ID | NPC Name | Template ID | Model JMP | World Position | Rotation (`1..8`) | Heading (`0..7`) | Orientation | Behavior & Kinematics |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 1 | `10` | **Captain Robinson** | `14003` | `1038.jmp` | `(1421, 632)` / `(1090, 2180)` | `6` | `3` (`SOUTH_WEST`) | Front-Left | Bridge commander, stationary 32-frame layout |
| 2 | `1` | **Jack** | `14091` | `1010.jmp` | `(117, 1303)` | `6` | `3` (`SOUTH_WEST`) | Front-Left | Bow tip "Titanic" pose, 140-frame layout |
| 3 | `2` | **Ross** | `14152` | `1207.jmp` | `(102, 1312)` | `6` | `3` (`SOUTH_WEST`) | Front-Left | Bow tip "Titanic" pose, 8-frame layout |
| 4 | `3` | **Crew 1** | `14002` | `1037.jmp` | `(343, 940)` | `4` | `5` (`SOUTH_EAST`) | Front-Right | Forward starboard watch, 32-frame layout |
| 5 | `4` | **Deck Crew 1** | `14001` | `1037.jmp` | `(1461, 315)` | `6` | `3` (`SOUTH_WEST`) | Front-Left | Patrol: `[(1462, 316), (1982, 601)]`, 2.0s delay |
| 6 | `5` | **Visitor 1** | `14080` | `1012.jmp` | `(855, 1302)` | `4` | `5` (`SOUTH_EAST`) | Front-Right | Overlooking port sea railing, 78-frame layout |
| 7 | `6` | **Visitor 2** | `14087` | `1013.jmp` | `(814, 1313)` | `4` | `5` (`SOUTH_EAST`) | Front-Right | Overlooking port sea railing, 78-frame layout |
| 8 | `7` | **Girl** | `14065` | `1009.jmp` | `(1013, 902)` | `6` | `3` (`SOUTH_WEST`) | Front-Left | Watching her cat Kedi, 140-frame layout |
| 9 | `8` | **Persian Cat** | `11000` | `1035.jmp` | `(1027, 957)` | `6` | `3` (`SOUTH_WEST`) | Front-Left | Patrol: `[(936, 942), (1126, 943)]`, 3.0s delay |
| 10 | `9` | **Crew 2** | `14002` | `1037.jmp` | `(1393, 578)` | `6` | `3` (`SOUTH_WEST`) | Front-Left | Bridge guard, 32-frame layout |
| 11 | `11` | **Deck Crew 2** | `14001` | `1037.jmp` | `(405, 925)` | `6` | `3` (`SOUTH_WEST`) | Front-Left | Forward deck watch, 32-frame layout |

---

## 4. Portals & Warps

### 4.1 Staircase Portal to Map 10002 (Ship Cabins)
- **Position**: `Vector2(1814, 904)` / `Vector2(1180, 2060)`
- **Portal ID**: `1` (Click ID `2`, `船艙切換`)
- **Target Map**: `10002` (Passenger Cabins)
- **Target Coordinates**: `Vector2(674, 1067)`
- **Trigger Radius**: `56.0` pixels
- **Visuals**: Animated 13-frame `Atlas_DoorLight` with `CanvasItem.BLEND_MODE_ADD` additive blending.

### 4.2 Gangway Portal to Map 10003 (Island Beach)
- **Position**: `Vector2(1038, 2235)`
- **Portal ID**: `2` (Click ID `1`, `沙灘至11016`)
- **Target Map**: `10003` (Beach / Newbie Island Path)
- **Target Coordinates**: `Vector2(1038, 2235)`
- **Trigger Radius**: `56.0` pixels

---

## 5. Camera2D & Viewport Tracking

- **Mode**: 2D Isometric player tracking.
- **Position Smoothing**: Enabled (`position_smoothing_enabled = true`, speed = `6.0`).
- **Map Bounds**:
  - `limit_left = 0`
  - `limit_top = 0`
  - `limit_right = 2432`
  - `limit_bottom = 1792`
- **HUD Coordinate Synchronization**: Player world position continuously reports to top-right Radar Minimap `CoordinatesLabel` formatted as `(X, Y)`.

---

## 6. Scene Packaging & Loading Verification

Both entry points are supported and verified:
1. `res://scenes/world/map_view.tscn`: Root runtime world coordinator scene.
2. `res://scenes/maps/map_10001_ship_deck.tscn`: Dedicated packed scene inheriting `map_view.tscn`.

### Verification Suite Execution
```powershell
& "C:\Godot\godot_console.exe" --headless --path "D:\Godot\WonderlandOnline\wonderland-online-client" -s res://tests/test_npc_positioning_and_facing.gd
& "C:\Godot\godot_console.exe" --headless --path "D:\Godot\WonderlandOnline\wonderland-online-client" -s res://tests/test_map_navigation_integration.gd
& "C:\Godot\godot_console.exe" --headless --path "D:\Godot\WonderlandOnline\wonderland-online-client" -s res://scripts/tests/test_collision_and_pathfinding.gd
& "C:\Godot\godot_console.exe" --headless --path "D:\Godot\WonderlandOnline\wonderland-online-client" -s res://tests/test_portals_and_ground_items.gd
```
- **Result**: 100% PASS across all tests with zero errors.
