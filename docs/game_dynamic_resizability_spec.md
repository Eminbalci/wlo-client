# Wonderland Online - Client Dynamic Resizability Specification

## 1. Executive Summary
This document specifies the responsive display stretch architecture, HUD dock anchoring, battle view geometry adaptation, floating window bounds clamping, and camera tracking systems implemented to make the entire Wonderland Online Godot 4 client dynamically resizable across arbitrary window dimensions (from an enforced minimum of 800x600 up to 1080p, 1440p, 4K, and ultrawide resolutions) with strict 1:1 pixel scaling (`stretch/mode="disabled"` and `stretch/aspect="ignore"`). UI elements retain their crisp pixel sizes without proportional scaling or stretching, while corner docks slide responsively along window borders with zero letterboxing.

---

## 2. Display & Stretch Configuration (`project.godot`)

### 2.1 Viewport, Min Size, and Stretch Mode Settings
```ini
[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/size/resizable=true
window/size/min_size=Vector2i(800, 600)
window/stretch/mode="disabled"
window/stretch/aspect="ignore"
```

### 2.2 Mechanism & Behavior
- **Default Viewport Dimensions**: 1280x720 (16:9 base design canvas).
- **Minimum Window Dimension Constraint (`min_size = Vector2i(800, 600)`)**: Enforced at both `ProjectSettings` and root `Window` levels. The user cannot shrink the window below 800x600, guaranteeing that all authentic UI docks (FormTalk 768px width, BattleView 800x600 arena) fit comfortably without layout breakdown. The window can be expanded upwards arbitrarily to 1080p, 1440p, 4K, or ultrawide.
- **`mode="disabled"` (Unscaled 1:1 Pixel Scaling)**: UI elements do NOT shrink, stretch, or downscale proportionally when the window is resized. 1 canvas unit = 1 physical screen pixel. UI art assets, text glyphs, and buttons remain 100% pixel-crisp.
- **`aspect="ignore"`**: The root viewport resolution matches the physical window resolution 1:1 without black bars or letterboxing padding.

---

## 3. HUD Responsive Anchors & Dock Layout (`scenes/ui/hud.tscn`)

The root `HUD` Control is configured with `anchors_preset = 15` (`PRESET_FULL_RECT`), spanning `0.0` to `1.0` in both dimensions (`grow_horizontal = 2`, `grow_vertical = 2`).

### 3.1 Dock Anchor Matrix
| Dock Component | Layout Mode | Preset | Anchors (`left`, `top`, `right`, `bottom`) | Offsets (`left`, `top`, `right`, `bottom`) | Behavior |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`PlayerStatusDock`** | `1` | `0` (Top-Left) | `(0.0, 0.0, 0.0, 0.0)` | `(0.0, 0.0, 241.0, 185.0)` | Pinned to top-left edge; contains HP/SP bars and animated role avatar. |
| **`RadarMinimapDock`** | `1` | `1` (Top-Right) | `(1.0, 0.0, 1.0, 0.0)` | `(-226.0, 0.0, 0.0, 144.0)` | Pinned to top-right edge (`grow_horizontal = 0`); contains radar minimap and controls. |
| **`HotbarDock`** | `1` | `1` (Top-Right) | `(1.0, 0.0, 1.0, 0.0)` | `(-56.0, 163.0, 0.0, 437.0)` | Pinned below minimap on right edge; 8 quick item/skill slots. |
| **`BottomActionDock`** | `1` | `3` (Bottom-Right) | `(1.0, 1.0, 1.0, 1.0)` | `(-282.0, -68.0, 0.0, 0.0)` | Pinned to bottom-right corner (`grow_horizontal = 0, grow_vertical = 0`); 6 circular buttons. |
| **`ChatDock`** | `1` | `2` (Bottom-Left) | `(0.0, 1.0, 0.0, 1.0)` | `(0.0, -25.0, 524.0, 0.0)` | Pinned to bottom-left corner (`grow_vertical = 0`); height 25px. |
| **`DialogueSystem/FormTalk1`**| `1` | `7` (Center-Bottom) | `(0.5, 1.0, 0.5, 1.0)` | `(-384.0, -180.0, 384.0, -11.0)` | Centered horizontally (768px wide) and anchored above screen bottom. |
| **`DialogueSystem/FormTalk3`**| `1` | `7` (Center-Bottom) | `(0.5, 1.0, 0.5, 1.0)` | `(20.0, -360.0, 352.0, -192.0)` | Centered offset right (332px wide) and anchored directly above FormTalk1. |

