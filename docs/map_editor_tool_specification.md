# Map Creation & Collision / Portal Editor Tool Specification

## Overview
The Map Editor (`scripts/tools/map_editor.gd` and `scenes/tools/map_editor.tscn`) is a standalone and in-editor development tool for Wonderland Online maps in Godot 4.
It enables loading existing map backgrounds from `map.JMG` archives or local files, inspecting and painting 20px axonometric collision tiles, configuring warp portals, placing ground item spawners, managing NPC entities, and exporting to three target formats:
1. Binary `.MapData` compatible with `MapData.load_from_mapdata_file` (36-byte block headers, XOR key `0x190C`, `PackedByteArray` matrix).
2. Human-readable JSON (`.json`) with Base64 collision encoding.
3. Production-ready Godot 4 scene (`.tscn`) extending `res://scripts/map/map_view.gd` with MapRenderer, Camera2D, PlayerEntity, Portal, GroundItem, and NpcEntity nodes.

---

## 1. Coordinate Mathematics & Transformations

The Wonderland Online tile grid operates at a base unit of 20 pixels per tile (`MapData.TILE_SCALE = 20`).

| Transformation | Method Signature | Formula / Implementation |
|---|---|---|
| World to Grid | `world_to_grid(world_pos: Vector2) -> Vector2i` | `Vector2i(int(floor(x / 20.0)), int(floor(y / 20.0)))` |
| Grid to World (Top-Left) | `grid_to_world(grid_pos: Vector2i) -> Vector2` | `Vector2(grid_pos.x * 20.0, grid_pos.y * 20.0)` |
| Grid to World (Center) | `grid_to_center_world(grid_pos: Vector2i) -> Vector2` | `Vector2((grid_pos.x + 0.5) * 20.0, (grid_pos.y + 0.5) * 20.0)` |
| World to Screen | `world_to_screen(world_pos: Vector2) -> Vector2` | `world_pos * zoom_level + pan_offset` |
| Screen to World | `screen_to_world(screen_pos: Vector2) -> Vector2` | `(screen_pos - pan_offset) / zoom_level` |

Viewport panning is triggered by right-click drag or middle-click drag, while mouse wheel up/down scales zoom centered at the cursor position.

---

## 2. Collision Flags & Color Coding

Collision values match `MapData.TileCollisionFlags`:

| Flag | Value | Name | Editor Overlay Color | Traversal Rule |
|---|---|---|---|---|
| `WALKABLE` | `0x00` | Walkable Land | `Color(0.10, 0.85, 0.25, 0.25)` | Unrestricted foot and vehicle movement |
| `SOLID_WALL` | `0x01` | Solid Obstacle / Wall | `Color(0.95, 0.15, 0.15, 0.45)` | Blocks all movement |
| `SEA` | `0x02` | Sea / Coastal | `Color(0.15, 0.45, 0.95, 0.45)` | Requires Boat, Raft, Ship, or Flying Vehicle |
| `DEEP_OCEAN` | `0x04` | Deep Ocean | `Color(0.05, 0.15, 0.55, 0.55)` | Requires Ship or Plane (Rafts sink) |
| `WATER` | `0x08` | Inland Water | `Color(0.15, 0.85, 0.95, 0.45)` | Requires any vehicle |
| `MOUNTAIN` | `0x10` | Mountain / Sky Peak | `Color(0.65, 0.40, 0.15, 0.55)` | Requires Flying Vehicle (Plane) |
| `SHALLOW_WATER` | `0x40` | Shallow Water | `Color(0.25, 0.90, 0.75, 0.40)` | Requires vehicle |
| `HOT_SPRING` | `0x80` | Hot Spring | `Color(0.75, 0.20, 0.85, 0.50)` | Special terrain / bathing |

### Collision Painting Tools
- **Brush:** Paints selected flag in 1x1, 3x3, 5x5, or 7x7 tile kernels.
- **Eraser:** Resets painted tiles to `0x00` (Walkable).
- **Rectangle Fill:** Dragging selects a bounding rectangle and fills all tiles within it.
- **Flood Fill:** Queue-based 4-directional contiguous tile filling without recursion.
- **Fill All:** Uses `PackedByteArray.fill()` for instant full-map assignment.
- **Clear All:** Resets entire grid to `0x00`.
- **Invert:** Toggles Walkable vs Solid Wall across the entire grid.

