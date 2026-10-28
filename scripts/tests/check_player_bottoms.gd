extends SceneTree

func _init() -> void:
	var loader = preload("res://scripts/core/archive_loader.gd").new()
	root.add_child(loader)
	
	for role_id in range(1, 15):
		var frames = loader.get_player_composite_frames(role_id)
		if frames.is_empty():
			continue
		# Stand frames: 32..63
		var min_b = 999
		var max_b = 0
		for i in range(32, min(64, frames.size())):
			var img = frames[i].get_image()
			# find lowest non-transparent pixel
			var lowest_y = 0
			for y in range(img.get_height() - 1, -1, -1):
				var has_pixel = false
				for x in range(img.get_width()):
					if img.get_pixel(x, y).a > 0.1:
						has_pixel = true
						break
				if has_pixel:
					lowest_y = y
					break
			if lowest_y > max_b: max_b = lowest_y
			if lowest_y < min_b: min_b = lowest_y
		print("Role ", role_id, ": stand frames lowest pixel y: min=", min_b, " max=", max_b)
	quit(0)
