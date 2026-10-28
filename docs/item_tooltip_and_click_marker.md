# Item Hover Tooltips & Ground Click Destination Marker Technical Specification

## 1. Overview
This module implements:
1. Authentic 4-frame animated ground click destination indicator (`Arrow1.bmp` - `Arrow4.bmp`) spawned upon map terrain click navigation.
2. Authentic light-blue ice parchment hover tooltip for inventory items and equipment sockets, displaying item level requirements, equipment types, attribute bonuses, durability, and descriptive lore.

## 2. Ground Click Destination Marker (`WloClickRipple`)
- **Script**: `scripts/fx/click_ripple.gd`
- **Scene**: `scenes/fx/click_ripple.tscn`
- **Textures**: `assets/fx/click_arrow_1.png` - `assets/fx/click_arrow_4.png` (extracted from authentic binary assets `Arrow1.bmp` - `Arrow4.bmp` with 1-bit transparency key `(0, 255, 0)`).
- **Animation Timing**:
  - `FRAME_INTERVAL`: 0.12s (~8.33 FPS)
  - `TOTAL_LOOPS`: 2 loops with smooth alpha fade-out during final cycle.
- **Rendering**:
  - Centered coordinate anchor at `(-32, -32)` so the pointer center precisely aligns with the clicked ground tile.
  - Rendered at `z_index = 30` above terrain, shadows, and grid lines.

## 3. Inventory & Equipment Hover Tooltips (`ItemTooltip`)
- **Script**: `scripts/ui/item_tooltip.gd`
- **Visual Styling**:
  - Background: Soft Ice-Blue Parchment (`Color(0.87, 0.92, 1.0, 0.96)`).
  - Border: Deep Slate Navy (`Color(0.12, 0.24, 0.42, 1.0)`), 1px width, 3px corner radius.
  - Drop Shadow: `Color(0.0, 0.0, 0.0, 0.35)` with 4px blur and (2, 2) offset.
- **Data Model**:
  - Item name and level requirement `[Lv. %d]`.
  - Equipment Slot classification: Headgear, Clothes, Weapon, Wrist / Shield, Shoes, Accessory, Consumable.
  - Attribute bonuses decoded from `itemDat.wpdat` (ATK, DEF, MATK, MDEF, SPD, MaxHP, MaxSP):
    - Forest Green (`Color(0.06, 0.48, 0.16)`) for positive stat increases.
    - Crimson (`Color(0.72, 0.12, 0.12)`) for stat penalties.
  - Equipment durability tracking (e.g. `Durability: 50 / 50`).
  - Item description paragraph with autowrap.
- **Viewport Clamping & Placement**:
  - Computes placement to the left of hovered inventory slots to prevent obscuring right-hand slots.
  - Clamps to viewport boundaries `[8, vp_size - 8]` on both axes to prevent off-screen clipping.

## 4. Test Suite Verification
- **Test Script**: `tests/test_item_tooltip_and_click_marker.gd`
- **Execution**:
  ```bash
  godot_console.exe --headless --path . -s "res://tests/test_item_tooltip_and_click_marker.gd"
  ```
- **Results**:
  - Part 1: Click marker 4-frame animation and 10 FPS sequence verified.
  - Part 2: Tooltip formatting, stat colors, durability, and viewport clamping verified.
  - Part 3: HUD inventory slot hover & exit hooks verified with 100% pass rate.