---

## 3. Entity Management

### 3.1 Warp Portals (`PortalEntry`)
- Parameters:
  - `portal_id`: Integer identifier.
  - `portal_name`: Display name (e.g. "Cabin Door").
  - `world_position`: Placement coordinates on map.
  - `target_map_id`: Destination Scene / Map ID.
  - `target_coords`: Destination landing coordinates `Vector2(x, y)`.
  - `trigger_radius`: Radius in world pixels (default: `56.0`).
  - `portal_color`: Ground aura tint (default: Cyan `Color(0.2, 0.75, 1.0, 0.85)`).
- Visual: Canvas arc circle, center diamond, destination label, and selection ring.

### 3.2 Ground Items (`GroundItemEntry`)
- Parameters:
  - `item_id`: Item identifier matching `Item.dat` (e.g. 46113 Shell, 41066 Coconut, 10002 Plate).
  - `item_name`: Name automatically resolved from `GameDatabase.items`.
  - `world_position`: Spawner world coordinates.
  - `slot`: Inventory slot index (1..50).
  - `respawn_seconds`: Respawn timer interval (default: `120.0` seconds).
- Visual: 16x16 icon box, label with item name and ID, and selection ring.

### 3.3 NPCs (`NpcEntry`)
- Parameters:
  - `npc_id`: NPC ID matching `Npc.dat` (e.g. 14001 Crew, 14003 Captain Robinson).
  - `npc_name`: Nameplate text.
  - `model_jmp`: Character sprite animation file (e.g. `1037.jmp`, `1038.jmp`).
  - `model_jma`: Sprite package (default `001.jma`).
  - `heading`: 8-directional orientation (0: North, 1: NW, 2: W, 3: SW, 4: S, 5: SE, 6: E, 7: NE).
  - `dialogue_text`: Default prompt speech text.
  - `dialogue_choices`: Array of dialogue option strings.
- Visual: Directional circle with heading pointer line, nameplate, and selection ring.

---

## 4. Export Specifications

### 4.1 Binary `.MapData` (`export_mapdata_binary`)
Exports file to `res://assets/user/Map/<disk_id>.MapData` where `<disk_id> = map_id ^ 0x190C`.
Block header structure (36 bytes):
- `offset + 0`: `u32` block ID (`1`)
- `offset + 4`: `u32` sprite ID (`0`)
- `offset + 8`: `s32` grid X (`0`)
- `offset + 12`: `s32` grid Y (`0`)
- `offset + 16`: `s16` block dimension X (`cols`)
- `offset + 18`: `s16` block dimension Y (`rows`)
- `offset + 20`: `u8` is uniform (`0`)
- `offset + 21`: `u8` elevation (`0`)
- `offset + 22..35`: 14 bytes reserved padding (`0`)
Followed by `cols * rows` bytes representing the continuous collision matrix.
Verified by roundtrip reading with `MapData.load_from_mapdata_file()`.

### 4.2 JSON Format (`export_map_json` / `import_map_json`)
Exports comprehensive JSON structure:
- `map_id`, `map_name`, `width_px`, `height_px`, `cols`, `rows`, `tile_scale`
- `player_spawn`: `{ "x", "y" }`
- `background_source`: Relative asset path or archive reference
- `collision_base64`: Raw `PackedByteArray` encoded via `Marshalls.raw_to_base64()`
- `portals`: List of portal definitions
- `ground_items`: List of ground item spawner definitions
- `npcs`: List of NPC entity definitions

### 4.3 Scene Generator (`export_map_scene`)
Generates Godot 4 text scene (`.tscn`) extending `res://scripts/map/map_view.gd` with:
- `MapRenderer`: Configured with `current_map_id = map_id`.
- `Camera2D`: Focused at `player_spawn_pos`.
- `Entities` (Y-sorted):
  - `Player` instance (`res://scenes/world/player.tscn`).
  - Portals attached with `res://scripts/map/portal.gd`.
  - Ground items attached with `res://scripts/map/ground_item.gd`.
  - NPCs instanced from `res://scenes/world/npc.tscn`.
- `CanvasLayer` containing `HUD` (`res://scenes/ui/hud.tscn`).
All generated scenes can be loaded directly by `ResourceLoader.load()` and instantiated in-game without modification.
