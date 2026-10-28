# Authentic Map NPC Positioning and Facing System

## Overview
This document specifies the authentic NPC coordinate placement, rotation decoding, directional heading resolution, and JMP animation frame layouts for Wonderland Online in Godot 4.

The system resolves the discrepancy between the original 32-bit client's `Eve.emg` binary event archive format and the 8-directional isometric sprite renderer.

---

## 1. Coordinate & Heading Mathematics

### 1.1 Rotation Encoding in Eve.emg (Category 0)
In the original binary archive `Eve.emg`, each NPC record in Category 0 encodes its orientation as a 1-based **clockwise** rotation integer ($1 \dots 8$):
- `1`: North (Back / Up)
- `2`: North-East (Back-Right / Up-Right)
- `3`: East (Right)
- `4`: South-East (Front-Right / Down-Right)
- `5`: South (Front / Down)
- `6`: South-West (Front-Left / Down-Left)
- `7`: West (Left)
- `8`: North-West (Back-Left / Up-Left)

### 1.2 Sprite Heading in JMP Archives (`IsometricMath.Heading`)
Wonderland Online JMP sprite archives store animation rows in a 0-based **counter-clockwise** order ($0 \dots 7$):
- `0` (`Heading.NORTH`): North (Back)
- `1` (`Heading.NORTH_WEST`): North-West (Back-Left)
- `2` (`Heading.WEST`): West (Left)
- `3` (`Heading.SOUTH_WEST`): South-West (Front-Left)
- `4` (`Heading.SOUTH`): South (Front / Camera)
- `5` (`Heading.SOUTH_EAST`): South-East (Front-Right)
- `6` (`Heading.EAST`): East (Right)
- `7` (`Heading.NORTH_EAST`): North-East (Back-Right)

### 1.3 Bidirectional Transformation Bijection
To convert between the authentic clockwise `Eve.emg` rotation ($1 \dots 8$) and the engine's counter-clockwise sprite heading ($0 \dots 7$), the following involution is implemented in [`IsometricMath`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/map/isometric_math.gd):

```gdscript
static func rotation_to_heading(rotation: int) -> int:
    if rotation <= 0:
        return Heading.SOUTH
    return (8 - ((rotation - 1) % 8)) % 8

static func heading_to_rotation(heading: int) -> int:
    return ((8 - (heading % 8)) % 8) + 1
```

Mapping verification table:

| Eve.emg Rotation | Cardinal Direction | Screen Facing | `IsometricMath.Heading` | JMP Frame Prefix (Stand) |
| :---: | :---: | :---: | :---: | :---: |
| `1` | North | Up / Back | `0` (`NORTH`) | `08-1.bmp` |
| `2` | North-East | Up-Right | `7` (`NORTH_EAST`) | `15-1.bmp` |
| `3` | East | Right | `6` (`EAST`) | `14-1.bmp` |
| `4` | South-East | Down-Right | `5` (`SOUTH_EAST`) | `13-1.bmp` |
| `5` | South | Down / Front | `4` (`SOUTH`) | `12-1.bmp` |
| `6` | South-West | Down-Left | `3` (`SOUTH_WEST`) | `11-1.bmp` |
| `7` | West | Left | `2` (`WEST`) | `10-1.bmp` |
| `8` | North-West | Up-Left | `1` (`NORTH_WEST`) | `09-1.bmp` |

---

## 2. JMP Frame Layout Categories

Wonderland Online JMP sprite archives use 5 distinct frame layout configurations depending on model complexity. In [`NpcEntity`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/world/npc.gd), `_compute_frame_index(total_frames)` maps `heading` to frame indices:

### 2.1 Standard Humanoids ($\ge 64$ frames)
- **Examples**: Sailor Jack (`1010.jmp`, 140 frames), Girl (`1009.jmp`, 140 frames), Natasha (`1068.jmp`, 140 frames), Visitors (`1012.jmp`/`1013.jmp`, 78 frames), Persian Cat (`1035.jmp`, 104 frames).
- **Structure**:
  - Frames $0 \dots 31$: Walk cycle ($8 \text{ directions} \times 4 \text{ frames}$, `00`..`07`).
  - Frames $32 \dots 63$: Stand idle ($8 \text{ directions} \times 4 \text{ frames}$, `08`..`15`).
- **Calculation**:
  $$\text{frame\_idx} = (\text{stand\_base} + (\text{heading} \bmod 8) \times 4 + \text{sub\_idx}) \bmod \text{total\_frames}$$
  where $\text{stand\_base} = 32$ when idle, $0$ when walking.

### 2.2 32-Frame Characters ($32$ frames)
Wonderland Online JMP archives contain two distinct structural subtypes for 32-frame models:

