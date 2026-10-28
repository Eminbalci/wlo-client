extends SceneTree

const MapViewScene = preload("res://scenes/world/map_view.tscn")

func _init() -> void:
	print("[Test] Instantiating MapView...")
	var map_view = MapViewScene.instantiate()
	root.add_child(map_view)
	
	await process_frame
	await process_frame
	
	print("[Test] Initial state:")
	print("  Current map_id: ", map_view.map_renderer.current_map_id if map_view.map_renderer else -1)
	print("  Player pos: ", map_view.player.world_position if "world_position" in map_view.player else map_view.player.position)
	
	print("[Test] Calling load_map(12000, Vector2(2346, 1598))...")
	map_view.load_map(12000, Vector2(2346, 1598))
	
	print("[Test] State immediately after load_map:")
	print("  Current map_id: ", map_view.map_renderer.current_map_id if map_view.map_renderer else -1)
	print("  Player pos: ", map_view.player.world_position if "world_position" in map_view.player else map_view.player.position)
	print("  Dynamic portals: ", map_view._dynamic_portals.size())
	for p in map_view._dynamic_portals:
		print("    Portal ID %d (%s) pos: %s target: %d player_inside: %s" % [p.portal_id, p.portal_name, p.position, p.target_map_id, p._player_inside])
	
	# Run a few frames
	for f in range(5):
		await process_frame
		print("[Test] Frame %d: map_id: %d player pos: %s" % [f, map_view.map_renderer.current_map_id, map_view.player.world_position if "world_position" in map_view.player else map_view.player.position])
	
	quit(0)
