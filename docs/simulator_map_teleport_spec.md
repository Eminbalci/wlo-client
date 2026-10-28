# World Editor Live Playtest & Simulator Map Teleportation Specification

## Overview & Problem Statement
In the Wonderland Online Godot 4 Client World Editor Suite (`scripts/tools/world_editor.gd`, `scenes/tools/world_editor.tscn`), the **Live Playtest & Simulator** tab (Tab 10) previously failed to teleport players to user-selected maps. Users selecting maps from `OptSimMap`, the global `OptQuickMap`, or the Database Inspector found that the simulator remained stuck on Map 10001 (Ship Deck) or spawned players at out-of-bounds coordinates without loading the destination map's authentic entities.

### Root Cause Analysis
1. **Unsynchronized Map Dropdown**: While `opt_sim_map` was declared as an `@onready` node in `world_editor.gd`, `_init_simulator()` only populated `opt_sim_role` and never configured or populated `opt_sim_map`.
2. **Coordinate Drift & Stale Spawns**: Switching maps did not update the spawn coordinate spinboxes (`SpinSimX`, `SpinSimY`). Players teleported to maps with dimensions smaller than Map 10001 spawned outside the map boundaries in black void space.
3. **MapView load_map Bypass**: `start_playtest()` instantiated `MapViewScene` into `sim_viewport` and invoked `map_renderer.load_map(active_map_id)` directly. This completely bypassed `MapView.load_map(target_map_id, spawn_pos)`, leaving `MapView`'s internal map switching pipeline (`_switch_map_entities`, `_spawn_dynamic_map_npcs`, `_spawn_map_portals`, `_spawn_ground_items`, and camera alignment) uncalled.
4. **No Runtime Teleport Control**: No mechanism existed to switch maps or teleport coordinates while the simulator was already active in the sub-viewport.

---

## Technical Architecture & Implementation

### 1. Unified Simulator Map Population & Reactive Synchronization
In `scripts/tools/world_editor.gd`:
- Implemented `_populate_sim_maps()`:
  - Collects all 1,184 maps indexed across `GameDatabase.scenes`, `SceneData.dat`, and `EveParser`.
  - Populates `opt_sim_map` with sorted entries formatted as `[ID] - [Name]`.
  - Connects `opt_sim_map.item_selected` to `_on_sim_map_selected`.
  - Synchronizes selection with `active_map_id`.
- Connected `_init_simulator()` to ensure `_populate_sim_maps()` runs alongside role configuration.
- Enhanced `_sync_active_map(map_id)`:
  - Bi-directionally synchronizes `opt_quick_map` (toolbar), `opt_sim_map` (simulator), `map_studio` (embedded canvas), and the database readout stats.
  - Automatically queries `_get_default_spawn_for_map(map_id)` and updates `spin_sim_x.value` and `spin_sim_y.value`.

### 2. Map Default Spawn Resolution Engine
Implemented `_get_default_spawn_for_map(map_id: int) -> Vector2` in `scripts/tools/world_editor.gd` and `_resolve_default_spawn(target_map_id: int) -> Vector2` in `scripts/map/map_view.gd`:
- **Canonical Overrides**:
  - `10001` (Ship Deck): `(1042, 1075)`
  - `10002` (Cabin): `(674, 1067)`
  - `10003` (Kitchen / Bunk): `(420, 360)`
  - `10004` (Store Room): `(300, 240)`
  - `10005` (Kelan Trail): `(400, 300)`
  - `10007` (Kelan Village): `(500, 400)`
  - `10008` (Large Island / Trail): `(200, 200)`
  - `10011` (Beach Awakening): `(1390, 2460)`
  - `12001` (Holy Village): `(500, 350)`
  - `20001` (Kelan Village): `(500, 400)`
- **Eve.emg Query**: If not canonical, inspects `EveParser.get_npcs_for_map(map_id)` and returns the first NPC's world position, or the first exit warp coordinate.
- **ArchiveLoader Geometry**: If no NPC/warp exists, queries map background texture dimensions from `ArchiveLoader.get_map_background(map_id)` and returns the center coordinate `(width / 2, height / 2)`.
- **Fallback**: Returns `Vector2(500, 400)`.

### 3. Authoritative Map Loading in MapView
Updated `start_playtest()` and `teleport_simulator_to()` to call `MapView.load_map(target_map_id, spawn_pos)`:
- Invokes `MapRenderer.load_map(target_map_id)` to load background tiles, collision data, and minimap texture.
- Binds collision matrix `_map_data` to `player.map_data` and all dynamic `NpcEntity` instances.
- Executes `_switch_map_entities(target_map_id)`:
  - Recycles previous dynamic NPCs, portals, and ground items.
  - Spawns authentic dynamic NPCs from `Eve.emg` with 128x128 JMA/JMP models, 8-directional headings, and `TalkDatabase` dialogues.
  - Spawns dynamic warp portals and ground items.
