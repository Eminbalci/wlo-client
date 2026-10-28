extends SceneTree

func _init() -> void:
	var loader_script = preload("res://scripts/core/archive_loader.gd")
	var loader = loader_script.new()
	loader.initialize_archives()
	
	var bg_tex = loader.get_map_background(10002)
	if not bg_tex:
		print("Failed to load 10002.jpg")
		quit(1)
		return
	
	var bg_img: Image = bg_tex.get_image().duplicate()
	bg_img.convert(Image.FORMAT_RGBA8)
	print("Loaded 10002.jpg: ", bg_img.get_size())
	
	# Cabin NPCs
	var cabin_npc_defs: Array[Dictionary] = [
		{"name": "Drunk Man", "id": 14042, "pos": Vector2(851, 539), "jmp": "1050.jmp", "frame": 0},
		{"name": "Peter", "id": 14146, "pos": Vector2(1302, 800), "jmp": "1050.jmp", "frame": 3},
		{"name": "John", "id": 14145, "pos": Vector2(1309, 714), "jmp": "1050.jmp", "frame": 2},
		{"name": "Natasha", "id": 14303, "pos": Vector2(1440, 682), "jmp": "1068.jmp", "frame": 32 + 3 * 4},
		{"name": "Breillat", "id": 10000, "pos": Vector2(1155, 580), "jmp": "1170.jmp", "frame": 4},
		{"name": "Game Machine a", "id": 18000, "pos": Vector2(226, 795), "jmp": "1088.jmp", "frame": 4},
		{"name": "Game Machine b", "id": 18001, "pos": Vector2(141, 829), "jmp": "1089.jmp", "frame": 4},
	]
	
	for def in cabin_npc_defs:
		var jmp_name: String = def["jmp"]
		var frame_idx: int = def["frame"]
		var pos: Vector2 = def["pos"]
		var frame_tex = loader.get_jma_frame_128("001.jma", jmp_name, frame_idx)
		if frame_tex:
			var f_img: Image = frame_tex.get_image()
			# Canvas is 128x128. Sprite offset in NpcEntity is Vector2(0, -64).
			# So top-left of canvas is at pos + Vector2(-64, -128)!
			var dst_x: int = int(pos.x - 64)
			var dst_y: int = int(pos.y - 128)
			bg_img.blend_rect(f_img, Rect2i(0, 0, 128, 128), Vector2i(dst_x, dst_y))
			print("Blended %s at (%d, %d)" % [def["name"], dst_x, dst_y])
		else:
			print("Failed to get frame for %s" % def["name"])
	
	bg_img.save_png("D:/Godot/WonderlandOnline/wonderland-online-client/tests/cabin_rendered_all_npcs.png")
	print("Saved cabin_rendered_all_npcs.png")
	
	# Crop table area
	var table_crop = bg_img.get_region(Rect2i(1150, 600, 400, 300))
	table_crop.save_png("D:/Godot/WonderlandOnline/wonderland-online-client/tests/cabin_rendered_table_crop.png")
	
	# Crop bar area
	var bar_crop = bg_img.get_region(Rect2i(700, 450, 300, 200))
	bar_crop.save_png("D:/Godot/WonderlandOnline/wonderland-online-client/tests/cabin_rendered_bar_crop.png")
	
	quit(0)
