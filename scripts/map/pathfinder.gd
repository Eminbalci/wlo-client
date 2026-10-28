class_name Pathfinder
extends RefCounted

## 8-directional A* Pathfinding Engine for Wonderland Online.
## Supports Ground.MMG authentic collision grids, vehicle traversal matrices,
## AStarGrid2D C++ native acceleration, corner-cutting prevention, obstacle fallback targeting,
## and raycast string-pulling smoothing.

const MapData = preload("res://scripts/map/map_data.gd")

const TILE_SCALE: int = 20
const SQRT_2: float = 1.41421356

# 8 movement directions: 4 orthogonal, 4 diagonal
const NEIGHBORS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
	Vector2i(1, 1),
	Vector2i(1, -1),
	Vector2i(-1, 1),
	Vector2i(-1, -1)
]

var map_data = null
var _astar_grids: Dictionary = {} # vehicle_type (int) -> AStarGrid2D

func _init(p_map_data = null) -> void:
	map_data = p_map_data
	_astar_grids.clear()

## Converts world pixel coordinates to grid coordinates (TILE_SCALE = 20)
static func world_to_grid(pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(pos.x / float(TILE_SCALE))), int(floor(pos.y / float(TILE_SCALE))))

## Converts grid coordinates to world pixel center
static func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2((float(grid_pos.x) + 0.5) * float(TILE_SCALE), (float(grid_pos.y) + 0.5) * float(TILE_SCALE))

## Checks if a grid cell is traversable with the specified vehicle
func is_cell_traversable(cell: Vector2i, vehicle: int = 0) -> bool:
	if map_data == null:
		return true
	if cell.x < 0 or cell.x >= map_data.cols or cell.y < 0 or cell.y >= map_data.rows:
		return false
	var flag: int = map_data.get_collision_byte(cell.x, cell.y)
	return MapData.check_traversal(flag, vehicle)["allowed"]

## Returns or instantiates the cached native AStarGrid2D for the specified vehicle type
func get_astar_grid(vehicle: int = 0) -> AStarGrid2D:
	if _astar_grids.has(vehicle):
		return _astar_grids[vehicle]
	
	if map_data == null or map_data.cols <= 0 or map_data.rows <= 0:
		return null
	
	var astar := AStarGrid2D.new()
	astar.region = Rect2i(0, 0, map_data.cols, map_data.rows)
	astar.cell_size = Vector2(TILE_SCALE, TILE_SCALE)
	astar.offset = Vector2(float(TILE_SCALE) * 0.5, float(TILE_SCALE) * 0.5)
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	
	for x in range(map_data.cols):
		for y in range(map_data.rows):
			var flag: int = map_data.get_collision_byte(x, y)
			var traversable: bool = MapData.check_traversal(flag, vehicle)["allowed"]
			if not traversable:
				astar.set_point_solid(Vector2i(x, y), true)
	
	_astar_grids[vehicle] = astar
	return astar

## Octile distance heuristic for 8-directional movement
func _heuristic(a: Vector2i, b: Vector2i) -> float:
	var dx: float = absf(float(a.x - b.x))
	var dy: float = absf(float(a.y - b.y))
	return (maxf(dx, dy) + (SQRT_2 - 1.0) * minf(dx, dy))

## Finds nearest adjacent walkable cell within max_radius if target is on an obstacle.
## Searches in concentric rings around target_cell, picking candidate closest to from_cell.
func find_nearest_walkable_cell(target_cell: Vector2i, from_cell: Vector2i, vehicle: int = 0, max_radius: int = 20) -> Vector2i:
	if is_cell_traversable(target_cell, vehicle):
		return target_cell
	
	for r in range(1, max_radius + 1):
		var candidates: Array[Vector2i] = []
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var cand := Vector2i(target_cell.x + dx, target_cell.y + dy)
				if is_cell_traversable(cand, vehicle):
					candidates.append(cand)
		
		if not candidates.is_empty():
			var best_cand: Vector2i = candidates[0]
			var min_dist: float = Vector2(best_cand).distance_squared_to(Vector2(from_cell))
			for i in range(1, candidates.size()):
				var d: float = Vector2(candidates[i]).distance_squared_to(Vector2(from_cell))
				if d < min_dist:
					min_dist = d
					best_cand = candidates[i]
			return best_cand
			
	return Vector2i(-1, -1)

## Line of sight raycast: ensures path does not pass through obstacle tiles or cut blocked corners
func has_line_of_sight(from_pos: Vector2, to_pos: Vector2, vehicle: int = 0) -> bool:
	if map_data == null:
		return true
	
	var dist: float = from_pos.distance_to(to_pos)
	if dist < 1.0:
		return true
	
	var start_cell := world_to_grid(from_pos)
	if not is_cell_traversable(start_cell, vehicle):
		return false
	var end_cell := world_to_grid(to_pos)
	if not is_cell_traversable(end_cell, vehicle):
		return false
	
	# Sample along the ray at 2-pixel intervals (1/10 of a 20px tile for zero edge leakage)
	var step_size: float = 2.0
	var steps: int = int(ceil(dist / step_size))
	var dir: Vector2 = (to_pos - from_pos).normalized()
	
	var prev_cell := start_cell
	for i in range(1, steps):
		var pt: Vector2 = from_pos + dir * (float(i) * step_size)
		var cell := world_to_grid(pt)
		if cell != prev_cell:
			# Diagonal corner cutting prevention: orthogonal neighbors must both be traversable
			if cell.x != prev_cell.x and cell.y != prev_cell.y:
				var ortho1 := Vector2i(cell.x, prev_cell.y)
				var ortho2 := Vector2i(prev_cell.x, cell.y)
				if not is_cell_traversable(ortho1, vehicle) or not is_cell_traversable(ortho2, vehicle):
					return false
			if not is_cell_traversable(cell, vehicle):
				return false
			prev_cell = cell
			
	if end_cell != prev_cell:
		if end_cell.x != prev_cell.x and end_cell.y != prev_cell.y:
			var ortho1 := Vector2i(end_cell.x, prev_cell.y)
			var ortho2 := Vector2i(prev_cell.x, end_cell.y)
			if not is_cell_traversable(ortho1, vehicle) or not is_cell_traversable(ortho2, vehicle):
				return false
				
	return true

