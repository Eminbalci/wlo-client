# Radar & Minimap Buttons Verification Specification

## Overview
This specification details the functional requirements, implementation design, and verification suite for the Radar / Minimap dock in Wonderland Online client (`scripts/ui/hud.gd`, `scenes/ui/hud.tscn`).

---

## Button & Feature Specifications

### 1. Zoom In (+) Button
- **Functionality**: Zooms the radar/minimap view in by a valid scale increment (e.g. `1.25x`), clamping to a maximum zoom factor (e.g. `2.0x`).
- **Implementation**: Adjusts the scale / transform of `MinimapView` or zoom multiplier variable within `HUD`.

### 2. Zoom Out (-) Button
- **Functionality**: Zooms the radar/minimap view out by a valid scale increment (e.g. `0.8x`), clamping to a minimum zoom factor (e.g. `1.0x`).
- **Implementation**: Adjusts the scale / transform of `MinimapView` or zoom multiplier variable within `HUD`.

### 3. Toggle Style / Collapse Button
- **Functionality**: Toggles the visibility or display style mode of the minimap dock (`RadarMinimapDock`).
- **Implementation**: Linked to `toggle_minimap()` in [`hud.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/ui/hud.gd), toggling `minimap_dock.visible`.

### 4. Player Coordinate Readout Update
- **Functionality**: Continuously updates `CoordinatesLabel` with the player's current world coordinates `(X, Y)` and repositions the player indicator dot proportionally.
- **Implementation**: Handled via [`update_coordinates(world_pos)`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/ui/hud.gd#L1824) and [`_update_marker_position()`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/ui/hud.gd#L1772).

### 5. Clicking on Minimap (Waypoints / Pathfinding)
- **Functionality**: Allows the player to click anywhere on the minimap view to set a movement waypoint or pathfinding destination on the world map.
- **Implementation**: Handled via [`_on_minimap_gui_input()`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/ui/hud.gd#L1746), emitting `minimap_clicked(norm_pos)` with normalized `[0.0..1.0]` coordinates.

---

## Verification Test Suite
- Executed via headless Godot runner:
  `C:\Godot\godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client tests/test_radar_minimap.gd`
- Validated via [`test_radar_minimap.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/tests/test_radar_minimap.gd).
