extends SceneTree

func _init() -> void:
	var loader = load("res://scripts/core/archive_loader.gd").new()
	root.add_child(loader)
	
	var body_anim = loader.get_jma_animation("004.jma", "4000.jmp")
	var face_anim = loader.get_jma_animation("004f.jma", "4600.jmp")
	var hair_anim = loader.get_jma_animation("004h.jma", "4101.jmp")
	var clothes_anim = loader.get_jma_animation("004e.jma", "4300.jmp")
	var shoes_anim = loader.get_jma_animation("004s.jma", "4400.jmp")
	
	print("Body: " + str(body_anim != null))
	print("Face: " + str(face_anim != null))
	print("Hair: " + str(hair_anim != null))
	print("Clothes: " + str(clothes_anim != null))
	print("Shoes: " + str(shoes_anim != null))
	
	var canvas := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))
	
	var layer_anims = [body_anim, face_anim, clothes_anim, shoes_anim, hair_anim]
	var frame_idx = 48
	
	for anim in layer_anims:
		if not anim: continue
		var j_frame = anim.get_frame(frame_idx)
		if not j_frame or j_frame.width <= 0 or j_frame.height <= 0: continue
		var layer_img = anim.decode_frame_image(frame_idx)
		if layer_img:
			canvas.blend_rect(
				layer_img,
				Rect2i(0, 0, j_frame.width, j_frame.height),
				Vector2i(j_frame.pivot_x, j_frame.pivot_y)
			)
	
	var out = "C:/Users/muham/.gemini/antigravity-cli/brain/c43cf149-bb6e-436c-95e5-06c734294986/daniel_with_face.png"
	canvas.save_png(out)
	print("Saved composite with face to: " + out)

	# Verify full pipeline via get_player_composite_frames
	var composite_frames = loader.get_player_composite_frames(6)
	print("Daniel get_player_composite_frames(6) size: " + str(composite_frames.size()))
	assert(composite_frames.size() >= 64, "Expected at least 64 frames from get_player_composite_frames(6)")
	var out_pipe = "C:/Users/muham/.gemini/antigravity-cli/brain/c43cf149-bb6e-436c-95e5-06c734294986/daniel_composite_pipeline.png"
	composite_frames[48].get_image().save_png(out_pipe)
	print("Saved full pipeline composite to: " + out_pipe)
	quit(0)
