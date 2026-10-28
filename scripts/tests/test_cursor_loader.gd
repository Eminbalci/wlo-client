extends SceneTree

func _init() -> void:
	print("--- Testing Extended Cursor Loader in Engine ---")
	var loader = preload("res://scripts/core/archive_loader.gd").new()
	for cname in ["cursor1", "cursor2", "cursor3", "cursor4", "cursor6"]:
		var frames = loader.get_cursor_frames(cname)
		print(cname, "frames count:", frames.size())
		assert(frames.size() > 0, "Frames for %s must be > 0" % cname)
	print("--- ALL EXTENDED CURSORS LOADED SUCCESSFULLY ---")
	quit(0)
