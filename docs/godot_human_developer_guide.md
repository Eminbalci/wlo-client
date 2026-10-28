# Wonderland Online Client - Human Developer Guide & Architecture

## Overview

This document provides a clean, comprehensive architecture reference for human developers maintaining, modifying, or extending the Godot 4.6.2 client for Wonderland Online.

---

## 1. Directory Structure

```
wonderland-online-client/
├── assets/                  # Raw game assets (JMA, WAV, BMP, PNG, fonts)
├── docs/                    # Technical architecture specifications & test reports
├── scenes/
│   ├── ui/                  # UI Scenes (Auth flow, Dialogue, HUD)
│   ├── world/               # World Scenes (MapView, MapRenderer, Entities)
│   └── tests/               # In-Engine test runners (HUD, Auth, Portals, Avatars)
├── scripts/
│   ├── autoload/            # Singletons (ArchiveLoader, GameDatabase, CursorManager)
│   ├── map/                 # Map parsers, renderers, isometric math & pathfinder
│   ├── network/             # TCP socket client, packet framing & encryption
│   ├── ui/
│   │   ├── auth/            # ServerSelect, LoginDialog, CharacterSelect, CharacterCreate
│   │   ├── hud/             # 9 Dedicated Modular Sub-controllers
│   │   └── hud.gd           # Facade coordinator script (backward-compatible API)
│   ├── world/               # PlayerEntity, NpcEntity, Portals, Cutscenes
│   └── tools/               # Developer test runners and asset auditing utilities
└── tests/                   # Standalone headless GDScript test suites
```

---

## 2. Modular HUD Architecture (`scripts/ui/hud/`)

The HUD has been refactored from a monolithic script into 9 focused, single-responsibility sub-controllers:

| Sub-controller | Class Name | File Path | Primary Responsibilities |
|---|---|---|---|
| **Player Status** | `HUDPlayerStatus` | `scripts/ui/hud/hud_player_status.gd` | 14-role avatar extraction from `008.jma`, 2-frame blinking state machine, 3-layer chroma mask HP/SP/EXP bars, element badge and name/level labels. |
| **Minimap** | `HUDMinimap` | `scripts/ui/hud/hud_minimap.gd` | Radar minimap background extraction from `map.JMG`, coordinate display, blinking player marker dot, zoom in/out, collapse toggle, click-to-move pathfinding waypoint. |
| **Action Dock** | `HUDActionDock` | `scripts/ui/hud/hud_action_dock.gd` | 6 circular bottom dock buttons (Status, Skill, Quest, Team, Friends, System), Location readout label. |
| **Hotbar** | `HUDHotbar` | `scripts/ui/hud/hud_hotbar.gd` | F1..F8 action quickslots, icon binding, hotkey triggers. |
| **Window Manager** | `HUDWindowManager` | `scripts/ui/hud/hud_window_manager.gd` | Title bar dragging with viewport boundary clamping, close buttons, window toggles (C, I, S, T, Q, F, Esc). |
| **Inventory** | `HUDInventory` | `scripts/ui/hud/hud_inventory.gd` | 45-slot grid (5x9), starter items, drag-and-drop slot swapping, quick use/equip via right-click/double-click, gold display, tooltips. |
| **Character Status** | `HUDCharacterStatus` | `scripts/ui/hud/hud_character_status.gd` | 6 equipment sockets (Head, Body, Wrist, Shoes, Weapon, Special), paper doll 64-frame composite preview, drag-and-drop equip/unequip, combat stat calculation. |
| **Chat System** | `HUDChat` | `scripts/ui/hud/hud_chat.gd` | Channel tabs (All, Current, Team, Guild, Whisper, System), LineEdit input, send button, resizer handle, 31-emote animated popup grid, whisper syntax. |
| **Dialogue** | `HUDDialogue` | `scripts/ui/hud/hud_dialogue.gd` | Dual-form dialogue (FormTalk1 speaker dialogue, FormTalk3 branching choices), typewriter text, portrait blinking, quest reward fanfare banner, SFX playback. |

### Facade Pattern (`scripts/ui/hud.gd`)
`scripts/ui/hud.gd` acts as a facade. It instantiates all 9 sub-controllers in `_ready()`, wires node references, forwards input events (`_input`, `_unhandled_input`), and exposes public methods and compatibility properties delegating directly to the appropriate sub-controller.

---

## 3. World & Movement Kinematics

- **Coordinate System**: Isometric grid tiles (`20x20` pixels per cell).
- **Collision Checking**: Tile flags evaluated via `MapData.check_traversal(flag, current_vehicle)`.
- **Vehicle Gates**:
  - `NONE` (Foot): Disallowed on Water, Deep Ocean, Mountain.
  - `RAFT`: Traverses Water; blocked on Deep Ocean and Mountain.
  - `BOAT` / `SHIP`: Traverses Water and Deep Ocean; blocked on Mountain and Land.
  - `PLANE`: Traverses all terrain including Mountains.
- **Pathfinding**: Integrated A* algorithm (`scripts/map/pathfinder.gd`) with diagonal corner-cutting prevention and line-of-sight raycasts for string-pulling open corridors.

---

## 4. Verification & Testing Commands

All test suites can be executed via Godot headless console:

```powershell
# 1. Verify all 199 client buttons across 6 scenes:
& "C:\Godot\godot_console.exe" --headless --path "D:\Godot\WonderlandOnline\wonderland-online-client" --script tests/test_all_client_buttons.gd

# 2. Verify HUD Sub-controllers:
& "C:\Godot\godot_console.exe" --headless --path "D:\Godot\WonderlandOnline\wonderland-online-client" scenes/tests/test_hud_subcontrollers.tscn

# 3. Verify HUD Runner & Live MapView Integration:
& "C:\Godot\godot_console.exe" --headless --path "D:\Godot\WonderlandOnline\wonderland-online-client" scenes/tests/test_hud_runner.tscn

# 4. Verify Collision Matrix & Vehicle Traversal Gates:
& "C:\Godot\godot_console.exe" --headless --path "D:\Godot\WonderlandOnline\wonderland-online-client" -s res://tests/test_collision_and_vehicles.gd

# 5. Verify A* Pathfinder & Navigation Detours:
& "C:\Godot\godot_console.exe" --headless --path "D:\Godot\WonderlandOnline\wonderland-online-client" -s res://tests/test_pathfinder_navigation.gd

# 6. Verify Auth & Character Creation Flow (113 tests):
& "C:\Godot\godot_console.exe" --headless --path "D:\Godot\WonderlandOnline\wonderland-online-client" scenes/tests/test_auth_flow.tscn

# 7. Audit All Scripts (133 files):
& "C:\Godot\godot_console.exe" --headless --path "D:\Godot\WonderlandOnline\wonderland-online-client" -s res://scripts/tools/audit_all_scripts.gd
```
