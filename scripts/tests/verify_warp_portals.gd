extends SceneTree

func _init() -> void:
	print("[Test] Starting map warp portals verification...")
	var ground_parser = preload("res://scripts/map/ground_parser.gd").new()
	
	var maps_to_test = [12000, 12001, 12002, 12003, 12004, 12005, 10001, 10002, 10003]
	for map_id in maps_to_test:
		var portals = ground_parser.get_map_warp_portals(map_id)
		print("Map %d: found %d portals" % [map_id, portals.size()])
		for p in portals:
			print("  -> Portal ID: %d, Name: %s, Pos: %s, Target: %d, Dest: %s" % [
				p["portal_id"], p["portal_name"], p["world_pos"], p["target_map_id"], p["target_coords"]
			])
			# Check interior bounds safety if interior room
			if map_id in [12001, 12002, 12003, 12004, 12005] or p["target_map_id"] in [12001, 12002, 12003, 12004, 12005]:
				var t_coords = p["target_coords"]
				if t_coords.x > 832 or t_coords.y > 640:
					print("  [WARNING] Portal target coords out of interior bounds: %s" % t_coords)
	
	print("[Test] Verification complete successfully.")
	quit(0)
