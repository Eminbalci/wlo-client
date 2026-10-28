# Wonderland Online - Authentic Compound & Alchemy Window Specification

## 1. Overview
The **Compound Window** (`scripts/ui/hud/compound_window.gd`, `scenes/ui/hud/compound_window.tscn`) is the authentic Wonderland Online item synthesis and alchemy interface (`Form_Compound_1`, 299x467). It is decoded directly from the Delphi binary `aLogin.exe` (`TRe_CompoundForm`), `Compound.dat`, and `Compound2.Dat`.

It allows players to combine primary base items with up to 4 sub materials and alchemy catalysts (Alchemy Books I-IV, gems, and spars) to synthesize upgraded gear, consumables, weapons, and alchemy concoctions.

---

## 2. Decoded Binary Specification (`aLogin.exe`)

### 2.1 VCL Class & Resource Identification
- **VCL Class Name:** `TRe_CompoundForm` (VA: `0x21b9b8`)
- **Skin / Background Bitmap:** `assets/menu/Skins/white/Form_Compound_1.bmp` (299x467)
- **Compound Action Button:** `assets/menu/Skins/default/Btn_Compound_1.bmp` (56x60, 3 states of 56x20)
- **Animated VFX Overlay:** `assets/menu/Skins/default/Compounding.bmp` (90x2185, 23 vertical frames of 90x95)
- **Skill Checkbox:** `assets/menu/Skins/default/btn_Check_1.bmp` / `btn_UnCheck_1.bmp` (16x48, 16x16 per state)
- **Skill Label:** `"Use Junior Alchemy"` / `"Use Primary Alchemy"`
- **Close Button:** `Btn_Close_S_1` / `Btn_Close_1` (18x18 at X: 268, Y: 22)

### 2.2 Layout & Slot Coordinates
| Component | Identifier | Coordinates (X, Y) | Dimensions (W x H) | Function |
|---|---|---|---|---|
| Background Frame | `FormBackground` | (0, 0) | 299 x 467 | Window parchment backing |
| Title Bar | `TitleLabel` | (24, 22) | 180 x 20 | "Compound" |
| Close Button | `BtnClose` | (268, 22) | 18 x 18 | Closes window, returns items |
| Skill Checkbox | `BtnSkillCheck` | (24, 52) | 16 x 16 | Toggles Junior Alchemy bonus |
| Skill Label | `LblSkill` | (44, 51) | 150 x 18 | "Use Junior Alchemy" |
| Bag Grid Scroll | `BagScroll` | (24, 76) | 174 x 344 | 5 columns x 10 rows (50 slots) |
| Main Slot (Base) | `CompoundItem_Main` | (206, 116) | 44 x 44 | Primary base item to upgrade |
| Sub Slot 0 | `CompoundItem_Sub_0` | (206, 186) | 38 x 38 | Secondary material / Spar / Book |
| Sub Slot 1 | `CompoundItem_Sub_1` | (206, 234) | 38 x 38 | Secondary material |
| Sub Slot 2 | `CompoundItem_Sub_2` | (206, 282) | 38 x 38 | Secondary material |
| Sub Slot 3 | `CompoundItem_Sub_3` | (206, 330) | 38 x 38 | Secondary material |
| Compounding VFX | `CompoundingAnim` | (180, 160) | 90 x 95 | 23-frame animated vortex |
| Compound Button | `BtnCompound` | (159, 429) | 56 x 20 | Initiates synthesis |
| Status Message | `StatusLabel` | (24, 424) | 130 x 32 | Validation & result notices |

---

## 3. Validation Logic & Error Handling

Decoded directly from `aLogin.exe` string constants:
1. `"No materials to compound"`: Triggered if `main_slot_data` is empty.
2. `"Book can't be base item"`: Triggered if player attempts to place an Alchemy Book (`47001..47004`) in `CompoundItem_Main`.
3. `"Cant compound large item"`: Triggered if attempting to compound vehicles (canoes, rafts, cars) or tents.
4. `"Use at least 2 materials"`: Triggered if total materials < 2 when no Alchemy Book is used.
5. `"Use at least 2 mats and Alchemy Book"`: Triggered if an Alchemy Book is present but fewer than 2 standard materials are loaded (total items must be >= 3).
6. `"Can use only 1 Alchemy Book"`: Triggered if attempting to place a second Alchemy Book in sub slots.

---

## 4. Synthesis Rank Calculation & Database Matching

### 4.1 Recipe Databases & Binary Decoding
- `assets/data/Compound.dat`: Legacy 168-record database (10,920 bytes, 65-byte records, XOR key `0xFBBC`).
- `assets/data/Compound2.Dat`: Authoritative 789-record crafting database (51,285 bytes, 65-byte records).
  - **Record 0**: Version header (word 6, padded with 63 zeros; skipped during recipe indexing).
  - **Records 1..788**: Active crafting recipes.
  - **Record Layout (65 bytes)**:
    - Offset `0..1`: `resultID = ((u16 ^ 0xFBBC) - 3) & 0xFFFF`
    - Offset `2..3`: `planID = ((u16 ^ 0xFBBC) - 3) & 0xFFFF`
    - Offset `4`: `unknownByte = ((u8 ^ 0xD3) - 3) & 0xFF`
    - Offset `5..6`: `toolID = ((u16 ^ 0xFBBC) - 3) & 0xFFFF`
    - Offset `7`: `amtRecv = ((u8 ^ 0xD3) - 3) & 0xFF` (Amount of crafted output item)
    - Offset `8..10`: 3 bytes metadata padding
    - Offset `11..25`: 5 ingredient slots (`u16 materialID`, `u8 materialAmount` per slot):
      - `materialID = ((u16 ^ 0xFBBC) - 3) & 0xFFFF`
      - `materialAmount = ((u8 ^ 0xD3) - 3) & 0xFF`
    - Offset `26..64`: Additional recipe metadata, animation flags, and time parameters.

