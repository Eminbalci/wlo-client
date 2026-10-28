# Character & Item Window Navigation Technical Specification

## Overview
This document specifies the authentic implementation of character and inventory navigation controls within `HUDCharacterStatus` (`Form_RoleStatus_1`) and `HUDInventory` (`Form_RoleStatus_2`) matching the real Wonderland Online client layout and Delphi form design (`wlridecode/menu/Skins/Form_RoleStatus_1.bmp` and `Form_RoleStatus_2.bmp`).

## 1. Architectural Changes

### 1.1 Header Inventory Page Navigation (`TitlePrev` & `TitleNext`)
- **Real Client Layout:** The top title header contains left (`TitlePrev` at `(146, 21)`) and right (`TitleNext` at `(221, 21)`) navigation arrows.
- **Functionality:** Cycles the player's active inventory bag between Page 1 (slots 0..24) and Page 2 (slots 25..49).
- **Implementation:**
  - `HUDCharacterStatus.current_inventory_page` property (clamped `0..1`).
  - Emits `inventory_page_changed(new_page: int)`.
  - Automatically invokes `HUDInventory.set_page(new_page)` when linked in `HUDWindowManager` / `HUD`.
  - Updates title text between `"Inventory - Page 1"` and `"Inventory - Page 2"`.

### 1.2 Lower Shoes / Mount Gear View Toggle (`ShoesPrev` & `ShoesNext`)
- **Real Client Layout:** The paperdoll equipment window includes left (`ShoesPrev` at `(40, 237)`) and right (`ShoesNext` at `(139, 237)`) arrows around the footwear slot.
- **Functionality:** Toggles the footwear display slot between normal player shoes/boots and mount/riding shoes.
- **Implementation:**
  - `shoes_view_mode` integer property (`0 = NORMAL_SHOES`, `1 = RIDING_SHOES`).
  - Emits `shoes_view_mode_changed(mode: int)`.
  - Updates the equipment footwear slot icon, visual watermark, and tooltip between `"Shoes"` and `"Riding Shoes"`.
  - Sends a system feedback log to the chat interface.

### 1.3 Potential Interaction (`Potential` Button)
- **Real Client Layout:** `Potential` button at `Vector2(126, 79)` with size `Vector2(55, 20)`.
- **Functionality:** Inspects and logs character potential awakening tier, unlocked potential stat bonuses, and attribute enlightenment.
- **Implementation:**
  - `_on_potential_button_pressed()` logs current potential tier and triggers visual feedback.

## 2. Testing & Verification
- Suite: `tests/test_character_item_window_navigation.gd`
- Results:
  - Header page arrow navigation verified (0 -> 1 -> 0 with signal emissions).
  - Shoes mode toggle verified (Normal <-> Riding Shoes with slot label updates).
  - Potential interaction verified.
  - Regression verified with `tests/test_consumable_item_recovery.gd` (35/35 passed) and `tests/test_floating_windows_and_system_settings.gd` (146/146 passed).
