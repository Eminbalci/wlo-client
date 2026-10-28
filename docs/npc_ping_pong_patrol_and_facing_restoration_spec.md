# NPC Ping-Pong Patrol Routes & Dialogue Heading Restoration Specification

## 1. Overview
This specification documents the implementation of authentic back-and-forth ping-pong patrol navigation ("git-gel") and dialogue facing orientation caching/restoration for NPCs in Wonderland Online Godot 4 client.

---

## 2. Ping-Pong Patrol Routing System (`scripts/world/npc.gd`)

### Background
Previously, NPC patrol waypoints advanced via standard modulo arithmetic:
`_current_step_idx = (_current_step_idx + 1) % walksteps.size()`
When reaching the final waypoint of an open route (e.g. `walksteps = [A, B]`), the NPC immediately targeted `A` again, wrapping across the map in a circular loop rather than walking back along the path traversed.

### Architecture & Parameters
- `is_patrol_ping_pong: bool` (default: `true`):
  When enabled, NPCs reverse patrol traversal direction upon reaching route endpoints.
- `_patrol_forward: bool` (default: `true`):
  Internal state variable tracking direction of progression (`true` = forward towards `size - 1`, `false` = backward towards `0`).
- `walksteps: Array[Vector2]`:
  Ordered list of patrol coordinates.
- `_current_step_idx: int`:
  Active target index in `walksteps`.

### Waypoint Advancement Algorithm (`_advance_patrol_step()`)
```gdscript
func _advance_patrol_step() -> void:
	if walksteps.is_empty():
		_current_step_idx = 0
		return
	if not is_patrol_ping_pong:
		_current_step_idx = (_current_step_idx + 1) % walksteps.size()
		return
	if walksteps.size() <= 1:
		_current_step_idx = 0
		return
	if _patrol_forward:
		if _current_step_idx + 1 < walksteps.size():
			_current_step_idx += 1
		else:
			_patrol_forward = false
			_current_step_idx = maxi(0, _current_step_idx - 1)
	else:
		if _current_step_idx - 1 >= 0:
			_current_step_idx -= 1
		else:
			_patrol_forward = true
			_current_step_idx = mini(walksteps.size() - 1, _current_step_idx + 1)
```

### Edge Cases Handled
1. **Empty / 1-Waypoint Route:** `walksteps.size() <= 1` safely retains index `0` without index out-of-bounds.
2. **2-Waypoint Route:** Oscillates strictly: `0 -> 1 -> 0 -> 1 -> 0`.
3. **Multi-Waypoint Route (N > 2):** Traverses `0 -> 1 -> ... -> N-1 -> N-2 -> ... -> 0 -> 1`.
4. **Obstacle Collision:** If a wall or obstacle is encountered, `_process_walksteps()` transitions to waiting state and invokes `_advance_patrol_step()`, reversing navigation away from the blocked path.
5. **Cyclic Route Option:** When `is_patrol_ping_pong = false`, preserves legacy circular wrap for looped perimeter routes.

---

## 3. Dialogue Facing Orientation Restoration (`scripts/world/npc.gd` & `scripts/map/map_view.gd`)

### Background
When a player interacts with an NPC, both the player and the NPC rotate to face each other. After dialogue concludes, stationary NPCs and patrolling NPCs previously remained locked facing the player's last interaction position rather than restoring their authentic facing direction.

### Implementation Details

#### `scripts/world/npc.gd`
- Added `@export var original_heading: int = -1`:
  Stores the authentic default facing direction of the NPC.
- Initialized in `_ready()`:
  ```gdscript
  if original_heading == -1:
      original_heading = heading
  ```
- Added public method `restore_facing() -> void`:
  ```gdscript
  func restore_facing() -> void:
      if original_heading >= 0:
          heading = original_heading
          facing_direction = original_heading
          if _anim_data:
              _update_frame()
  ```

#### `scripts/map/map_view.gd`
- Tracks active speaking NPC:
  `var _active_dialogue_npc: Node2D = null`
- In `interact_with_npc(npc: Node2D)` and `_on_npc_interacted(npc: Node2D)`:
  - Sets `_active_dialogue_npc = npc`.
  - Ensures `original_heading` is cached if uninitialized (`original_heading < 0`).
  - Rotates NPC towards the player.
- In `_on_dialogue_closed() -> void`:
  - Restores `_active_dialogue_npc`:
    ```gdscript
    if _active_dialogue_npc and is_instance_valid(_active_dialogue_npc):
        if _active_dialogue_npc.has_method("restore_facing"):
            _active_dialogue_npc.restore_facing()
        _active_dialogue_npc = null
    ```
  - Sweeps all in-map entities to restore facing for any stationary NPC whose orientation was altered:
    ```gdscript
    if entities:
        for child in entities.get_children():
            if is_instance_valid(child) and child != player and child is NpcEntity:
                if child.has_method("restore_facing") and child.original_heading >= 0 and child.heading != child.original_heading:
                    if not child.is_moving:
                        child.restore_facing()
    ```

---

## 4. Automated Verification Matrix
Verified with headless test suite `tests/test_npc_ping_pong_and_facing_restoration.gd`:
- `[TEST 1]`: 2-Waypoint ping-pong sequence `0 <-> 1` oscillation (PASSED).
- `[TEST 2]`: 3-Waypoint ping-pong sequence `0 -> 1 -> 2 -> 1 -> 0` round trip (PASSED).
- `[TEST 3]`: Cyclic modulo wrap when `is_patrol_ping_pong = false` (PASSED).
- `[TEST 4]`: Single-element and empty walkstep edge cases safely pinned at index 0 (PASSED).
- `[TEST 5]`: Obstacle collision turnaround in ping-pong mode (PASSED).
- `[TEST 6]`: `original_heading` caching on `_ready()` and `restore_facing()` execution (PASSED).
- `[TEST 7]`: Full `MapView` integration: player interaction turn and dialogue close restoration (PASSED).