### 4.2 Two-Stage Synthesis Engine
1. **Stage 1 (Exact Compound2.Dat Recipe Match)**:
   - When ingredients match all required materials for an exact recipe in `Compound2.Dat`:
     - Guaranteed 100% success rate.
     - Produces exact `resultID` with configured `amount` (`amtRecv`).
2. **Stage 2 (Authentic Alchemy Grade Synthesis - Spec 37 / AC64)**:
   - When no fixed recipe matches, computes authentic grade alchemy:
     $$\text{BaseGrade} = \left\lfloor \frac{G_{\text{Main}} + G_{\text{Sub}}}{2} \right\rfloor$$
     $$\Delta G = \text{random delta bounded by active skill tier and catalyst books}$$
     - **Junior Alchemy (`15998`)**: $-2 \le \Delta G \le +2$, Alchemy Book I (+1 Grade).
     - **Primary Alchemy (no skill)**: $-3 \le \Delta G \le +1$, no books allowed.
     - **Catalyst Books (I-IV)**: Add $+1$ to $+4$ grade tiers.
     - $\text{TargetRank} = \max(1, \text{BaseGrade} + \Delta G)$.
   - **Success Condition**: Resolves an item from `GameDatabase` matching `TargetRank` and identical material/equipment category.
   - **Failure Condition**: When $\Delta G < 0$ or failure roll triggers, yields Slime / Clay byproduct (`Item ID 36001`).
   - Deducts 1 of each ingredient loaded into the slots and awards the synthesized product.

---

## 5. Controls, Hotkeys & UI Integration
- **Compound Hotkey `[V]`**: Toggles Compound Window via `toggle_compound_window()`.
- **Character Status Hotkeys `[C / E]`**: Dedicated to toggling Character Status Window (`toggle_character_status()`).
- **Inventory Hotkey `[I]`**: Toggles Inventory Window (`toggle_inventory()`).
- **Action Dock Button 3 (`BtnQuest` / `Btn_Compound_1`)**: Tooltip `"Compound [V]"`, triggers `toggle_compound_window()`.
- **Initial Visibility Configuration**: `CompoundWindow.tscn` is saved with `visible = false` and instantiated hidden in `FloatingWindows` to prevent unintended auto-closing on first toggle.
- **Synthesis Status Reporting**: `_refresh_slots_ui(false)` updates slot textures without erasing the synthesis feedback string (`"Compound Success! Obtained %s!"`).
- **Drag Window**: Clicking and dragging the upper header area (`Y <= 45`) repositions the window within viewport bounds.
- **Escape Key**: Closes the window and safely returns any placed ingredients back to the inventory bag.

---

## 6. Playtest Simulator Spawner & Cheat Command Integration
- **Simulator HUD Resolution**: `WorldEditor._get_simulator_hud()` inspects `CanvasLayer/HUD`, fallback `HUD`, and `_simulator_instance.hud`, ensuring subcontroller `_ready()` initialization prior to item operations.
- **Item & Gold Granting**: Grants authentic items parsed from `Item.dat` via `GameDatabase.items.get_item(item_id)` and increments character gold balance.
- **Chat Cheat Commands**:
  - `/give <item_id> [count]`: Grants specified item count (default: 1) into inventory bag.
  - `/gold <amount>`: Adjusts character gold balance.
  - `/clear`: Clears all 45 bag slots via `clear_inventory()` and updates inventory visual slots.

---

## 7. Inventory Data Synchronization & Material Deduction
- **Inventory Data Binding**: `CompoundWindow.refresh_inventory_from_hud()` checks `_hud.inventory_ctrl.inventory_data`, `_hud.inventory.inventory_data`, and `_hud._inventory_data` to ensure the 50-slot compounding grid accurately mirrors player bag items.
- **Material Deduction**: Upon synthesis execution, `_commit_inventory_deduction()` invokes `_hud.remove_inventory_item(item_id, count)` which delegates to `HUDInventory.remove_item_by_id(item_id, count)`. Stacked items have counts decremented; empty slots are cleanly reset via `clear_inventory_slot()`.
- **Kinematic & Dialogue Locking**: Player movement is strictly prevented while dialogue or cutscenes are active, and combat/action animations (`MotionState.ATTACK`, `DEFEND`, `VICTORY`) enforce `is_movement_locked = true` until auto-recovery to `MotionState.IDLE`.
- **Cutscene Speech & Audio**: Cutscene shouts during the ship sinking sequence broadcast to HUD chat logs in addition to overhead speech bubbles, and beach awakening ambient audio prioritizes authentic rolling surf ambience (`SEB0037.wav`). Map BGM associations in `AudioEditor` align with authentic `SceneData.dat` specifications (Map 10001: BGM0007, Map 10002: BGM0011, Map 10003/10011: BGM0024).
