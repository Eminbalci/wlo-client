# Wonderland Online - Battle Formation & Random Encounter Studio Tool Specification

## 1. Overview
The **Battle Formation & Random Encounter Studio** (`BattleEditor`) is an authentic, production-grade visual developer and authoring tool integrated into the Wonderland Online Godot 4 client. It enables rapid layout, visual configuration, encounter probability tuning, turn-order simulation, and scene export for turn-based combat encounters in Wonderland Online.

- **Script Path:** `res://scripts/tools/battle_editor.gd`
- **Scene Path:** `res://scenes/tools/battle_editor.tscn`
- **Test Runner Scene:** `res://scenes/tests/test_battle_editor.tscn`
- **Test Suite Script:** `res://tests/test_battle_editor.gd`
- **Base Class:** `Control`
- **Minimum Resolution:** 800x600 (dark-themed slate/navy UI)

---

## 2. Architecture & Scene Hierarchy

```
BattleEditor (Control, min 800x600)
├── Background (Panel with Navy/Slate StyleBoxFlat)
└── MainVBox (VBoxContainer)
    ├── TopBar (PanelContainer)
    │   └── TopHBox: Title, MapSelector, MapIdSpin, MapNameEdit, EncRateSpin, EncRateSlider, PresetOption, BtnApplyPreset, BtnClearArena, BtnNewTable, BtnLoadTable, BtnSaveTable, BtnExportScene
    ├── ContentHBox (HBoxContainer)
    │   ├── LeftArea (VBoxContainer, stretch_ratio=1.6)
    │   │   ├── CanvasHeader (PanelContainer): "2:1 Axonometric Battle Arena"
    │   │   ├── CanvasPanel (PanelContainer, StyleBoxFlat_canvas)
    │   │   │   └── BattleCanvas (Control, min 580x380, mouse_filter=STOP)
    │   │   └── CanvasFooter (PanelContainer): Controls & Element color legend
    │   └── RightPanel (VBoxContainer, min_width 340)
    │       └── InspectorTabs (TabContainer)
    │           ├── Tab 0: "Slot Inspector" (IsEnemy toggle, Slot#, ID, Name, Level, SPD, HP, SP, Element, JMP, Boss toggle, Save/Clear buttons)
    │           ├── Tab 1: "Turn Order" (Action queue sorted descending by SPD with tie-break markers)
    │           ├── Tab 2: "Encounter Groups" (Troop list, Weights, Add Troop, Remove, Step Roll Simulator & Readout)
    │           └── Tab 3: "Loot Drops" (Item ID, Name, Rate %, Min/Max Qty, Add, Remove, Drop Roll Simulator & Readout)
    └── StatusBar (PanelContainer)
        └── StatusHBox: StatusReadout, MapReadout, ParticipantReadout
```

---

## 3. 2:1 Axonometric Battle Field Grid

### 3.1 Diamond Geometry & Projection
The battle arena utilizes an authentic 2:1 axonometric isometric projection matching the classic Wonderland Online battle field layout:
- **Diamond Half-Width ($hw$):** `24.0 px` (Full width = `48.0 px`)
- **Diamond Half-Height ($hh$):** `12.0 px` (Full height = `24.0 px`)
- **Aspect Ratio:** $48.0 / 24.0 = 2.0$ (Strict 2:1 ratio)
- **Diamond Vertices:**
  - Top: $(cx, cy - hh)$
  - Right: $(cx + hw, cy)$
  - Bottom: $(cx, cy + hh)$
  - Left: $(cx - hw, cy)$

### 3.2 Slot Grid Layout (8 Player Slots vs 8 Enemy Slots)
Both sides possess 8 formation slots partitioned into 4 Front-row slots (`0..3`) and 4 Back-row slots (`4..7`):
- **Player Party (Facing North-East):**
  - Front Row (`0..3`): Starts at $(110, 210)$, stepping along vector $(+44, +22)$ per column.
  - Back Row (`4..7`): Starts at $(66, 240)$ (offset behind Front row), stepping along vector $(+44, +22)$.
- **Enemy Troop (Facing South-West):**
  - Front Row (`0..3`): Starts at $(350, 170)$, stepping along vector $(+44, +22)$ per column.
  - Back Row (`4..7`): Starts at $(394, 140)$ (offset behind Front row), stepping along vector $(+44, +22)$.
- **Neutral Divider Line:** A subtle visual boundary separating player and enemy zones from $(275, 110)$ to $(345, 310)$.

### 3.3 Mouse Point-in-Polygon Collision
The editor supports interactive clicking and hovering on both player and enemy grid slots. Given a screen coordinate $P = (px, py)$ and diamond center $(cx, cy)$:
$$\frac{|px - cx|}{hw} + \frac{|py - cy|}{hh} \le 1.05$$
Points satisfying the inequality are resolved to their corresponding `(is_enemy: bool, slot: int)` index.

---

## 4. Monster & Troop Formator

