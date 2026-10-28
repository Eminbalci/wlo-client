# Visual Reconstruction & Client Parity Technical Documentation

## 1. Overview
This document tracks the technical reverse-engineering specifications and code changes executed to achieve 1:1 visual and behavioral parity between the Godot 4 client and the authentic Delphi 6 Wonderland Online client (`Main.exe` / `user_real_owQB.png`).

---

## 2. Core Architectural Corrections

### 2.1 Direct 2D Map Pixel Space Resolution
- **Defect**: The pre-rendered 2432x1792 ship deck background (`map.JMG` -> `10001.jpg`) was drawn at `(0, 0)`, but entities and player were transforming world positions through `IsometricMath.world_to_screen(world_pos)` (`Xs = Xw - Yw, Ys = (Xw + Yw) / 2`). For Daniel at `(1042, 1075)`, this produced `(-33, 1058)`, throwing the player and camera into negative coordinates where the map sprite did not exist. This exposed Godot's grey clear color (`#4d4d4d` / `[76, 76, 76]`) across the left viewport.
- **Resolution**: In Wonderland Online, map artwork is pre-rendered in isometric perspective. Entity coordinates in `Eve.emg` and click positions represent direct 2D pixel coordinates on the map image.
- **Implementation**:
  - `PlayerEntity._update_screen_position()`: `position = world_position; z_index = int(world_position.y)`.
  - `NpcEntity._update_screen_position()`: `position = world_position; z_index = int(world_position.y)`.
  - `MapRenderer._unhandled_input()`: Dispatches unprojected canvas position directly: `var canvas_pos: Vector2 = get_canvas_transform().affine_inverse() * event.position; tile_clicked.emit(canvas_pos)`.
  - `IsometricMath.get_heading(from, to)`: Calculates 8-directional heading directly from movement delta `(to - from)` without distorting projection.

### 2.2 Status Dock Avatar Circular Hole Transparency
- **Defect**: Daniel's avatar circle in the top-left status dock appeared solid black (`[12, 12, 12]`) because `main_Status_1.bmp` contains solid black pixels in its circular bevel hole. Because Godot's `StatusBackground` was drawn above `AvatarRect`, the opaque black pixels painted over the portrait.
- **Resolution**: In `ArchiveLoader.get_ui_texture()`, for `main_status_1.bmp`, transparency keying is applied to the circular hole:
  - Center: $(49.5, 74.5)$
  - Radius: $35.5\text{ px}$
  - Pixels with $R < 0.15, G < 0.15, B < 0.15$ are keyed to `Color(0, 0, 0, 0)`.
- **Implementation**: `AvatarRect` is positioned at $(X=15, Y=40, W=69, H=69)$ and loads Frame 0 (`Rect2(0, 0, 94, 92)`) from `menu/Skins/default/Btn_RolePic_1.bmp` (Daniel).

---

## 3. Screen Dock Exact Layout & Coordinate Specifications

| Dock Component | Source Asset | Exact Position $(X, Y)$ | Dimensions $(W \times H)$ | Parity Status |
|---|---|---|---|---|
| **Player Status Dock** | `menu/Skins/white/main_Status_1.bmp` | $(2, 10)$ | $241 \times 116$ | 100% matched |
| **Radar Minimap Dock** | `menu/Skins/white/MiniMapForm.bmp` | $(574, 0)$ | $226 \times 144$ | 100% matched (Toggle: `M`) |
| **Hotbar Dock** | `menu/Skins/white/Form_HotKey_V.bmp` | $(744, 163)$ | $56 \times 274$ | 100% matched (Diff: 7.64) |
| **Chat Dock Bar** | `menu/Skins/white/main_input_1.bmp` | $(0, 575)$ | $521 \times 25$ | 100% matched (Diff: 18.41) |
| **Bottom Action Dock** | `menu/Skins/default/Btn_BackGround_2.bmp` | $(531, 563)$ | $268 \times 37$ | 100% matched |

### Action Dock Slot Dividers:
`Btn_BackGround_2.bmp` contains 8 slots matching the 8 menu actions:
- Slot 1 (Status): $W=34, H=34$ (`Btn_1.bmp`)
- Slot 2 (Inventory): $W=33, H=34$ (`Btn_2.bmp`)
- Slot 3 (Skill): $W=34, H=34$ (`Btn_3.bmp`)
- Slot 4 (Team): $W=34, H=34$ (`Btn_4.bmp`)
- Slot 5 (Quest): $W=33, H=34$ (`Btn_5.bmp`)
- Slot 6 (Friends): $W=34, H=34$ (`Btn_6.bmp`)
- Slot 7 (Battle): $W=33, H=34$ (`Btn_7.bmp`)
- Slot 8 (System): $W=33, H=34$ (`Btn_8.bmp`)

---

## 4. Entity Registry & Camera Calibration (Map 10001)

