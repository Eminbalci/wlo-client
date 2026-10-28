# Wonderland Online - World Editor Suite Specification

## 1. Overview
The World Editor Suite provides in-engine tooling for Wonderland Online content creation and modification inside Godot 4. The suite comprises three interconnected tools:
1. **NpcEditor** (`res://scripts/tools/npc_editor.gd`, `res://scenes/tools/npc_editor.tscn`): Visual NPC creator, 8-directional sprite animator, talk portrait inspector, and .tscn scene generator.
2. **MapEditor** (`res://scripts/tools/map_editor.gd`, `res://scenes/tools/map_editor.tscn`): Map creation, 2:1 axonometric collision grid painter, portal/warp placer, ground item harvester placer, and binary `.MapData` exporter.
3. **WorldEditor** (`res://scripts/tools/world_editor.gd`, `res://scenes/tools/world_editor.tscn`): Unified 5-tab suite coordinating Map Studio, NPC Studio, Searchable Database Inspector (7,569 items, 4,929 NPCs, 17,493 dialogues, 86 scenes), and one-click in-engine Live Playtest Simulator.

---

## 2. NpcEditor Technical Specification

### 2.1 Class Architecture
- **Inherits:** `Control`
- **Script:** [npc_editor.gd](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/tools/npc_editor.gd)
- **Scene:** [npc_editor.tscn](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scenes/tools/npc_editor.tscn)

### 2.2 Public API & Methods
- `create_npc_entity() -> NpcEntity`
  - Instantiates `res://scenes/world/npc.tscn` (or `NpcEntity.new()`).
  - Configures all exported variables: `npc_id`, `npc_name`, `model_jmp`, `model_jma`, `world_position`, `heading`, `talk_id`, `talk_image`, `dialogue_text`, `dialogue_choices`, `move_speed`, `walksteps`, and `walkstep_delays`.
  - Returns the configured entity ready for node tree addition.
- `rotate_preview(dir: int) -> void`
  - Rotates preview heading by direction (`+1` clockwise, `-1` counter-clockwise).
- `set_heading(p_heading: int) -> void`
  - Sets preview heading to `p_heading % 8` (0=North, 1=North-West, 2=West, 3=South-West, 4=South, 5=South-East, 6=East, 7=North-East).
- `save_custom_preset(preset_name: String = "", custom_data: Dictionary = {}) -> bool`
  - Persists custom NPC configurations into `user://custom_npcs.json`.
- `load_presets() -> Dictionary`
  - Reads and merges presets from `user://custom_npcs.json` and built-in defaults.
- `export_npc_scene(file_path: String = "") -> String`
  - Generates a standalone, fully configured Godot 4 `.tscn` scene file extending `NpcEntity`.
- `copy_gdscript_snippet() -> String`
  - Copies ready-to-paste dynamic spawn GDScript code to system clipboard.

---

## 3. MapEditor Technical Specification

### 3.1 Class Architecture
- **Inherits:** `Control`
- **Script:** [map_editor.gd](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/tools/map_editor.gd)
- **Scene:** [map_editor.tscn](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scenes/tools/map_editor.tscn)

### 3.2 Collision Terrain Matrix
Collision flags strictly match the 2:1 axonometric projection standard:
- `0x00`: Walkable (default traversable land)
- `0x01`: Solid Wall (impassable obstacle)
- `0x02`: Sea (requires canoe, raft, boat, or ship)
- `0x04`: Deep Ocean (requires ship, steamship, or plane)
- `0x08`: Water (requires marine vehicle)
- `0x10`: Mountain (requires flying vehicle / plane)
- `0x40`: Shallow Water
- `0x80`: Hot Spring

### 3.3 Public API & Methods
- `set_map_header(p_id: int, p_name: String, p_w: int, p_h: int) -> void`
  - Re-initializes map dimensions, grid resolution (20px per tile), and loads map background texture.
- `paint_tile(gx: int, gy: int, flag: int) -> void`
  - Paints tile collision flag at grid coordinate `(gx, gy)` using current brush size (1x1, 3x3, 5x5, 7x7).
- `set_collision_cell(gx: int, gy: int, flag: int) -> void`
  - Sets collision flag directly at single tile cell `(gx, gy)`.
- `get_collision_cell(gx: int, gy: int) -> int`
  - Returns collision flag at `(gx, gy)`.
- `flood_fill_collision(start_gx: int, start_gy: int, fill_flag: int) -> void`
  - 4-way queue-based flood fill replacing contiguous matching collision tiles.
- `add_portal(pos: Vector2, target_id: int, dest: Vector2, arg4 = "Portal", arg5 = 56.0, col: Color = Color(0.2, 0.75, 1.0, 0.85)) -> PortalEntry`
  - Places warp portal with trigger radius and destination parameters.
- `add_ground_item(pos: Vector2, p_item_id: int, arg3 = "", arg4 = 1, arg5 = 120.0) -> GroundItemEntry`
  - Places harvesting ground resource with item ID, slot index, and respawn timer.
- `add_npc(pos: Vector2, p_npc_id: int, p_name: String, p_jmp: String, p_heading: int = 4) -> NpcPlacementEntry`
  - Places NPC entity on map.
- `export_mapdata_binary(file_path: String = "") -> bool`
  - Exports bit-exact binary `.MapData` format: 36-byte block header (dimensions, elevation, flags) + raw collision matrix.
  - Verified compatible with `MapData.load_from_mapdata_file`.
- `export_map_json(file_path: String = "") -> bool`
  - Serializes full map state, dimensions, collision stats, portals, items, and NPCs into structured JSON.
- `export_map_scene(file_path: String = "") -> bool`
  - Emits production-ready Godot 4 `.tscn` scene extending `map_view.gd` with MapRenderer, Camera2D, Player, Portals, GroundItems, and NPCs.

---

## 4. WorldEditor Technical Specification

### 4.1 Class Architecture
- **Inherits:** `Control`
- **Script:** [world_editor.gd](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/tools/world_editor.gd)
- **Scene:** [world_editor.tscn](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scenes/tools/world_editor.tscn)

### 4.2 Tab Structure
- **Tab 1: Map Studio:** Hosts embedded `map_editor.tscn`.
- **Tab 2: NPC Studio:** Hosts embedded `npc_editor.tscn`.
- **Tab 3: Database Inspector:** Searchable database coordinator for:
  - Items (7,569 entries)
  - NPCs (4,929 entries)
  - Dialogues / Talks (17,493 entries)
  - Scenes / Maps (86 entries)
- **Tab 4: Live Playtest Simulator:** In-engine viewport simulator running `scenes/world/map_view.tscn`.

### 4.3 Search API
- `search_database(category: String, query: String) -> Array`
  - Queries `GameDatabase` registries with real-time text matching.
  - Returns structured dictionaries with ID, name, sprite/icon IDs, and descriptive details.

---

## 5. Automated Verification
The complete test suite is verified via headless console:
```powershell
& "C:\Godot\godot_console.exe" --headless --path "D:\Godot\WonderlandOnline\wonderland-online-client" scenes/tests/test_world_editor_tools.tscn
```
- Total Suites: 3
- Pass Rate: 100%
- Regressions: 0