### 4.1 Participant Data Model
Every occupied slot stores a normalized dictionary with the following schema:

| Field | Type | Description | Default |
|---|---|---|---|
| `monster_id` | `int` | Unique monster/actor numerical identifier | `1` |
| `monster_name`| `String` | Display name of the participant | `"Monster"` |
| `level` | `int` | Combat level ($1 \le \text{level} \le 200$) | `1` |
| `hp` | `int` | Current HP value | `100` |
| `max_hp` | `int` | Maximum HP cap ($\ge \text{hp}$) | `100` |
| `sp` | `int` | Current SP value | `50` |
| `max_sp` | `int` | Maximum SP cap ($\ge \text{sp}$) | `50` |
| `element` | `int` | Elemental affinity (`0`=None, `1`=Earth, `2`=Water, `3`=Fire, `4`=Wind) | `0` |
| `jmp_name` | `String` | Sprite animation file path in JMA archives | `"monster.jmp"` |
| `is_boss` | `bool` | Flag designating boss or leader status | `false` |
| `spd` | `int` | Speed/Agility attribute governing turn order | `10` |

### 4.2 Elemental Affinities & Color Badges
- `Element.NONE` (`0`): Grey `Color(0.7, 0.7, 0.7, 1.0)`
- `Element.EARTH` (`1`): Ochre Yellow `Color(0.85, 0.65, 0.25, 1.0)`
- `Element.WATER` (`2`): Cyan Blue `Color(0.25, 0.65, 0.95, 1.0)`
- `Element.FIRE` (`3`): Crimson Red `Color(0.95, 0.35, 0.25, 1.0)`
- `Element.WIND` (`4`): Emerald Green `Color(0.35, 0.95, 0.45, 1.0)`

### 4.3 Slot Placement API Methods
```gdscript
func set_enemy_slot(slot: int, monster_data: Dictionary) -> bool
func get_enemy_slot(slot: int) -> Dictionary
func set_player_slot(slot: int, player_data: Dictionary) -> bool
func get_player_slot(slot: int) -> Dictionary
func clear_slot(is_enemy: bool, slot: int) -> void
func clear_all_slots() -> void
```
- Parameters:
  - `slot`: Integer in range `[0..7]`. Out-of-bounds indices return `false` or empty dictionary `{}` with runtime warnings.
  - `monster_data` / `player_data`: Dictionary conforming to the participant schema. Values are automatically sanitized and clamped.
- Return Values:
  - `bool`: `true` upon successful assignment, `false` upon bounds violation.
  - `Dictionary`: Duplicate deep copy of slot attributes, or `{}` if unoccupied.

---

## 5. Authentic Party Formation Presets

The editor includes pre-configured authentic Wonderland Online early-game troop compositions:

### 1. "Kelan Slimes Troop"
- Front Row Slot 0: Blue Jelly (Level 1, Water, HP 45, SP 15, SPD 8, `slime_blue.jmp`)
- Front Row Slot 1: Blue Jelly (Level 1, Water, HP 45, SP 15, SPD 8, `slime_blue.jmp`)
- Back Row Slot 4: Green Jelly (Level 2, Earth, HP 70, SP 25, SPD 6, `slime_green.jmp`)

### 2. "Kelan Cave Bats"
- Front Row Slot 0: Cave Bat (Level 3, Wind, HP 95, SP 30, SPD 14, `cave_bat.jmp`)
- Front Row Slot 1: Cave Bat (Level 3, Wind, HP 95, SP 30, SPD 14, `cave_bat.jmp`)
- Front Row Slot 2: Cave Bat (Level 3, Wind, HP 95, SP 30, SPD 14, `cave_bat.jmp`)
- Back Row Slot 4: Leader Bat (Level 5, Fire, HP 190, SP 60, SPD 18, `is_boss: true`, `leader_bat.jmp`)

### 3. "Shipwreck Pirates"
- Front Row Slots 0..3: 4x Sailor Pirate (Level 8, Water, HP 240, SP 80, SPD 12, `pirate_sailor.jmp`)
- Back Row Slot 5: Pirate Captain (Level 12, Fire, HP 850, SP 250, SPD 22, `is_boss: true`, `pirate_captain.jmp`)

### Preset API:
```gdscript
func get_preset_names() -> Array[String]
func load_formation_preset(preset_name: String) -> bool
func save_formation_preset(preset_name: String) -> void
```

---

## 6. Battle Simulation & Turn Order Preview

### 6.1 SPD Sorting & Deterministic Tie-Breaking
The turn queue snapshots all active actors across both Player (`0..7`) and Enemy (`0..7`) grids:
1. **Primary Sort Key:** Actor `spd` value descending. Highest speed acts first.
2. **Tie-Breaker Rule:** When actor SPDs are equal, Player actors take deterministic precedence over Enemy actors (consistent with `Wlo.pserver.core` combat pipeline).
3. **Secondary Tie-Breaker:** Lower slot index takes precedence.

