extends SceneTree

func _init() -> void:
	print("--- Running Test Map Navigation Integration ---")
	
	var map_view_scene = load("res://scenes/world/map_view.tscn")
	if not map_view_scene:
		print("FAILED: map_view.tscn could not be loaded")
		quit(1)
		return
	
	var map_view = map_view_scene.instantiate()
	root.add_child(map_view)
	
	# Allow ready to fire
	await process_frame
	
	var player = map_view.get_node_or_null("Entities/Player")
	assert(player != null, "Player must exist in MapView")
	var map_renderer = map_view.get_node_or_null("MapRenderer")
	assert(map_renderer != null, "MapRenderer must exist in MapView")
	
	# Test 1: Simulate click via tile_clicked signal along walkable deck corridor (y=1070)
	player.world_position = Vector2(1070.0, 1070.0)
	var start_pos: Vector2 = player.world_position
	var click_dest: Vector2 = Vector2(1150.0, 1070.0)
	print("Testing single-click navigation from %s to %s..." % [start_pos, click_dest])
	
	map_renderer.tile_clicked.emit(click_dest)
	assert(player.is_moving == true, "Player should be moving after tile_clicked emitted")
	assert(player.target_world_position == click_dest, "Player target should match clicked destination")
	
	# Simulate 15 frames
	for f in range(15):
		await process_frame
		assert(player.is_moving == true, "Player must remain in motion towards destination (frame %d)" % f)
	
	print("Player in transit, current position: %s" % player.world_position)
	assert(player.world_position.distance_to(start_pos) > 20.0, "Player must have traversed distance")
	
	# Test 2: Simulate continuous mouse hold & drag along walkable corridor
	var drag_dest: Vector2 = Vector2(1190.0, 1070.0)
	print("Testing continuous mouse follow redirected to %s..." % drag_dest)
	map_renderer.tile_clicked.emit(drag_dest)
	assert(player.target_world_position == drag_dest, "Target must seamlessly update to dragged location")
	assert(player.is_moving == true, "Player should maintain movement while dragged")
	
	for f in range(10):
		await process_frame
	
	# Test 3: Warp to Cabin via portal and check that player doesn't ghost-path
	var cabin_coords = Vector2(674.0, 1067.0)
	print("Triggering warp to 10002...")
	map_view._on_portal_triggered(null, 10002, cabin_coords)
	await process_frame
	print("After warp: map_renderer.current_map_id = ", map_renderer.current_map_id, " player.world_position = ", player.world_position, " is_moving = ", player.is_moving)
	
	assert(map_renderer.current_map_id == 10002, "MapRenderer should load Map 10002")
	assert(player.world_position == cabin_coords, "Player must be at cabin spawn coordinates")
	assert(player.is_moving == false, "Player must not be moving immediately after warp")
	assert(map_renderer._is_mouse_held == false, "Mouse hold state must be reset on warp")
	
	print("Pass: Warp to Cabin (10002) completed cleanly at %s." % player.world_position)
	
	map_view.queue_free()
	print("--- ALL MAP NAVIGATION INTEGRATION TESTS PASSED ---")
	quit(0)