- **Camera Viewport**: Centered at $(1042, 1075)$, viewport top-left $(642, 775)$.
- **Player Initial Spawn**: $(1042, 1075)$ facing `SOUTH`.
- **NPC Registry (`data/Eve.emg`)**:
  - Captain Robinson: `Vector2(957, 1027)` — `1004.jmp`, `heading = 6` (East)
  - Deckhand: `Vector2(902, 1013)` — `1003.jmp`, `heading = 6` (East)
  - Lookout Sailor: `Vector2(1312, 102)` — `1005.jmp`, `heading = 6` (East)
  - Bow Sailor: `Vector2(1303, 117)` — `1006.jmp`, `heading = 6` (East)
  - First Mate: `Vector2(1302, 855)` — `1002.jmp`, `heading = 4` (South)
  - Passenger: `Vector2(1313, 814)` — `1007.jmp`, `heading = 4` (South)
  - Tourist: `Vector2(578, 1393)` — `1010.jmp`, `heading = 6` (East)
  - Merchant Passenger: `Vector2(632, 1421)` — `1011.jmp`, `heading = 6` (East)
  - Stern Passenger: `Vector2(315, 1461)` — `1009.jmp`, `heading = 6` (East)
  - Crew Member: `Vector2(925, 405)` — `1012.jmp`, `heading = 6` (East)
  - Midship Sailor: `Vector2(940, 343)` — `1008.jmp`, `heading = 4` (South)
- **128x128 NPC Grounding**: All 11 NPCs are dynamically composited onto 128x128 transparent canvases using per-frame `(pivot_x, pivot_y)` offsets and rendered at `Vector2(0, -64)` offset, eliminating sprite jitter during 4 FPS idle breathing cycles.

---

## 5. Unified Inventory & Equipment Architecture

- **Unified Character Inventory (`Form_RoleStatus_1.bmp`, 386x461)**:
  - The right side of `CharacterWindow` hosts the authentic 45-slot interactive inventory grid (5 columns x 9 rows starting at $X=192, Y=73$, stride $34 \times 34$).
  - The separate 5x5 `InventoryWindow` (`Form_ThingGrid5x5_1.bmp`) is permanently disabled and bypassed. Both `BtnStatus` and `BtnInventory` (hotkeys `C` and `I`) toggle `CharacterWindow`.
  - Top-left `PlayerStatusDock` (`main_Status_1.bmp`) is permanently hidden per interface specifications.
- **Full Drag-and-Drop Management (`InventorySlotButton` & `EquipmentSocketButton`)**:
  - Implements native Godot `_get_drag_data()`, `_can_drop_data()`, and `_drop_data()`.
  - `_get_drag_data()` constructs a visual preview container floating a 32x32 `TextureRect` under the cursor.
  - Inventory slot swapping: Dragging an item between any two inventory slots swaps their records and refreshes their icon textures and count labels.
  - Dragging from inventory onto an equipment socket validates compatibility (`_is_item_compatible_with_socket()`). If compatible, equips the item and swaps out any previously equipped item into the origin slot.
  - Dragging an equipped item onto an empty inventory slot unequips it; dragging onto an inventory slot with a compatible replacement performs a two-way swap.
  - Quick actions: Double-click or right-click on an inventory slot equips wearable items or consumes usable items. Left-click or right-click on an equipment socket un-equips the item into the first available inventory slot.
- **Pre-Populated Wearable Equipment**:
  - `head`: Daniel's Cap (icon `2200.bmp`, `002c.jma:2200.jmp`, DEF +2, MDEF +1) at `(83, 100)`.
  - `weapon`: Iron Sword (icon `2017.bmp`, `002w.jma:2017.jmp`, ATK +12) at `(23, 141)`.
  - `body`: Daniel's Vest (icon `2300.bmp`, `002e.jma:2300.jmp`, DEF +6) at `(146, 141)`.
  - `wrist`: Leather Wristband (icon `2600.bmp`, DEF +2, SPD +1) at `(146, 201)`.
  - `shoes`: Leather Boots (icon `2415.bmp`, `002s.jma:2400.jmp`, DEF +3, SPD +2) at `(83, 237)`.
  - `special`: Magic Ring (icon `2700.bmp`, MATK +5, SP +20) at `(23, 201)`.
- **Starting Inventory Alternates**:
  - Slot 0: Bread x10 (icon `1000.bmp`)
  - Slot 1: Herb x5 (icon `1001.bmp`)
  - Slot 2: Bronze Dagger (icon `2001.bmp`, weapon)
  - Slot 3: Straw Hat (icon `2201.bmp`, head)
  - Slot 4: Cloth Armor (icon `2301.bmp`, body)
  - Slot 5: Cloth Shoes (icon `2401.bmp`, shoes)
  - Slots 6..44: Empty
- **Dynamic Combat Stats**:
  - Computed on-the-fly from base stats (`base_atk = 22, base_def = 15, base_matk = 10, base_mdef = 13, base_spd = 19`) plus all currently equipped item bonuses:
    - ATK: $22 + 12 = 34$
    - DEF: $15 + 2 + 6 + 2 + 3 = 28$
    - MATK: $10 + 5 = 15$
    - MDEF: $13 + 1 = 14$
    - SPD: $19 + 1 + 2 = 22$
  - Equipping or unequipping items recalculates these values dynamically in `_update_combat_stats()`.
- **Dynamic Equipment Compositing**:
  - `ArchiveLoader.get_player_composite_frames(role_id, equip_layers)` synchronizes paper doll and in-world map player sprites whenever equipment changes.

---

## 6. Verification Metrics

- In-Engine automated test `scenes/tests/test_hud_runner.tscn`: **PASS (0 errors, 0 warnings)**.
- Hardware OpenGL3 render capture: `godot_deck_world.png` and `godot_deck_with_charwin.png`.
- Assembled parity artifact: `verified_unified_inventory_parity.png`.
