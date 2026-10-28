# Window Interaction, Close Buttons & Equipment Sockets Specification

## Overview
This document specifies the technical implementation, coordinate architecture, and interaction pipeline for Delphi VCL floating windows, close buttons, character status alignment, and equipment sockets in the Godot 4.6 Wonderland Online client (`D:\Godot\WonderlandOnline\wonderland-online-client`).

---

## 1. Floating Window Dragging Architecture

### 1.1 HeaderBar Drag Surface
All 8 floating Delphi VCL windows (`CharacterWindow`, `InventoryWindow`, `SkillWindow`, `TeamWindow`, `QuestWindow`, `FriendsWindow`, `FightWindow`, `SystemWindow`) support smooth window dragging across the viewport:
- **Drag Zone Geometry**: A dedicated `HeaderBar` `Control` node positioned at $X = 0, Y = 0$ with size `Vector2(win.size.x - 44, 45)`.
- **Hit-Box Separation**: The header bar spans $Y = 0..45$ but stops 44px short of the right border to avoid overlapping the top-right ornate close button.
- **Cursor & Mouse Filter**:
  - `HeaderBar.mouse_filter = Control.MOUSE_FILTER_STOP`
  - `HeaderBar.mouse_default_cursor_shape = Control.CURSOR_MOVE`
- **Child Event Passthrough**: Any title labels (such as `TitleLabel`) residing inside or over the header bar have `mouse_filter = Control.MOUSE_FILTER_IGNORE` (`2`) to prevent intercepting mouse input.

### 1.2 Drag State & Viewport Clamping Pipeline
Dragging is coordinated centrally in [hud.gd](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/ui/hud.gd):
```gdscript
var _dragging_window: Control = null
var _drag_offset: Vector2 = Vector2.ZERO

func _start_window_drag(win: Control, global_mouse_pos: Vector2) -> void:
	_dragging_window = win
	_drag_offset = win.global_position - global_mouse_pos
	win.move_to_front()

func _input(event: InputEvent) -> void:
	if _dragging_window:
		if event is InputEventMouseMotion:
			var vp_size: Vector2 = get_viewport_rect().size
			var target_pos: Vector2 = event.global_position + _drag_offset
			var max_x: float = max(0.0, vp_size.x - _dragging_window.size.x)
			var max_y: float = max(0.0, vp_size.y - _dragging_window.size.y)
			_dragging_window.global_position = Vector2(
				clampf(target_pos.x, 0.0, max_x),
				clampf(target_pos.y, 0.0, max_y)
			)
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_dragging_window = null
			get_viewport().set_input_as_handled()
```
- **Clamp Guarantees**: Window origins cannot go below `(0, 0)` or beyond `viewport_size - win.size`, ensuring windows remain 100% visible and interactive at all times.

---

## 2. Close Button Geometry & Texture Slicing

### 2.1 Ornate Hit-Box Positioning
Each floating window incorporates an authentic ornate close button located at the top-right corner of the window frame:
- **Origin**: `Vector2(win.size.x - 40, 6)`
- **Dimensions**: `Vector2(34, 26)`
- **Bitmap Alignment**: In Delphi skin bitmaps (e.g. `Form_RoleStatus_1.bmp`, $386 \times 461$), the pre-printed circular ornate gem occupies $X = 340..382, Y = 0..34$, with its visual center at `(361, 17)`. The button bounds cleanly encompass this ornate motif.
- **Input Properties**:
  - `mouse_filter = Control.MOUSE_FILTER_STOP`
  - `mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND`
- **Signal Binding**: Connected directly to `win.hide()`, triggering the window close callback.

### 2.2 3-State Sliced Textures
The close button uses the authentic 3-state sliced texture `menu/Skins/default/btn_close_s_1.bmp` streamed in-memory via `ArchiveLoader.get_ui_texture()`:
- **Slice Height**: $H / 3 \approx 20\text{px}$ per state.
- **Normal State**: `Y = 0..H/3`
- **Pressed State**: `Y = H/3..2H/3`
- **Hover State**: `Y = 2H/3..H`

---

## 3. Character Status Layout & Gold Positioning

### 3.1 Bitmap Coordinate Forensics (`Form_RoleStatus_1.bmp`)
Forensic scan of the $386 \times 461$ character status skin reveals two distinct layout columns:
1. **Left Column (Pre-printed Blue Labels, $X = 15..45$)**:
   - `HP`: $Y = 276..286$
   - `SP`: $Y = 290..300$
   - `EXP`: $Y = 304..314$
   - `Gold`: $Y = 319..329$
   - `ATK`, `DEF`, `MATK`, `MDEF`, `SPD`: $Y = 337..415$
2. **Right Column (Inventory Grid, $X = 192..362$)**:
   - 45-slot interactive 5x9 item grid spanning $Y = 73..379$.

