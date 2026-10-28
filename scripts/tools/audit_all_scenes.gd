extends SceneTree

func _init() -> void:
	var dir_queue = ["res://scenes"]
	var error_scenes = []
	var checked_count = 0
	
	while not dir_queue.is_empty():
		var dir_path = dir_queue.pop_front()
		var dir = DirAccess.open(dir_path)
		if not dir:
			continue
		dir.list_dir_begin()
		var fname = dir.get_next()
		while fname != "":
			if dir.current_is_dir() and not fname.begins_with("."):
				dir_queue.append(dir_path + "/" + fname)
			elif fname.ends_with(".tscn"):
				checked_count += 1
				var full_res = dir_path + "/" + fname
				var res = ResourceLoader.load(full_res)
				if res == null:
					error_scenes.append(full_res)
					print("[ERROR LOAD SCENE] ", full_res)
			fname = dir.get_next()
		dir.list_dir_end()
	
	print("\n--- SCENE LOAD AUDIT SUMMARY ---")
	print("Checked scenes: ", checked_count)
	print("Error scenes: ", error_scenes.size())
	for es in error_scenes:
		print("  -> ", es)
	quit(0 if error_scenes.is_empty() else 1)
