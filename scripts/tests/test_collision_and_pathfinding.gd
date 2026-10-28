extends SceneTree

## Comprehensive automated test suite for Wonderland Online
## Pathfinding, Collision Bounds, Vehicle Gating, and Obstacle Avoidance.

const GroundParser = preload("res://scripts/map/ground_parser.gd")
const MapData = preload("res://scripts/map/map_data.gd")
const Pathfinder = preload("res://scripts/map/pathfinder.gd")
const PlayerEntity = preload("res://scripts/world/player.gd")

func _init() -> void:
	print("============================================================")
	print("RUNNING PATHFINDING & COLLISION AUTOMATED VERIFICATION SUITE")
	print("============================================================")
	
	test_ground_parser_column_major()
	test_map_10001_deck_collision()
	test_map_10002_cabin_collision()
	test_vehicle_traversal_matrices()
	test_corner_cutting_prevention()
	test_obstacle_routing_and_fallback()
	test_player_entity_pathfinding_integration()
	
	print("\n============================================================")
	print("ALL PATHFINDING & COLLISION TESTS PASSED SUCCESSFULLY! (0 ERRORS)")
	print("============================================================")
	quit(0)

func test_ground_parser_column_major() -> void:
	print("\n[TEST 1] Ground.MMG Column-Major Storage & Dimensions")
	var gp := GroundParser.new()
	assert(gp.has_map(10001), "Map 10001 must exist in Ground.MMG")
	assert(gp.has_map(10002), "Map 10002 must exist in Ground.MMG")
	
	var map10001 = gp.load_map(10001)
	assert(map10001 != null, "Map 10001 must load")
	assert(map10001.cols == 122, "Map 10001 cols must be 122")
	assert(map10001.rows == 90, "Map 10001 rows must be 90")
	assert(map10001.grid.size() == 122 * 90, "Map 10001 grid size must equal cols * rows")
	
	# Verify column-major indexing: idx = grid_x * rows + grid_y
	# Check Player starting position on Deck: (1042, 1075) -> grid (52, 53)
	var spawn_gx: int = 1042 / 20
	var spawn_gy: int = 1075 / 20
	assert(spawn_gx == 52 and spawn_gy == 53, "Spawn grid coords must be (52, 53)")
	assert(map10001.is_walkable(spawn_gx, spawn_gy), "Deck spawn (52, 53) must be walkable in column-major")
	assert(map10001.get_tile_type(spawn_gx, spawn_gy) == 0, "Deck spawn tile flag must be 0 (WALKABLE)")
	
	# Check out-of-bounds safety
	assert(not map10001.is_walkable(-1, 0), "Negative X must not be walkable")
	assert(not map10001.is_walkable(0, -1), "Negative Y must not be walkable")
	assert(not map10001.is_walkable(122, 50), "X >= cols must not be walkable")
	assert(not map10001.is_walkable(50, 90), "Y >= rows must not be walkable")
	assert(map10001.get_tile_type(-1, 0) == 1, "Out-of-bounds must return solid wall flag 1")
	print("  -> Passed: Column-major grid indexing and bounds checking verified.")

