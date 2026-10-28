extends SceneTree

func _init() -> void:
	var dir_queue = ["res://scripts", "res://tests", "res://scenes"]
	var error_files = []
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
			elif fname.ends_with(".gd"):
				checked_count += 1
				var full_res = dir_path + "/" + fname
				var res = ResourceLoader.load(full_res)
				if res == null:
					error_files.append(full_res)
					print("[ERROR LOAD] ", full_res)
			fname = dir.get_next()
		dir.list_dir_end()
	
	print("\n--- SYNTAX / LOAD AUDIT SUMMARY ---")
	print("Checked files: ", checked_count)
	print("Error files: ", error_files.size())
	for ef in error_files:
		print("  -> ", ef)
	quit(0 if error_files.is_empty() else 1)
