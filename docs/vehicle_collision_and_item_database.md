# Technical Documentation: Map Collision, Vehicle Gates & Item Database Parity

## 1. Architectural Overview

This subsystem implements authentic tile collision enforcement, multimodal vehicle traversal gating, and bit-exact item database decryption for the Wonderland Online Godot client (`wonderland-online-client`).

---

## 2. Terrain Collision & Vehicle Traversal Matrix

### 2.1 Collision Flags (`TileCollisionFlags`)

Extracted from `.MapData` block streams (`user/Map/<ID ^ 0x190C>.MapData`) and `data/Ground.MMG` isometric cell matrices:

| Flag Constant | Hex Byte | Decimal | Terrain Semantics | Traversal Requirement |
|---|---|---|---|---|
| `WALKABLE` | `0x00` | 0 | Normal walkable land / ground | Foot, Mounts, Raft (shore), Boats, Plane |
| `SOLID_WALL` | `0x01` | 1 | Solid impassable obstacle / railing / border | Impassable to all entities |
| `WATER` | `0x02` | 2 | Marine water / sea / rivers | Boat, Raft, Canoe, Plane |
| `DEEP_OCEAN` | `0x04` | 4 | Deep ocean currents & high seas | Ship, Steamship, Plane (Raft blocked) |
| `MOUNTAIN` | `0x08` | 8 | Elevated cliff / mountain peaks | Flying vehicle (Plane, Balloon, UFO) |
| `SHALLOW_WATER` | `0x40` | 64 | Tidal shore / shallow water | Boat, Raft, Canoe, Plane |
| `HOT_SPRING` | `0x80` | 128 | Geothermal water / hot springs | Bathing stance / special access |

### 2.2 Vehicle State Machine (`PlayerEntity.VehicleType`)

```gdscript
enum VehicleType {
    NONE = 0,   # On foot / walking
    RAFT = 1,   # Fragile watercraft (Raft, Robinson's Raft, Wooden Raft)
    BOAT = 2,   # Standard water vessel (Canoe, Motorboat, Sailboat, Shark)
    SHIP = 3,   # Heavy naval vessel (Steamship, Battleship)
    PLANE = 4   # Aerial craft (Bamboo Dragonfly, Propeller Plane, Hot Air Balloon, UFO)
}
```

### 2.3 Traversal Decision Engine (`MapData.check_traversal`)

```gdscript
static func check_traversal(flag: int, vehicle: int) -> Dictionary
```

- **Parameters:**
  - `flag: int`: Collision byte of destination grid cell.
  - `vehicle: int`: Active `VehicleType` (0..4).
- **Return Type:** `Dictionary` with keys:
  - `"allowed": bool`: Whether movement can proceed.
  - `"reason": String`: Player-facing feedback message if blocked.
- **Rules:**
  1. `flag & SOLID_WALL (0x01)`: Blocked for all vehicles. Reason: `"Path is blocked by an obstacle."`
  2. `flag & MOUNTAIN (0x08 | 0x80)`: Allowed only if `vehicle == VehicleType.PLANE`. Otherwise: `"You need a flying vehicle to cross this terrain!"`
  3. `flag & DEEP_OCEAN (0x04)`: Allowed for `BOAT`, `SHIP`, `PLANE`. Raft is blocked with `"A fragile raft cannot cross deep ocean! You need a ship or advanced vehicle."` Foot is blocked with `"You need a ship or advanced vehicle to traverse deep ocean!"`
  4. `flag & WATER (0x02 | 0x40)`: Allowed for all mounted vehicles (`!= NONE`). Foot is blocked with `"You need a vehicle to traverse water!"`
  5. `flag == WALKABLE (0x00)`: Allowed.

---

## 3. Kinematic Gate Integration

### 3.1 Player Movement Validation

In `PlayerEntity.set_target_world_position(new_target: Vector2) -> bool`:
1. Converts pixel destination `new_target` to grid coordinates via `MapData.world_to_grid(new_target)`.
2. Queries collision byte from `_map_data.get_collision_byte(gx, gy)`.
3. Runs `MapData.check_traversal(flag, current_vehicle)`.
4. If not allowed: cancels motion (`is_moving = false`), emits `movement_blocked(reason, new_target)`, and returns `false`.
5. If allowed: updates `target_world_position`, computes 8-directional heading via `IsometricMath.get_heading`, sets `is_moving = true`, and returns `true`.

### 3.2 HUD Notification

`MapView` connects `player.movement_blocked` to `_on_player_movement_blocked(reason, target_pos)`. Dispatches system alert directly into the chat log:
```gdscript
hud.add_chat_message("System", reason, "System")
```

---

## 4. Item Database Parity & Multi-Archive Asset Pipeline

### 4.1 Item.dat 451-Byte Record Specifications

Cross-referenced with `PhoenixData.dll` (`PhxItemDat`, `PhxItemInfo`) and `itemDat.wpdat`:

| Byte Offset | Size | Type | Decryption Routine | Semantic Field |
|---|---|---|---|---|
| `0x00` | 1 | `uint8` | Raw | Name Length ($L \in [2, 14]$) |
| `0x01..0x0E` | 14 | `char[]` | In-place reversal: `rec[15 - L .. 14]` | Display Name |
| `0x0F` | 1 | `uint8` | `((v ^ 0x9A) - 9) & 0xFF` | Item Type (`1`=Equip, `25`=Tool, `39`=Vehicle) |
| `0x10` | 2 | `uint16` | `((v ^ 0xEFC3) - 9) & 0xFFFF` | Item ID |
| `0x12` | 2 | `uint16` | `((v ^ 0xEFC3) - 9) & 0xFFFF` | Small Icon ID (`%d.bmp`) |
| `0x14` | 2 | `uint16` | `((v ^ 0xEFC3) - 9) & 0xFFFF` | Large Icon ID (`%d.bmp`) |
| `0x2E` | 1 | `uint8` | `((v ^ 0x9A) - 9) & 0xFF` | Equip Position / Wear Slot (`1`=Head, `2`=Body, `3`=Weapon, `4`=Wrist, `5`=Shoes, `6`=Ring) |
| `0x92` | 1 | `uint8` | Raw | Description Length ($D \in [0, 200]$) |
| `0x93..0x190` | 254 | `char[]` | In-place reversal: `rec[0x191 - D .. 0x190]` | Item Description |

### 4.2 Multi-Archive Icon Indexing (`ArchiveLoader`)

Wonderland Online partitions item icons across multiple archives:
- `assets/pic/item.BMg`: Standard items (icons `1000.bmp`..`3198.bmp`)
- `assets/pic/item1.BMg`: Vehicles and oversized appliances (e.g. Raft `8000.bmp`, dimensions $136 \times 103$ px)
- `assets/pic/item2.BMg` & `item3.BMg`: Special event and expansion equipment

`ArchiveLoader.get_item_icon(icon_id: int) -> ImageTexture` now scans `_item_archives = [item.BMg, item1.BMg, item2.BMg, item3.BMg, item_c01.BMg, item_c02.BMg]`, ensuring 100% texture availability.
