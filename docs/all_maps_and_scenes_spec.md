# Wonderland Online All Maps & Scenes Database Specification

## Overview

This specification establishes the authoritative database and extraction architecture for all 1,119 maps in `Eve.emg` and all 1,172 scene records in `SceneData.dat`. It defines the binary parsing algorithms, cryptographic transformations, background texture index resolution across multi-JMG archives (`map.JMG`, `map_d01.JMg`, `map_c01.JMg`), authoritative JSON datasets (`all_maps.json` and `all_scenes.json`), and the GDScript engine interfaces in `SceneDatabase` and `EveParser`.

---

## 1. Binary Layout & Decryption Formulas

### 1.1 SceneData.dat Record Layout (131 Bytes per Record)

Authentic Wonderland Online `SceneData.dat` contains 1,172 fixed-size records of exactly 131 bytes each (total file size: 153,532 bytes). Record 0 is the null/uninitialized header (`raw_id = 4`, `map_id = 59999`); records 1 through 1,171 represent authentic scenes and zones.

#### Map ID Decryption
```python
def decode_scene_id(raw_word: int) -> int:
    return ((raw_word ^ 0xEA6C) - 9) & 0xFFFF
```

#### Field Offset Map

| Offset | Size | Type | Field Description | Decoding Rule |
| :--- | :--- | :--- | :--- | :--- |
| `0x00..0x01` | 2 | uint16 | Encrypted Map/Scene ID | `decode_scene_id(uint16_le(rec[0..2]))` |
| `0x02` | 1 | uint8 | Scene Name Length ($N \le 20$) | Length prefix for Delphi ShortString |
| `0x03..0x16` | 20 | bytes | Reversed Delphi ShortString Name | `bytes(rec[23 - N : 23][::-1]).decode('big5')` |
| `0x19` | 1 | uint8 | BGM Name Length ($M \le 7$) | Length prefix for BGM name string |
| `0x1A..0x20` | 7 | bytes | Reversed BGM Name String | `bytes(rec[26 : 26 + M][::-1]).decode('ascii')` |
| `0x26..0x39` | 20 | 10x uint16 | Base Zone / Parent Scene Words | Arithmetic-XOR decryption with `0xEA6C` |
| `0x3C..0x4F` | 20 | 10x uint16 | Associated Map ID Words | Arithmetic-XOR decryption with `0xEA6C` |
| `0x60..0x64` | 5 | 5x uint8 | Scene Attribute & Environment Flags | Arithmetic-XOR decryption with `0x2C` |
| `0x6F..0x82` | 20 | 5x uint32 | Dimension & Trigger Attributes | Arithmetic-XOR decryption with `0x062B7BA7` |

---

### 1.2 Eve.emg Binary Container Architecture

`Eve.emg` is the master overworld entity and event container. It consists of:
1. **Header Block (12 Bytes):**
   - Offset `0x00..0x07`: 8-byte file identifier / signature.
   - Offset `0x08..0x0B`: `uint32` entry count = 1,119 maps.
2. **Map Index Table (10 Bytes per Map):**
   - `map_id` (`uint16`): Map identifier (e.g. 10001 = Ship Deck).
   - `scene_id` (`uint16`): Associated Scene identifier in `SceneData.dat`.
   - `data_ptr` (`uint32`): Absolute byte offset to map data block.
   - `data_len` (`uint16`): Byte length of map data block.
3. **Category Offset Table (Last 44 Bytes of each Map Block):**
   Each map block terminates with 11 `uint32` relative offsets pointing to specific entity categories within the block:

| Category Index | Category Name | Description |
| :---: | :--- | :--- |
| `0` | **NPC (Category 0)** | Spawners, template IDs, facing rotations, walksteps, dialogue events |
| `1` | **Entry Points (Category 1)** | Default player spawn points and arrival markers |
| `2` | **Mining Areas (Category 2)** | Resource mining spots (ores, logs, clay) |
| `3` | **ItemAreas (Category 3)** | Native overworld ground item spawns (shells, coconuts, fruit) |
| `4` | **Events (Category 4)** | Scripted quest and scene trigger events |
| `5` | **Groups (Category 5)** | Monster group and mob formation configurations |
| `6` | **WarpLoc (Category 6)** | Interactive map exit and entry portals (destination map and coordinates) |
| `7` | **InteractiveInfo (Category 7)**| Interactive props and furniture interactions |
| `8` | **BattleInfo (Category 8)** | Combat encounter background and music configurations |
| `9` | **PreEvent (Category 9)** | Prerequisite event conditions and flags |
| `10` | **GroupExt (Category 10)** | Extended monster group spawn variations |

---

### 1.3 Entity Structures Decoded in Eve.emg

