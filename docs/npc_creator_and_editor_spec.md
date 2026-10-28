# Wonderland Online - NPC Creator & Editing Tool Specification

## Overview
The **NPC Creator & Editor Tool** (`NpcEditor`) is a production-grade, interactive developer and modding tool integrated directly into the Wonderland Online Godot 4 client. It enables rapid authoring, inspection, 8-directional kinematic previewing, dialogue structuring, patrol pathing, and zero-defect scene export for all Wonderland Online Non-Player Characters (NPCs).

- **Script Path:** `res://scripts/tools/npc_editor.gd`
- **Scene Path:** `res://scenes/tools/npc_editor.tscn`
- **Class Identifier:** `NpcEditor` (inherits `Control`)
- **Native Resolution:** 800x600 (scales dynamically with canvas items stretch mode)

---

## Architecture & Subsystems

```
NpcEditor (Control, 800x600)
├── Background (Panel with Navy/Slate StyleBoxFlat)
└── MainVBox (VBoxContainer)
    ├── TopBar (PanelContainer)
    │   └── TopHBox: Title, PresetOption, BtnSavePreset, BtnLoadPresets, BtnNewNpc
    ├── BodyHBox (HBoxContainer)
    │   ├── LeftColumn (VBoxContainer, width 340px)
    │   │   ├── AppearancePanel (PanelContainer)
    │   │   │   ├── JmpHBox: ModelJmpOption, ModelJmpEdit
    │   │   │   ├── JmaHBox: ModelJmaEdit
    │   │   │   ├── PreviewSplitHBox
    │   │   │   │   ├── SpriteContainer: SpritePreviewRect (128x128), CrosshairOverlay (160x150)
    │   │   │   │   └── PortraitContainer: PortraitPreviewRect (72x72), TalkImageSpin, TalkImageOption
    │   │   │   ├── AnimControlsHBox: BtnTurnLeft, HeadingOption (0..7), BtnTurnRight, BtnPlayPause
    │   │   │   ├── AnimOptionsHBox: CheckCrosshair, AnimSpeedSpin
    │   │   │   └── FrameInfoLabel ("Frame: X / Y | Heading: SOUTH")
    │   │   └── WaypointsPanel (PanelContainer, height 160px)
    │   │       ├── WaypointsList (ItemList)
    │   │       ├── WaypointInputsHBox: WaypointXSpin, WaypointYSpin, WaypointDelaySpin
    │   │       └── WaypointButtonsHBox: BtnAddWaypoint, BtnAddSpawnPos, BtnRemoveWaypoint, BtnClearWaypoints
    │   └── RightColumn (VBoxContainer)
    │       └── TabContainer
    │           ├── ParametersTab: NpcId, NpcName, MapId, SpawnPos (X, Y), MoveSpeed, TalkId, Npc.dat Lookup, Talk.dat Lookup
    │           ├── DialogueTab: DialogueTextEdit, ChoicesList, ChoiceInput, Choice Buttons
    │           └── ExportTab: ExportPathEdit, BtnExportScene, BtnTestEntity, BtnCopySnippet, CodePreviewEdit
    └── BottomBar (PanelContainer)
        └── BottomHBox: StatusPrefix, StatusLabel
```

---

## Core Capabilities

### 1. Visual Appearance Browser & Live Sprite Preview
- **Archive & Model Selection:** Quick selection via `COMMON_JMPS` dropdown with automatic archive pairing (e.g. `1038.jmp` in `001.jma`, `8025.jmp` in `008.jma`) or manual entry.
- **Bust / Portrait Preview:** Live 72x72 or scaled bust preview retrieved from `ArchiveLoader.get_npc_portrait(talk_image_id)` (with authentic XOR decryption from `008.jma`).
- **Ground Centering Crosshair Indicator:** 
  - Custom canvas drawing on `CrosshairOverlay` using 2:1 axonometric projection lines:
    - Isometric diamond base ($W=40$, $H=20$) marking ground contact tile.
    - Horizontal ground plane line.
    - Vertical alignment axis.
    - Center ground anchor dot at foot level ($Y = \text{center\_y} + 58.0$).
- **8-Directional Kinematic Rotation:**
  - Turn Left / Turn Right buttons advancing or reversing counter-clockwise headings (0..7) matching `IsometricMath.Heading`:
    - `0`: North (Back)
    - `1`: North-West
    - `2`: West
    - `3`: South-West
    - `4`: South (Front)
    - `5`: South-East
    - `6`: East
    - `7`: North-East
- **Animated Idle Loop:**
  - Timer-based frame calculation matching `NpcEntity._compute_frame_index` across 64-frame, 32-frame, 16-frame, 8-frame, and 4-frame JMP animations.
  - Interactive play/pause and playback speed scaling (0.2x to 5.0x).