## Optimizes waypoints via raycast string-pulling, removing redundant zigzag waypoints across open space
func string_pull(waypoints: Array[Vector2], vehicle: int = 0) -> Array[Vector2]:
	if waypoints.size() <= 2:
		if waypoints.size() == 2:
			if waypoints[0].distance_to(waypoints[1]) < 1.0:
				return []
			return [waypoints[1]]
		return waypoints
	
	var smoothed: Array[Vector2] = []
	var current_idx: int = 0
	
	while current_idx < waypoints.size() - 1:
		var farthest_idx: int = current_idx + 1
		for test_idx in range(waypoints.size() - 1, current_idx, -1):
			if has_line_of_sight(waypoints[current_idx], waypoints[test_idx], vehicle):
				farthest_idx = test_idx
				break
		
		smoothed.append(waypoints[farthest_idx])
		current_idx = farthest_idx
	
	return smoothed

## Core 8-directional A* search powered by AStarGrid2D
func _a_star_search(start_cell: Vector2i, target_cell: Vector2i, vehicle: int = 0) -> Array[Vector2i]:
	if start_cell == target_cell:
		return [start_cell]
	
	var astar := get_astar_grid(vehicle)
	if astar:
		var id_path: Array[Vector2i] = astar.get_id_path(start_cell, target_cell)
		return id_path
	
	return []

## Main entrypoint: computes smooth 8-directional path from start_pos to target_pos
func find_path(start_pos: Vector2, target_pos: Vector2, vehicle: int = 0, allow_fallback: bool = true) -> Array[Vector2]:
	if start_pos.distance_to(target_pos) < 2.0:
		return []
	
	var start_cell := world_to_grid(start_pos)
	var orig_target_cell := world_to_grid(target_pos)
	var target_cell := orig_target_cell
	
	# If start cell is not traversable, find nearest walkable
	if not is_cell_traversable(start_cell, vehicle):
		var fallback_start := find_nearest_walkable_cell(start_cell, target_cell, vehicle, 4)
		if fallback_start != Vector2i(-1, -1):
			start_cell = fallback_start
		else:
			return []
	
	var actual_dest_pos: Vector2 = target_pos
	
	# If target cell is an obstacle (e.g. NPC or wall), find nearest adjacent walkable cell
	if not is_cell_traversable(target_cell, vehicle):
		if not allow_fallback:
			return []
		var fallback_target := find_nearest_walkable_cell(target_cell, start_cell, vehicle, 20)
		if fallback_target == Vector2i(-1, -1):
			return []
		target_cell = fallback_target
		actual_dest_pos = grid_to_world(target_cell)
	
	# Quick check: if start and destination share cell
	if start_cell == target_cell:
		if has_line_of_sight(start_pos, actual_dest_pos, vehicle):
			if start_pos.distance_to(actual_dest_pos) >= 2.0:
				return [actual_dest_pos]
		return []
	
	# Quick direct line-of-sight check across open ground
	if has_line_of_sight(start_pos, actual_dest_pos, vehicle):
		return [actual_dest_pos]
	
	# Run A* search on grid
	var cell_path := _a_star_search(start_cell, target_cell, vehicle)
	if cell_path.is_empty() and allow_fallback:
		# Concentric ring search around orig_target_cell for closest cell with a valid A* path from start_cell
		for r in range(1, 21):
			var ring_candidates: Array[Vector2i] = []
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					if maxi(absi(dx), absi(dy)) != r:
						continue
					var cand := Vector2i(orig_target_cell.x + dx, orig_target_cell.y + dy)
					if is_cell_traversable(cand, vehicle) and cand != start_cell:
						ring_candidates.append(cand)
			
			if ring_candidates.is_empty():
				continue
			
			# Sort candidates in ring by distance to start_cell (closer to start first)
			ring_candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
				return Vector2(a).distance_squared_to(Vector2(start_cell)) < Vector2(b).distance_squared_to(Vector2(start_cell))
			)
			
			for cand in ring_candidates:
				var test_path := _a_star_search(start_cell, cand, vehicle)
				if not test_path.is_empty():
					cell_path = test_path
					target_cell = cand
					actual_dest_pos = grid_to_world(target_cell)
					break
			
			if not cell_path.is_empty():
				break
	
	if cell_path.is_empty():
		return []
	
	if cell_path.size() == 1:
		if cell_path[0] == start_cell:
			return []
		return [actual_dest_pos]
	
	# Convert grid cells to world waypoints
	var raw_waypoints: Array[Vector2] = []
	raw_waypoints.append(start_pos)
	for i in range(1, cell_path.size() - 1):
		raw_waypoints.append(grid_to_world(cell_path[i]))
	raw_waypoints.append(actual_dest_pos)
	
	# String-pulling optimization
	return string_pull(raw_waypoints, vehicle)