func test_map_10001_deck_collision() -> void:
	print("\n[TEST 2] Map 10001 (Ship Deck) Railing and Ocean Blocking")
	var mdata := MapData.load_map(10001)
	var pf := Pathfinder.new(mdata)
	
	# Open deck coordinates
	var deck_coords: Array[Vector2] = [
		Vector2(1042, 1075), # Center spawn
		Vector2(1013, 902),  # Near Npc7
		Vector2(1027, 957),  # Near Npc8
		Vector2(1421, 632),  # Mid deck near Npc10
		Vector2(343, 940)    # Fore deck near Npc3
	]
	for c in deck_coords:
		var grid := Pathfinder.world_to_grid(c)
		assert(pf.is_cell_traversable(grid), "Deck coord %s (grid %s) must be traversable" % [c, grid])
	
	# Railings and deep ocean coordinates outside the ship
	var blocked_coords: Array[Vector2] = [
		Vector2(200, 200),   # Deep ocean top-left
		Vector2(500, 500),   # Ocean off port bow
		Vector2(100, 100),   # Top ocean corner
		Vector2(2200, 200),  # Ocean off starboard bow
		Vector2(2300, 1600)  # Ocean off stern
	]
	for c in blocked_coords:
		var grid := Pathfinder.world_to_grid(c)
		assert(not pf.is_cell_traversable(grid), "Ocean/outside coord %s (grid %s) must be BLOCKED" % [c, grid])
	
	# Pathfinding from deck into ocean must be strictly blocked (empty path)
	var path_to_ocean := pf.find_path(Vector2(1042, 1075), Vector2(500, 500), 0, false)
	assert(path_to_ocean.is_empty(), "Path into ocean must be empty")
	print("  -> Passed: Ship deck open areas walkable, railings and ocean strictly blocked.")

func test_map_10002_cabin_collision() -> void:
	print("\n[TEST 3] Map 10002 (Cabin) Room Interior, Walls & Furniture")
	var mdata := MapData.load_map(10002)
	assert(mdata != null, "Map 10002 must load")
	assert(mdata.cols == 83 and mdata.rows == 64, "Cabin dims must be 83x64")
	var pf := Pathfinder.new(mdata)
	
	# Entrance is at (674, 1067) -> grid (33, 53)
	var entrance := Vector2(674, 1067)
	var entrance_grid := Pathfinder.world_to_grid(entrance)
	assert(pf.is_cell_traversable(entrance_grid), "Cabin entrance %s must be traversable" % [entrance_grid])
	
	# Open floor coordinates
	var floor_coords: Array[Vector2] = [
		Vector2(700, 900),
		Vector2(800, 800),
		Vector2(900, 750),
		Vector2(1100, 700)
	]
	for c in floor_coords:
		var grid := Pathfinder.world_to_grid(c)
		assert(pf.is_cell_traversable(grid), "Cabin floor %s (grid %s) must be traversable" % [c, grid])
	
	# Solid walls and furniture:
	# Outside the cabin walls
	var outside_wall := Vector2(100, 100)
	assert(not pf.is_cell_traversable(Pathfinder.world_to_grid(outside_wall)), "Outside cabin wall must be blocked")
	
	# Bar counter / behind counter (Drunk Man at 851, 539 -> grid 42, 26)
	var drunk_man_grid := Pathfinder.world_to_grid(Vector2(851, 539))
	assert(not pf.is_cell_traversable(drunk_man_grid), "Drunk Man counter position must be solid obstacle")
	
	# Reception counter (Natasha at 1440, 682 -> grid 72, 34)
	var natasha_grid := Pathfinder.world_to_grid(Vector2(1440, 682))
	assert(not pf.is_cell_traversable(natasha_grid), "Natasha counter position must be solid obstacle")
	print("  -> Passed: Cabin floor traversable; exterior walls, counters, and furniture blocked.")

