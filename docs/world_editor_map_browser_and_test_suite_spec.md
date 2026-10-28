# World Editor Map Browser & Automated Test Suite Specification

## Overview
This specification details the architecture, integration, and verification of the Map Browser and NPC Inspector within `MapEditor` and `WorldEditor`, as well as the master automated test suite `tests/test_all_maps_and_npcs.gd` validating end-to-end map and NPC extraction and runtime spawning across the entirety of Wonderland Online (1,119 maps in `Eve.emg`, 1,172 scenes in `SceneData.dat`, 4,930+ NPC templates in `Npc.dat`, and 8,181 placed NPC instances).

---

## 1. Map Browser & NPC Inspector Architecture

### 1.1 MapEditor Browser Integration (`scripts/tools/map_editor.gd`)
- **Map Dropdown (`preset_select: OptionButton`)**:
  - Automatically populated with all 1,119+ maps indexed from `EveParser` and `SceneDatabase`.
  - Format: `"[ID] Name"` (e.g. `"[10001] Ship Deck"`, `"[10003] Deserted Island"`, `"[10005] North Island Path"`).
  - Emits `item_selected` to trigger `load_map_from_id(selected_id)`.
- **Searchable Quick Filter (`map_search_edit: LineEdit`)**:
  - Filters the `preset_select` dropdown dynamically as characters are entered.
  - Pressing Enter (`text_submitted`) with an integer map ID loads that map directly.
- **NPC Dock Panel (`map_npc_dock_list: ItemList`)**:
  - Lists every NPC placed on the loaded map with full telemetry:
    `"[#ClickID] Name (Tpl:TemplateID) | Pos: (X, Y) | Facing: Heading"`
  - Selecting an NPC in the list focuses the canvas view on the NPC's world coordinates and populates the entity inspector form.

### 1.2 WorldEditor Universal Map Selector (`scripts/tools/world_editor.gd`)
- **Quick Map Selector (`opt_quick_map: OptionButton`)**:
  - Populated with all 1,119+ maps from `_game_database.scenes` and `EveParser`.
  - Synchronizes the active map ID across all 11 content studios (`MapStudio`, `NPCStudio`, `QuestStudio`, `DatabaseInspector`, `Simulator`).
- **Map Search Bar (`edit_quick_map_search: LineEdit`)**:
  - Real-time text filtering for map IDs and English/Chinese scene names.
- **Simulator & Map Studio Synchronization**:
  - Selecting any map automatically loads its background texture across Multi-JMG archives (`map.JMG`, `map_c01.JMg`, `map_d01.JMg`), collision flags from `.MapData`, warp portals, ground harvestable items, and dynamic NPC entities.

---

## 2. Multi-JMG Asset Streaming Engine (`scripts/core/archive_loader.gd`)
- **Archive Handles**:
  - `map.JMG`: 326 original map backgrounds (Map IDs 10000..60015).
  - `map_d01.JMg`: 27 expansion map backgrounds (Map IDs 10202..13502).
  - `map_c01.JMg`: 4 interior map backgrounds (Map IDs 10075..10078).
- **APIs**:
  - `has_map_background(scene_id: int) -> bool`: Fast existence check without decompression overhead.
  - `get_map_background(scene_id: int) -> ImageTexture`: Resolves filename variants (`"%d.jpg"`, `"%05d.jpg"`, `"%04d.jpg"`, `10011 -> 10003.jpg`) across all three archives with RAM caching.
  - `get_npc_texture(sprite_id: int, heading: int = 0) -> ImageTexture`: Composites playable roles (1..14) and decodes standard NPC/monster sprites (001.jma, 007.jma) into 128x128 textures.

---

## 3. Automated Test Suite (`tests/test_all_maps_and_npcs.gd`)

The suite provides 100% automated headless verification across 7 rigorous testing tiers:

1. **TEST 1: SceneDatabase**:
   - Asserts all 1,172 scenes decoded from `SceneData.dat` / `all_scenes.json`.
   - Validates landmark map records (10001, 10002, 10003, 10005, 10007, 10011, 10075).
2. **TEST 2: EveParser**:
   - Asserts all 1,119 maps indexed from `Eve.emg`.
   - Validates exact counts: 8,181 NPC spawns, 2,791 warps, 209 ground items.
   - Validates specific map spawn counts (11 on 10001, 7 on 10002, 8 on 10003, 5 on 10005).
3. **TEST 3: NpcDatabase**:
   - Asserts 4,946 NPC templates loaded from `all_npcs.json` / `Npc.dat`.
   - Validates key story actors (Captain Robinson, Jack, Ross, Drunk Man, Peter, John, Natasha, Breillat, Kelang, Persian Cat).
4. **TEST 4: Multi-JMG ArchiveLoader**:
   - Verifies physical presence and JPEG extraction across `map.JMG` (10001.jpg), `map_c01.JMg` (10075.jpg), and `map_d01.JMg` (10202.jpg).
5. **TEST 5: Runtime MapView Loading & Dynamic NPC Spawning**:
   - Instantiates `MapView` node and executes round-trip map transitions:
     - Map 10001 (Ship Deck): 11 active entities, Captain Robinson at (1421, 632).
     - Map 10002 (Cabin): 7 active entities.
     - Map 10003 (Deserted Island): authentic beach awakening/kitchen entities.
     - Map 10005 (Kelan Trail): 5 dynamic entities.
     - Map 10007 (Kelan Village): authentic background and entities.
6. **TEST 6: Kinematics, Click IDs, and Talk Trigger Resolution**:
   - Validates all 8 Eve rotation <-> JMP heading conversions (`rotation_to_heading` and `heading_to_rotation`).
   - Validates Click ID lookups (`get_npc_by_id`, `get_warp_by_id`).
   - Validates authentic dialogue resolution via `TalkDatabase.resolve_talk_for_npc()`.
7. **TEST 7: MapEditor & WorldEditor Integration**:
   - Instantiates `MapEditor` and asserts 1,184 maps loaded into `preset_select`.
   - Validates NPC dock list population and coordinate formatting.
   - Instantiates `WorldEditor` and validates `opt_quick_map` active map synchronization to MapStudio.

---

## 4. Execution & Verification Command

```powershell
C:\Godot\godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client -s res://tests/test_all_maps_and_npcs.gd
```

**Verification Result**:
```
================================================================================
--- [100% SUCCESS] ALL 7 MAP & NPC INTEGRATION TESTS PASSED WITH ZERO ERRORS ---
================================================================================
```
