extends Node

func _ready() -> void:
	print("Starting companion portrait extraction...")
	var ArchiveLoaderClass = load("res://scripts/core/archive_loader.gd")
	var loader = ArchiveLoaderClass.new()
	get_tree().root.add_child(loader)
	
	var targets := [
		{"name": "roca_avatar", "talk_image": 8090, "sprite_id": 1221},
		{"name": "kelang_avatar", "talk_image": 8038, "sprite_id": 1131},
		{"name": "robinson_avatar", "talk_image": 8067, "sprite_id": 1195},
		{"name": "niss_avatar", "talk_image": 8091, "sprite_id": 1223},
		{"name": "frederico_avatar", "talk_image": 8097, "sprite_id": 1260},
		{"name": "s_monkey_avatar", "talk_image": 0, "sprite_id": 1103, "jma": "001.jma", "jmp": "1103.jmp"}
	]
	
	for target in targets:
		var tex: Texture2D = null
		if target.talk_image > 0:
			tex = loader.get_npc_portrait(target.talk_image)
		
		if tex == null and target.get("talk_image", 0) == 0:
			# Non-humanoid monster/pet: extract from sprite animation frame 0
			var jma_name: String = target.get("jma", "001.jma")
			var jmp_name: String = target.get("jmp", "%d.jmp" % target.sprite_id)
			var anim = loader.get_jma_animation(jma_name, jmp_name)
			if anim and anim.frames.size() > 0:
				var img: Image = anim.decode_frame_image(0)
				if img:
					# Create cropped 72x72 square avatar centered on head/upper body
					var cropped := Image.create(72, 72, false, Image.FORMAT_RGBA8)
					cropped.fill(Color(0, 0, 0, 0))
					var sw: int = img.get_width()
					var sh: int = img.get_height()
					var src_rect := Rect2i(0, 0, mini(sw, 72), mini(sh, 72))
					var dst_pos := Vector2i(maxi(0, (72 - src_rect.size.x) / 2), maxi(0, (72 - src_rect.size.y) / 2))
					cropped.blend_rect(img, src_rect, dst_pos)
					tex = ImageTexture.create_from_image(cropped)
		
		if tex:
			var img: Image = tex.get_image()
			if img:
				var path := "res://assets/hud/%s.png" % target.name
				var save_err := img.save_png(ProjectSettings.globalize_path(path))
				print("Saved %s -> %s (res: %d)" % [target.name, path, save_err])
		else:
			print("FAILED to extract %s" % target.name)
	
	get_tree().quit(0)
