extends SceneTree

func _init() -> void:
	print("==================================================================")
	print("--- Running Character Normal Animations (216-frame) Test Suite ---")
	print("==================================================================")

	# 1. Initialize GameDatabase and ArchiveLoader singletons
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
		loader.initialize_archives()

	loader.clear_composite_cache()

	# -------------------------------------------------------------------------
	# PART 1: Composite Frame Count Verification
	# -------------------------------------------------------------------------
	print("\n[PART 1] Verifying 216-frame composite generation for Daniel (Role 6)...")
	var daniel_frames: Array[ImageTexture] = loader.get_player_composite_frames(6, {})
	print("Daniel composite frame count: %d" % daniel_frames.size())
	assert(daniel_frames.size() >= 216, "Daniel composite must have >= 216 frames, got %d" % daniel_frames.size())
	print("PASS: Daniel composite yielded >= 216 frames (actual: %d)." % daniel_frames.size())

	print("\n[PART 1B] Verifying 216-frame composite for Betty (Role 2)...")
	var betty_frames: Array[ImageTexture] = loader.get_player_composite_frames(2, {})
	print("Betty composite frame count: %d" % betty_frames.size())
	assert(betty_frames.size() >= 216, "Betty composite must have >= 216 frames, got %d" % betty_frames.size())
	print("PASS: Betty composite yielded >= 216 frames (actual: %d)." % betty_frames.size())

	# -------------------------------------------------------------------------
	# PART 2: Animation Frame Range Non-Empty & Pixel Verification
	# -------------------------------------------------------------------------
	print("\n[PART 2] Verifying content across key normal animation cycles...")
	var test_frame_samples: Dictionary = {
		"Walk North (0)": 0,
		"Walk East (8)": 8,
		"Walk South (16)": 16,
		"Walk West (24)": 24,
		"Idle/Stand North (32)": 32,
		"Idle/Stand South (48)": 48,
		"Sit North (64)": 64,
		"Sit South (80)": 80,
		"Sit West (92)": 92,
		"Attack/Combat Strike North (112)": 112,
		"Attack/Combat Strike South (128)": 128,
		"Attack/Combat Strike West (140)": 140,
		"Defend/Hurt North (144)": 144,
		"Defend/Hurt South (160)": 160,
		"Prone Awakened (105: 26-2.bmp)": 105,
		"Rising Kneel (104: 26-1.bmp)": 104,
		"Defeat / Collapse (192)": 192,
		"Victory Emote (200)": 200,
		"Victory Emote End (215)": 215
	}

	for label: String in test_frame_samples:
		var f_idx: int = test_frame_samples[label]
		assert(f_idx < daniel_frames.size(), "Sample frame %d must be within composite bounds" % f_idx)
		var tex: ImageTexture = daniel_frames[f_idx]
		assert(tex != null, "%s: Frame %d texture is null" % [label, f_idx])
		assert(tex.get_width() == 128 and tex.get_height() == 128, "%s: Frame %d invalid size" % [label, f_idx])
		var img: Image = tex.get_image()
		assert(img != null and not img.is_empty(), "%s: Frame %d image is empty" % [label, f_idx])

		# Verify visible pixels exist in the rendered composite frame
		var opaque_count := 0
		for y in range(img.get_height()):
			for x in range(img.get_width()):
				if img.get_pixel(x, y).a > 0.05:
					opaque_count += 1
		assert(opaque_count > 30, "%s: Frame %d has too few visible pixels (%d)" % [label, f_idx, opaque_count])
		print("  PASS: %-35s (Frame %3d) verified with %d opaque pixels." % [label, f_idx, opaque_count])

	# -------------------------------------------------------------------------
	# PART 3: PlayerEntity MotionState Machine Transitions
	# -------------------------------------------------------------------------
	print("\n[PART 3] Verifying PlayerEntity MotionState transitions...")
	var player_cls = load("res://scripts/world/player.gd")
	var player = player_cls.new()
	player.archive_loader = loader
	player.role_id = 6
	root.add_child(player)
	player._load_player_art()

	var recorded_states: Array = []
	player.motion_state_changed.connect(func(st): recorded_states.append(st))

	# 3A: Initial State is IDLE
	assert(player.motion_state == player_cls.MotionState.IDLE, "Player initial motion state must be IDLE")
	print("  PASS: Initial motion_state is IDLE.")

	# 3B: WALK State
	player.motion_state = player_cls.MotionState.WALK
	player._update_animation(0.1)
	assert(player.motion_state == player_cls.MotionState.WALK, "Player should be in WALK state")
	assert(player.sprite.texture != null, "Sprite texture must not be null in WALK")
	print("  PASS: WALK state active and rendering walk frames.")

	# 3C: SIT State via play_sit_animation()
	player.play_sit_animation()
	player._update_animation(0.1)
	assert(player.motion_state == player_cls.MotionState.SIT, "Player should be in SIT state")
	assert(player.sprite.texture != null, "Sprite texture must not be null in SIT")
	print("  PASS: SIT state active via play_sit_animation().")

	# 3D: ATTACK State via play_attack_animation()
	player.play_attack_animation()
	player._update_animation(0.1)
	assert(player.motion_state == player_cls.MotionState.ATTACK, "Player should be in ATTACK state")
	assert(player.sprite.texture != null, "Sprite texture must not be null in ATTACK")
	print("  PASS: ATTACK state active via play_attack_animation().")

	# 3E: DEFEND State via play_hurt_animation()
	player.play_hurt_animation()
	player._update_animation(0.1)
	assert(player.motion_state == player_cls.MotionState.DEFEND, "Player should be in DEFEND state")
	assert(player.sprite.texture != null, "Sprite texture must not be null in DEFEND")
	print("  PASS: DEFEND state active via play_hurt_animation().")

	# 3F: VICTORY State via play_victory_animation()
	player.play_victory_animation()
	player._update_animation(0.1)
	assert(player.motion_state == player_cls.MotionState.VICTORY, "Player should be in VICTORY state")
	assert(player.sprite.texture != null, "Sprite texture must not be null in VICTORY")
	print("  PASS: VICTORY state active via play_victory_animation().")

	# 3G: STAND State via play_stand_animation()
	player.play_stand_animation()
	player._update_animation(0.1)
	assert(player.motion_state == player_cls.MotionState.IDLE, "Player should return to IDLE after stand")
	print("  PASS: STAND state active via play_stand_animation().")

	# 3H: PRONE State via set_prone(true)
	player.set_prone(true)
	player._update_animation(0.1)
	assert(player.is_prone == true, "Player is_prone must be true")
	assert(player.motion_state == player_cls.MotionState.PRONE, "Player motion_state must be PRONE")
	assert(player.is_movement_locked == true, "Player movement must be locked when PRONE")
	assert(player.sprite.texture != null, "Prone sprite texture must not be null")
	
	# Verify authentic prone frame (index 105: 26-2.bmp) is rendered
	var prone_idx = player.get_prone_frame_index()
	assert(prone_idx == 105, "get_prone_frame_index() should return authentic 26-2.bmp index 105, got %d" % prone_idx)
	print("  PASS: PRONE state active with authentic prone composite texture at index %d." % prone_idx)

	# Movement should be rejected when prone
	var move_result: bool = player.set_target_world_position(Vector2(500, 500))
	assert(move_result == false, "Movement must be rejected while PRONE")
	assert(player.is_moving == false, "Player must not move while PRONE")
	print("  PASS: Movement safely blocked while PRONE.")

	# Release prone via set_prone(false)
	player.set_prone(false)
	assert(player.is_prone == false, "Player is_prone must be false")
	assert(player.motion_state == player_cls.MotionState.IDLE, "Player motion_state must be restored to IDLE")
	assert(player.is_movement_locked == false, "Player movement lock must be released")
	print("  PASS: PRONE state cleanly released back to IDLE.")

	# Sitting then pathing -> stands up and walks
	player.play_sit_animation()
	assert(player.motion_state == player_cls.MotionState.SIT, "Should be sitting")
	var start_pos: Vector2 = player.world_position
	player.set_target_world_position(start_pos + Vector2(100, 0))
	assert(player.motion_state == player_cls.MotionState.WALK or player.motion_state == player_cls.MotionState.IDLE, "Should stand up on movement request")
	print("  PASS: Movement while sitting automatically stands character up.")

	player.queue_free()

	print("\n==================================================================")
	print("--- ALL CHARACTER NORMAL ANIMATION TESTS PASSED (0 ERRORS) ---")
	print("==================================================================")
	quit(0)