#### Category 0: NPCs (`cat_offsets[0]`)
- `count` (`uint16`)
- Per NPC:
  - `click_id` (`uint16`): In-game entity click identifier.
  - `name` (20 bytes): Delphi string (Big5 Traditional Chinese / ASCII).
  - `entity_type` (`uint8`): Entity classification byte.
  - `world_x`, `world_y` (`uint32` x2): Authentic isometric world position.
  - `events_len` (`uint8`) + `events` (`uint8` array): Dialogue and quest triggers.
  - `unk2_len` (`uint8`) + skip `unk2_len` bytes.
  - `unk_b2` (`uint8`).
  - `npc_id` (`uint32`): Template ID referencing `Npc.dat` (e.g. 14003 = Captain Robinson).
  - `rotation` (`uint8`): Facing orientation (1..8 clockwise, mapped to IsometricMath 0..7).
  - `walk_behavior` (`uint8`): Patrol mode (0=Static, 1=Random patrol, 2=Fixed path).
  - `unk_b5` (`uint8`).
  - `walksteps_len` (`uint8`) + array of `[x: uint32, y: uint32, delay_ms: uint32]`.
  - Skip 13 bytes (`unk_b6`, `unk_b7`, 2x `uint32`, 3x `uint8`).
  - `patterns_len` (`uint8`) + skip `patterns_len * 92` bytes.
  - Skip 8 bytes (`w1..w4`).

#### Category 1: Entry Points (`cat_offsets[1]`)
- `count` (`uint16`)
- Per Entry Point:
  - `click_id` (`uint16`): Entry marker ID.
  - `name` (20 bytes): Entry label (e.g. `進出點1`).
  - `unk_b1` (`uint8`).
  - `world_x`, `world_y` (`uint32` x2): Arrival coordinates.
  - `blen1` (`uint8`) + skip `blen1` bytes.
  - `blen2` (`uint8`) + skip `blen2` bytes.
  - Skip 18 bytes (`unk_b2`, 4x `uint32`, `unk_b3`).

#### Category 3: ItemAreas (`cat_offsets[3]`)
- `count` (`uint16`)
- Per Item:
  - `click_id` (`uint16`): Interactive harvest click ID.
  - `name_len` (`uint8`) + `name` (19 bytes): Item category name (e.g. `道具`).
  - `unk_b1` (`uint8`).
  - `world_x`, `world_y` (`uint32` x2): Ground position.
  - `blen1` (`uint8`) + skip `blen1` bytes.
  - `blen2` (`uint8`) + skip `blen2` bytes.
  - `unk_b2` (`uint8`).
  - `item_id` (`uint32`): Resource template ID (e.g. 46113 = Shell, 41066 = Coconut).
  - Skip 3 bytes.
  - `respawn_seconds` (`uint16`): Respawn interval in seconds (default 120s if 0).
  - `unk_w2` (`uint16`).

#### Category 6: WarpLoc (`cat_offsets[6]`)
- `count` (`uint16`)
- Per Warp Portal:
  - `click_id` (`uint16`): Portal click ID.
  - `name` (20 bytes): Portal destination label (e.g. `小猴子海灘`).
  - `target_map_id` (`uint16`): Destination map ID (e.g. 10003, 10002).
  - `dest_x`, `dest_y` (`uint32` x2): Destination arrival coordinates.
  - Skip 3 bytes (`unk_b1`, `needed_to_pass`, `unk_b3`).

---

## 2. Multi-JMG Map Background Resolution

Map background artwork is archived across three proprietary DirectDraw package archives:

| Archive Path | Entry Count | Coverage Scope |
| :--- | :---: | :--- |
| `pic/map_c01.JMg` | 4 | High-priority patched maps (`10075.jpg`..`10078.jpg`) |
| `pic/map_d01.JMg` | 27 | Expansion scenes (`10202.jpg`..`10206.jpg`, `13058.jpg`, etc.) |
| `pic/map.JMG` | 326 | Standard core maps (`10000.jpg`..`13222.jpg`) |
| **Total** | **357** | Full resolution JPG artwork for 354 Eve maps |

### JMG Container File Layout
1. Offset `0x00..0x01`: `uint16` total entry count.
2. Index table (32 bytes per entry):
   - Offset `0x00`: `name_len` (`uint8`).
   - Offset `0x01..0x17`: `name_bytes` (23 ASCII characters, null-terminated).
   - Offset `0x18..0x1B`: `offset` (`uint32` absolute file offset).
   - Offset `0x1C..0x1F`: `size` (`uint32` uncompressed JPEG byte length).

### Prioritized Background Resolution Logic
For any map with `map_id` and `scene_id`:
1. Check `f"{map_id}.jpg"` in `map_c01.JMg`, then `map_d01.JMg`, then `map.JMG`.
2. Check `f"{scene_id}.jpg"` in `map_c01.JMg`, then `map_d01.JMg`, then `map.JMG`.
3. 323 maps match directly by `map_id`; 31 maps match by `scene_id`.

