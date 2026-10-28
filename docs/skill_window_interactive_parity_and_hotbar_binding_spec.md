# Skill Window Interactive Parity & Hotbar Binding Specification

## Executive Summary
This document specifies the reverse engineering, visual reconstruction, and functional architecture of the **Skill Window** (`Form_Skill_1`, 290x459) and the **Hotbar Skill Binding & Activation Subsystem** in the Wonderland Online Godot 4 client (`wonderland-online-client`).

The subsystem incorporates authentic 2000s MMORPG bitmap skin assets sliced and defringed from the original game archives (`D:/GitHub/wlridecode/menu/Skins/white/` and `default/`), 5 category tabs (Earth, Water, Fire, Wind, Special) with reactive filtering, a scrollable skill list with custom Delphi-style row components, a detailed inspection card with mathematical damage formulas and target scopes, bidirectional drag-and-drop & click-to-assign hotbar mapping (F1..F8), and full runtime skill casting with SP cost validation, status dock synchronization, and center screen feedback.

---

## 1. Window Geometry & Skin Asset Architecture

### 1.1 Geometry & Alignment
In the original 32-bit Borland Delphi client (`aLogin.exe`), the skill window interface is rendered using `Form_Skill_1.bmp` (or `Form_Skill_2.bmp`) with pre-composed upper list and lower detail card frames.

