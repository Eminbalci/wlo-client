# NPC Direction Sprite Indexing & Animation Specification

## Overview
This document specifies the authentic directional animation indexing, frame layout taxonomy, heading-to-frame mapping formulas, and cross-subsystem parity for Wonderland Online NPC and monster standees in Godot 4.

It documents the diagnosis and resolution of the heading frame aliasing and inversion defect where South-West (Heading 3) and South (Heading 4) evaluated to backward-facing or identical sprite frames.

---

## 1. Root Cause Diagnosis of Direction Indexing Defect

### 1.1 Reported Symptoms
- In `NpcEditor` (`scripts/tools/npc_editor.gd`), selecting **South-West** (`3`) or **South** (`4`) on 32-frame models (such as Captain Robinson `1038.jmp` or Deck Crew `1037.jmp`) rendered backward-facing or identical frames.
- In `ArchiveLoader.extract_heading_frame`, South-West (`3`) and South (`4`) were grouped in the same match branch (`3, 4: diag_idx = 2`), forcing both headings to return the exact same frame (Frame 24).
- In `scripts/world/npc.gd` and `scripts/tools/npc_editor.gd`, the 32-frame match block was mapped inverted:
  ```gdscript
  # BUGGY LEGACY MAPPING:
  match heading % 8:
      IsometricMath.Heading.SOUTH_WEST, IsometricMath.Heading.WEST:
          diag_idx = 0 # base = 16 + 0*4 = 16 (09-1: North-West / Back-Left!)
      IsometricMath.Heading.NORTH_WEST, IsometricMath.Heading.NORTH:
          diag_idx = 1 # base = 16 + 1*4 = 20 (11-1: South-West / Front-Left!)
      IsometricMath.Heading.NORTH_EAST, IsometricMath.Heading.EAST:
          diag_idx = 2 # base = 16 + 2*4 = 24 (13-1: South-East / Front-Right!)
      IsometricMath.Heading.SOUTH_EAST, IsometricMath.Heading.SOUTH:
          diag_idx = 3 # base = 16 + 3*4 = 28 (15-1: North-East / Back-Right!)
  ```
- Because of this inversion:
  - Selecting **South-West** (`3`) rendered Frame 16 (`09-1.bmp`), which is **North-West** (facing backward away from camera).
  - Selecting **South** (`4`) rendered Frame 28 (`15-1.bmp`), which is **North-East** (facing backward away from camera).
  - South and South-East were mapped to identical frames (Frame 28).
  - South-West and West were mapped to identical frames (Frame 16).

---

## 2. JMP Sprite Frame Taxonomy & Binary Layouts

Reverse engineering of the binary `.jmp` sprite files across `001.jma` and `007.jma` reveals 5 primary frame count categories and 2 internal subtypes.

### 2.1 32-Frame Layouts

#### Subtype A: 4-Diagonal Walk + 4-Diagonal Stand (Standard NPC Model)
- **Primary Models**: `1038.jmp` (Captain Robinson), `1037.jmp` (Deck Crew), `1060.jmp`, `1092.jmp`, `1095.jmp`, `1243.jmp`, `1286.jmp`, `1384.jmp`, `1418.jmp`, `1717.jmp`, `1736.jmp`.
- **Walk Cycle (Frames 0..15)**:
  - Frames `00..03` (`01-1.bmp` .. `01-4.bmp`): North-West Walk (Block 0)
  - Frames `04..07` (`03-1.bmp` .. `03-4.bmp`): South-West Walk (Block 1)
  - Frames `08..11` (`05-1.bmp` .. `05-4.bmp`): South-East Walk (Block 2)
  - Frames `12..15` (`07-1.bmp` .. `07-4.bmp`): North-East Walk (Block 3)
- **Stand Idle Cycle (Frames 16..31)**:
  - Frames `16..19` (`09-1.bmp` .. `09-4.bmp`): North-West Stand (Block 0, Back-Left)
  - Frames `20..23` (`11-1.bmp` .. `11-4.bmp`): South-West Stand (Block 1, Front-Left)
  - Frames `24..27` (`13-1.bmp` .. `13-4.bmp`): South-East Stand (Block 2, Front-Right)
  - Frames `28..31` (`15-1.bmp` .. `15-4.bmp`): North-East Stand (Block 3, Back-Right)

#### Subtype B: 8-Directional Stationary Stand
- **Model Example**: `1274.jmp` (detected by frame 0 name starting with `08-`).
- **Structure**: 8 directions $\times$ 4 idle frames (`08-1..4` through `15-1..4`).
- **Formula**: `frame_idx = ((heading % 8) * 4 + sub_idx) % total_frames`.

### 2.2 16-Frame Layouts (4 Diagonals $\times$ 4 Stand Frames)
- **Primary Models**: `1170.jmp` (Breillat), `1091.jmp`.
- **Frames**:
  - `00..03` (`09-1..4.bmp`): North-West Stand (Block 0)
  - `04..07` (`11-1..4.bmp`): South-West Stand (Block 1)
  - `08..11` (`13-1..4.bmp`): South-East Stand (Block 2)
  - `12..15` (`15-1..4.bmp`): North-East Stand (Block 3)

### 2.3 8-Frame Layouts
- **Subtype 8A: 8 Single-Frame Standees** (`1207.jmp` Ross, `1088.jmp`/`1089.jmp` Arcade Machines, `1150..1152.jmp`).
  - Frames `0..7` directly map to Heading `0..7` (`08-1` through `15-1`).