---

## 3. Authoritative JSON Datasets

Authoritative, pre-extracted JSON datasets are generated and synchronized between the WLRI pipeline and the Godot client:
- `D:\Godot\WonderlandOnline\wonderland-online-client\assets\data\all_maps.json` (5.42 MB)
- `D:\GitHub\WLRI\data\all_maps.json` (5.42 MB)
- `D:\Godot\WonderlandOnline\wonderland-online-client\assets\data\all_scenes.json` (193 KB)
- `D:\GitHub\WLRI\data\all_scenes.json` (193 KB)

### 3.1 all_maps.json Schema (Map-ID Dictionary)

```json
{
  "10001": {
    "map_id": 10001,
    "scene_id": 10001,
    "name": "Ship Deck",
    "bgm_name": "BGM0007",
    "bgm_id": 7,
    "has_bg": true,
    "bg_file": "10001.jpg",
    "bg_archive": "map.JMG",
    "npc_count": 11,
    "warp_count": 2,
    "item_count": 0,
    "entry_count": 1,
    "npcs": [
      {
        "click_id": 1,
        "name": "Sailor Jack",
        "entity_type": 1,
        "x": 862,
        "y": 675,
        "npc_id": 14004,
        "rotation": 5,
        "walk_behavior": 1,
        "walksteps": [],
        "events": [1, 2]
      }
    ],
    "warps": [
      {
        "click_id": 1,
        "name": "Island Beach",
        "target_map": 10003,
        "target_x": 1038,
        "target_y": 2235
      },
      {
        "click_id": 2,
        "name": "Cabin Entrance",
        "target_map": 10002,
        "target_x": 674,
        "target_y": 1067
      }
    ],
    "items": [],
    "entries": [
      {
        "click_id": 1,
        "name": "Entry 1",
        "x": 1814,
        "y": 904
      }
    ]
  }
}
```

---

## 4. Godot Engine Client APIs

### 4.1 SceneDatabase (`scripts/database/scene_database.gd`)

```gdscript
class_name SceneDatabase
extends RefCounted

## Decodes and caches all 1,172 scene binary records from SceneData.dat or all_scenes.json.

func load_from_file(file_path: String) -> bool
func load_from_json(json_path: String) -> bool
func get_scene(map_id: int) -> SceneRecord
func get_all_scenes() -> Dictionary
func get_total_scenes() -> int
func get_all_map_ids() -> Array[int]
func get_map_summary(map_id: int) -> Dictionary
func search_maps_by_name(query: String) -> Array[Dictionary]
```

### 4.2 EveParser (`scripts/map/eve_parser.gd`)

```gdscript
class_name EveParser
extends RefCounted

## Authoritative parser and cache for all 1,119 maps in Eve.emg and all_maps.json.

func initialize() -> bool
func has_map(map_id: int) -> bool
func get_total_maps() -> int
func get_all_map_ids() -> Array[int]
func get_total_npc_spawns() -> int
func get_total_warps() -> int
func get_warps_for_map(map_id: int) -> Array[WarpInfo]
func get_warp_by_id(map_id: int, click_id: int) -> WarpInfo
func get_ground_items_for_map(map_id: int) -> Array[GroundItemSpawn]
func get_npcs_for_map(map_id: int) -> Array[NpcSpawnInfo]
func get_npc_by_id(map_id: int, click_id: int) -> NpcSpawnInfo
func get_map_summary(map_id: int) -> Dictionary
func search_maps_by_name(query: String) -> Array[Dictionary]
```

---

## 5. Verification & Regression Metrics

Empirical testing performed via Godot headless CLI (`godot_console.exe --headless`):

1. `tests/test_all_maps_and_scenes_database.gd`:
   - 1,172 total scenes verified in `SceneDatabase`.
   - 1,119 total maps verified in `EveParser`.
   - Authentic scene names (`Ship Deck`, `Cabin`, `Newbie Island`, `Shayii Peak`, `Egypt`, `Inca`) confirmed bit-exact.
   - BGM names (`BGM0007`, `BGM0011`, `BGM0024`) and integer IDs validated.
   - Authoritative JSON schemas for `all_maps.json` (1,119 maps) and `all_scenes.json` (1,172 scenes) confirmed valid.
2. `tests/test_portals_and_ground_items.gd`:
   - Ground items (46113 Shell at 2262,4325, 41066 Coconut at 1756,3385) verified.
   - Warps for Map 10001 (Island 10003, Cabin 10002) verified.
3. `tests/test_multi_jmg_map_archives.gd`:
   - All 357 background textures across `map.JMG`, `map_d01.JMg`, `map_c01.JMg` verified.
   - `MapRenderer` camera limits clamped to texture boundaries.
