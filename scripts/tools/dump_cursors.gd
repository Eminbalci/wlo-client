extends SceneTree

## Dumps every frame of each cursorN.ani into CAPTURE_DIR/cursors/ for visual identification.

func _init() -> void:
	var out_dir := OS.get_environment("CAPTURE_DIR")
	if out_dir == "":
		out_dir = "res://screenshots_auth"
	DirAccess.make_dir_recursive_absolute(out_dir.path_join("cursors"))
	var loader = root.get_node_or_null("ArchiveLoader")
	if loader == null:
		loader = load("res://scripts/core/archive_loader.gd").new()
		root.add_child(loader)
		loader.initialize_archives()
	for n in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 99]:
		var frames: Array = loader.get_cursor_frames("cursor%d" % n)
		print("CUR cursor", n, " frames=", frames.size(), " size=", frames[0].get_size() if not frames.is_empty() else "-")
		for i in frames.size():
			(frames[i] as Texture2D).get_image().save_png(out_dir.path_join("cursors/c%d_%d.png" % [n, i]))
	quit()
