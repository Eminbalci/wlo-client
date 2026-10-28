extends SceneTree

const ArchiveLoaderScript = preload("res://scripts/core/archive_loader.gd")

func _init() -> void:
	var loader: Node = ArchiveLoaderScript.new()
	root.add_child(loader)
	loader.initialize_archives()
	
	var anim_body = loader.get_jma_animation("004.jma", "4000.jmp")
	var anim_weapon = loader.get_jma_animation("004w.jma", "4040.jmp")
	
	# Let's check each of the 8 directions standing frames:
	# Direction 0 (North): 32..35
	# Direction 1 (North-West): 36..39
	# Direction 2 (West): 40..43
	# Direction 3 (South-West): 44..47
	# Direction 4 (South): 48..51
	# Direction 5 (South-East): 52..55
	# Direction 6 (East): 56..59
	# Direction 7 (North-East): 60..63
	for dir_idx in range(8):
		var frame_idx = 32 + dir_idx * 4
		var fb = anim_body.get_frame(frame_idx)
		var fw = anim_weapon.get_frame(frame_idx)
		var offset_x = (fw.bound_w - 128) / 2
		var offset_y = (fw.bound_h - 128) / 2
		print("Dir %d: Body[%d] piv=(%d,%d) w=%d h=%d | Wep piv=(%d,%d) adj=(%d,%d) w=%d h=%d" % [
			dir_idx, frame_idx, fb.pivot_x, fb.pivot_y, fb.width, fb.height,
			fw.pivot_x, fw.pivot_y, fw.pivot_x - offset_x, fw.pivot_y - offset_y, fw.width, fw.height
		])

	quit()