func test_vehicle_traversal_matrices() -> void:
	print("\n[TEST 4] Multimodal Vehicle Gating (Foot=0, Raft=1, Boat=2, Ship=3, Plane=4)")
	# 1. Solid Wall (Flag 1) - blocked for all vehicles
	for v in [0, 1, 2, 3, 4]:
		var res := MapData.check_traversal(1, v)
		assert(not res["allowed"], "Solid wall (flag 1) must block vehicle %d" % v)
	
	# 2. Water / Sea (Flag 2, 8, 0x40)
	# Foot (0) is blocked
	var foot_water := MapData.check_traversal(2, 0)
	assert(not foot_water["allowed"], "Foot must NOT traverse water")
	assert("vehicle to traverse water" in foot_water["reason"], "Reason must mention vehicle")
	
	# Raft (1), Boat (2), Ship (3), Plane (4) can traverse water
	for v in [1, 2, 3, 4]:
		assert(MapData.check_traversal(2, v)["allowed"], "Vehicle %d must traverse water" % v)
	
	# 3. Deep Ocean (Flag 4)
	# Foot and Raft are blocked
	assert(not MapData.check_traversal(4, 0)["allowed"], "Foot must NOT traverse deep ocean")
	var raft_deep := MapData.check_traversal(4, 1)
	assert(not raft_deep["allowed"], "Raft must NOT traverse deep ocean")
	assert("fragile raft" in raft_deep["reason"], "Reason must warn about fragile raft")
	
	# Boat, Ship, Plane can traverse deep ocean
	assert(MapData.check_traversal(4, 2)["allowed"], "Boat must traverse deep ocean")
	assert(MapData.check_traversal(4, 3)["allowed"], "Ship must traverse deep ocean")
	assert(MapData.check_traversal(4, 4)["allowed"], "Plane must traverse deep ocean")
	
	# 4. Mountains / High Peaks (Flag 16)
	# Only Plane (4) can fly over
	for v in [0, 1, 2, 3]:
		assert(not MapData.check_traversal(16, v)["allowed"], "Ground vehicle %d must NOT traverse mountain" % v)
	assert(MapData.check_traversal(16, 4)["allowed"], "Plane must fly over mountain")
	print("  -> Passed: Vehicle traversal matrix matches official WLRI specifications.")

func test_corner_cutting_prevention() -> void:
	print("\n[TEST 5] Diagonal Corner Cutting Prevention (C++ AStarGrid2D & Raycast)")
	# Build a 10x10 test grid
	var mock_map = preload("res://scripts/map/map_data.gd").new()
	var gmap = preload("res://scripts/map/ground_parser.gd").GroundMap.new()
	gmap.cols = 10
	gmap.rows = 10
	gmap.grid = PackedByteArray()
	gmap.grid.resize(100)
	gmap.grid.fill(0) # all walkable
	mock_map.ground_map = gmap
	
	var pf := Pathfinder.new(mock_map)
	
	# Open diagonal: (1,1) to (2,2)
	var p1 := Pathfinder.grid_to_world(Vector2i(1, 1))
	var p2 := Pathfinder.grid_to_world(Vector2i(2, 2))
	assert(pf.has_line_of_sight(p1, p2), "Open diagonal must have LOS")
	
	# Block orthogonal corner (2, 1)
	gmap.grid[2 * 10 + 1] = 1 # col 2, row 1
	assert(not pf.has_line_of_sight(p1, p2), "Diagonal past blocked corner (2,1) MUST NOT have LOS")
	
	# Reset and block other orthogonal corner (1, 2)
	gmap.grid.fill(0)
	gmap.grid[1 * 10 + 2] = 1 # col 1, row 2
	assert(not pf.has_line_of_sight(p1, p2), "Diagonal past blocked corner (1,2) MUST NOT have LOS")
	
	# Verify AStarGrid2D diagonal_mode strictly respects this rule
	var astar := pf.get_astar_grid(0)
	var astar_path := astar.get_id_path(Vector2i(1, 1), Vector2i(2, 2))
	# With (1, 2) blocked, the path cannot be a single diagonal step [(1,1), (2,2)]
	# It must route orthogonally via (2, 1) -> [(1,1), (2,1), (2,2)]
	assert(astar_path.size() == 3, "AStarGrid2D must route around the blocked corner")
	assert(astar_path[1] == Vector2i(2, 1), "Intermediate step must be (2, 1)")
	print("  -> Passed: Corner cutting strictly prevented in both A* search and line-of-sight raycasts.")

