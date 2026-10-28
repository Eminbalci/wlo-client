# Wonderland Online - Item, Equipment & Alchemy Studio Specification

## 1. Overview
The **Item, Equipment & Alchemy Studio** (`scripts/tools/item_editor.gd`, `scenes/tools/item_editor.tscn`) is a specialized visual authoring environment for the Wonderland Online Godot 4 client. It enables game designers and developers to create, modify, inspect, synthesize, and export items, equipment stat modifiers, and authentic alchemy synthesis recipes matching the Delphi client and server mechanics.

The tool features:
- **Item Master Specifications:** Item identification, naming, descriptions, icon ID binding, level requirements, equipment ranks, durability thresholds, equipment slot classification, and commercial buy/sell pricing.
- **Live 32x32 Icon Preview:** In-engine icon extraction via `ArchiveLoader.get_item_icon(icon_id)` with robust procedural fallback for missing or offline archives.
- **Stat Modifiers Builder:** Configurable stat deltas (ATK, DEF, MATK, MDEF, SPD, HP Bonus, SP Bonus) and formatted stat readout (`get_formatted_stats() -> Array[Dictionary]`).
- **WLO Authentic Alchemy & Synthesis Engine:** Synthesis calculation implementing authentic Wonderland Online rank formulas, catalyst bonus tiers (Alchemy Books I-IV), variance thresholds, and success rate probabilities.
- **Classic Presets:** Out-of-the-box configurations for Bronze Sword, Iron Armor, Feather Boots, Healing Grass, and Mana Potion.
- **Dual JSON Persistence:** Complete item record export/import and alchemy recipe JSON export.
- **Live Parchment Tooltip Preview:** Soft ice-blue parchment rendering matching authentic in-game tooltips.

---

## 2. File and Class Architecture