- **Window Dimensions:** Exactly `Vector2(290.0, 459.0)` (`WINDOW_WIDTH = 290.0`, `WINDOW_HEIGHT = 459.0`).
- **Scene File:** [`scenes/ui/hud/skill_window.tscn`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scenes/ui/hud/skill_window.tscn) and embedded under `FloatingWindows/SkillWindow` in [`scenes/ui/hud.tscn`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scenes/ui/hud.tscn).
- **Script File:** [`scripts/ui/hud/skill_window.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/ui/hud/skill_window.gd) (`SkillWindow` class inheriting `Control`).
- **Background Texture:** `res://assets/hud/form_skill_1.png` (290x459 PNG).

### 1.2 Authentic 18x18 Close Button
- **Position:** `Vector2(260.0, 8.0)` (exact 12px right margin: `290 - (260 + 18) = 12px`, 8px top padding).
- **Size:** `Vector2(18.0, 18.0)`.
- **Textures:**
  - Normal: `res://assets/hud/btn_close_normal.png`
  - Hover: `res://assets/hud/btn_close_hover.png`
  - Pressed: `res://assets/hud/btn_close_pressed.png`
- **Text:** Strictly empty string `""` (no synthetic "X").
- **Cursor:** `Control.CURSOR_POINTING_HAND`.
- **Audio:** Invokes `AuthAudio.play_click()` on button down.

### 1.3 Asset Slicing & Chroma Defringing
All bitmap sources were extracted and processed with strict green chroma-key elimination (`RGB(0, 255, 0)`), background alpha masking, and 1-pixel morphological defringing to eliminate edge halos:
- `assets/hud/form_skill_1.png`: Main dialog frame (290x459) sliced from `Form_Skill_1.bmp`.
- `assets/hud/form_skill_2.png`: Alternate skill frame (290x459) sliced from `Form_Skill_2.bmp`.
- `assets/hud/btn_skill_icon_1..5_{normal,hover,pressed}.png`: 3-state category tab buttons (38x21) sliced from `SkillIcon.bmp` corresponding to Earth, Water, Fire, Wind, and Special.
- `assets/hud/slot_grid_1x1.png`: 32x32 inventory/detail slot border sliced from `1x1Grid.bmp`.
- `assets/hud/slot_grid_1x1_active.png`: 32x32 active/highlighted slot border sliced from `1x1Grid_2.bmp`.

---

## 2. 5 Category Tabs & Reactive Filtering Architecture

### 2.1 Tab Layout & Visual Styling
The category tabs are positioned immediately beneath the window title header:
- **Container Bounds:** `Vector2(0.0, 38.0)`, size `Vector2(290.0, 24.0)`.
- **Tab Dimensions:** `Vector2(38.0, 21.0)` per tab button.
- **X-Offsets:**
  - Tab 0 (Earth): `X = 24.0`
  - Tab 1 (Water): `X = 72.0`
  - Tab 2 (Fire): `X = 120.0`
  - Tab 3 (Wind): `X = 168.0`
  - Tab 4 (Special): `X = 216.0`
- **State Feedback:** The active tab is visually emphasized with brightness modulation `Color(1.15, 1.15, 1.15, 1.0)`, while inactive tabs receive subdued modulation `Color(0.85, 0.85, 0.85, 0.9)`.
- **Auto-Selection:** Upon opening or initialization, the window reads the player's active element from `character_status_ctrl.current_element` (e.g. Earth, Water, Fire, Wind) and automatically selects the matching element tab.

### 2.2 Category Skill Filtering
When a tab is selected, `refresh_skill_list()` queries `GameDatabase.skills` (or uses an offline fallback dataset if the database is uninitialized):
- **Earth (0):** Matches `element == SkillDatabase.Element.EARTH` (1).
- **Water (1):** Matches `element == SkillDatabase.Element.WATER` (2).
- **Fire (2):** Matches `element == SkillDatabase.Element.FIRE` (3).
- **Wind (3):** Matches `element == SkillDatabase.Element.WIND` (4).
- **Special (4):** Matches `element == SkillDatabase.Element.NONE` (0) or `skill_type == SkillDatabase.SkillType.SPECIAL` (4) (e.g. Hand Attack, Alchemy, Common stunts).
- **Starter Stunt Pinning:** If the player has a role-specific starter stunt (e.g. Daniel's Overarm Stumble ID 15038, Rocco's Summon Dogs Groups ID 11075), it is automatically pinned to the top of the category list followed by numeric ID sorting.

---

## 3. Skill List Row Item Component (`SkillRowButton`)

### 3.1 Component Architecture
Each skill in the active tab is instantiated as an interactive [`SkillRowButton`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/ui/hud/skill_row_button.gd) inside `ScrollContainer/VBoxContainer`:
- **Row Bounds:** Width = 236.0, Height = 28.0 (custom minimum size `Vector2(236, 28)`).
- **Sub-Nodes:**
  - `Background`: Tinted semi-transparent backing with hover (`Color(1.0, 1.0, 1.0, 0.12)`) and selection highlight (`Color(1.0, 0.85, 0.2, 0.25)`).
  - `Icon`: 24x24 texture rect at `Vector2(2, 2)` displaying the skill icon. Sourced dynamically from `ArchiveLoader.get_skill_icon(id)` or fallback element badges.
  - `NameLabel`: Positioned at `Vector2(32, 2)`, 11px font with 2px black outline, displaying skill name.
  - `CostLabel`: Positioned at `Vector2(148, 2)`, displaying `SP: %d` in bright cyan (`Color(0.3, 0.85, 1.0)`).
  - `RankLabel`: Positioned at `Vector2(196, 2)`, displaying `Lv.%d` or `R.%d`.

### 3.2 Drag-and-Drop Implementation
[`SkillRowButton`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/ui/hud/skill_row_button.gd) implements Godot 4's native `_get_drag_data(at_position)`:
```gdscript
func _get_drag_data(at_position: Vector2) -> Variant:
    var preview := TextureRect.new()
    preview.texture = icon_rect.texture
    preview.custom_minimum_size = Vector2(32, 32)
    preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    set_drag_preview(preview)

    return {
        "type": "skill",
        "id": int(skill_data.get("id", 0)),
        "name": str(skill_data.get("name", "")),
        "sp_cost": int(skill_data.get("sp_cost", 0)),
        "icon_tex": icon_rect.texture
    }
```

---

## 4. Lower Detail Inspection Card Architecture

### 4.1 Card Geometry & Layout
The detail panel resides in the lower region of `Form_Skill_1`:
- **Position:** `Vector2(24.0, 308.0)`.
- **Dimensions:** `Vector2(242.0, 88.0)`.
- **Components:**
  - **Slot Aperture (`DetailSlotBg`):** 36x36 texture at `Vector2(4, 4)` with `slot_grid_1x1.png`.
  - **Skill Icon (`DetailIcon`):** 32x32 texture inside slot aperture at `Vector2(6, 6)`.
  - **Name Label (`DetailName`):** Positioned at `Vector2(46, 4)`, 12px bold font with yellow accent (`Color(1.0, 0.9, 0.3)`).
  - **Attributes Label (`DetailType`):** Positioned at `Vector2(46, 20)`, displaying Element, Scope, and SP cost (e.g. `Fire | Single | SP 8`).
  - **Description Label (`DetailDesc`):** Positioned at `Vector2(6, 42)`, multi-line wrapped text (10px, subdued gray) explaining lore and tactical application.
  - **Effect Formula Label (`DetailEffect`):** Positioned at `Vector2(6, 68)`, displaying calculated damage formula (e.g. `Damage: 50 + (ATK * 1.35)` or `Restores 60 HP`).

---

## 5. Hotbar Binding & Quick-Bind Controls

### 5.1 Drag-and-Drop Binding
Players can drag any skill row from the skill window and drop it onto any of the 8 hotbar slots (`F1..F8`).
- [`HUDHotbar`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/ui/hud/hud_hotbar.gd) provides:
  - `can_drop_on_slot(slot_index: int, data: Variant) -> bool`: Validates `data is Dictionary and data.get("type") in ["item", "skill"]`.
  - `drop_on_slot(slot_index: int, data: Variant) -> void`: Stores `{ "type": "skill", "id": data.id, "name": data.name, "sp_cost": data.sp_cost, "icon_tex": data.icon_tex }`.

### 5.2 Click-to-Assign Quick-Bind Bar
At the bottom of the skill window (`Vector2(24, 402)`, size `Vector2(242, 48)`), 8 miniature buttons (`F1` to `F8`) allow instant one-click assignment of the currently selected skill to the chosen hotbar slot:
- Clicking `F1`..`F8` invokes `bind_skill_to_hotbar(slot_index)`.
- Emits `skill_assigned_to_hotbar(slot_index, skill_data)` signal.
- Plays authentic UI confirmation audio `AuthAudio.play_click()`.

---

## 6. Hotbar Skill Activation & Runtime Execution

### 6.1 Activation Flow
When a player triggers a hotbar slot (via hotkey `F1`..`F8` or mouse click):
1. [`HUDHotbar`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/ui/hud/hud_hotbar.gd) detects slot type is `"skill"`.
2. Triggers `hud.use_skill(skill_id)`.
3. [`HUD`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/ui/hud.gd) queries skill data from `GameDatabase.skills` to obtain authentic `sp_cost`.
4. Reads player's current SP from `character_status_ctrl.current_sp`.

### 6.2 SP Validation & Deduction
- **Insufficient SP (`current_sp < sp_cost`):**
  - Plays error sound `AuthAudio.play_error()`.
  - Displays center toast notification: `Not enough SP for [Skill Name]! (%d/%d)` in soft red (`Color(1.0, 0.4, 0.4)`).
  - Prints warning in system chat channel.
  - Returns `false` with zero SP deducted.
- **Sufficient SP (`current_sp >= sp_cost`):**
  - Deducts `current_sp -= sp_cost`.
  - Updates `character_status_ctrl.current_sp` and `character_status_ctrl.stat_left_sp.text`.
  - Updates player status dock `SpLabel` with remaining SP.
  - Plays confirmation sound `AuthAudio.play_click()`.
  - Displays floating center toast: `Used skill [Skill Name] (-%d SP)`.
  - Emits chat message: `[System] You cast [Skill Name] (Cost: %d SP).`
  - Spawns local player speech bubble with skill name.
  - Returns `true`.

---

## 7. Automated Headless Verification Suite

### 7.1 Test Suite Structure
The test suite [`tests/test_skill_window_and_hotbar.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/tests/test_skill_window_and_hotbar.gd) provides automated headless test coverage:
1. **Geometry & Layout:** Sizing (290x459), background skin texture, close button at `(260, 8)` with 18x18 size and zero synthetic text.
2. **Embedding & Hierarchy:** Verification of embedded `SkillWindow` inside `scenes/ui/hud.tscn`, category tabs container, scroll container, detail card, and quick-bind container.
3. **Reactive Filtering:** Iteration through all 5 tabs (Earth: 130 skills, Water: 150 skills, Fire: 149 skills, Wind: 127 skills, Special: 397 skills) with signal emission checks and element category matching.
4. **Detail Card Inspection:** Skill selection, detail name, SP cost, description, and formula readouts.
5. **Drag-and-Drop Payloads:** Type `"skill"`, numeric ID, name string, and SP cost checks.
6. **Hotbar Binding:** Direct method binding and drag-and-drop simulation verifying hotbar slot updates.
7. **Runtime Skill Activation:** SP validation, deduction from 50 to 42 (cost 8), dock label synchronization, and graceful failure on insufficient SP.
8. **Close Button Interaction:** Button signal propagation and window dismissal.

### 7.2 Verification Execution
```bash
C:\Godot\godot_console.exe --headless --script tests/test_skill_window_and_hotbar.gd
# Result: 76 passed, 0 failed (100% pass)

C:\Godot\godot_console.exe --headless --script tests/test_floating_windows_and_system_settings.gd
# Result: 139 passed, 0 failed (100% pass)
```
Total: **215 assertions passing with zero errors.**
