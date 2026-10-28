# Technical Documentation: Radar Minimap & Real-Time Player Indicator

## Overview
The Radar Minimap system provides an authentic 1:1 downscaled in-memory visualization of the player's active world map within the 226x144 `RadarMinimapDock` frame. It replaces static placeholder bitmaps with dynamically downscaled map thumbnails and renders a blinking player indicator dot at normalized coordinates.

## Architecture & Component Hierarchy

```
RadarMinimapDock (Control: 226x144, top-right anchor)
├── MinimapView (TextureRect: 212x131 at offset (6, 6), clip_contents=true)
│   └── PlayerMarker (MinimapMarker: Control, blinking circle at normalized pos)
├── MinimapFrame (TextureRect: 226x144, MiniMapForm.bmp with transparent cutout)
├── MapNameLabel (Label: map title e.g. "Ship Deck", "Cabin")
└── CoordinatesLabel (Label: player coordinates e.g. "(1542, 675)")
```

### Components

1. **`ArchiveLoader.get_minimap_texture(scene_id: int) -> ImageTexture`**
   - Retrieves full-resolution background from `map.JMG` (e.g. `10001.jpg`: 2432x1792, `10002.jpg`: 1659x1266).
   - In-memory bilinear downscale via `Image.resize(212, 131, Image.INTERPOLATE_BILINEAR)`.
   - Caches downscaled `ImageTexture` under key `"minimap_%d" % scene_id`. Zero disk writes.
   - Falls back gracefully to legacy candidate bitmaps if map image is absent.

2. **`MinimapMarker` (`scripts/ui/minimap_marker.gd`)**
   - Renders radar blip via canvas drawing (`_draw()`):
     - Drop shadow / contrast border: `draw_circle(Vector2.ZERO, marker_radius + 1.2, border_color)`
     - Core blip: `draw_circle(Vector2.ZERO, marker_radius, marker_color)`
     - Specular highlight: `draw_circle(Vector2(-0.6, -0.6), 1.2, highlight_color)`
   - `set_marker_color(p_color: Color) -> void`: Updates core color and triggers `queue_redraw()`.

3. **`HUD` (`scripts/ui/hud.gd`)**
   - `update_minimap(map_texture: Texture2D = null, player_norm_pos: Vector2 = Vector2(-1, -1)) -> void`: Updates viewport texture and/or normalized player position.
   - `set_map_context(p_map_id: int, p_map_name: String, p_map_size: Vector2 = Vector2.ZERO, p_minimap_tex: Texture2D = null) -> void`: Authoritative map switch updater.
   - `get_minimap_content_rect() -> Rect2`: Computes draw rectangle accounting for both `STRETCH_SCALE` and `STRETCH_KEEP_ASPECT_CENTERED`.
   - `_update_marker_position() -> void`: Projects `current_player_norm_pos` to pixel space within `content_rect`.
   - `_process(delta: float) -> void`: Toggles marker color every 0.25s between neon green `Color(0.15, 0.98, 0.2, 1.0)` and golden yellow `Color(1.0, 0.92, 0.1, 1.0)`.
   - `_on_minimap_gui_input(event: InputEvent) -> void`: Converts viewport click to normalized position and emits `minimap_clicked(norm_pos)`.

4. **`MapRenderer` (`scripts/map/map_renderer.gd`)**
   - Exposes `get_map_texture() -> Texture2D` and `get_map_pixel_size() -> Vector2`.
   - Resolves canonical names (10001: "Ship Deck", 10002: "Cabin", 10003: "Beach") with database fallback.
   - Updates HUD context immediately upon `load_map(map_id)`.

5. **`MapView` (`scripts/map/map_view.gd`)**
   - Listens to `map_renderer.map_loaded` and updates HUD map context and initial normalized position.
   - Listens to `player.position_updated` and calls `hud.update_coordinates(world_pos)`.
   - Hooks `hud.minimap_clicked` to trigger pathfinding towards clicked world coordinates.
   - Updates coordinates on portal transitions in `_on_portal_triggered`.

## Verification & Headless Testing
- Verification suite: `tests/test_radar_minimap.gd`.
- Test execution: `godot_console.exe --headless --path "D:/Godot/WonderlandOnline/wonderland-online-client" -s "res://tests/test_radar_minimap.gd"`.
- Results: All Part 1 (HUD unit tests, marker placement, blinking toggle, click handler) and Part 2 (MapView real-time movement, portal warp to Map 10002 Cabin, texture change assertion) passed with zero errors.