#### Subtype A: 4-Diagonal Walk + Stand (Standard Animated NPCs)
- **Examples**: Captain Robinson (`1038.jmp`, 32 frames), Crew (`1037.jmp`, 32 frames), Models `1060`, `1092`, `1095`, `1243`, `1286`, `1384`, `1418`, `1717`, `1736`.
- **Structure**:
  - Frames $0 \dots 15$: 4-diagonal walk cycles ($4 \text{ directions} \times 4 \text{ frames}$: `01` for NW, `03` for SW, `05` for SE, `07` for NE).
  - Frames $16 \dots 31$: 4-diagonal stand idle ($4 \text{ directions} \times 4 \text{ frames}$: `09` for NW, `11` for SW, `13` for SE, `15` for NE).
- **Heading to Diagonal Block Mapping**:
  - `diag_idx = 0` (`01` walk / `09` stand): `NORTH_WEST` (`1`), `NORTH` (`0`) [Back-Left]
  - `diag_idx = 1` (`03` walk / `11` stand): `SOUTH_WEST` (`3`), `WEST` (`2`) [Front-Left]
  - `diag_idx = 2` (`05` walk / `13` stand): `SOUTH_EAST` (`5`), `SOUTH` (`4`) [Front-Right]
  - `diag_idx = 3` (`07` walk / `15` stand): `NORTH_EAST` (`7`), `EAST` (`6`) [Back-Right]
- **Calculation**:
  $$\text{base} = (0 \text{ if moving else } 16) + \text{diag\_idx} \times 4$$
  $$\text{frame\_idx} = (\text{base} + \text{sub\_idx}) \bmod \text{total\_frames}$$
  *Notice: South-West (`3`) resolves to `diag_idx = 1` (stand base 20, `11-1`), while South (`4`) resolves to `diag_idx = 2` (stand base 24, `13-1`), ensuring authentic, distinct facing and preventing identical frame reuse.*

#### Subtype B: 8-Directional Stationary Stand
- **Examples**: Model `1274.jmp` (identified by frame 0 named `08-1.bmp`).
- **Structure**: 8 directions $\times$ 4 idle frames (`08`..`15`).
- **Calculation**:
  $$\text{frame\_idx} = ((\text{heading} \bmod 8) \times 4 + \text{sub\_idx}) \bmod \text{total\_frames}$$

### 2.3 Diagonal 4-Way Animated Characters ($16$ frames)
- **Examples**: Breillat (`1170.jmp`, 16 frames).
- **Structure**: 4 diagonal directions $\times$ 4 idle frames (`09` for NW, `11` for SW, `13` for SE, `15` for NE).
- **Calculation**:
  - `diag_block = 0` for `NORTH_WEST` / `NORTH`
  - `diag_block = 1` for `SOUTH_WEST` / `WEST`
  - `diag_block = 2` for `SOUTH_EAST` / `SOUTH`
  - `diag_block = 3` for `NORTH_EAST` / `EAST`
  - $\text{frame\_idx} = (\text{diag\_block} \times 4 + \text{sub\_idx}) \bmod \text{total\_frames}$

### 2.4 Single-Frame 8-Way Objects ($8$ frames)
- **Examples**: Ross (`1207.jmp`, 8 frames), Arcade Machines (`1088.jmp`/`1089.jmp`, 8 frames).
- **Structure**: 8 single-frame directions (`08`..`15`).
- **Calculation**:
  $$\text{frame\_idx} = \text{heading} \bmod 8$$

### 2.5 Single-Frame 4-Way Diagonal Characters ($4$ frames)
- **Examples**: Drunk Man, Peter, John (`1050.jmp`, 4 frames).
- **Structure**: 4 diagonal frames (`09-1` for NW, `11-1` for SW, `13-1` for SE, `15-1` for NE).
- **Calculation**:
  - `0` for `NORTH_WEST` / `NORTH`
  - `1` for `SOUTH_WEST` / `WEST`
  - `2` for `SOUTH_EAST` / `SOUTH`
  - `3` for `NORTH_EAST` / `EAST`

---

## 3. Map NPC Master Reference

### 3.1 Ship Deck (Map 10001, Scene 10001)

