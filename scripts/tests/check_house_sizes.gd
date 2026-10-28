extends SceneTree

func _init() -> void:
	var loader = preload("res://scripts/core/archive_loader.gd").new()
	for mid in [12000, 12001, 12002, 12003, 12004, 12005]:
		var tex = loader.get_map_background(mid)
		if tex:
			print("Map %d background size: %s" % [mid, tex.get_size()])
		else:
			print("Map %d background: NULL" % mid)
	quit(0)
