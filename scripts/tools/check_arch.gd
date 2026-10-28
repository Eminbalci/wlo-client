extends SceneTree

func _init() -> void:
	var loader = load("res://scripts/core/archive_loader.gd").new()
	root.add_child(loader)
	loader.initialize_archives()
	for id in [1098, 1099, 2466]:
		var name = "%d.bmp" % id
		for arch in loader._item_archives:
			if arch.has_file(name):
				print(name, " is in archive containing ", arch.file_count, " files")
	quit(0)
