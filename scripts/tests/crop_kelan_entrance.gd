extends SceneTree

func _init() -> void:
	var loader = preload("res://scripts/core/archive_loader.gd").new()
	var tex: ImageTexture = loader.get_map_background(12000)
	if tex:
		var img = tex.get_image()
		var crop_rect = Rect2i(892 - 250, 734 - 250, 500, 500)
		var crop = img.get_region(crop_rect)
		crop.save_png("kelan_entrance_crop.png")
		print("[Done] Saved kelan_entrance_crop.png")
	quit(0)
