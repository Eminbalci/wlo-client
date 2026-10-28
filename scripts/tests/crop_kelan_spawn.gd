extends SceneTree

func _init() -> void:
	var loader = preload("res://scripts/core/archive_loader.gd").new()
	var tex: ImageTexture = loader.get_map_background(12000)
	if tex:
		var img = tex.get_image()
		var crop_rect = Rect2i(2346 - 250, 1598 - 250, 500, 500)
		var crop = img.get_region(crop_rect)
		crop.save_png("kelan_spawn_crop.png")
		print("[Done] Saved kelan_spawn_crop.png")
	quit(0)
