# Unified World Editor Suite & Database Inspector Technical Specification

## Overview
The Unified World Editor Suite & Database Inspector (`scenes/tools/world_editor.tscn` and `scripts/tools/world_editor.gd`) provides an in-engine authoring, database exploration, and interactive playtest platform for the Wonderland Online Godot 4 client. It consolidates Map Studio, NPC Studio, searchable database inspection across 29,000+ authentic game entities, and a live in-engine simulator.

---

## Architecture & Layout

### 1. Top Toolbar & Quick Navigation
- **`BtnNewMap`**: Initializes a blank canvas template in Map Studio.
- **`BtnNewNPC`**: Clears form fields and primes NPC Studio for a new entity.
- **`BtnOpenMapData`**: Reloads the active map's binary collision data from `user/Map/<ID ^ 0x190C>.MapData` or `data/Ground.MMG`.
- **`BtnSaveAll`**: Triggers atomic serialization of map collision and custom NPC definitions.
- **`BtnRefreshDB`**: Hot-reloads `GameDatabase` and `ArchiveLoader` caches.
- **`OptQuickMap`**: Synchronizes the active map ID across Map Studio, NPC Studio, and the Simulator.

### 2. Tab 1: Map Studio
- **Hosted Component**: Embeds `scenes/tools/map_editor.tscn` (`MapEditor`).
- **Capabilities**:
  - Isometric 20px grid and collision visualization (walkable, solid obstacle, sea, deep ocean, mountain).
  - Background streaming from `pic/map.JMG` via `ArchiveLoader.get_map_background`.
  - Dynamic placement of warp portals, ground resource spawns, and NPC entities.
  - Multi-brush collision painting, flood fill, rect fill, and collision stats calculation.
  - Binary `.MapData` export and `.json` schema interchange.

### 3. Tab 2: NPC Studio
- **Hosted Component**: Embeds `scenes/tools/npc_editor.tscn` (`NpcEditor`).
- **Capabilities**:
  - Full attribute configuration: NPC ID, name, sprite ID, model JMP, model JMA, talk portrait TID, base stats (HP, SP, Level, Speed).
  - 8-way isometric facing preview with authentic heading conversions (`IsometricMath.Heading`).
  - Animated frame preview rendered directly from `001.jma` via `ArchiveLoader.get_jma_frame_128`.
  - Live talk portrait preview via `ArchiveLoader.get_npc_portrait(talk_image)`.
  - Multi-line dialogue authoring with token support (`#n`, `#s`, `#f`, `#R`, `#B`, `#G`, `#Y`) and branching choice options.
  - Waypoint patrol paths and standalone `.tscn` NPC scene export.

### 4. Tab 3: Database Inspector
- **Searchable Multi-Category Index**:
  - **Items (7,569 records)**: Real-time search across ID, item name, and description. Displays authentic 32x32 item icons streamed from `item*.BMg` archives via `ArchiveLoader.get_item_icon`, equip slots (Headgear, Clothes, Weapon, etc.), level, rank, durability, buy/sell prices, and formatted stat deltas.
  - **NPCs (4,929 records)**: Displays NPC ID, name, sprite ID, model ID, talk portrait TID, animated bust preview, level, max HP, and max SP. Includes a one-click `"Load into NPC Studio for Placement"` action.
  - **Dialogues (17,493 records)**: Formatted BBCode presentation with authentic token highlights, raw script extraction, speaker metadata, sound effect tokens, and interactive `"Follow Next Talk Chain"` navigation.
  - **Scenes (86 records)**: Scene map ID, authentic name, BGM ID, in-memory background thumbnail, and 212x131 minimap preview. Includes quick-actions `"Open Scene in Map Studio"` and `"Playtest Scene in Simulator"`.
- **Performance & Virtualization**:
  - Paginated display (50 records per page) ensuring zero frame drops even when querying 17,493 dialogue records.

### 5. Tab 4: Live Playtest & Simulator
- **Quick-Launch Workflow**:
  - Instantiates `scenes/world/map_view.tscn` dynamically into a managed `SubViewport`.
  - Applies active map ID to `MapRenderer.load_map(active_map_id)`.
  - Injects player entity with selected playable character role (Roles 1 to 14) and teleportation to configured test coordinates.
  - Injects studio-authored custom NPCs and portals into the active simulation.
  - Zero-leak cleanup: frees simulation tree cleanly on stop and restores editor state.

---

## Method Signatures & Types

### `WorldEditor` (`scripts/tools/world_editor.gd`)
```gdscript
func _sync_active_map(map_id: int) -> void
func start_playtest() -> void
func stop_playtest() -> void
func _refresh_db_inspector_results() -> void
func _render_db_page() -> void
func _show_item_details(item_id: int) -> void
func _show_npc_details(npc_id: int) -> void
func _show_talk_details(talk_id: int) -> void
func _show_scene_details(map_id: int) -> void
```

---

## Automated Verification Suite

Run headlessly via Godot console:
```powershell
C:\Godot\godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client -s res://tests/test_world_editor.gd
```
- **Tab Verification**: Confirms all 4 tabs exist and are selectable.
- **Database Verification**: Confirms loading and querying across 7,569 items, 4,929 NPCs, 17,493 dialogues, and 86 scenes.
- **Sub-Editor Verification**: Confirms `map_studio` and `npc_studio` instantiation and signal routing.
- **Simulator Verification**: Confirms MapView instantiation, execution, and clean termination.
