extends SceneTree

func _init() -> void:
	var loader_script = preload("res://scripts/core/archive_loader.gd")
	var loader = loader_script.new()
	loader.initialize_archives()
	var bg_tex = loader.get_map_background(10001)
	var img = bg_tex.get_image()
	
	# Crop region around player spawn (1042, 1075): say from x: 800..1300, y: 700..1300
	var crop = img.get_region(Rect2i(800, 600, 500, 700))
	crop.save_png("D:/Godot/WonderlandOnline/wonderland-online-client/tests/deck_mast_area.png")
	print("Saved deck_mast_area.png (size %s)" % str(crop.get_size()))
	quit(0)