### 3.2 Floating Window Viewport Clamping (`scripts/ui/hud/hud_window_manager.gd`)
- All 8 floating VCL windows (`CharacterWindow`, `InventoryWindow`, `FightWindow`, `SkillWindow`, `TeamWindow`, `QuestWindow`, `FriendsWindow`, `SystemWindow`) automatically listen to viewport `size_changed` signals via `clamp_open_windows()`.
- When the window is resized downwards to smaller dimensions (e.g., 800x600), any open floating windows are clamped inside the new viewport boundary (`clampf(pos, 0, vp_size - win_size)`), preventing them from being positioned off-screen.

---

## 4. Turn-Based Battle View Responsive Architecture (`scenes/battle/battle_view.tscn`)

### 4.1 Root Control & Full-Rect Expansion
`scenes/battle/battle_view.tscn` root Control:
```tscn
[node name="BattleView" type="Control"]
custom_minimum_size = Vector2(800, 600)
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_battle_view")
```

### 4.2 Dynamic Centering & Docking in `scripts/battle/battle_view.gd`
1. **Field Offset Computation**:
   ```gdscript
   func get_field_offset() -> Vector2:
       return Vector2(maxf(0.0, (size.x - CANVAS_SIZE.x) * 0.5), maxf(0.0, (size.y - CANVAS_SIZE.y) * 0.5))
   ```
2. **Axonometric Slot Position Calculation**:
   ```gdscript
   func get_slot_screen_position(is_enemy: bool, slot: int) -> Vector2:
       var base_pos: Vector2
       if not is_enemy:
           if slot < FRONT_ROW_COUNT:
               base_pos = PLAYER_FRONT_START + PLAYER_STEP * float(slot)
           else:
               base_pos = PLAYER_BACK_START + PLAYER_STEP * float(slot - FRONT_ROW_COUNT)
       else:
           if slot < FRONT_ROW_COUNT:
               base_pos = ENEMY_FRONT_START + ENEMY_STEP * float(slot)
           else:
               base_pos = ENEMY_BACK_START + ENEMY_STEP * float(slot - FRONT_ROW_COUNT)
       return base_pos + get_field_offset()
   ```
3. **Responsive UI Elements**:
   - **`ActionButtonsBar`**: Anchored `PRESET_BOTTOM_RIGHT` (`offset_left = -240.0, offset_top = -100.0, offset_right = -20.0, offset_bottom = -16.0`).
   - **`StatusPanel`**: Anchored `PRESET_BOTTOM_LEFT` (`offset_left = 16.0, offset_top = -125.0, offset_right = 169.0, offset_bottom = -10.0`).
   - **`LogPanel`**: Anchored `PRESET_CENTER_TOP` (`offset_left = -280.0, offset_top = 10.0, offset_right = 280.0, offset_bottom = 42.0`).
   - **Modals (`SkillSelectDialog`, `ItemSelectDialog`, `VictoryDialog`)**: Anchored `PRESET_CENTER` with `grow_horizontal = 2, grow_vertical = 2`.
4. **Layout Synchronization via `NOTIFICATION_RESIZED`**:
   Whenever `size` changes, `_update_layout()` updates all active actor standees and calls `arena_canvas.queue_redraw()` to redraw the 16 diamond polygons and the neutral divider line at the new centered coordinates.

---

## 5. World View Camera2D Limits & Tracking (`scripts/map/map_view.gd`)