```gdscript
func calculate_turn_order() -> Array[Dictionary]
```
Returns an ordered `Array[Dictionary]` containing actor references, calculated row, team, and attributes.

---

## 7. Map Encounter Table Authoring

### 7.1 Encounter Trigger Logic & Weight Selection
- **Map Binding:** Binds encounter tables to specific Map IDs (e.g. Map `10003` Newbie Beach, Map `11016` Kelan Trail).
- **Step Encounter Rate:** Configurable encounter probability $P \in [0.0\%, 100.0\%]$ rolled upon player movement steps.
- **Troop Spawn Weights:** Each encounter group has an integer spawn weight $W_i$. Selection probability is:
$$P(\text{Group}_k) = \frac{W_k}{\sum_{i=1}^{N} W_i}$$

```gdscript
func add_encounter_group(group_data: Dictionary) -> int
func remove_encounter_group(index: int) -> bool
func get_encounter_groups() -> Array[Dictionary]
func clear_encounter_groups() -> void
func roll_random_encounter(step_roll: float = -1.0, group_roll: float = -1.0) -> Dictionary
```
- Parameters:
  - `step_roll`: Optional test override for the step roll ($[0.0, 100.0]$). If $< 0$, generates `randf() * 100.0`.
  - `group_roll`: Optional test override for the group selection roll. If $< 0$, generates `randf() * total_weight`.
- Return Value:
  - Dictionary containing `triggered` (`bool`), `group` (`Dictionary`), `step_roll` (`float`), and `total_weight` (`int`).

---

## 8. Loot Drop Table Editor

### 8.1 Drop Configuration & Rolling
Each drop entry specifies an item ID, name, drop percentage, and min/max quantity limits:

```gdscript
func add_loot_drop(item_id: int, item_name: String, drop_rate_pct: float, min_qty: int = 1, max_qty: int = 1) -> void
func remove_loot_drop(index: int) -> bool
func get_loot_drops() -> Array[Dictionary]
func clear_loot_drops() -> void
func roll_loot_drops(rng_seed: int = -1) -> Array[Dictionary]
```
- A drop item with `drop_rate_pct = 100.0` is guaranteed to drop.
- Items with `drop_rate_pct = 0.0` never drop.
- Yielded quantity is uniformly distributed within `[min_qty, max_qty]`.

---

## 9. Serialization & Godot 4 Scene Export

### 9.1 JSON Encounter Table
```gdscript
func create_encounter_data() -> Dictionary
func save_encounter_table(path: String) -> bool
func load_encounter_table(path: String) -> Dictionary
```
Exports all map bindings, slot states, troop weights, and loot drops as human-readable, formatted JSON.

### 9.2 Standalone Battle Scene Exporter (`.tscn`)
```gdscript
func export_battle_scene(path: String) -> String
```
Generates a complete, valid Godot 4 text scene file (`.tscn`) ready for live combat rendering. The exported scene includes:
- Root `Node2D` named `BattleArena` with map and encounter metadata.
- `ArenaBackground` `ColorRect` (800x600, dark arena).
- `ArenaDividerLine` `Line2D` marking the neutral combat boundary.
- `PlayerParty` `Node2D` holding 8 `Marker2D` nodes with slot coordinates and occupant attributes.
- `EnemyTroop` `Node2D` holding 8 `Marker2D` nodes with slot coordinates, boss markers, and monster metadata.
- `TurnManager` `Node` with active participant counts.

---

## 10. Verification & Test Execution

Run the automated test suite headlessly via Godot console:
```powershell
C:\Godot\godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client scenes/tests/test_battle_editor.tscn
```

### Verified Test Capabilities:
1. `_test_instantiation_and_structure`: Control size $\ge 800\times 600$, 21 public API methods verified.
2. `_test_axonometric_grid_formation`: Exact 2:1 aspect ratio ($48\times 24$ px), 4-vertex diamond polygons, front/back row offsets, and point-in-polygon mouse hit detection.
3. `_test_monster_and_player_placement`: Attribute storage, sanitization, slot clear, and out-of-bounds guards ($<0$ or $\ge 8$).
4. `_test_party_formation_presets`: Kelan Slimes, Kelan Cave Bats, Shipwreck Pirates, and custom preset saving/reloading.
5. `_test_turn_order_simulation`: Descending SPD sort ($32 \to 25 \to 18 \to 10 \to 5$) and player-first deterministic tie-breaking.
6. `_test_encounter_table_and_probability`: Deterministic step triggers, group weight selection, and 1,000-trial statistical verification.
7. `_test_loot_drop_table`: 100% guaranteed drops, 0% drop prevention, and quantity ranges.
8. `_test_serialization_and_roundtrip`: File I/O roundtrip preserving all slot formations, rates, and drop tables.
9. `_test_scene_export`: Complete `.tscn` file generation and instantiation via Godot `load()` and `instantiate()`.
