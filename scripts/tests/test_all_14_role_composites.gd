extends SceneTree

func _init() -> void:
	print("--- Testing all 14 Role Composites ---")
	var game_db = load("res://scripts/database/game_database.gd").new()
	var loader = load("res://scripts/core/archive_loader.gd").new()
	root.add_child(game_db)
	root.add_child(loader)
	
	for role_id in range(1, 15):
		var frames = loader.get_player_composite_frames(role_id, {})
		var r_name = game_db.get_role(role_id).get("name", "Unknown")
		if frames.is_empty():
			print("[FAIL] Role %d (%s): composite frames is EMPTY!" % [role_id, r_name])
		else:
			print("[PASS] Role %d (%s): %d frames generated, first frame size: %s" % [role_id, r_name, frames.size(), str(frames[0].get_size())])
	
	quit()