- Calls `player.teleport_to(spawn_pos)` to clear existing pathfinding waypoints, reset movement states, and update camera smoothing.
- Marks destination portals inside trigger radius to suppress recursive warp loops.
- Fires `_on_map_loaded(target_map_id)` to sync HUD status, coordinates, and minimap indicator.

### 4. Interactive In-Engine Teleportation & UI Controls
In `scenes/tools/world_editor.tscn`:
- Added `BtnSimTeleport` ("Teleport") button to `SimToolbar`.
- Updated `SpinSimX` and `SpinSimY` `max_value` from `5000.0` to `10000.0` to support large world maps up to 10,000 pixels.
- In `scripts/tools/world_editor.gd`:
  - Connected `btn_sim_teleport.pressed` to `_on_btn_sim_teleport_pressed()`.
  - Implemented `teleport_simulator_to(map_id, spawn_pos)` supporting live real-time map switching while playtest is active.
  - Contextual studio NPC injection: `chk_sim_inject_npcs` checks if `npc_studio.map_id_spin` matches the destination map before injecting customized NPCs.

---

## Data Flow Diagram

```
[ User Interaction ]
   ├── OptSimMap Selected ────────────┐
   ├── OptQuickMap Selected ──────────┤
   ├── Database Inspector Playtest ───┤
   └── BtnSimTeleport Pressed ────────┤
                                      ▼
                        _sync_active_map(map_id)
                                      │
            ┌─────────────────────────┴─────────────────────────┐
            ▼                                                   ▼
_get_default_spawn_for_map(map_id)                     Sync UI Controls
  - Canonical table overrides                            - opt_quick_map.selected
  - Eve.emg NPC/warp query                               - opt_sim_map.selected
  - Background center fallback                           - spin_sim_x.value
            │                                            - spin_sim_y.value
            ▼                                                   │
  spawn_pos: Vector2                                            │
            │                                                   │
            └─────────────────────────┬─────────────────────────┘
                                      ▼
                       teleport_simulator_to(mid, spawn_pos)
                       OR start_playtest()
                                      │
                                      ▼
                       MapView.load_map(mid, spawn_pos)
                                      ├── map_renderer.load_map(mid)
                                      ├── _switch_map_entities(mid)
                                      │     ├── _spawn_dynamic_map_npcs(mid)
                                      │     ├── _spawn_map_portals(mid)
                                      │     └── _spawn_ground_items(mid)
                                      ├── player.teleport_to(spawn_pos)
                                      ├── _update_camera_to_player()
                                      └── _on_map_loaded(mid)
```

---

## Verification & Automated Test Suite

Test Suite: `tests/test_simulator_teleport.gd`
Command: `C:\Godot\godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client -s res://tests/test_simulator_teleport.gd`

### Test Results
- **Test 1**: `opt_sim_map` population verified with 1,184 maps and `btn_sim_teleport` button node confirmed. **PASSED**
- **Test 2**: Selected Map 10002 (Cabin) in `opt_sim_map`. Verified `active_map_id` synced to 10002 and default spawn coordinates set to `(674, 1067)`. **PASSED**
- **Test 3**: Launched simulator on Map 10002. Verified `MapView` loaded Map 10002, 7 cabin entities active, player positioned at `(674, 1067)`, and ship deck entities hidden. **PASSED**
- **Test 4**: Real-time live teleport to Map 10005 (Kelan Trail) while simulator was running. Verified `MapView` dynamically spawned 5 authentic `Eve.emg` NPCs (Dragon Old Man, Persian Cat, Tabby Cat, Breillat, Gold Chest). **PASSED**
- **Test 5**: Custom coordinate teleport using `btn_sim_teleport` to Map 12001 (Holy Village) at `(523, 334)`. Verified player positioned at `(523, 334)` and 3 authentic NPCs spawned. **PASSED**
- **Test 6**: Teleported back to Map 10001 (Ship Deck). Verified dynamic NPCs recycled, ship deck restored with 11 visible deck entities. **PASSED**
- **Test 7 & 8**: Playtest cleanly stopped, instances freed without memory leaks. **PASSED**

**Overall Verification**: 8 PASSED, 0 FAILED (100% Zero-Error).