- **Subtype 8B: 4 Walk + 4 Stand** (`1430.jmp`).
  - Frames `0..3` (`01`, `03`, `05`, `07`): Walk.
  - Frames `4..7` (`09`, `11`, `13`, `15`): Stand.

### 2.4 4-Frame Layouts (4 Single-Frame Diagonals)
- **Primary Models**: `1050.jmp` (Drunk Man, Peter, John), `1301.jmp`, `1352.jmp`, `1423.jmp`.
- **Frames**:
  - `0` (`09-1.bmp`): North-West (Block 0)
  - `1` (`11-1.bmp`): South-West (Block 1)
  - `2` (`13-1.bmp`): South-East (Block 2)
  - `3` (`15-1.bmp`): North-East (Block 3)

### 2.5 Standard Humanoids ($\ge 64$ Frames)
- **Primary Models**: `1010.jmp` (Sailor Jack, 140 frames), `1009.jmp` (Girl, 140 frames), `1068.jmp` (Natasha, 140 frames), Role Composites (`2000.jmp` Daniel, `3000.jmp` Betty, 216 frames).
- **Structure**:
  - Frames `00..31`: 8-way Walk (`00`..`07` $\times$ 4 frames).
  - Frames `32..63`: 8-way Stand (`08`..`15` $\times$ 4 frames).

---

## 3. Authoritative Heading-to-Diagonal Resolution Formula

In axonometric isometric projection, 8 cardinal and intercardinal headings map to the 4 diagonal sprite blocks:

| `IsometricMath.Heading` | Direction Name | Screen Facing | Diagonal Block | Stand Frame (32-Frame) | Walk Frame (32-Frame) |
| :---: | :---: | :---: | :---: | :---: | :---: |
| `0` (`NORTH`) | North | Back / Up | Block 0 | `16..19` (`09`) | `00..03` (`01`) |
| `1` (`NORTH_WEST`) | North-West | Back-Left | Block 0 | `16..19` (`09`) | `00..03` (`01`) |
| `2` (`WEST`) | West | Left | Block 1 | `20..23` (`11`) | `04..07` (`03`) |
| `3` (`SOUTH_WEST`) | South-West | Front-Left | Block 1 | `20..23` (`11`) | `04..07` (`03`) |
| `4` (`SOUTH`) | South | Front / Camera | Block 2 | `24..27` (`13`) | `08..11` (`05`) |
| `5` (`SOUTH_EAST`) | South-East | Front-Right | Block 2 | `24..27` (`13`) | `08..11` (`05`) |
| `6` (`EAST`) | East | Right | Block 3 | `28..31` (`15`) | `12..15` (`07`) |
| `7` (`NORTH_EAST`) | North-East | Back-Right | Block 3 | `28..31` (`15`) | `12..15` (`07`) |

### Key Guarantees:
1. **South-West (`3`) vs South (`4`) Distinction**:
   - `SOUTH_WEST` (`3`) resolves to `diag_idx = 1` $\rightarrow$ Frame 20 (`11-1.bmp`, Front-Left).
   - `SOUTH` (`4`) resolves to `diag_idx = 2` $\rightarrow$ Frame 24 (`13-1.bmp`, Front-Right).
   - South-West and South **never** share the same frame.
2. **Elimination of Backward Facing**:
   - South-West (`3`) no longer renders Frame 16 (`09-1.bmp`, Back-Left).
   - South (`4`) no longer renders Frame 28 (`15-1.bmp`, Back-Right).
3. **8-Way Stand Detection**:
   - For models like `1274.jmp`, frame 0 detection (`frames[0].name.begins_with("08")`) activates 8-way direct calculation `((heading % 8) * 4 + sub_idx)`, giving all 8 directions unique frames.

---

## 4. Modified Source Files

1. [`scripts/tools/npc_editor.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/tools/npc_editor.gd):
   - Corrected `_compute_preview_frame(total_frames, heading_val)` to use authentic diagonal ordering and 8-way stand subtype branching.
2. [`scripts/world/npc.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/world/npc.gd):
   - Updated `_compute_frame_index(total_frames)` with matching diagonal order and 8-way stand detection.
3. [`scripts/core/archive_loader.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/core/archive_loader.gd):
   - Aligned `extract_heading_frame` lambda in `get_npc_texture` across 32, 16, 8, and 4 frame models.
4. [`scripts/map/map_view.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/map/map_view.gd):
   - Fixed line 344 to pass `npc.heading` (0..7) instead of raw `spawn.rotation` (1..8) to `loader.get_npc_texture(sprite_id, npc.heading)`.
5. [`tests/test_npc_positioning_and_facing.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/tests/test_npc_positioning_and_facing.gd):
   - Updated test assertions in Part 4 to assert authentic stand frames 20..23 for SW and 24..27 for SE.
6. [`tests/test_npc_direction_sprite_indexing.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/tests/test_npc_direction_sprite_indexing.gd):
   - Comprehensive test suite covering all 7 layout variants and verifying 100% parity across `NpcEntity`, `NpcEditor`, and `ArchiveLoader`.

---

## 5. Verification & Test Execution

Run the automated test suites via `godot_console.exe`:

```powershell
# Dedicated NPC Direction Sprite Indexing Suite:
godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client -s res://tests/test_npc_direction_sprite_indexing.gd

# NPC Positioning and Facing Parity Suite:
godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client -s res://tests/test_npc_positioning_and_facing.gd

# Complete NPC Editor Tool Verification Suite:
godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client -s res://scripts/tests/test_npc_editor.gd
```
Result: 100% zero-error pass rate across all suites.