### 2.1 File Locations
- **Editor Script:** [item_editor.gd](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/tools/item_editor.gd)
- **Editor Scene:** [item_editor.tscn](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scenes/tools/item_editor.tscn)
- **Test Suite (Node):** [test_item_editor.gd](file:///D:/Godot/WonderlandOnline/wonderland-online-client/tests/test_item_editor.gd)
- **Test Scene:** [test_item_editor.tscn](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scenes/tests/test_item_editor.tscn)
- **Test Runner (SceneTree):** [test_item_editor.gd](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/tests/test_item_editor.gd)

### 2.2 Class Inheritance
```text
Control
  └── ItemEditor (scripts/tools/item_editor.gd)
```

### 2.3 Equipment Slot Enumeration (`EquipSlot`)
| Value | Identifier | In-Game Slot Name | Description |
|---|---|---|---|
| 0 | `NONE` | None / Inventory | General items, quest objects, non-equipables |
| 1 | `HEADGEAR` | Headgear | Hats, circlets, helms, caps |
| 2 | `CLOTHES` | Clothes | Armor, robes, tunics, dresses |
| 3 | `WEAPON` | Weapon | Swords, staves, bows, daggers, spears |
| 4 | `WRIST_SHIELD` | Wrist / Shield | Shields, bracers, wristbands, gauntlets |
| 5 | `SHOES` | Shoes | Boots, sandals, greaves, shoes |
| 6 | `ACCESSORY` | Accessory | Rings, necklaces, badges, charms |
| 7 | `CONSUMABLE` | Consumable | Potions, herbs, food, recovery items |
| 8 | `CRAFTING_MATERIAL` | Crafting Material | Ores, logs, pelts, refined components |
| 9 | `TENT_FURNITURE` | Tent Furniture | Workbenches, chests, beds, decor |

---

## 3. Public API & Methods

### 3.1 Stat Formatting
`get_formatted_stats() -> Array[Dictionary]`
- **Parameters:** None.
- **Return Type:** `Array[Dictionary]`
- **Dictionary Schema:**
  - `name: String` ("ATK", "DEF", "MATK", "MDEF", "SPD", "HP", "SP")
  - `delta: int` (Positive or negative numerical modifier)
  - `text: String` ("ATK +12", "SPD -2", etc.)
  - `is_positive: bool` (`delta >= 0`)
- **Description:** Iterates all non-zero stat fields and generates formatted deltas suitable for UI display and tooltips.

### 3.2 Alchemy Synthesis Engine
`calculate_synthesis_result(mat_a_rank: int, mat_b_rank: int, catalyst_tier: int) -> Dictionary`
- **Parameters:**
  - `mat_a_rank: int`: Rank of primary material.
  - `mat_b_rank: int`: Rank of secondary material.
  - `catalyst_tier: int`: Alchemy Book grade (0=None, 1=Book I, 2=Book II, 3=Book III, 4=Book IV).
- **Return Type:** `Dictionary`
- **Mathematical Formulas:**
  - `base_rank = int((mat_a_rank + mat_b_rank) / 2.0) + catalyst_tier`
  - `min_rank = maxi(1, base_rank - 1)`
  - `max_rank = base_rank + 2`
  - `success_rate = clampf(0.90 - (float(base_rank) * 0.03) + (float(catalyst_tier) * 0.10), 0.15, 0.95)`
  - `success_percentage = int(round(success_rate * 100.0))`
- **Returned Dictionary Keys:**
  - `mat_a_rank: int`
  - `mat_b_rank: int`
  - `catalyst_tier: int`
  - `base_rank: int`
  - `min_rank: int`
  - `max_rank: int`
  - `success_rate: float`
  - `success_percentage: int`
  - `rank_range_str: String`

### 3.3 Presets Management
`apply_preset(preset_name: String) -> bool`
- **Supported Presets:**
  - `"Bronze Sword"`: ID 23001, Weapon, Rank 3, ATK +12, SPD -2, Buy 150g, Sell 75g.
  - `"Iron Armor"`: ID 21005, Clothes, Rank 5, DEF +18, MDEF +4, Buy 300g, Sell 150g.
  - `"Feather Boots"`: ID 24003, Shoes, Rank 4, SPD +15, DEF +3, Buy 200g, Sell 100g.
  - `"Healing Grass"`: ID 32001, Consumable, Rank 1, HP Bonus +50, Buy 10g, Sell 5g.
  - `"Mana Potion"`: ID 32002, Consumable, Rank 2, SP Bonus +60, Buy 25g, Sell 12g.
- **Side Effects:** Synchronizes internal properties to UI controls, updates icon and tooltip previews, and emits `preset_applied`.

### 3.4 Data Persistence & Export
`create_item_record() -> Dictionary`
- Serializes complete item master properties, equipment slot string, nested stat dictionary, and formatted stats array.

`save_item_json(path: String) -> bool`
- Writes `create_item_record()` to the specified filesystem path with JSON indentation. Emits `item_saved`.

`load_item_json(path: String) -> Dictionary`
- Reads, parses, and populates editor state from a serialized JSON item file. Emits `item_loaded`.

`export_recipe_json(path: String) -> bool`
- Exports synthesis recipe schema including material IDs, material ranks, catalyst tier, target item reference, and calculated rank variance. Emits `recipe_exported`.

---

## 4. Preset Specification Matrix

| Preset Name | ID | Slot | Rank | Level | Durability | Buy (G) | Sell (G) | Stat Modifiers |
|---|---|---|---|---|---|---|---|---|
| **Bronze Sword** | 23001 | Weapon (3) | 3 | 10 | 50 / 50 | 150 | 75 | ATK +12, SPD -2 |
| **Iron Armor** | 21005 | Clothes (2) | 5 | 15 | 60 / 60 | 300 | 150 | DEF +18, MDEF +4 |
| **Feather Boots** | 24003 | Shoes (5) | 4 | 12 | 45 / 45 | 200 | 100 | SPD +15, DEF +3 |
| **Healing Grass** | 32001 | Consumable (7) | 1 | 1 | 1 / 1 | 10 | 5 | HP +50 |
| **Mana Potion** | 32002 | Consumable (7) | 2 | 1 | 1 / 1 | 25 | 12 | SP +60 |

---

## 5. Automated Headless Verification

The test suite validates item creation, stat formatting, preset loading, alchemy synthesis calculations, JSON persistence, and visual scene binding without requiring a GUI window.

### Command Line Execution
```powershell
# Execute via Scene Runner
C:\Godot\godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client scenes/tests/test_item_editor.tscn

# Execute via Script Runner
C:\Godot\godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client -s res://scripts/tests/test_item_editor.gd
```

### Verification Results Summary
- **TEST 1:** Item creation and master attribute initialization -> PASSED.
- **TEST 2:** Stat modifiers builder and formatted stat delta generation -> PASSED.
- **TEST 3:** 5 built-in presets validation -> PASSED.
- **TEST 4:** WLO Alchemy synthesis rank and success probability calculations -> PASSED.
- **TEST 5:** Item record creation, JSON export, disk presence, and import round-trip -> PASSED.
- **TEST 6:** Recipe JSON export with full synthesis payload -> PASSED.
- **TEST 7:** Scene instantiation, UI node binding, icon preview, and tooltip preview -> PASSED.
- **Total Test Pass Rate:** 100%.
