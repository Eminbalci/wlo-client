extends SceneTree

const ArchiveLoaderScript = preload("res://scripts/core/archive_loader.gd")

func _init() -> void:
	var loader: Node = ArchiveLoaderScript.new()
	root.add_child(loader)
	loader.initialize_archives()
	
	var anim_body = loader.get_jma_animation("004.jma", "4000.jmp")
	var anim_clothes = loader.get_jma_animation("004e.jma", "4300.jmp")
	var anim_shoes = loader.get_jma_animation("004s.jma", "4400.jmp")
	var anim_hair = loader.get_jma_animation("004h.jma", "4101.jmp")
	var anim_weapon = loader.get_jma_animation("004w.jma", "4040.jmp")
	
	# Let's render frame 48 (South stand) in two ways:
	# Way A: Weapon IN FRONT (body -> clothes -> shoes -> hair -> weapon)
	# Way B: Weapon BEHIND (weapon -> body -> clothes -> shoes -> hair)
	for way in ["front", "behind"]:
		var canvas := Image.create(128, 128, false, Image.FORMAT_RGBA8)
		canvas.fill(Color(0, 0, 0, 0))
		
		var layers: Array = []
		if way == "front":
			layers = [anim_body, anim_clothes, anim_shoes, anim_hair, anim_weapon]
		else:
			layers = [anim_weapon, anim_body, anim_clothes, anim_shoes, anim_hair]
			
		for anim in layers:
			var jf = anim.get_frame(48)
			var img = anim.decode_frame_image(48)
			var ox = (jf.bound_w - 128) / 2
			var oy = (jf.bound_h - 128) / 2
			canvas.blend_rect(img, Rect2i(0, 0, jf.width, jf.height), Vector2i(jf.pivot_x - ox, jf.pivot_y - oy))
			
		canvas.save_png("C:/Users/muham/.gemini/antigravity-cli/brain/b9048478-a164-4259-861a-bfea601814c4/daniel_weapon_" + way + ".png")

	# Let's also do the same for Betty (Role 2)
	var anim_b2 = loader.get_jma_animation("003.jma", "3000.jmp")
	var anim_c2 = loader.get_jma_animation("003e.jma", "3301.jmp")
	var anim_s2 = loader.get_jma_animation("003s.jma", "3401.jmp")
	var anim_h2 = loader.get_jma_animation("003h.jma", "3101.jmp")
	var anim_w2 = loader.get_jma_animation("003w.jma", "3040.jmp")
	for way in ["front", "behind"]:
		var canvas := Image.create(128, 128, false, Image.FORMAT_RGBA8)
		canvas.fill(Color(0, 0, 0, 0))
		var layers: Array = []
		if way == "front":
			layers = [anim_b2, anim_c2, anim_s2, anim_h2, anim_w2]
		else:
			layers = [anim_w2, anim_b2, anim_c2, anim_s2, anim_h2]
		for anim in layers:
			var jf = anim.get_frame(48)
			var img = anim.decode_frame_image(48)
			var ox = (jf.bound_w - 128) / 2
			var oy = (jf.bound_h - 128) / 2
			canvas.blend_rect(img, Rect2i(0, 0, jf.width, jf.height), Vector2i(jf.pivot_x - ox, jf.pivot_y - oy))
		canvas.save_png("C:/Users/muham/.gemini/antigravity-cli/brain/b9048478-a164-4259-861a-bfea601814c4/betty_weapon_" + way + ".png")

	quit()
