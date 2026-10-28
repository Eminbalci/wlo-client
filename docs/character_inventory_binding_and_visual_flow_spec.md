# Character Inventory Binding & Visual Flow Specification

## Overview
This document specifies the dynamic character data binding architecture between `MapView`, `HUD`, `CharacterManager`, and `GameDatabase`. It details the resolution of the character mismatch defect where the in-world player character differed from the inventory status paperdoll and stats window.

---

## 1. Defect Analysis & Root Cause

### 1.1 Symptoms
- Player selects **Daniel** (Role 6, Fire Element, Level 1, HP 190, SP 124) in Character Select.
- World overworld sprite and top-left status dock avatar display Daniel.
- Opening the Character / Item Window (`'C'` / `'I'`) displayed **Betty** (Role 2, Wind Element, Level 10, HP 320/320, SP 150/150, EXP 4500/10000) and Betty's pink overalls paperdoll sprite.

### 1.2 Root Cause Diagnosis
1. `scripts/ui/hud.gd` hardcoded Betty in `_ready()` via `set_player_stats("Betty", ...)` and `update_character_stats("Betty", ...)`.
2. Equipment sockets pre-populated Betty's starting items (`21003 Harness Pants`, `24003 Pink Shoes`, `11033 Iron Sword`).
3. `update_character_paper_doll()` defaulted to Role 2 (Betty) when `player` was not yet instantiated at HUD initialization time.
4. `scripts/map/map_view.gd` never pushed the complete character dictionary (`char_data`) to the HUD status window or equipment layers.
5. In `scripts/ui/login_screen.gd`, fallback starter dictionary had a typo with `"name": "Daniel", "role_id": 1` instead of `role_id: 6`.

---

## 2. Technical Implementation

### 2.1 Dynamic Character Binding: `apply_character_data`
Implemented in [`scripts/ui/hud.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/ui/hud.gd):
```gdscript
func apply_character_data(char_data: Dictionary) -> void:
    if char_data.is_empty():
        return
    
    var r_id: int = int(char_data.get("role_id", _current_player_role_id))
    var c_name: String = str(char_data.get("name", "Daniel"))
    var c_level: int = int(char_data.get("level", 1))
    var c_element: String = str(char_data.get("element", "Fire"))
    var c_hp: int = int(char_data.get("hp", 190))
    var c_max_hp: int = int(char_data.get("max_hp", c_hp))
    var c_sp: int = int(char_data.get("sp", 124))
    var c_max_sp: int = int(char_data.get("max_sp", c_sp))
    var c_exp: int = int(char_data.get("exp", 0))
    var c_max_exp: int = int(char_data.get("max_exp", 10000))
    
    var c_str: int = int(char_data.get("str", 12))
    var c_con: int = int(char_data.get("con", 10))
    var c_int: int = int(char_data.get("int", 8))
    var c_wis: int = int(char_data.get("wis", 8))
    var c_agi: int = int(char_data.get("agi", 10))
    var c_free: int = int(char_data.get("free_points", 0))
    var c_gold: int = int(char_data.get("gold", 500))
    
    _current_player_role_id = r_id
    _current_player_element = c_element
    
    set_player_role(r_id)
    set_player_element(c_element)
    set_player_stats(c_name, c_level, c_hp, c_max_hp, c_sp, c_max_sp, exp_pct)
```

### 2.2 Authentic Starter Outfit Loading
Resolves clothes and shoes definitions for each of the 14 authentic roles from `GameDatabase.get_role(role_id)`:
- Role 6 (Daniel): `default_clothes_archive: "004e.jma"`, `default_clothes_jmp: "4300.jmp"`, `default_shoes_archive: "004s.jma"`, `default_shoes_jmp: "4400.jmp"`
- Dynamically assigns `current_equip_layers` and updates `char_paper_doll.texture` using `ArchiveLoader.get_player_composite_frames(role_id, current_equip_layers)` south standing frame index 48.

### 2.3 MapView Lifecycle Integration
In [`scripts/map/map_view.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/map/map_view.gd):
- Binds `hud.player = player` before character data application.
- Forwards `GameDatabase.active_character` directly into `hud.apply_character_data(char_data)`.