### 5.1 Adaptive Limit Expansion (`update_camera_limits()`)
When the viewport is wider or taller than a map (e.g., in 2K or 4K resolutions):
```gdscript
func update_camera_limits() -> void:
    if not camera or not map_renderer:
        return
    var map_size: Vector2 = map_renderer.get_map_pixel_size() if map_renderer.has_method("get_map_pixel_size") else Vector2.ZERO
    if map_size.x <= 0 or map_size.y <= 0:
        return
        
    var vp_size: Vector2 = get_viewport_rect().size if is_inside_tree() else Vector2(1280, 720)
    if vp_size.x <= 0 or vp_size.y <= 0:
        vp_size = Vector2(1280, 720)
        
    if map_size.x < vp_size.x:
        var extra_x: float = (vp_size.x - map_size.x) * 0.5
        camera.limit_left = int(-extra_x)
        camera.limit_right = int(map_size.x + extra_x)
    else:
        camera.limit_left = 0
        camera.limit_right = int(map_size.x)
        
    if map_size.y < vp_size.y:
        var extra_y: float = (vp_size.y - map_size.y) * 0.5
        camera.limit_top = int(-extra_y)
        camera.limit_bottom = int(map_size.y + extra_y)
    else:
        camera.limit_top = 0
        camera.limit_bottom = int(map_size.y)
```

### 5.2 Viewport Resize Listening
`MapView` connects `update_camera_limits()` to both `get_viewport().size_changed` and `get_tree().root.size_changed`, ensuring seamless real-time recalculation of camera limits when resizing the window.

---

## 6. Automated Verification Results

