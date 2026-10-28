extends SceneTree

func _init() -> void:
	var loader = preload("res://scripts/core/archive_loader.gd").new()
	root.add_child(loader)
	for rid in [1, 2, 6]:
		var frames = loader.get_avatar_frames(rid)
		print("Role %d frames: %d" % [rid, frames.size()])
		if not frames.is_empty():
			var img = frames[0].get_image()
			print("  Role %d frame 0 size: %s" % [rid, img.get_size()])
			img.save_png("test_avatar_role_%d.png" % rid)
	quit(0)