### 2.4 Server Configuration Sync
Updated `res://assets/SERVER.INI` and `D:\GitHub\WLRI\SERVER.INI` with real production server endpoints from `C:\Games\WLRI\SERVER.INI`:
- **Rhodes Island**: `Rhodes1` (20.187.103.41), `Rhodes2` (104.208.85.33), `Rhodes3` (20.187.123.156), `Rhodes4` (20.205.14.213) on port 6414.
- **Lion Island**: `Lion1` (47.238.172.210) on port 6414.
- **Local Dev**: `Local` (127.0.0.1) on port 6414.

---

## 3. Empirical Verification Evidence

### 3.1 Visual Flow Screenshot Artifacts
1. [Server Selection](file:///C:/Users/muham/.gemini/antigravity-cli/brain/c43cf149-bb6e-436c-95e5-06c734294986/visual_flow_01_server_select.png)
2. [Login Dialog](file:///C:/Users/muham/.gemini/antigravity-cli/brain/c43cf149-bb6e-436c-95e5-06c734294986/visual_flow_02_login_dialog.png)
3. [Character Selection](file:///C:/Users/muham/.gemini/antigravity-cli/brain/c43cf149-bb6e-436c-95e5-06c734294986/visual_flow_03_char_select.png)
4. [Character Create Standees](file:///C:/Users/muham/.gemini/antigravity-cli/brain/c43cf149-bb6e-436c-95e5-06c734294986/visual_flow_04_char_create_standees.png)
5. [Ship Deck Map 10001](file:///C:/Users/muham/.gemini/antigravity-cli/brain/c43cf149-bb6e-436c-95e5-06c734294986/visual_flow_05_ship_deck.png)
6. [Character Window & Inventory Match](file:///C:/Users/muham/.gemini/antigravity-cli/brain/c43cf149-bb6e-436c-95e5-06c734294986/visual_flow_06_inventory_character_match.png)

### 3.2 Automated Test Execution
- Comprehensive Button Test: [`tests/test_all_client_buttons.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/tests/test_all_client_buttons.gd) passed 199/199 buttons (100% pass rate).
- Visual Flow Verification: [`tests/visual_flow_inspector.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/tests/visual_flow_inspector.gd) passed all 7 steps with active character assertion verifying Daniel, Level 1, Fire element, HP 190/190, SP 124/124, and paperdoll texture match.
- Character & Inventory Binding Test: [`tests/test_character_inventory_binding.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/tests/test_character_inventory_binding.gd) passed 10/10 checks (100% pass rate).

---

## 4. Inventory Layout, Close Button, Paperdoll & Overland Weapon System

### 4.1 Header Labels Clean-Up
- Floating redundant labels (`StatName`, `StatLevel`, `StatElement`) hovering over inventory columns are removed (`visible = false`). The character name, level, and element are cleanly displayed in the authentic header panels.

### 4.2 Ornate Gold Close Button Wiring
- Window close button positioned at `(356, 12)` sized `24x24` over the skin's pre-rendered ornate gold `(X)`.
- Replaced the intrusive grey square replacement stylebox with a transparent normal stylebox (`StyleBoxEmpty`) and subtle feedback hover/press styles.
- Wired `CloseButton.pressed` to `close_inventory()` / `close_window("CharacterWindow")` in `hud_inventory.gd` and `hud_window_manager.gd`.

### 4.3 Vertical Layout Alignments
- **Inventory Item Grid**: Shifted up by 6px (`offset_top = 67.0`, `offset_bottom = 373.0`).
- **Paperdoll Standee**: Shifted up by 6px (`offset_top = 127.0`, `offset_bottom = 255.0`), preventing shoes from colliding with HP/SP bars.
- **Combat Stats Table**: Shifted up by 3px (`StatAtk` at 335, `StatDef` at 351, `StatMatk` at 367, `StatMdef` at 383, `StatSpd` at 399) to center vertically within their row slots.
- **POINT 0 Label**: Shifted ~4px up and ~6px right (`offset_left = 142.0`, `offset_top = 314.0`) so the value is positioned beside the blue POINT badge instead of overlapping it.

### 4.4 Weapon Offset & Paperdoll Behind-Back Rendering
- **Bounding Box Correction**: Weapon frames in JMA archives are packed within 256x256 bounding boxes, whereas the base character canvas is 128x128. Corrected the pivot offset in `archive_loader.gd`:
  ```gdscript
  var ox: int = int((j_frame.bound_w - 128) / 2) if j_frame.bound_w > 128 else 0
  var oy: int = int((j_frame.bound_h - 128) / 2) if j_frame.bound_h > 128 else 0
  ```
  Subtracting `ox = 64, oy = 64` shifts the weapon directly onto the character's back/hand instead of rendering detached in the bottom-right corner.
- **Directional Z-Ordering**:
  - Headings 2, 3, 4, 5, 6 (East, SE, South, SW, West - including paperdoll frame 48): Weapon layer is rendered behind the body layer (`behind_body = true`).
  - Headings 0, 1, 7 (North, NE, NW): Weapon layer is rendered in front of the body and clothing layers.
- **Role Archive Prefix Resolution**: Dynamically matches role body archive prefix (`004w.jma:4040.jmp` for Role 6, `003w.jma:3040.jmp` for Role 2, etc.) supporting both `"weapon"` and `"hand"` dictionary keys.

### 4.5 Overland Walking Weapon & Player Drop Shadow
- **Overland Walking Weapon**: Composite frame generation in `ArchiveLoader` maps walking animation frames (0..31) and idle frames (32..63) with weapon layers. When `player.gd` loads equipment, the sprite updates in real-time across all 8 walking and standing directions.
- **Player Drop Shadow**: Implemented subtle soft translucent oval drop shadow below feet in `player.gd` `_draw()`:
  ```gdscript
  if not is_prone and not _is_animating_wakeup and current_vehicle == VehicleType.NONE:
      draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
      draw_circle(Vector2(0, -1), 14.0, Color(0.0, 0.0, 0.0, 0.35))
      draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
  ```
  Redrawn dynamically upon vehicle mount/unmount and knockdown states.

### 4.6 Inventory Grid & Equipment Socket Alignment
- **Inventory Grid (5x5 / 5x9)**: Shifted down 4px (`offset_top = 71.0`, `offset_bottom = 377.0`, `position.y = 71.0`) in `scenes/ui/hud.tscn` and `scripts/ui/hud/hud_inventory.gd`. This aligns the 34x34 slot buttons directly into the authentic `Form_RoleStatus_1.bmp` parchment grid lines starting at outer border Y=71, inner divider Y=73..107.
- **Paperdoll Equipment Sockets**: Shifted up 4px in `scripts/ui/hud/hud_character_status.gd`:
  - `head`: `Vector2(83, 96)` (previously `Vector2(83, 100)`)
  - `weapon`: `Vector2(23, 137)` (previously `Vector2(23, 141)`)
  - `wrist`: `Vector2(146, 137)` (previously `Vector2(146, 141)`)
  - `special`: `Vector2(23, 197)` (previously `Vector2(23, 201)`)
  - `body`: `Vector2(146, 197)` (previously `Vector2(146, 201)`)
  - `shoes`: `Vector2(83, 233)` (previously `Vector2(83, 237)`)
  All 6 sockets now align perfectly within the authentic parchment border boxes in `Form_RoleStatus_1.bmp`.

