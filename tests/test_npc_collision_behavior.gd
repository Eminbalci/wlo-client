extends SceneTree

func _init() -> void:
	print("--- Testing NPC Collision Checking & Walksteps Constraint ---")
	var MapData = load("res://scripts/map/map_data.gd")
	var mdata = MapData.load_map(10001)
	assert(mdata != null, "Map 10001 must load")
	
	var NpcEntity = load("res://scripts/world/npc.gd")
	var npc = NpcEntity.new()
	npc.map_data = mdata
	
	# Place NPC at (1540, 680) which is walkable
	var g_start = MapData.world_to_grid(Vector2(1540, 680))
	assert(mdata.is_walkable(g_start.x, g_start.y, 0), "Start position must be walkable")
	npc.world_position = Vector2(1540, 680)
	
	# Point walkstep into sky/wall: (1540, 200) where Y=200 is solid wall (flag 1)
	var g_wall = MapData.world_to_grid(Vector2(1540, 200))
	assert(not mdata.is_walkable(g_wall.x, g_wall.y, 0), "Y=200 must be non-walkable wall")
	
	var steps: Array[Vector2] = [Vector2(1540, 200), Vector2(1540, 680)]
	var delays: Array[float] = [1.0, 1.0]
	npc.walksteps = steps
	npc.walkstep_delays = delays
	npc.move_speed = 1000.0 # High speed to attempt moving into wall immediately
	
	# Simulate process step
	npc._process_walksteps(0.1)
	
	# Verify that NPC did NOT enter the non-walkable tile!
	var current_grid = MapData.world_to_grid(npc.world_position)
	assert(mdata.is_walkable(current_grid.x, current_grid.y, 0), "NPC must remain in walkable area!")
	assert(npc._is_waiting_at_step == true, "NPC must trigger wait upon detecting collision")
	assert(npc._current_step_idx == 1, "NPC must reverse/advance to next waypoint on obstacle")
	
	print("PASS: NPC collision avoidance verified! NPC stopped before obstacle and reversed waypoint.")
	npc.free()
	quit(0)