### 2. Dialogue & Authentic Database Lookups
- **Npc.dat Integration:**
  - Direct lookup via `GameDatabase.npcs.get_npc(npc_id)` resolves authentic NPC names, sprite IDs, model files, and portrait IDs.
- **Talk.dat Integration:**
  - Direct lookup via `GameDatabase.talks.get_talk(talk_id)` decodes plain dialogue text and extracts branching choice strings automatically into `_dialogue_choices`.
- **Branching Dialogue Choice Management:**
  - Create, reorder, delete, and clear interactive branching options for `dialogue_choices: Array[String]`.

### 3. Patrol Waypoint Configuration (Walksteps)
- **Waypoints List:** Configures autonomous patrol sequences (`walksteps: Array[Vector2]` and `walkstep_delays: Array[float]`).
- Quick button to capture current `spawn_pos` as patrol origin.
- Add, update, delete, and clear waypoint waypoints with per-step wait delays (seconds).

### 4. Presets Library
- **Built-in Authentic Presets:**
  - `Captain Robinson`: NPC 14003, JMP 1038.jmp, TID 8025, Map 10001 (Ship Deck)
  - `Kelan Leader`: NPC 14062, JMP 1131.jmp, TID 8038, Map 10011 (North Island Beach)
  - `Sailor Jack`: NPC 14091, JMP 1010.jmp, TID 8004, Map 10001 (Ship Deck)
  - `Chef`: NPC 12006, JMP 1144.jmp, TID 8021, Map 10001 (Ship Deck)
  - `Natasha`: NPC 14303, JMP 1068.jmp, TID 8083, Map 10011 (North Island Beach)
  - `Traveling Merchant`: NPC 14941, JMP 1050.jmp, TID 8017, Map 10011 (North Island Beach)
  - `Ross`: NPC 14152, JMP 1207.jmp, TID 8005, Map 10001 (Ship Deck)
- **Custom Presets:**
  - Stored persistently in `user://custom_npcs.json`.
  - Save and load functions preserve all attributes, waypoints, and dialogue choices.

---

## API Reference

### Signals
- `preset_loaded(preset_name: String)`: Emitted after a preset is applied.
- `npc_exported(file_path: String)`: Emitted when a scene file is written to disk.
- `npc_created(entity: NpcEntity)`: Emitted when an entity instance is created.
- `preview_updated()`: Emitted whenever the sprite preview frame or heading updates.

### Methods

#### `export_npc_scene(file_path: String = "") -> String`
Generates a standalone Godot 4 `.tscn` scene extending `NpcEntity` pre-configured with all properties, collision shape, sprite offset, and nameplate.
- **Parameters:**
  - `file_path`: Target file path (e.g. `res://scenes/world/npc_captain_robinson.tscn`). If empty, auto-generates from sanitized NPC name.
- **Returns:** Written file path string on success, or empty string on failure.

#### `create_npc_entity() -> NpcEntity`
Instantiates a complete, configured `NpcEntity` ready to be added to any map's `Entities` container via `add_child()`.
- **Returns:** Instantiated `NpcEntity`.

#### `copy_gdscript_snippet() -> String`
Generates a copy-paste ready GDScript code snippet that instantiates, configures, and adds the NPC to the active scene, and sets the system clipboard.
- **Returns:** Generated snippet string.

#### `save_custom_preset(preset_name: String = "") -> bool`
Saves the current configuration to `user://custom_npcs.json`.
- **Returns:** `true` if saved successfully.

#### `load_custom_presets() -> Dictionary`
Loads all custom presets from `user://custom_npcs.json`.
- **Returns:** Dictionary mapping preset names to configuration dictionaries.

#### `lookup_npc_database(id: int) -> void`
Populates name, model JMP, archive, and talk portrait TID from `Npc.dat`.

#### `lookup_talk_database(tid: int) -> void`
Populates dialogue text and branching choices from `Talk.dat`.

---

## Verification & Test Suite
Automated regression tests are located at `res://scripts/tests/test_npc_editor.gd`.
Tests verify:
1. Scene loading and instantiation of `npc_editor.tscn`.
2. Loading all 5 required built-in presets without error.
3. 8-directional kinematic rotations.
4. Frame calculation parity for 32-frame and 140-frame animations.
5. Dialogue branching choice addition and deletion.
6. Patrol waypoint addition, delays, and coordinate serialization.
7. Custom preset serialization to `user://custom_npcs.json`.
8. `create_npc_entity()` returning valid `NpcEntity` with matching attributes.
9. `export_npc_scene()` producing a valid `.tscn` that loads cleanly in `ResourceLoader`.
10. `copy_gdscript_snippet()` producing syntax-valid GDScript.
11. Ground crosshair overlay canvas draw without rendering errors.
