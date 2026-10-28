extends SceneTree

## Automated Test for 8-Directional A* Pathfinding, Multi-Waypoint Kinematics,
## and Vehicle Traversal Gates in Wonderland Online Godot Client.

const IsometricMath = preload("res://scripts/map/isometric_math.gd")
const MapData = preload("res://scripts/map/map_data.gd")
const Pathfinder = preload("res://scripts/map/pathfinder.gd")

func _init() -> void:
	print("=================================================================")
	print("--- Running Test Pathfinder Navigation & Player Kinematics ---")
	print("=================================================================")
	
	# -----------------------------------------------------------------
	# PART 1: A* PATHFINDING AROUND OBSTACLES ON MAP 10001
	# -----------------------------------------------------------------
	print("\n[PART 1] Testing A* Pathfinding around obstacles on Map 10001...")
	
	var map_10001 := MapData.load_map(10001)
	assert(map_10001 != null, "Map 10001 must load from Ground.MMG")
	assert(map_10001.cols > 0 and map_10001.rows > 0, "Map 10001 must have non-zero dimensions")
	print("  PASS: Loaded Map 10001 (cols=%d, rows=%d)" % [map_10001.cols, map_10001.rows])
	
	var pathfinder := Pathfinder.new(map_10001)
	
	# Test 1A: Obstacle corner-cutting prevention on Map 10001
	# Cell (57, 30) [world (1150, 610)] to Cell (58, 31) [world (1170, 630)]
	# Direct diagonal is blocked by solid corner at (58, 30)
	var pos_a := Vector2(1150.0, 610.0)
	var pos_b := Vector2(1170.0, 630.0)
	
	var has_los := pathfinder.has_line_of_sight(pos_a, pos_b, 0)
	assert(has_los == false, "Direct diagonal line of sight must be blocked by corner obstacle")
	print("  PASS: Line of sight correctly blocked across obstacle corner between %s and %s" % [pos_a, pos_b])
	
	var path_around := pathfinder.find_path(pos_a, pos_b, 0)
	assert(not path_around.is_empty(), "Pathfinder must find detour path around obstacle")
	assert(path_around.size() >= 2, "Path must contain at least 2 waypoints (detour + destination)")
	assert(path_around.back() == pos_b, "Final waypoint must match destination")
	
	# Verify all waypoints in path are walkable
	for wp in path_around:
		var cell := Pathfinder.world_to_grid(wp)
		assert(pathfinder.is_cell_traversable(cell, 0), "Waypoint %s must be on a traversable cell" % wp)
	print("  PASS: A* detour found with %d waypoints: %s" % [path_around.size(), path_around])
	
	# Test 1B: Multi-waypoint detour (>= 3 waypoints) across Ship Deck
	# From (57, 30) [world (1150, 610)] to (69, 30) [world (1390, 610)]
	var pos_c := Vector2(1390.0, 610.0)
	var long_path := pathfinder.find_path(pos_a, pos_c, 0)
	assert(long_path.size() >= 3, "Expected at least 3 waypoints for long complex detour, got %d" % long_path.size())
	assert(long_path.back() == pos_c, "Final waypoint of long detour must match destination")
	print("  PASS: Long detour found with %d waypoints: %s" % [long_path.size(), long_path])
	
	# Test 1C: Direct line-of-sight path in open corridor returns single waypoint
	var corridor_start := Vector2(1070.0, 1070.0)
	var corridor_dest := Vector2(1150.0, 1070.0)
	var straight_path := pathfinder.find_path(corridor_start, corridor_dest, 0)
	assert(straight_path.size() == 1, "Straight corridor path should contain exactly 1 waypoint")
	assert(straight_path[0] == corridor_dest, "Single waypoint must equal clicked destination")
	print("  PASS: Open corridor string-pulled directly to 1 waypoint: %s" % straight_path[0])
	
	# -----------------------------------------------------------------
	# PART 2: PLAYER ENTITY FOLLOWING MULTIPLE WAYPOINTS TO DESTINATION
	# -----------------------------------------------------------------
	print("\n[PART 2] Testing PlayerEntity Kinematics & Multi-Waypoint Navigation...")
	
	var player_scene = load("res://scenes/world/player.tscn")
	assert(player_scene != null, "player.tscn must exist and load")
	var player = player_scene.instantiate()
	root.add_child(player)
	
	player.map_data = map_10001
	player.world_position = pos_a
	player.is_moving = false
	
	var heading_changes: Array[int] = []
	player.heading_changed.connect(func(new_heading: int):
		heading_changes.append(new_heading)
	)
	
	# Issue move command requiring 2 waypoints
	var move_ok: bool = player.set_target_world_position(pos_b)
	assert(move_ok == true, "set_target_world_position must succeed for valid path")
	assert(player.is_moving == true, "Player must start moving")
	assert(player._current_waypoints.size() == 2, "Player must store 2 waypoints")
	
	var expected_wp0: Vector2 = player._current_waypoints[0]
	var expected_wp1: Vector2 = player._current_waypoints[1]
	assert(player.target_world_position == expected_wp0, "Player must initially target first waypoint")
	var expected_heading0: int = IsometricMath.get_heading(pos_a, expected_wp0)
	assert(player.current_heading == expected_heading0, "Heading must face first waypoint")
	print("  PASS: Player initialized multi-waypoint transit toward %s facing heading %d" % [expected_wp0, expected_heading0])
	
	# Simulate movement until first waypoint is reached
	# Move speed = 120 px/s, distance between (1990, 530) and (1990, 550) is 20 px -> ~4 frames at delta=0.05
	var frames_count := 0
	while player.target_world_position == expected_wp0 and frames_count < 20:
		player._process(0.05)
		frames_count += 1
	
	assert(player.world_position == expected_wp0, "Player must snap to waypoint 0 upon arrival")
	assert(player._current_waypoints.size() == 1, "Waypoint 0 must be popped from queue")
	assert(player.target_world_position == expected_wp1, "Target must transition to waypoint 1")
	assert(player.is_moving == true, "Player must maintain motion toward next waypoint")
	var expected_heading1: int = IsometricMath.get_heading(expected_wp0, expected_wp1)
	assert(player.current_heading == expected_heading1, "Heading must update to face waypoint 1")
	print("  PASS: Waypoint 0 reached at frame %d; transitioned to waypoint 1 (%s)" % [frames_count, expected_wp1])
	
	# Simulate movement until final destination is reached
	while player.is_moving and frames_count < 50:
		player._process(0.05)
		frames_count += 1
	
	assert(player.is_moving == false, "Player must stop moving once final destination is reached")
	assert(player.world_position == pos_b, "Player must arrive at exact final destination")
	assert(player._current_waypoints.is_empty(), "Waypoint queue must be empty after arrival")
	print("  PASS: Player cleanly arrived at destination %s and stopped motion" % player.world_position)
	
	# Test Teleportation cleans waypoints
	player.set_target_world_position(pos_a)
	assert(player.is_moving == true, "Player should be moving again")
	assert(not player._current_waypoints.is_empty(), "Waypoints must be active")
	var warp_target := Vector2(1500.0, 1000.0)
	player.teleport_to(warp_target)
	assert(player.world_position == warp_target, "teleport_to must set world_position")
	assert(player.target_world_position == warp_target, "teleport_to must set target_world_position")
	assert(player.is_moving == false, "teleport_to must stop motion")
	assert(player._current_waypoints.is_empty(), "teleport_to must clear waypoints")
	print("  PASS: teleport_to correctly resets position, stops movement, and purges waypoints")
	
	# -----------------------------------------------------------------
	# PART 3: VEHICLE TRAVERSAL GATES & FEEDBACK
	# -----------------------------------------------------------------
	print("\n[PART 3] Testing Vehicle Traversal Gates & Signal Emission...")
	
	# Build synthetic terrain map with known obstacle, water, ocean, and mountain tiles
	var gate_map := MapData.new()
	var gate_block := MapData.MapBlock.new()
	gate_block.grid_x = 0
	gate_block.grid_y = 0
	gate_block.block_dim_x = 20
	gate_block.block_dim_y = 10
	gate_block.is_uniform = false
	gate_block.collision_matrix.resize(20 * 10)
	gate_block.collision_matrix.fill(0) # Walkable land
	
	# Tile (1, 1) [world (30, 30)]: Solid Obstacle / Wall (0x01)
	gate_block.collision_matrix[1 * 20 + 1] = MapData.TileCollisionFlags.SOLID_WALL
	# Tile (3, 1) [world (70, 30)]: Water (0x08)
	gate_block.collision_matrix[1 * 20 + 3] = MapData.TileCollisionFlags.WATER
	# Tile (5, 1) [world (110, 30)]: Deep Ocean (0x04)
	gate_block.collision_matrix[1 * 20 + 5] = MapData.TileCollisionFlags.DEEP_OCEAN
	# Tile (7, 1) [world (150, 30)]: Mountain (0x10)
	gate_block.collision_matrix[1 * 20 + 7] = MapData.TileCollisionFlags.MOUNTAIN
	gate_map.blocks.append(gate_block)
	
	player.map_data = gate_map
	player.world_position = Vector2(10.0, 30.0) # On walkable land at (0, 1)
	
	var blocked_events: Array[Dictionary] = []
	player.movement_blocked.connect(func(reason: String, pos: Vector2):
		blocked_events.append({"reason": reason, "pos": pos})
	)
	
	# 3A. Solid Obstacle
	var target_obstacle := Vector2(30.0, 30.0)
	var ok_wall: bool = player.set_target_world_position(target_obstacle)
	assert(ok_wall == false, "Solid wall must block movement")
	assert(player.is_moving == false, "Player must not move when blocked by wall")
	assert(blocked_events.size() == 1, "Expected 1 blocked event")
	assert(blocked_events[0]["reason"] == "Path is blocked by an obstacle.", "Unexpected reason: %s" % blocked_events[0]["reason"])
	print("  PASS: Wall blocks movement: '%s'" % blocked_events[0]["reason"])
	
	# 3B. Foot on Water (direct gate check without fallback)
	blocked_events.clear()
	var target_water := Vector2(70.0, 30.0)
	var ok_water_foot: bool = player.set_target_world_position(target_water, false)
	assert(ok_water_foot == false, "Foot on water must be blocked")
	assert(blocked_events.size() == 1, "Expected 1 blocked event")
	assert(blocked_events[0]["reason"] == "You need a vehicle to traverse water!", "Unexpected reason: %s" % blocked_events[0]["reason"])
	print("  PASS: Foot on water blocked: '%s'" % blocked_events[0]["reason"])
	
	# 3C. Mount Raft & cross into Water
	player.mount_vehicle(player.VehicleType.RAFT)
	assert(player.current_vehicle == player.VehicleType.RAFT, "Player must have Raft mounted")
	var ok_water_raft: bool = player.set_target_world_position(target_water)
	assert(ok_water_raft == true, "Raft must traverse water")
	assert(player.is_moving == true, "Player must be moving on raft")
	print("  PASS: Raft successfully navigates to water")
	
	# 3D. Raft on Deep Ocean (direct gate check without fallback)
	blocked_events.clear()
	var target_ocean := Vector2(110.0, 30.0)
	var ok_ocean_raft: bool = player.set_target_world_position(target_ocean, false)
	assert(ok_ocean_raft == false, "Raft must be blocked by deep ocean")
	assert(blocked_events.size() == 1, "Expected 1 blocked event")
	assert(blocked_events[0]["reason"] == "A fragile raft cannot cross deep ocean! You need a ship or advanced vehicle.", "Unexpected reason: %s" % blocked_events[0]["reason"])
	print("  PASS: Raft on deep ocean blocked: '%s'" % blocked_events[0]["reason"])
	
	# 3E. Mount Ship & cross Deep Ocean
	player.mount_vehicle(player.VehicleType.SHIP)
	var ok_ocean_ship: bool = player.set_target_world_position(target_ocean)
	assert(ok_ocean_ship == true, "Ship must traverse deep ocean")
	print("  PASS: Ship successfully navigates to deep ocean")
	
	# 3F. Ship on Mountain (direct gate check without fallback)
	blocked_events.clear()
	var target_mountain := Vector2(150.0, 30.0)
	var ok_mountain_ship: bool = player.set_target_world_position(target_mountain, false)
	assert(ok_mountain_ship == false, "Ship must be blocked by mountain")
	assert(blocked_events.size() == 1, "Expected 1 blocked event")
	assert(blocked_events[0]["reason"] == "You need a flying vehicle to cross this terrain!", "Unexpected reason: %s" % blocked_events[0]["reason"])
	print("  PASS: Mountain blocked without plane: '%s'" % blocked_events[0]["reason"])
	
	# 3G. Mount Plane & fly over Mountain
	player.mount_vehicle(player.VehicleType.PLANE)
	var ok_mountain_plane: bool = player.set_target_world_position(target_mountain)
	assert(ok_mountain_plane == true, "Plane must traverse mountain")
	print("  PASS: Plane successfully navigates over mountain")
	
	# 3H. Authentic Map 10003 Sea Traversal Check (direct gate check without fallback)
	var map_10003 := MapData.load_map(10003)
	assert(map_10003 != null, "Map 10003 must load from Ground.MMG")
	player.map_data = map_10003
	player.dismount_vehicle()
	
	# Cells (50, 5) and (51, 5) are authentic sea tiles (flag 2)
	var sea_start_pos := Vector2(1010.0, 110.0)
	var sea_target_pos := Vector2(1030.0, 110.0)
	player.world_position = sea_start_pos
	
	blocked_events.clear()
	var ok_auth_foot: bool = player.set_target_world_position(sea_target_pos, false)
	assert(ok_auth_foot == false, "Player on foot must be blocked by authentic Map 10003 sea tile")
	assert(blocked_events.size() == 1, "Expected blocked event on authentic sea")
	assert(blocked_events[0]["reason"] == "You need a vehicle to traverse water!", "Reason mismatch: %s" % blocked_events[0]["reason"])
	print("  PASS: Authentic Map 10003 sea tile (%s) correctly gated on foot" % sea_target_pos)
	
	player.mount_vehicle(player.VehicleType.BOAT)
	var ok_auth_boat: bool = player.set_target_world_position(sea_target_pos)
	assert(ok_auth_boat == true, "Player on boat must be allowed onto authentic Map 10003 sea tile")
	assert(player.is_moving == true, "Player on boat should be moving across sea")
	print("  PASS: Boat permitted onto authentic Map 10003 sea tile (%s)" % sea_target_pos)
	
	# -----------------------------------------------------------------
	# PART 4: CLOSEST WALKABLE FALLBACK WHEN DESTINATION IS BLOCKED
	# -----------------------------------------------------------------
	print("\n[PART 4] Testing Pathfinder Closest Walkable Fallback Navigation...")
	player.map_data = map_10001
	player.dismount_vehicle()
	# Start on Ship Deck at (69, 30) -> world (1390, 610)
	player.world_position = pos_c
	player.is_moving = false
	player._current_waypoints.clear()
	
	# Wall / Obstacle at (58, 30) -> world (1170, 610)
	var obstacle_pos := Vector2(1170.0, 610.0)
	var obs_cell := Pathfinder.world_to_grid(obstacle_pos)
	assert(pathfinder.is_cell_traversable(obs_cell, 0) == false, "Tile (58, 30) must be a solid obstacle")
	
	# Calling set_target_world_position(obstacle_pos) with default allow_fallback=true
	# Must find path to the closest walkable cell adjacent to obstacle
	var fallback_move_ok: bool = player.set_target_world_position(obstacle_pos)
	assert(fallback_move_ok == true, "set_target_world_position on obstacle must succeed via closest walkable fallback")
	assert(player.is_moving == true, "Player must begin moving toward closest walkable position")
	assert(player._current_waypoints.size() > 0, "Waypoints must be generated to closest position")
	var final_wp: Vector2 = player._current_waypoints.back()
	var final_cell: Vector2i = Pathfinder.world_to_grid(final_wp)
	assert(pathfinder.is_cell_traversable(final_cell, 0) == true, "Final waypoint must be a traversable cell")
	var cell_dist := maxi(absi(final_cell.x - obs_cell.x), absi(final_cell.y - obs_cell.y))
	assert(cell_dist <= 2, "Fallback destination must be adjacent to clicked obstacle, got %d" % cell_dist)
	print("  PASS: Clicking obstacle (%s) from %s redirected path to closest walkable cell %s (world %s)" % [obs_cell, pos_c, final_cell, final_wp])
	
	# Verify that if player is ALREADY at the closest reachable cell, clicking obstacle emits blocked signal
	player.world_position = final_wp
	player.is_moving = false
	player._current_waypoints.clear()
	blocked_events.clear()
	var already_there_ok: bool = player.set_target_world_position(obstacle_pos)
	assert(already_there_ok == false, "Clicking obstacle when already at closest position must return false")
	assert(player.is_moving == false, "Player must not move when already at closest position")
	assert(blocked_events.size() == 1, "movement_blocked signal must be emitted when already at closest point")
	assert(blocked_events[0]["reason"] == "Path is blocked by an obstacle.", "Reason must be obstacle blocked")
	print("  PASS: Re-clicking obstacle when already at closest cell safely emits blocked signal")
	
	player.queue_free()
	print("\n=================================================================")
	print("--- ALL PATHFINDER NAVIGATION & PLAYER KINEMATICS TESTS PASSED ---")
	print("=================================================================")
	quit(0)
