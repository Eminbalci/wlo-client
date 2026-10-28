extends SceneTree

## Headless Unit & Integration Tests for NPC Ping-Pong Patrol Routes & Heading Restoration

const IsometricMath = preload("res://scripts/map/isometric_math.gd")
const MapData = preload("res://scripts/map/map_data.gd")
const NpcEntity = preload("res://scripts/world/npc.gd")
const MapView = preload("res://scripts/map/map_view.gd")

func _init() -> void:
	print("\n==================================================================")
	print("--- Running Test Suite: NPC Ping-Pong Patrol & Heading Restore ---")
	print("==================================================================\n")
	_run_tests.call_deferred()

func _run_tests() -> void:
	var total_passed: int = 0
	var total_failed: int = 0

	# -------------------------------------------------------------
	# Test 1: 2-Waypoint Ping-Pong Patrol Sequence
	# -------------------------------------------------------------
	print(">>> [TEST 1] Testing 2-Waypoint Ping-Pong Sequence...")
	var npc = NpcEntity.new()
	var steps2: Array[Vector2] = [Vector2(100, 100), Vector2(200, 200)]
	npc.walksteps = steps2
	npc.is_patrol_ping_pong = true
	npc._current_step_idx = 0
	npc._patrol_forward = true

	# Advancements: 0 -> 1 -> 0 -> 1 -> 0 -> 1
	var expected_indices = [1, 0, 1, 0, 1, 0]
	var matched: bool = true
	for exp_idx in expected_indices:
		npc._advance_patrol_step()
		if npc._current_step_idx != exp_idx:
			print("  [FAIL] Expected step idx %d, got %d (forward: %s)" % [exp_idx, npc._current_step_idx, npc._patrol_forward])
			matched = false
			break
	if matched:
		print("  [PASS] 2-Waypoint ping-pong sequence matches 0 <-> 1 oscillation.")
		total_passed += 1
	else:
		total_failed += 1
	npc.free()

	# -------------------------------------------------------------
	# Test 2: 3-Waypoint Ping-Pong Patrol Sequence
	# -------------------------------------------------------------
	print("\n>>> [TEST 2] Testing 3-Waypoint Ping-Pong Sequence...")
	npc = NpcEntity.new()
	var steps3: Array[Vector2] = [Vector2(100, 100), Vector2(200, 200), Vector2(300, 300)]
	npc.walksteps = steps3
	npc.is_patrol_ping_pong = true
	npc._current_step_idx = 0
	npc._patrol_forward = true

	# Starting at 0: 0 -> 1 -> 2 -> 1 -> 0 -> 1 -> 2 -> 1 -> 0
	var expected_3 = [1, 2, 1, 0, 1, 2, 1, 0]
	matched = true
	for exp_idx in expected_3:
		npc._advance_patrol_step()
		if npc._current_step_idx != exp_idx:
			print("  [FAIL] Expected step idx %d, got %d (forward: %s)" % [exp_idx, npc._current_step_idx, npc._patrol_forward])
			matched = false
			break
	if matched:
		print("  [PASS] 3-Waypoint ping-pong sequence matches 0 -> 1 -> 2 -> 1 -> 0 -> 1 -> 2 -> 1 -> 0.")
		total_passed += 1
	else:
		total_failed += 1
	npc.free()

	# -------------------------------------------------------------
	# Test 3: Fallback when is_patrol_ping_pong is false (Standard Cyclic Wrap)
	# -------------------------------------------------------------
	print("\n>>> [TEST 3] Testing Cyclic Wrap when is_patrol_ping_pong = false...")
	npc = NpcEntity.new()
	var steps3_cyclic: Array[Vector2] = [Vector2(100, 100), Vector2(200, 200), Vector2(300, 300)]
	npc.walksteps = steps3_cyclic
	npc.is_patrol_ping_pong = false
	npc._current_step_idx = 0

	var expected_cyclic = [1, 2, 0, 1, 2, 0]
	matched = true
	for exp_idx in expected_cyclic:
		npc._advance_patrol_step()
		if npc._current_step_idx != exp_idx:
			print("  [FAIL] Expected cyclic step idx %d, got %d" % [exp_idx, npc._current_step_idx])
			matched = false
			break
	if matched:
		print("  [PASS] Cyclic modulo wrap functions correctly when is_patrol_ping_pong is disabled.")
		total_passed += 1
	else:
		total_failed += 1
	npc.free()

	# -------------------------------------------------------------
	# Test 4: Single-element and empty walksteps edge cases
	# -------------------------------------------------------------
	print("\n>>> [TEST 4] Testing Single-Element and Empty Walksteps...")
	npc = NpcEntity.new()
	var steps_empty: Array[Vector2] = []
	npc.walksteps = steps_empty
	npc.is_patrol_ping_pong = true
	npc._advance_patrol_step()
	var empty_ok: bool = (npc._current_step_idx == 0)

	var steps_single: Array[Vector2] = [Vector2(50, 50)]
	npc.walksteps = steps_single
	npc._advance_patrol_step()
	var single_ok: bool = (npc._current_step_idx == 0)

	if empty_ok and single_ok:
		print("  [PASS] Empty and single-element walksteps safely remain at index 0.")
		total_passed += 1
	else:
		print("  [FAIL] Empty (%s) or single (%s) index handling error." % [empty_ok, single_ok])
		total_failed += 1
	npc.free()

	# -------------------------------------------------------------
	# Test 5: Obstacle Collision Ping-Pong Turnaround
	# -------------------------------------------------------------
	print("\n>>> [TEST 5] Testing Obstacle Collision Reverse in Patrol...")
	var mdata = MapData.load_map(10001)
	assert(mdata != null, "Map 10001 must load")
	npc = NpcEntity.new()
	npc.map_data = mdata
	# Start at walkable location (1540, 680)
	npc.world_position = Vector2(1540, 680)
	# Waypoints: [walkable(1540, 680), wall(1540, 200)]
	var steps_obs: Array[Vector2] = [Vector2(1540, 680), Vector2(1540, 200)]
	var delays_obs: Array[float] = [1.0, 1.0]
	npc.walksteps = steps_obs
	npc.walkstep_delays = delays_obs
	npc.is_patrol_ping_pong = true
	npc._current_step_idx = 1 # Moving towards wall
	npc._patrol_forward = true
	npc.move_speed = 1000.0

	# Step movement into wall
	npc._process_walksteps(0.1)

	if npc._is_waiting_at_step and npc._current_step_idx == 0 and not npc._patrol_forward:
		print("  [PASS] Obstacle collision reversed patrol direction: step_idx = 0, _patrol_forward = false.")
		total_passed += 1
	else:
		print("  [FAIL] Obstacle collision reversal failed: wait=%s, idx=%d, fwd=%s" % [npc._is_waiting_at_step, npc._current_step_idx, npc._patrol_forward])
		total_failed += 1
	npc.free()

	# -------------------------------------------------------------
	# Test 6: NPC original_heading Caching & restore_facing()
	# -------------------------------------------------------------
	print("\n>>> [TEST 6] Testing NPC original_heading & restore_facing()...")
	var npc_scene = load("res://scenes/world/npc.tscn")
	var npc_inst: NpcEntity = npc_scene.instantiate() as NpcEntity
	npc_inst.heading = IsometricMath.Heading.EAST
	root.add_child(npc_inst)
	await process_frame

	if npc_inst.original_heading == IsometricMath.Heading.EAST:
		print("  [PASS] original_heading correctly initialized from heading on _ready().")
		total_passed += 1
	else:
		print("  [FAIL] original_heading expected %d, got %d" % [IsometricMath.Heading.EAST, npc_inst.original_heading])
		total_failed += 1

	# Turn NPC to SOUTH_WEST (e.g. while talking to player)
	npc_inst.heading = IsometricMath.Heading.SOUTH_WEST
	if npc_inst.heading == IsometricMath.Heading.SOUTH_WEST:
		print("  [PASS] NPC heading successfully rotated to SOUTH_WEST during conversation.")
		total_passed += 1
	else:
		print("  [FAIL] NPC heading rotation failed.")
		total_failed += 1

	# Restore facing
	npc_inst.restore_facing()
	if npc_inst.heading == IsometricMath.Heading.EAST and npc_inst.facing_direction == IsometricMath.Heading.EAST:
		print("  [PASS] restore_facing() restored NPC orientation back to original EAST heading.")
		total_passed += 1
	else:
		print("  [FAIL] restore_facing() failed: heading=%d, facing_direction=%d" % [npc_inst.heading, npc_inst.facing_direction])
		total_failed += 1
	npc_inst.queue_free()
	await process_frame

	# -------------------------------------------------------------
	# Test 7: MapView Dialogue Interaction & Automatic Facing Restoration
	# -------------------------------------------------------------
	print("\n>>> [TEST 7] Testing MapView Dialogue Close Automatic Facing Restoration...")
	var mv_scene = load("res://scenes/world/map_view.tscn")
	var map_view = mv_scene.instantiate()
	root.add_child(map_view)
	await process_frame

	# Player position at (100, 100)
	if map_view.player:
		map_view.player.world_position = Vector2(100, 100)

	# Instantiate NPC at (150, 100) facing NORTH (heading 0)
	var test_npc: NpcEntity = npc_scene.instantiate() as NpcEntity
	test_npc.npc_name = "Deck Officer"
	test_npc.npc_id = 9999
	test_npc.world_position = Vector2(150, 100)
	test_npc.heading = IsometricMath.Heading.NORTH
	map_view.entities.add_child(test_npc)
	await process_frame

	# Verify initial heading
	assert(test_npc.original_heading == IsometricMath.Heading.NORTH, "NPC original_heading must be NORTH")

	# Trigger interaction
	map_view.interact_with_npc(test_npc)
	await process_frame

	# NPC should now be facing player (player is to the West/South-West of NPC)
	var talk_heading = test_npc.heading
	if talk_heading != IsometricMath.Heading.NORTH:
		print("  [PASS] NPC rotated to face player during interaction (heading changed from 0 to %d)." % talk_heading)
		total_passed += 1
	else:
		print("  [FAIL] NPC did not turn towards player during interaction.")
		total_failed += 1

	# Conclude dialogue
	map_view._on_dialogue_closed()
	await process_frame

	# Verify facing restored
	if test_npc.heading == IsometricMath.Heading.NORTH:
		print("  [PASS] NPC facing successfully restored to original NORTH heading on dialogue close.")
		total_passed += 1
	else:
		print("  [FAIL] NPC heading not restored on dialogue close: got %d, expected 0 (NORTH)." % test_npc.heading)
		total_failed += 1

	map_view.queue_free()
	await process_frame

	print("\n==================================================================")
	print("--- TEST SUMMARY: %d Passed, %d Failed ---" % [total_passed, total_failed])
	print("==================================================================\n")

	if total_failed == 0:
		print(">>> ALL TESTS PASSED SUCCESSFULLY! <<<\n")
		quit(0)
	else:
		push_error("TEST SUITE FAILED with %d errors" % total_failed)
		quit(1)