| ClickID | NPC Name | Template ID | JMP Model | World Pos | Eve.emg Rot | Heading | Orientation | Notes |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `1` | Jack | `14091` | `1010.jmp` | `(117, 1303)` | `6` | `3` (`SOUTH_WEST`) | Front-Left | Bow tip "Titanic" pose |
| `2` | Ross | `14152` | `1207.jmp` | `(102, 1312)` | `6` | `3` (`SOUTH_WEST`) | Front-Left | Bow tip "Titanic" pose |
| `3` | Crew | `14002` | `1037.jmp` | `(343, 940)` | `4` | `5` (`SOUTH_EAST`) | Front-Right | Forward starboard watch |
| `4` | Deck Crew | `14001` | `1037.jmp` | `(1461, 315)` | `6` | `3` (`SOUTH_WEST`) | Front-Left | Patrol: `(1462, 316)` to `(1982, 601)` |
| `5` | Visitor 1 | `14080` | `1012.jmp` | `(855, 1302)` | `4` | `5` (`SOUTH_EAST`) | Front-Right | Overlooking port sea railing |
| `6` | Visitor 2 | `14087` | `1013.jmp` | `(814, 1313)` | `4` | `5` (`SOUTH_EAST`) | Front-Right | Overlooking port sea railing |
| `7` | Girl | `14065` | `1009.jmp` | `(1013, 902)` | `6` | `3` (`SOUTH_WEST`) | Front-Left | Watching her cat Kedi |
| `8` | Persian Cat | `11000` | `1035.jmp` | `(1027, 957)` | `6` | `3` (`SOUTH_WEST`) | Front-Left | Patrol: `(936, 942)` to `(1126, 943)` |
| `9` | Crew | `14002` | `1037.jmp` | `(1393, 578)` | `6` | `3` (`SOUTH_WEST`) | Front-Left | Bridge guard |
| `10` | Captain Robinson | `14003` | `1038.jmp` | `(1421, 632)` | `6` | `3` (`SOUTH_WEST`) | Front-Left | Ship bridge commander |
| `11` | Deck Crew | `14001` | `1037.jmp` | `(405, 925)` | `6` | `3` (`SOUTH_WEST`) | Front-Left | Forward deck watch |

### 3.2 Ship Cabin (Map 10002, Scene 10002)

| ClickID | NPC Name | Template ID | JMP Model | World Pos | Eve.emg Rot | Heading | Orientation | Notes |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `1` | Drunk Man | `14042` | `1050.jmp` | `(851, 539)` | `8` | `1` (`NORTH_WEST`) | Back-Left | Facing bar counter |
| `2` | Peter | `14146` | `1050.jmp` | `(1302, 800)` | `2` | `7` (`NORTH_EAST`) | Back-Right | Sitting at table facing John |
| `3` | John | `14145` | `1050.jmp` | `(1309, 714)` | `4` | `5` (`SOUTH_EAST`) | Front-Right | Sitting at table facing Peter |
| `4` | Natasha | `14303` | `1068.jmp` | `(1440, 682)` | `6` | `3` (`SOUTH_WEST`) | Front-Left | Lounge greeting |
| `5` | Breillat | `10000` | `1170.jmp` | `(1155, 580)` | `6` | `3` (`SOUTH_WEST`) | Front-Left | Center cabin receptionist (lower legs clipped behind diagonal bar counter edge `cy >= 41 + (cx - 1) * 0.514`) |
| `6` | Game Machine a | `18000` | `1088.jmp` | `(226, 795)` | `5` | `4` (`SOUTH`) | Front | `256x256` bounding canvas (`offset = (-3, -96)`) aligned pixel-perfectly over background |
| `7` | Game Machine b | `18001` | `1089.jmp` | `(141, 829)` | `5` | `4` (`SOUTH`) | Front | `256x256` bounding canvas (`offset = (0, -96)`) aligned pixel-perfectly over background |

---

## 4. EveParser API Specification

The [`EveParser`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/map/eve_parser.gd) class now includes native Category 0 parsing:

```gdscript
## Extracts all authentic NPC records from Eve.emg for a given map_id
func get_npcs_for_map(map_id: int) -> Array[NpcSpawnInfo]:

## Retrieves a specific NPC by click_id for a given map_id
func get_npc_by_id(map_id: int, click_id: int) -> NpcSpawnInfo:
```

### Return Type: `NpcSpawnInfo`
- `click_id: int`: Interactive entity ID (matches Talk.dat and Eve event bindings).
- `name: String`: Name string from Eve block.
- `entity_type: int`: Binary entity category byte.
- `world_x: int`, `world_y: int`: Authentic pixel spawn position on map background.
- `world_pos: Vector2`: Equivalent `Vector2(world_x, world_y)`.
- `npc_id: int`: Npc.dat template ID for stats, models, and portraits.
- `rotation: int`: Raw 1-based clockwise Eve rotation ($1 \dots 8$).
- `heading: int`: Resolved 0-based counter-clockwise JMP heading ($0 \dots 7$).
- `walk_behavior: int`: Movement behavior flag ($1$ for static, $2$ for patrol).
- `walksteps: Array[Vector2]`: Waypoint array for patrolling entities.
- `walkstep_delays: Array[float]`: Waypoint wait times in seconds.
- `events: Array[int]`: Trigger event indices for script and dialogue execution.
- `source_map_id: int`: Originating map ID.

---

## 5. Verification Suite

Run headlessly via `godot_console.exe`:
```powershell
C:\Godot\godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client -s res://tests/test_npc_positioning_and_facing.gd
```
Asserts:
1. Bidirectional bijective mapping between Eve rotations and JMP headings.
2. Exact decoding of all 11 Ship Deck NPCs from `Eve.emg`.
3. Exact decoding of all 7 Cabin NPCs from `Eve.emg`.
4. Frame index calculations across 140, 32, 16, 8, and 4 frame JMP models.
5. In-scene node hierarchy, coordinates, and facing directions in `map_view.tscn`.
6. Dynamic spawning and face-to-face table seating alignment in `map_view.gd`.
