extends SceneTree

func _init() -> void:
	print("--- Running Test Click Navigation ---")
	
	var player_scene = load("res://scenes/world/player.tscn")
	if not player_scene:
		print("FAILED: player.tscn could not be loaded")
		quit(1)
		return
	
	var player = player_scene.instantiate()
	root.add_child(player)
	
	# Initial conditions
	player.world_position = Vector2(1000.0, 1000.0)
	player.is_moving = false
	
	# 1. Test set_target_world_position (click 120 pixels to the right)
	var target = Vector2(1120.0, 1000.0)
	player.set_target_world_position(target)
	
	assert(player.is_moving == true, "Player should be moving after set_target_world_position")
	assert(player.target_world_position == target, "target_world_position should match clicked target")
	print("Pass: Player started moving toward target %s" % target)
	
	# 2. Simulate 5 frames of movement (speed = 120 px/s, delta = 0.1s -> 12 px/frame)
	for i in range(5):
		player._process(0.1)
		var expected_min_x = 1000.0 + (i + 1) * 10.0
		assert(player.world_position.x >= expected_min_x, "Player should be progressing along x axis")
		assert(player.target_world_position == target, "target_world_position must NOT be overwritten by world_position setter!")
		assert(player.is_moving == true, "Player must NOT stop before reaching target! (frame %d)" % i)
	
	print("Pass: Player moved 5 frames without stopping. Current pos: %s, target: %s" % [player.world_position, player.target_world_position])
	
	# 3. Simulate until arrival (remaining distance ~60 px -> ~6 frames of 0.1s)
	for i in range(10):
		player._process(0.1)
		if not player.is_moving:
			break
	
	assert(player.is_moving == false, "Player should stop moving once arrived at target")
	assert(player.world_position.distance_to(target) < 1.0, "Player should have reached target location")
	print("Pass: Player arrived at exact target %s and stopped cleanly." % player.world_position)
	
	# 4. Test teleport_to
	var warp_pos = Vector2(1814.0, 904.0)
	player.teleport_to(warp_pos)
	assert(player.world_position == warp_pos, "teleport_to must set world_position")
	assert(player.target_world_position == warp_pos, "teleport_to must update target_world_position")
	assert(player.is_moving == false, "teleport_to must ensure is_moving is false")
	print("Pass: teleport_to successfully repositioned player without ghost pathing.")
	
	# 5. Test clicking directly on player (dist <= 2.0)
	player.set_target_world_position(warp_pos + Vector2(1.0, 0.5))
	assert(player.is_moving == false, "Clicking within 2px of player must not trigger movement")
	print("Pass: Clicking within 2px correctly sets is_moving = false.")
	
	player.queue_free()
	print("--- ALL CLICK NAVIGATION TESTS PASSED ---")
	quit(0)
