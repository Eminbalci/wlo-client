# NPC Animation, Patrol Direction & Foot Drop Shadow Specification

## Overview
This specification details the authentic animation frame indexing, kinematics direction mapping, and ground projection geometry for 2:1 axonometric entities in Wonderland Online.

## 1. 32-Frame NPC Animation Architecture (1037.jmp, 1038.jmp)
Authentic 32-frame NPC sprites (e.g., Captain Robinson `1038.jmp`, Deck Crew `1037.jmp`) are organized as 4 diagonal isometric directions, partitioned into two distinct banks:
- **Walk Bank (Frames 0..15):** 4 diagonal directions * 4 frames cycle (walking steps).
- **Stand Bank (Frames 16..31):** 4 diagonal directions * 4 frames cycle (idle standing / breathing).

### Heading to Diagonal Index Mapping
In 2:1 axonometric projection, 8-directional headings snap to the 4 authentic diagonal rows:
- `Heading.SOUTH_WEST` (3) / `Heading.WEST` (2) -> Diagonal Index `0`
- `Heading.NORTH_WEST` (1) / `Heading.NORTH` (0) -> Diagonal Index `1`
- `Heading.NORTH_EAST` (7) / `Heading.EAST` (6) -> Diagonal Index `2`
- `Heading.SOUTH_EAST` (5) / `Heading.SOUTH` (4) -> Diagonal Index `3`

### Frame Index Computation Formula
```gdscript
var diag_idx: int = 0
match heading % 8:
	IsometricMath.Heading.SOUTH_WEST, IsometricMath.Heading.WEST:
		diag_idx = 0
	IsometricMath.Heading.NORTH_WEST, IsometricMath.Heading.NORTH:
		diag_idx = 1
	IsometricMath.Heading.NORTH_EAST, IsometricMath.Heading.EAST:
		diag_idx = 2
	IsometricMath.Heading.SOUTH_EAST, IsometricMath.Heading.SOUTH:
		diag_idx = 3

if is_moving:
	var base: int = diag_idx * 4
	var sub_idx: int = int(_anim_frame_timer * 6.0) % 4
	return (base + sub_idx) % total_frames
else:
	var base: int = 16 + diag_idx * 4
	var sub_idx: int = int(_anim_frame_timer * 1.5) % 4
	return (base + sub_idx) % total_frames
```

## 2. Captain Robinson Stationary Bridge Parity
In `scripts/tools/npc_editor.gd`:
- Captain Robinson's preset `BUILTIN_PRESETS["Captain Robinson"]` default patrol steps were corrected from `[Vector2(1720, 906), Vector2(1780, 930)]` to `[]` (`walksteps = []`, `walkstep_delays = []`).
- Added `is_preview_walking: bool = false` toggle property with `toggle_preview_walk()` and `set_preview_walking()`. When not previewing walk or paused, preview uses the standing frame bank (`16 + diag_idx * 4`), preventing in-place walking during stationarity.

## 3. Patrol Direction Kinematics
In `scripts/world/npc.gd`:
- When traversing waypoints in `_process_walksteps()`, heading is computed directly from current position towards waypoint target:
  `heading = IsometricMath.get_heading(world_position, target)`
- When reaching waypoints or waiting (`_is_waiting_at_step`), `is_moving` is immediately set to `false`, `_anim_frame_timer` is reset to `0.0`, and `_update_frame()` triggers an instantaneous transition to the idle standing frame.

## 4. Foot Drop Shadow Projection
To match authentic client visuals, entities cast a 2:1 axonometric oval drop shadow beneath the feet:
- **Geometry:** 2:1 axonometric ellipse drawn at `(0, 0)` with radii `rx = 14.0 px`, `ry = 7.0 px`.
- **Color:** Translucent black `Color(0.0, 0.0, 0.0, 0.35)`.
- **Layering:** Rendered in `_draw()` on `Node2D` preceding child sprite draw calls, seamlessly anchoring grounded characters without foot floating.
- **States:** Suppressed when prone or wakeup animating in `player.gd`.
