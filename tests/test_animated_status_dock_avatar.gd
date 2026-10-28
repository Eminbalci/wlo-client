extends SceneTree

## Headless test suite for animated status dock avatar bust (Role 1..14 from 008.jma)
## and authentic visible HP/SP/EXP progress bars.

func _init() -> void:
	print("\n=================================================================")
	print("--- Running Test Animated Status Dock Avatar & HP/SP Bars Suite ---")
	print("=================================================================\n")
	
	# --------------------------------------------------------------------------
	# 1. Verify ArchiveLoader & 008.jma Authentic Bust Mappings (8001..8014)
	# --------------------------------------------------------------------------
	var loader := root.get_node_or_null("ArchiveLoader")
	if loader == null:
		var ArchiveLoaderClass = load("res://scripts/core/archive_loader.gd")
		loader = ArchiveLoaderClass.new()
		loader.name = "ArchiveLoader"
		root.add_child(loader)
	assert(loader != null, "ArchiveLoader singleton missing")
	assert(loader.has_method("get_avatar_frames"), "ArchiveLoader missing get_avatar_frames method")
	print("[PASS] ArchiveLoader API verified")
	
	for role_id in range(1, 15):
		var frames: Array[ImageTexture] = loader.get_avatar_frames(role_id)
		assert(frames.size() >= 2, "Role %d must have at least 2 frames from 008.jma" % role_id)
		assert(frames[0] != null and frames[1] != null, "Role %d frame texture is null" % role_id)
		assert(frames[0].get_size() == Vector2(72, 72), "Role %d frame 0 must be 72x72" % role_id)
		assert(frames[1].get_size() == Vector2(72, 72), "Role %d frame 1 must be 72x72" % role_id)
		
		var img0 := frames[0].get_image()
		var img1 := frames[1].get_image()
		var diff_count := 0
		for y in range(72):
			for x in range(72):
				if img0.get_pixel(x, y) != img1.get_pixel(x, y):
					diff_count += 1
		assert(diff_count > 0, "Role %d Frame 0 and Frame 1 must differ (blinking animation), found 0 diffs" % role_id)
		print("[PASS] Role %d authentic 008.jma bust verified: 2 frames (72x72), blink diff pixels=%d" % [role_id, diff_count])
	
	# Verify Daniel (Role 6) authentic orange/red hair portrait (8006.jmp)
	var daniel_frames: Array[ImageTexture] = loader.get_avatar_frames(6)
	var daniel_img := daniel_frames[0].get_image()
	var orange_hair_pixels := 0
	for y in range(72):
		for x in range(72):
			var p := daniel_img.get_pixel(x, y)
			# Daniel's orange hair: high red, moderate green, lower blue
			if p.a > 0.5 and p.r > 0.6 and p.g > 0.35 and p.b < 0.5:
				orange_hair_pixels += 1
	assert(orange_hair_pixels > 200, "Daniel (Role 6) must have authentic orange hair (found %d pixels)" % orange_hair_pixels)
	print("[PASS] Daniel (Role 6) authentic orange hair portrait verified (orange pixels=%d)" % orange_hair_pixels)
	
	# --------------------------------------------------------------------------
	# 2. Verify HUD Status Dock Layering and Node Hierarchy
	# --------------------------------------------------------------------------
	var hud_scene = preload("res://scenes/ui/hud.tscn")
	var hud: HUD = hud_scene.instantiate()
	root.add_child(hud)
	await process_frame
	
	assert(hud.status_dock != null, "PlayerStatusDock missing")
	var dock: Control = hud.status_dock
	
	var avatar_bg: ColorRect = dock.get_node_or_null("AvatarBg")
	assert(avatar_bg != null, "AvatarBg ColorRect missing from PlayerStatusDock")
	assert(avatar_bg.color.r8 == 41 and avatar_bg.color.g8 == 41 and avatar_bg.color.b8 == 41, "AvatarBg must match authentic RGB (41,41,41)")
	
	var avatar_rect: TextureRect = dock.get_node_or_null("AvatarRect")
	assert(avatar_rect != null, "AvatarRect missing from PlayerStatusDock")
	assert(avatar_rect.texture != null, "AvatarRect texture must be populated")
	assert(avatar_rect.position == Vector2(30, -4), "AvatarRect must be positioned at (30, -4) to prevent clipping in golden bezel aperture")
	assert(avatar_rect.size == Vector2(72, 72), "AvatarRect must be sized 72x72")
	print("[PASS] AvatarBg and AvatarRect aperture alignment verified")
	
	var status_bg: TextureRect = dock.get_node_or_null("StatusBackground")
	assert(status_bg != null, "StatusBackground missing from PlayerStatusDock")
	
	var hp_bar: TextureProgressBar = dock.get_node_or_null("HpBar")
	assert(hp_bar != null, "HpBar TextureProgressBar missing")
	
	var sp_bar: TextureProgressBar = dock.get_node_or_null("SpBar")
	assert(sp_bar != null, "SpBar TextureProgressBar missing")
	
	# Verify tree order: StatusBackground MUST be before HpBar and SpBar so it does not draw over them
	var bg_idx := status_bg.get_index()
	var hp_idx := hp_bar.get_index()
	var sp_idx := sp_bar.get_index()
	assert(bg_idx < hp_idx, "StatusBackground (index %d) must be placed BEFORE HpBar (index %d) in tree" % [bg_idx, hp_idx])
	assert(bg_idx < sp_idx, "StatusBackground (index %d) must be placed BEFORE SpBar (index %d) in tree" % [bg_idx, sp_idx])
	print("[PASS] Node tree hierarchy verified: StatusBackground draws behind HpBar and SpBar")
	
	# Verify authentic textures and clean material (no broken chroma shader discarding pixels)
	assert(hp_bar.texture_progress != null, "HpBar texture_progress missing")
	assert(hp_bar.texture_progress.resource_path.ends_with("Main_Hp.png") or hp_bar.texture_progress.get_path().contains("Main_Hp"), "HpBar must use Main_Hp.png")
	assert(hp_bar.material == null, "HpBar material must be null (clean native progress clipping)")
	
	assert(sp_bar.texture_progress != null, "SpBar texture_progress missing")
	assert(sp_bar.texture_progress.resource_path.ends_with("Main_Sp.png") or sp_bar.texture_progress.get_path().contains("Main_Sp"), "SpBar must use Main_Sp.png")
	assert(sp_bar.material == null, "SpBar material must be null (clean native progress clipping)")
	print("[PASS] Authentic Main_Hp.png and Main_Sp.png progress textures verified without shaders")
	
	# --------------------------------------------------------------------------
	# 3. Verify Avatar Blinking State Machine
	# --------------------------------------------------------------------------
	assert(hud._current_player_role_id == 6, "Default role must be 6 (Daniel)")
	assert(avatar_rect.texture == hud._avatar_frames[0], "Avatar should start on Frame 0 (idle eyes open)")
	
	# Simulate 1.0s - idle
	hud._process(1.0)
	assert(hud._avatar_is_blinking == false, "Avatar should not blink at 1.0s")
	assert(avatar_rect.texture == hud._avatar_frames[0], "Avatar must remain on Frame 0 during idle")
	
	# Advance past blink interval (3.5s) - trigger blink
	hud._process(2.6)
	assert(hud._avatar_is_blinking == true, "Avatar must enter blinking state after interval")
	assert(avatar_rect.texture == hud._avatar_frames[1], "Avatar must switch to Frame 1 (closed eyes) during blink")
	print("[PASS] Periodic blink trigger verified: transitioned to Frame 1 (eyes closed)")
	
	# Advance past blink duration (0.15s) - return to idle
	hud._process(0.16)
	assert(hud._avatar_is_blinking == false, "Avatar must return to idle after blink duration")
	assert(avatar_rect.texture == hud._avatar_frames[0], "Avatar must switch back to Frame 0 (open eyes)")
	print("[PASS] Blink completion verified: returned to Frame 0 (eyes open)")
	
	# Test Dynamic Switching to Betty (Role 2)
	hud.set_player_role(2)
	assert(hud._current_player_role_id == 2, "Current role must be 2 (Betty)")
	var betty_frames = loader.get_avatar_frames(2)
	assert(avatar_rect.texture == betty_frames[0], "AvatarRect must update to Betty Frame 0")
	print("[PASS] Dynamic role switch to Betty (Role 2) verified")
	
	# Switch back to Daniel (Role 6)
	hud.set_player_role(6)
	assert(hud._current_player_role_id == 6, "Current role must return to 6 (Daniel)")
	assert(avatar_rect.texture == daniel_frames[0], "AvatarRect must return to Daniel Frame 0")
	print("[PASS] Return switch to Daniel (Role 6) verified")
	
	# --------------------------------------------------------------------------
	# 4. Verify HP, SP, and EXP Bars Proportional Fill and Visibility
	# --------------------------------------------------------------------------
	# Case A: Full Stats (190/190 HP, 124/124 SP, 45% EXP)
	hud.set_player_stats("Daniel", 10, 190, 190, 124, 124, 45, 100)
	assert(hp_bar.value == 190.0 and hp_bar.max_value == 190.0, "Full HP value mismatch")
	assert(sp_bar.value == 124.0 and sp_bar.max_value == 124.0, "Full SP value mismatch")
	assert(hud.hp_label.text == "HP   190/190", "HP label text mismatch: %s" % hud.hp_label.text)
	assert(hud.sp_label.text == "SP   124/124", "SP label text mismatch: %s" % hud.sp_label.text)
	assert(hud.exp_label.text == "45%", "EXP label text mismatch: %s" % hud.exp_label.text)
	assert(hud.exp_bar.value == 45.0, "EXP bar value mismatch")
	print("[PASS] Full stats values & label readout verified (190/190 HP, 124/124 SP, 45% EXP)")
	
	# Case B: Partial Stats (50% HP = 95/190, 25% SP = 31/124)
	hud.set_player_stats("Daniel", 10, 95, 190, 31, 124, 80, 100)
	assert(hp_bar.value == 95.0, "Partial HP value mismatch")
	assert(sp_bar.value == 31.0, "Partial SP value mismatch")
	assert(hud.hp_label.text == "HP   95/190", "Partial HP label text mismatch")
	assert(hud.sp_label.text == "SP   31/124", "Partial SP label text mismatch")
	assert(hud.exp_label.text == "80%", "Partial EXP label text mismatch")
	print("[PASS] Proportional partial stats fill verified (50% HP, 25% SP, 80% EXP)")
	
	# Case C: Zero Stats (0/190 HP, 0/124 SP)
	hud.set_player_stats("Daniel", 10, 0, 190, 0, 124, 0, 100)
	assert(hp_bar.value == 0.0, "Zero HP value mismatch")
	assert(sp_bar.value == 0.0, "Zero SP value mismatch")
	assert(hud.hp_label.text == "HP   0/190", "Zero HP label text mismatch")
	assert(hud.sp_label.text == "SP   0/124", "Zero SP label text mismatch")
	print("[PASS] Zero stats fill verified (0% HP, 0% SP)")
	
	hud.queue_free()
	
	print("\n=================================================================")
	print("--- ALL ANIMATED STATUS DOCK AVATAR & BAR VERIFICATIONS PASSED (100%) ---")
	print("=================================================================\n")
	quit(0)
