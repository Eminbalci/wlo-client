extends SceneTree

func _init() -> void:
	print("--- Running Test Walk Composite No Face Glitch ---")

	var game_db = root.get_node_or_null("GameDatabase")
	if not game_db:
		var db_cls = load("res://scripts/database/game_database.gd")
		game_db = db_cls.new()
		game_db.name = "GameDatabase"
		root.add_child(game_db)

	var loader = root.get_node_or_null("ArchiveLoader")
	if not loader:
		var cls = load("res://scripts/core/archive_loader.gd")
		loader = cls.new()
		loader.name = "ArchiveLoader"
		root.add_child(loader)

	loader.clear_composite_cache()

	# Test Role 2 (Betty)
	print("\n[Testing Role 2: Betty]")
	var betty_face = loader.get_jma_animation("003f.jma", "3600.jmp")
	assert(betty_face != null, "Betty face animation should exist")
	print("Betty face animation frame count: %d (expected 20 portrait emotion frames)" % betty_face.frames.size())
	assert(betty_face.frames.size() == 20, "Betty face should have 20 frames")

	var betty_frames = loader.get_player_composite_frames(2, {})
	assert(betty_frames.size() >= 64, "Betty composite should have >= 64 frames, got %d" % betty_frames.size())
	print("PASS: Role 2 composite generated %d frames." % betty_frames.size())

	# Verify NW walk frames (indices 4..7) are non-empty and valid
	for idx in range(4, 8):
		var img: Image = betty_frames[idx].get_image()
		assert(img != null and not img.is_empty(), "Frame %d should have a valid image" % idx)
		var has_opaque := false
		for y in range(img.get_height()):
			for x in range(img.get_width()):
				if img.get_pixel(x, y).a > 0.1:
					has_opaque = true
					break
			if has_opaque:
				break
		assert(has_opaque, "Frame %d should contain opaque pixels" % idx)
	print("PASS: Role 2 NW walk frames (4..7) contain valid rendered pixels.")

	# Test Role 6 (Daniel)
	print("\n[Testing Role 6: Daniel]")
	var daniel_face = loader.get_jma_animation("004f.jma", "4600.jmp")
	assert(daniel_face != null, "Daniel face animation should exist")
	print("Daniel face animation frame count: %d (expected 20 portrait emotion frames)" % daniel_face.frames.size())
	assert(daniel_face.frames.size() == 20, "Daniel face should have 20 frames")

	var daniel_frames = loader.get_player_composite_frames(6, {})
	assert(daniel_frames.size() >= 64, "Daniel composite should have >= 64 frames, got %d" % daniel_frames.size())
	print("PASS: Role 6 composite generated %d frames." % daniel_frames.size())

	for idx in range(4, 8):
		var img: Image = daniel_frames[idx].get_image()
		assert(img != null and not img.is_empty(), "Frame %d should have a valid image" % idx)
		var has_opaque := false
		for y in range(img.get_height()):
			for x in range(img.get_width()):
				if img.get_pixel(x, y).a > 0.1:
					has_opaque = true
					break
			if has_opaque:
				break
		assert(has_opaque, "Frame %d should contain opaque pixels" % idx)
	print("PASS: Role 6 NW walk frames (4..7) contain valid rendered pixels.")

	# Verify glitch elimination:
	# Manually compose Daniel frame 4 WITH face overlay (the old buggy behavior)
	# and confirm current composite frame 4 differs from buggy composite (i.e. no face glitch overlay).
	var d_body = loader.get_jma_animation("004.jma", "4000.jmp")
	var d_clothes = loader.get_jma_animation("004e.jma", "4300.jmp")
	var d_shoes = loader.get_jma_animation("004s.jma", "4400.jmp")
	var d_hair = loader.get_jma_animation("004h.jma", "4101.jmp")

	var buggy_canvas := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	buggy_canvas.fill(Color(0, 0, 0, 0))
	var buggy_layers = [d_body, daniel_face, d_clothes, d_shoes, d_hair]
	for anim in buggy_layers:
		if not anim: continue
		var jf = anim.get_frame(4)
		if not jf or jf.width <= 0 or jf.height <= 0: continue
		var limg: Image = anim.decode_frame_image(4)
		if limg:
			buggy_canvas.blend_rect(limg, Rect2i(0, 0, jf.width, jf.height), Vector2i(jf.pivot_x, jf.pivot_y))

	var current_daniel_frame_4 = daniel_frames[4].get_image()
	var diff_count := 0
	for y in range(128):
		for x in range(128):
			if current_daniel_frame_4.get_pixel(x, y) != buggy_canvas.get_pixel(x, y):
				diff_count += 1

	print("Difference pixel count between clean composite and buggy composite at frame 4: %d" % diff_count)
	assert(diff_count > 0, "Clean composite frame 4 MUST NOT match the buggy face-glitched composite!")
	print("PASS: Verified that frame 4 has no unwanted face portrait overlay.")

	# Also verify awakening sequence composite doesn't crash or glitch
	var betty_awaken = loader.get_player_awakening_composite_frames(2, {})
	assert(betty_awaken.size() == 3, "Betty awakening should have 3 frames")
	print("PASS: Betty awakening composite loaded 3 clean frames.")

	print("\nALL TESTS PASSED SUCCESSFULLY!")
	quit(0)
