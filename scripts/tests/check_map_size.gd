extends SceneTree

const ArchiveLoaderClass = preload("res://scripts/core/archive_loader.gd")

func _init() -> void:
	var al = ArchiveLoaderClass.new()
	root.add_child(al)
	al._ready()
	var tex = al.get_map_background(10001)
	if tex:
		print("Map 10001 background size: %dx%d" % [tex.get_width(), tex.get_height()])
	else:
		print("Could not load map 10001")
	quit(0)