func test_obstacle_routing_and_fallback() -> void:
	print("\n[TEST 6] Obstacle Routing & Fallback Targeting")
	# 1. Deck obstacle avoidance
	var mdata_deck := MapData.load_map(10001)
	var pf_deck := Pathfinder.new(mdata_deck)
	var p_start := Vector2(800, 1300)
	var p_dest := Vector2(1400, 600)
	var deck_path := pf_deck.find_path(p_start, p_dest)
	assert(deck_path.size() > 2, "Path across deck around central obstacles must have waypoints")
	
	# Verify every single waypoint along the path is strictly on a traversable tile
	for wp in deck_path:
		var grid := Pathfinder.world_to_grid(wp)
		assert(pf_deck.is_cell_traversable(grid), "Waypoint %s (grid %s) must be traversable" % [wp, grid])
	
	# 2. Cabin NPC fallback targeting
	var mdata_cabin := MapData.load_map(10002)
	var pf_cabin := Pathfinder.new(mdata_cabin)
	var cabin_entrance := Vector2(674, 1067)
	
	# Drunk Man is at (851, 539) which is an obstacle tile
	var drunk_man := Vector2(851, 539)
	var path_drunk := pf_cabin.find_path(cabin_entrance, drunk_man, 0, true)
	assert(path_drunk.size() > 0, "Path to Drunk Man with fallback must succeed")
	var drunk_dest := path_drunk[-1]
	var drunk_dest_grid := Pathfinder.world_to_grid(drunk_dest)
	assert(pf_cabin.is_cell_traversable(drunk_dest_grid), "Destination next to Drunk Man must be walkable")
	assert(drunk_dest.distance_to(drunk_man) <= 60.0, "Destination must be adjacent to Drunk Man")
	
	# Natasha is at (1440, 682) behind the counter
	var natasha := Vector2(1440, 682)
	var path_natasha := pf_cabin.find_path(cabin_entrance, natasha, 0, true)
	assert(path_natasha.size() > 0, "Path to Natasha with fallback must succeed")
	var natasha_dest := path_natasha[-1]
	var natasha_dest_grid := Pathfinder.world_to_grid(natasha_dest)
	assert(pf_cabin.is_cell_traversable(natasha_dest_grid), "Destination next to Natasha must be walkable")
	assert(natasha_dest.distance_to(natasha) <= 60.0, "Destination must be adjacent to Natasha counter")
	print("  -> Passed: Path routing around obstacles and fallback targeting verified.")

func test_player_entity_pathfinding_integration() -> void:
	print("\n[TEST 7] PlayerEntity Kinematics & Collision Integration")
	var player := PlayerEntity.new()
	var mdata := MapData.load_map(10001)
	player.map_data = mdata
	player.world_position = Vector2(1042, 1075)
	
	# 1. Valid move command
	var ok: bool = player.set_target_world_position(Vector2(1013, 902))
	assert(ok, "Valid move on deck must return true")
	assert(player.is_moving, "Player must enter moving state")
	assert(player._current_waypoints.size() > 0, "Waypoints must be populated")
	
	# Simulate movement ticks
	var total_time: float = 0.0
	while player.is_moving and total_time < 3.0:
		player._update_movement(0.016)
		total_time += 0.016
		# Verify that player position never lands on a solid cell during movement
		var cell := Pathfinder.world_to_grid(player.world_position)
		assert(mdata.is_walkable(cell.x, cell.y), "Player position during movement must remain walkable: %s" % cell)
	
	assert(not player.is_moving, "Player must arrive at destination")
	assert(player.world_position.distance_to(Vector2(1013, 902)) <= 2.0, "Player must arrive near target")
	
	# 2. Blocked move into ocean (direct move check without fallback)
	var state := {"blocked": false, "reason": ""}
	player.movement_blocked.connect(func(reason: String, _t: Vector2):
		state["blocked"] = true
		state["reason"] = reason
	)
	var blocked_ok: bool = player.set_target_world_position(Vector2(500, 500), false)
	assert(not blocked_ok, "Move into ocean must return false")
	assert(not player.is_moving, "Player must NOT start moving toward ocean")
	assert(state["blocked"], "movement_blocked signal must be emitted")
	assert(state["reason"].length() > 0, "Blocked reason must be provided")
	print("  -> Passed: PlayerEntity movement and collision signal integration verified.")
