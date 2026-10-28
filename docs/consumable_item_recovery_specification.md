# Consumable Item Recovery & Status Effects Specification

## Overview
In Wonderland Online, consumable food, beverages, and medicines restore character and pet HP, SP, and Amity. Previously, `HUDInventory.use_or_equip_inventory_item` only decremented item stacks and printed `"Used [Item]"`, leaving HP and SP unchanged. 

This specification details the authentic status recovery fields decoded from `assets/data/itemDat.wpdat` and `assets/data/Item.dat`, the `ItemRecord` recovery calculation logic, the `HUDCharacterStatus` restoration synchronization, and the inventory consumption pipeline.

---

## 1. Decoded Status Fields in `Item.dat` & `itemDat.wpdat`

In the original binary data, items store 16-bit status type codes (`st1`, `st2`) and 32-bit delta values (`su1`, `su2`).
The authentic value delta formula is:
```
delta = raw_val - 100
```

### Status Types for Consumables (`equip_pos in [7, 8]` or `item_type in [20, 23]`):
| Status Type ID | Semantic Meaning | Example Items | Value Formula |
|---|---|---|---|
| `25` | HP Recovery | Bread (32011), Roast Cuttlefish (32083), White Rice (32001) | `raw_val - 100` (e.g. 150 -> +50 HP) |
| `26` | SP Recovery | Rice Wine (32002), Steamed Cod (32087), French Bread (32016) | `raw_val - 100` (e.g. 250 -> +150 SP) |
| `64` | Pet Amity Recovery | Doting Chocolate (32290), Pet Food (27022) | `raw_val - 100` (e.g. 101 -> +1 Amity) |
| `36` | EXP Gain | 5% EXP Capsule (34061) | `raw_val - 100` |
| `250` | Special Effects | Prepared Chinese Ink (33001), Return Scroll, Tent | Custom interaction flags |

Dual-recovery items like Multi Bread (ID 32013) encode both `st1 = 25` (su1 = 240 -> +140 HP) and `st2 = 26` (su2 = 160 -> +60 SP).

---

## 2. Item Database & Tooltip Integration

### `ItemRecord` Helpers (`scripts/database/item_database.gd`)
- `get_hp_restore() -> int`: Iterates over `status_types` and `status_values`, summing all `st == 25` deltas (`val - 100`).
- `get_sp_restore() -> int`: Sums all `st == 26` deltas (`val - 100`).
- `get_amity_restore() -> int`: Sums all `st == 64` deltas (`val - 100`).
- `get_formatted_stats() -> Array[Dictionary]`: Differentiates between equipment stat modifiers (`MaxHP`, `MaxSP`) and consumable stat modifiers (`HP`, `SP`, `Amity`). Tooltips automatically render `"HP +50"`, `"SP +150"` in authentic Royal Green styling.

---

## 3. Character Status Restoration (`scripts/ui/hud/hud_character_status.gd`)

Implemented `restore_hp(amount: int) -> int` and `restore_sp(amount: int) -> int`:
- Clamps values to `current_max_hp` and `current_max_sp`.
- Returns exact restored amount (`current_hp - old_hp`).
- Updates `stat_left_hp` (`"%d / %d" % [current_hp, current_max_hp]`) and `stat_left_sp`.
- Synchronizes `CharacterManager` save state and calls `hud.set_player_stats(...)` to smoothly update player status dock bars and EXP/HP readouts.

---

## 4. Inventory Consumption Pipeline (`scripts/ui/hud/hud_inventory.gd`)

When `use_or_equip_inventory_item(slot_idx)` is executed on a consumable item:
1. **Metadata Resolution:** Reads `hp_restore` and `sp_restore` cached on the item dictionary (or fetches from `GameDatabase.items.get_item(item_id)`).
2. **Restoration Execution:** Invokes `char_ctrl.restore_hp(hp_rest)` and `char_ctrl.restore_sp(sp_rest)`.
3. **Stack Decrement:** Decrements `count` if `> 1`, or clears the slot if single item.
4. **Audio & Visual Feedback:**
   - Plays authentic click SFX `res://assets/sound/wav0151.wav`.
   - Logs system chat message: `"Used Bread (+50 HP)."` or `"Used Multi Bread (+140 HP, +60 SP)."`.
   - Displays floating center toast notification: `hud.show_toast("Used Bread (+50 HP)")`.

---

## 5. Automated Verification

Dedicated test suite `tests/test_consumable_item_recovery.gd`:
- `test_item_database_consumable_records()`: Verifies Bread (+50 HP), Rice Wine (+150 SP), Multi Bread (+140 HP, +60 SP), and formatted stats output.
- `test_character_status_restoration()`: Verifies partial restoration, over-cap clamping, and full HP/SP zero-restoration boundary conditions.
- `test_inventory_consumable_use()`: Verifies stack decrement, inventory clearing, HP/SP restoration execution, and system logging.
- `test_item_tooltip_consumable_stats()`: Verifies hover tooltip container displays green `"HP +140"` and `"SP +60"` badges.

**Execution Result:** 35/35 passed, 0 failures (100%).
