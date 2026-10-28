# Project Assets & Data Ingestion Specification

## 1. Asset Storage & Integration Structure
All game binary packages, databases, image directories, sound archives, and configuration files have been ingested directly into the Godot project tree under `res://assets/` to eliminate external filesystem dependencies on `D:/GitHub/WLRI`.

### Ingested Directory Layout
- `res://assets/.gdignore`: Direct instruction file preventing Godot Engine from running destructive or slow automated asset re-imports on raw binary archives and legacy BMP files.
- `res://assets/data/`: Game databases (`Item.dat`, `Npc.dat`, `SceneData.dat`, `Skill.dat`, `Ground.MMG`, `Wem.MMG`, `Eve.emg`, `Player.emg`).
- `res://assets/jma/`: All 219 sprite animation archives (`001.jma` through `009.jma` and subpackages).
- `res://assets/pic/`: DirectDraw map surfaces and item packages (`map.JMG`, `item.BMg`, `jRole.JMg`).
- `res://assets/sound/`: Authentic background audio WAV files and sound effects (`BGM*.wav`, `SE*.wav`).
- `res://assets/menu/`: Delphi VCL UI skin bitmaps and button state slices (`menu/Skins/white/`, `menu/Skins/default/`).
- `res://assets/cursor/`: Original animated cursor containers (`cursor1.ani`).
- `res://assets/user/`: Disk collision grids (`user/Map/*.MapData`).
- `res://assets/font/`, `res://assets/sty/`, `res://assets/voice/`: Auxiliary game font, style, and voice archives.
- `res://assets/SERVER.INI`: Server routing and network endpoints configuration.

---

## 2. Dynamic Runtime Resolution & Fallback Architecture
All core singletons and loaders resolve `res://assets/` paths natively while maintaining automatic backwards compatibility:
- `ArchiveLoader` (`scripts/core/archive_loader.gd`): In-memory texture streaming, JMA/JMP animation parsing, cursor extraction from `res://assets/`.
- `GameDatabase` (`scripts/database/game_database.gd`): Pure binary loaders for items, scenes, skills, and NPCs with clean Big5/ASCII reversed-string decoding.
- `GroundParser` (`scripts/map/ground_parser.gd`): Binary MMG chunk decompression and tile lookup from `res://assets/data/Ground.MMG` and `res://assets/data/Wem.MMG`.
- `MapRenderer` (`scripts/map/map_renderer.gd`): Dynamic map tile rendering and collision loading from `res://assets/user/Map/%d.MapData`.
- `ServerConfig` (`scripts/network/server_config.gd`): Connection endpoint parsing from `res://assets/SERVER.INI`.

---

## 3. Kinematics & 8-Directional Turning Resolver
### Angle & Coordinate Transformation
Calculates screen displacement vector $\Delta S = \text{world\_to\_screen}(P_{\text{target}}) - \text{world\_to\_screen}(P_{\text{current}})$.
- Angle in degrees $\theta = \text{rad\_to\_deg}(\Delta S.\text{angle}())$.
- $0^\circ \rightarrow$ East (Heading 6)
- $45^\circ \rightarrow$ South-East (Heading 5)
- $90^\circ \rightarrow$ South (Heading 4, Facing camera)
- $135^\circ \rightarrow$ South-West (Heading 3)
- $180^\circ \rightarrow$ West (Heading 2)
- $225^\circ \rightarrow$ North-West (Heading 1)
- $270^\circ \rightarrow$ North (Heading 0, Away from camera)
- $315^\circ \rightarrow$ North-East (Heading 7)

### Animation Frame Indexing
In `002.jma -> 2000.jmp` (Daniel, Role 2), all 8 directions are natively modeled across 32 frames without requiring horizontal sprite flips:
- Walking Frame Index: $\text{current\_heading} \times 4 + \text{frame\_sub\_idx}$
- Idle Frame Index: $\text{current\_heading} \times 4$
- `sprite.flip_h = false` across all headings.

---

## 4. Map 10001 (Cruise Ship Deck) NPC Spawning
All 11 NPCs defined in `Eve.emg` record 10001 are spawned at authentic coordinates:
1. `Bow Sailor`: Model `1006.jmp`, World $(1361.5, 1244.5)$
2. `Lookout Sailor`: Model `1005.jmp`, World $(1363.0, 1261.0)$
3. `Midship Sailor`: Model `1008.jmp`, World $(1111.5, 768.5)$
4. `Stern Passenger`: Model `1009.jmp`, World $(1045.5, -415.5)$
5. `First Mate`: Model `1002.jmp`, World $(1729.5, 874.5)$
6. `Captain Robinson`: Model `1004.jmp`, World $(1720.0, 906.0)$
7. `Deckhand`: Model `1003.jmp`, World $(1408.5, 395.5)$
8. `Crew Member`: Model `1004.jmp`, World $(1470.5, 443.5)$
9. `Tourist`: Model `1010.jmp`, World $(1274.5, -118.5)$
10. `Merchant Passenger`: Model `1011.jmp`, World $(1342.5, -78.5)$
11. `Cabin Attendant`: Model `1012.jmp`, World $(1127.5, 722.5)$

---

## 5. Authentic Delphi VCL HUD Alignments
- `PlayerStatusDock`:
  - Name & Level: $X=95..228, Y=16..32$
  - EXP Bar: $X=95..225, Y=63..68$ (5px line), EXP Label: $X=95..225, Y=50..62$
  - HP Bar: $X=95..225, Y=87..92$ (5px line), HP Label: $X=95..225, Y=74..86$
  - SP Bar: $X=95..225, Y=110..115$ (5px line), SP Label: $X=95..225, Y=97..109$
- `ChatDock`:
  - `ChatHistoryPanel`: `StyleBoxEmpty` (eliminates opaque background box, preserving pure transparent MMO style text with shadow).
- `BottomActionDock`:
  - Re-anchored to Top-Right below minimap: $X=-280..0, Y=145..180$ (`anchors_preset = 1`).
