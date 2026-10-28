extends SceneTree

func _init() -> void:
	print("Testing ArchiveLoader composite generation across all 14 roles...")
	var game_db_cls = load("res://scripts/database/game_database.gd")
	var game_db = game_db_cls.new()
	root.add_child(game_db)

	var loader_cls = load("res://scripts/core/archive_loader.gd")
	var loader = loader_cls.new()
	root.add_child(loader)
	loader.initialize_archives()

	var success_count := 0
	for r in range(1, 15):
		var frames = loader.get_player_composite_frames(r, {})
		print("Role %2d: %d frames" % [r, frames.size()])
		if frames.size() >= 32:
			success_count += 1
		else:
			print("WARNING: Role %d generated fewer than 32 frames (%d)" % [r, frames.size()])

	print("Success: %d / 14 roles" % success_count)
	quit(0 if success_count == 14 else 1)