### 3.2 Value Label Alignment & Formatting
Previously, `GoldLabel` was placed in the bottom-right whitespace (`Vector2(240, 428)`). It has been relocated to match the left-column stat rows:
- **Coordinates**: `offset_left = 48.0, offset_top = 318.0, offset_right = 160.0, offset_bottom = 332.0`
- **Horizontal Alignment**: Aligned with `StatLeftHp`, `StatLeftSp`, and `StatLeftExp` value text ($X = 48$).
- **Formatting**: Formatted as pure numeric string `%d` (e.g. `"500"`) without duplicate `"Gold: "` prefix, directly complementing the pre-printed blue `"Gold"` label on the skin bitmap.

---

## 4. Equipment Socket Architecture & Item Mappings

### 4.1 Coordinate Matrix Around PaperDoll
The 6 equipment sockets are arranged symmetrically around the central PaperDoll ($X = 37..165, Y = 100..269$) in `CharacterWindow`:

| Socket Node | Alias | Coordinates | `equip_pos` | Target Item Type | Starting Gear (Betty) |
|-------------|-------|-------------|-------------|------------------|-----------------------|
| `Slot_head` | `head` | `Vector2(83, 100)` | 1 | Head / Helmet | (Empty) |
| `Slot_weapon` | `hand` | `Vector2(23, 141)` | 3 | Weapons | Iron Sword (`item_id = 20001`) |
| `Slot_wrist` | `arm` | `Vector2(146, 141)` | 4 | Bracers / Gloves | (Empty) |
| `Slot_special` | `special` | `Vector2(23, 201)` | 6 | Rings / Accessories | (Empty) |
| `Slot_body` | `body` | `Vector2(146, 201)` | 2 | Clothes / Armor | Harness Pants (`item_id = 21001`) |
| `Slot_shoes` | `shoes` | `Vector2(83, 237)` | 5 | Shoes / Boots | Pink Shoes (`item_id = 22001`) |

### 4.2 Delphi Skin Pre-Printed Label Alignment
`Form_RoleStatus_1.bmp` features pre-printed socket labels in Chinese:
- Left socket `(23, 141)`: Labeled **手** (`hand`). In Wonderland Online, weapons are equipped to the hand socket.
- Right socket `(146, 141)`: Labeled **臂** (`arm`). Bracers and wrist guards are equipped to the arm socket.
- Aliases are registered in `hud.gd` (`"hand" -> "weapon"`, `"arm" -> "wrist"`) guaranteeing 100% interoperability between binary `equip_pos` indices, visual skin text, and inventory item metadata.

### 4.3 Socket Interaction & Drag-and-Drop Pipeline
Implemented in [equipment_socket_button.gd](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/ui/equipment_socket_button.gd) and [hud.gd](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/ui/hud.gd):
- **Single Left-Click**: Initiates drag-and-drop (`_get_drag_data`). Shows 32x32 item icon following mouse cursor.
- **Double Left-Click**: Unequips item into first free inventory slot.
- **Right-Click**: Direct quick-unequip into inventory.
- **Drop Validation**: `_can_drop_data` verifies item compatibility via `_is_item_compatible_with_socket(item_data, socket_name)`:
  - Validates `wear_slot` from `Item.dat` (or fallback ID ranges: `20000..20999` Weapon, `21000..21999` Body, `22000..22999` Shoes).
  - Swaps existing equipped item back to the originating inventory slot if replacing an item.

---

## 5. Automated Verification & Test Coverage

All interactions are covered by automated headless test suites using `godot_console.exe --headless`:

1. **`scenes/tests/test_hud_runner.tscn`**:
   - Asserts close button presence, dimensions (`Vector2(34, 26)`), and top-right positioning (`win.size.x - 40, 6`) on all 8 floating windows.
   - Asserts `mouse_filter == MOUSE_FILTER_STOP` on close buttons and header bars.
   - Asserts `GoldLabel` position bounds ($X \in [40, 160], Y \in [310, 340]$) and text formatting.
   - Verifies smooth dragging on `CharacterWindow` with displacement offset checks and boundary clamping.
   - Verifies equipment socket coordinates and starter item population (`weapon`, `body`, `shoes`).
2. **`tests/test_equipment_visibility.gd`**:
   - Validates equip/unequip cycles, paper-doll layering, and base nude body permanence.
3. **`tests/test_collision_and_vehicles.gd`**:
   - Validates collision gates, vehicle traversal, and movement validation.
4. **`tests/test_pathfinder_navigation.gd`**:
   - Validates 8-way A* navigation and waypoint smoothing.
5. **`tests/test_portals_and_ground_items.gd`**:
   - Validates MMG warp portals, harvestable ground nodes, and proximity loot pickups.
6. **`tests/test_talk_database.gd`**:
   - Validates dialogue cipher decryption, tokens, emotion bubbles, and portrait extraction.
