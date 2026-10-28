# Pathfinder & Player Kinematics Integration

Technical specification for 8-directional A* pathfinding, string-pulling raycasts, multi-waypoint kinematics, and vehicle traversal gates in Wonderland Online Godot client.

## Overview

The player movement pipeline connects [`PlayerEntity`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/world/player.gd) with [`Pathfinder`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/map/pathfinder.gd) and [`MapData`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/map/map_data.gd), providing seamless navigation around complex obstacles on Ground.MMG maps, corner-cutting prevention, waypoint progression, heading alignment, and authentic vehicle gate enforcement.

## System Architecture

```
User Click / Target Position
           │
           ▼
[PlayerEntity.set_target_world_position(new_target, allow_fallback=true)]
           │
           ├─► If map_data == null: direct linear kinematics to target
           │
           └─► If map_data != null:
                     │
                     ▼
       [Pathfinder.find_path(start, target, vehicle, allow_fallback=true)]
                     │
                     ├─► Check target traversability (is_cell_traversable)
                     ├─► If target cell blocked & allow_fallback:
                     │       └─► find_nearest_walkable_cell(target, start, vehicle, max_radius=20)
                     ├─► Line-of-sight check (has_line_of_sight, corner-cutting prevention)
                     ├─► 8-directional A* search (Octile heuristic, MinHeap open set)
                     ├─► If A* returns empty & allow_fallback:
                     │       └─► Concentric ring search (r=1..20) for closest cell reachable from start
                     └─► String-pulling raycast optimization
                             │
                             ▼
                 Waypoints: Array[Vector2]
                             │
                             ├─► If empty: check target collision byte & vehicle requirements
                             │       └─► If blocked / already at closest point: emit movement_blocked(reason, target) -> return false
                             │
                             └─► If valid path:
                                     ├─► _current_waypoints = path
                                     ├─► target_world_position = _current_waypoints[0]
                                     ├─► is_moving = true
                                     ├─► current_heading = IsometricMath.get_heading(pos, target)
                                     ├─► emit heading_changed
                                     └─► return true
```

## Kinematics & Multi-Waypoint Progression

During `_update_movement(delta: float)`:
1. The character moves along the vector towards `target_world_position` at `move_speed` pixels per second.
2. When `world_position.distance_to(target_world_position) <= move_speed * delta`:
   - `world_position` snaps to `target_world_position`.
   - The completed waypoint is popped from `_current_waypoints` via `pop_front()`.
   - If `_current_waypoints.is_empty()`:
     - `is_moving` is set to `false`.
   - If remaining waypoints exist:
     - `target_world_position` updates to `_current_waypoints[0]`.
     - `current_heading` updates to face the new waypoint via `IsometricMath.get_heading`.
     - `heading_changed.emit(current_heading)` triggers sprite rotation.
3. Instant teleportation via `teleport_to(new_pos)` resets `is_moving = false`, updates `world_position` and `target_world_position`, and purges all active waypoints via `_current_waypoints.clear()`.

## Closest Walkable Fallback Navigation

When the user clicks an impassable obstacle (such as solid walls, rocks, trees, water on foot, or mountains without an aircraft):
1. **Concentric Search Rings:** [`Pathfinder.find_nearest_walkable_cell`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/map/pathfinder.gd) searches up to `max_radius = 20` (400px diameter) in concentric Chebyshev rings around the target cell.
2. **Proximity Prioritization:** Candidate cells in each ring are sorted by proximity to the player's current grid position (`from_cell`), selecting the closest point on the player's approach vector.
3. **Reachable Cell Discovery:** If direct A* to the candidate cell fails (e.g. candidate is enclosed or on an isolated island), [`Pathfinder.find_path`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/map/pathfinder.gd) executes a concentric ring search evaluating reachable candidates via native `_a_star_search(start_cell, cand, vehicle)` until a reachable point is resolved.
4. **Natural Arrival & Obstacle Re-Click Feedback:**
   - The player smoothly routes and walks to the nearest accessible boundary.
   - If the player is already positioned at the closest reachable boundary and clicks the obstacle again, movement safely stops and emits `movement_blocked(reason, target)`.

## Vehicle Traversal Gates

| Vehicle | Terrain Flags Permitted | Blocked Feedback |
| :--- | :--- | :--- |
| **NONE (Foot)** | `WALKABLE` (0x00) | Water: `"You need a vehicle to traverse water!"`<br>Solid Wall: `"Path is blocked by an obstacle."`<br>Mountain: `"You need a flying vehicle to cross this terrain!"` |
| **RAFT** | `WALKABLE`, `WATER` (0x02, 0x08), `SHALLOW_WATER` (0x40) | Deep Ocean: `"A fragile raft cannot cross deep ocean! You need a ship or advanced vehicle."` |
| **BOAT / SHIP** | `WALKABLE`, `WATER`, `DEEP_OCEAN` (0x04) | Mountain: `"You need a flying vehicle to cross this terrain!"` |
| **PLANE** | `WALKABLE`, `WATER`, `DEEP_OCEAN`, `MOUNTAIN` (0x10, 0x80) | Solid Wall: `"Path is blocked by an obstacle."` |

## Verification Suite

Execute automated headless verification:
```powershell
C:\Godot\godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client --script res://tests/test_pathfinder_navigation.gd
```
Coverage includes:
- A* corner obstacle detour routing on Ship Deck (Map 10001).
- Multi-waypoint queue progression, heading rotation, and destination arrival.
- Vehicle gate rejection and permission across foot, raft, boat, ship, and plane terrains.
