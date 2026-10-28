extends SceneTree

func _init() -> void:
	var loader = preload("res://scripts/core/archive_loader.gd").new()
	var tex = loader.get_map_background(12000)
	if tex:
		print("[ArchiveLoader] 12000.jpg found! Size: ", tex.get_size())
	else:
		print("[ArchiveLoader] 12000.jpg NOT found!")
	quit(0)