Automated test suite: `res://tests/test_game_resizable.gd` executed via `godot_console.exe --headless`:
```
=================================================================
--- Running Wonderland Online Dynamic Resizability Test Suite ---
=================================================================

>>> [TEST 1] Verifying Display & Stretch Configuration in ProjectSettings...
  Settings: width=1280, height=720, resizable=true, min_size=(800, 600), mode=disabled, aspect=ignore
  PASS: ProjectSettings display stretch & min_size configuration validated.

>>> [TEST 2] Verifying HUD Responsive Docks across Window Resizes...
  Testing HUD at Window (800, 600): Canvas visible rect = (800.0, 600.0), HUD size = (800.0, 600.0)
    [OK] All HUD docks at resolution (800, 600) verified at exact screen boundaries.
  Testing HUD at Window (1024, 768): Canvas visible rect = (1024.0, 768.0), HUD size = (1024.0, 768.0)
    [OK] All HUD docks at resolution (1024, 768) verified at exact screen boundaries.
  Testing HUD at Window (1280, 720): Canvas visible rect = (1280.0, 720.0), HUD size = (1280.0, 720.0)
    [OK] All HUD docks at resolution (1280, 720) verified at exact screen boundaries.
  Testing HUD at Window (1600, 900): Canvas visible rect = (1600.0, 900.0), HUD size = (1600.0, 900.0)
    [OK] All HUD docks at resolution (1600, 900) verified at exact screen boundaries.
  Testing HUD at Window (1785, 895): Canvas visible rect = (1785.0, 895.0), HUD size = (1785.0, 895.0)
    [OK] All HUD docks at resolution (1785, 895) verified at exact screen boundaries.
  Testing HUD at Window (1920, 1080): Canvas visible rect = (1920.0, 1080.0), HUD size = (1920.0, 1080.0)
    [OK] All HUD docks at resolution (1920, 1080) verified at exact screen boundaries.
  Testing HUD at Window (2560, 1440): Canvas visible rect = (2560.0, 1440.0), HUD size = (2560.0, 1440.0)
    [OK] All HUD docks at resolution (2560, 1440) verified at exact screen boundaries.
  Testing HUD at Window (3840, 2160): Canvas visible rect = (3840.0, 2160.0), HUD size = (3840.0, 2160.0)
    [OK] All HUD docks at resolution (3840, 2160) verified at exact screen boundaries.

>>> [TEST 3] Verifying BattleView Responsive Geometry & Action Bars across Resizes...
  Testing BattleView at Window (800, 600): Canvas visible rect = (800.0, 600.0), BattleView size = (800.0, 600.0)
    [OK] BattleView at resolution (800, 600) verified (action bar bottom-right, status bottom-left, arena centered).
  Testing BattleView at Window (1024, 768): Canvas visible rect = (1024.0, 768.0), BattleView size = (1024.0, 768.0)
    [OK] BattleView at resolution (1024, 768) verified (action bar bottom-right, status bottom-left, arena centered).
  Testing BattleView at Window (1280, 720): Canvas visible rect = (1280.0, 720.0), BattleView size = (1280.0, 720.0)
    [OK] BattleView at resolution (1280, 720) verified (action bar bottom-right, status bottom-left, arena centered).
  Testing BattleView at Window (1600, 900): Canvas visible rect = (1600.0, 900.0), BattleView size = (1600.0, 900.0)
    [OK] BattleView at resolution (1600, 900) verified (action bar bottom-right, status bottom-left, arena centered).
  Testing BattleView at Window (1785, 895): Canvas visible rect = (1785.0, 895.0), BattleView size = (1785.0, 895.0)
    [OK] BattleView at resolution (1785, 895) verified (action bar bottom-right, status bottom-left, arena centered).
  Testing BattleView at Window (1920, 1080): Canvas visible rect = (1920.0, 1080.0), BattleView size = (1920.0, 1080.0)
    [OK] BattleView at resolution (1920, 1080) verified (action bar bottom-right, status bottom-left, arena centered).
  Testing BattleView at Window (2560, 1440): Canvas visible rect = (2560.0, 1440.0), BattleView size = (2560.0, 1440.0)
    [OK] BattleView at resolution (2560, 1440) verified (action bar bottom-right, status bottom-left, arena centered).
  Testing BattleView at Window (3840, 2160): Canvas visible rect = (3840.0, 2160.0), BattleView size = (3840.0, 2160.0)
    [OK] BattleView at resolution (3840, 2160) verified (action bar bottom-right, status bottom-left, arena centered).

>>> [TEST 4] Verifying MapView Camera2D Tracking & Adaptive Limit Expansion...
  Testing Camera at Window (800, 600): vp_size=(800.0, 600.0), map_size=(2432.0, 1792.0), limits=[0, 0, 2432, 1792]
    [OK] Camera2D limits and player tracking at resolution (800, 600) verified.
  Testing Camera at Window (1024, 768): vp_size=(1024.0, 768.0), map_size=(2432.0, 1792.0), limits=[0, 0, 2432, 1792]
    [OK] Camera2D limits and player tracking at resolution (1024, 768) verified.
  Testing Camera at Window (1280, 720): vp_size=(1280.0, 720.0), map_size=(2432.0, 1792.0), limits=[0, 0, 2432, 1792]
    [OK] Camera2D limits and player tracking at resolution (1280, 720) verified.
  Testing Camera at Window (1600, 900): vp_size=(1600.0, 900.0), map_size=(2432.0, 1792.0), limits=[0, 0, 2432, 1792]
    [OK] Camera2D limits and player tracking at resolution (1600, 900) verified.
  Testing Camera at Window (1785, 895): vp_size=(1785.0, 895.0), map_size=(2432.0, 1792.0), limits=[0, 0, 2432, 1792]
    [OK] Camera2D limits and player tracking at resolution (1785, 895) verified.
  Testing Camera at Window (1920, 1080): vp_size=(1920.0, 1080.0), map_size=(2432.0, 1792.0), limits=[0, 0, 2432, 1792]
    [OK] Camera2D limits and player tracking at resolution (1920, 1080) verified.
  Testing Camera at Window (2560, 1440): vp_size=(2560.0, 1440.0), map_size=(2432.0, 1792.0), limits=[-64, 0, 2496, 1792]
    [OK] Camera2D limits and player tracking at resolution (2560, 1440) verified.
  Testing Camera at Window (3840, 2160): vp_size=(3840.0, 2160.0), map_size=(2432.0, 1792.0), limits=[-704, -184, 3136, 1976]
    [OK] Camera2D limits and player tracking at resolution (3840, 2160) verified.

=================================================================
--- ALL RESIZABILITY TESTS PASSED (100% ZERO-ERROR) ------------
=================================================================
```
