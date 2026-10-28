extends Node

func _ready() -> void:
	print("--- Running In-Engine Verification of Animated Avatar & Asset Visibility ---")
	
	# 1. Verify Asset Visibility & .gdignore Configuration
	assert(not FileAccess.file_exists("res://assets/.gdignore"), "Root assets/.gdignore must NOT exist (it hid all files in Godot editor)")
	print("[PASS] Root assets/.gdignore is absent; assets folder is visible in Godot FileSystem dock")
	
	for all_dir in ["jma", "sound", "voice", "pic", "user", "sty", "data", "hud", "menu", "fonts", "cursor", "sprites"]:
		var dir_path := "res://assets/%s" % all_dir
		var ignore_path := "res://assets/%s/.gdignore" % all_dir
		assert(DirAccess.dir_exists_absolute(dir_path) or DirAccess.dir_exists_absolute("D:/Godot/WonderlandOnline/wonderland-online-client/assets/" + all_dir), "Directory %s missing" % all_dir)
		assert(not FileAccess.file_exists(ignore_path), "No .gdignore in %s (must be fully visible in Godot project)" % all_dir)
		print("[PASS] Asset directory assets/%s/ is present and 100%% visible in Godot Editor" % all_dir)
	
	for visible_dir in ["data", "hud", "menu", "fonts", "cursor", "sprites"]:
		var dir_path := "res://assets/%s" % visible_dir
		assert(DirAccess.dir_exists_absolute(dir_path) or DirAccess.dir_exists_absolute("D:/Godot/WonderlandOnline/wonderland-online-client/assets/" + visible_dir), "Visible directory %s missing" % visible_dir)
		print("[PASS] Browsable asset directory assets/%s/ is active and visible" % visible_dir)
	
	# 2. Verify ArchiveLoader singleton
	var loader := get_node_or_null("/root/ArchiveLoader")
	assert(loader != null, "ArchiveLoader singleton not found")
	assert(loader.has_method("get_avatar_frames"), "ArchiveLoader missing get_avatar_frames method")
	print("[PASS] ArchiveLoader.get_avatar_frames API verified")
	
	# 3. Verify All 14 Roles Avatar Frames in RAM
	for role_id in range(1, 15):
		var frames: Array[ImageTexture] = loader.get_avatar_frames(role_id)
		assert(frames.size() >= 2, "Expected at least 2 frames for Role %d, got %d" % [role_id, frames.size()])
		assert(frames[0] != null and frames[1] != null, "Null frame texture in Role %d" % role_id)
		assert(frames[0].get_size() == Vector2(72, 72), "Expected 72x72 frame 0 for Role %d, got %s" % [role_id, frames[0].get_size()])
		assert(frames[1].get_size() == Vector2(72, 72), "Expected 72x72 frame 1 for Role %d, got %s" % [role_id, frames[1].get_size()])
		
		# Verify pixel difference between open eyes (frame 0) and blinking (frame 1)
		var img0 := frames[0].get_image()
		var img1 := frames[1].get_image()
		var diff_count := 0
		for y in range(72):
			for x in range(72):
				if img0.get_pixel(x, y) != img1.get_pixel(x, y):
					diff_count += 1
		assert(diff_count > 0, "Role %d Frame 0 and Frame 1 must differ (blinking animation), found 0 diffs" % role_id)
		print("[PASS] Role %d verified: 2 frames (72x72), blinking diff pixels=%d" % [role_id, diff_count])
	
	# 4. Verify HUD Animated Avatar Playback & Dynamic Role Switching
	var hud_scene = preload("res://scenes/ui/hud.tscn")
	var hud: HUD = hud_scene.instantiate()
	add_child(hud)
	
	assert(hud.status_dock != null, "PlayerStatusDock missing")
	var avatar_rect: TextureRect = hud.status_dock.get_node("AvatarRect")
	assert(avatar_rect != null, "AvatarRect missing from PlayerStatusDock")
	
	var avatar_bg: ColorRect = hud.status_dock.get_node_or_null("AvatarBg")
	assert(avatar_bg != null, "AvatarBg ColorRect missing from PlayerStatusDock")
	assert(avatar_bg.color.r8 == 41 and avatar_bg.color.g8 == 41 and avatar_bg.color.b8 == 41, "AvatarBg must match authentic RGB (41,41,41)")
	print("[PASS] AvatarBg dark backplate verified behind AvatarRect: RGB=(41,41,41)")
	
	# Default Daniel (Role 6)
	assert(hud._current_player_role_id == 6, "Default role should be 6 (Daniel)")
	assert(avatar_rect.texture != null, "AvatarRect texture must be populated")
	assert(hud._avatar_frames.size() == 2, "Daniel must have 2 avatar frames")
	assert(avatar_rect.texture == hud._avatar_frames[0], "Avatar should start on Frame 0 (idle eyes open)")
	print("[PASS] Initial Daniel Role 6 idle portrait verified on AvatarRect")
	
	# Simulate 1.0s - should still be idle (eyes open)
	hud._process(1.0)
	assert(hud._avatar_is_blinking == false, "Avatar should not blink at 1.0s")
	assert(avatar_rect.texture == hud._avatar_frames[0], "Avatar should remain on Frame 0 during idle")
	
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
	
	# Betty blink test
	hud._process(3.6)
	assert(hud._avatar_is_blinking == true, "Betty avatar should blink")
	assert(avatar_rect.texture == betty_frames[1], "Betty avatar must show Frame 1 when blinking")
	hud._process(0.16)
	assert(hud._avatar_is_blinking == false, "Betty avatar should finish blink")
	assert(avatar_rect.texture == betty_frames[0], "Betty avatar must return to Frame 0")
	print("[PASS] Betty periodic blinking animation verified")
	
	# Switch back to Daniel (Role 6)
	hud.set_player_role(6)
	assert(hud._current_player_role_id == 6, "Current role must return to 6 (Daniel)")
	var daniel_frames = loader.get_avatar_frames(6)
	assert(avatar_rect.texture == daniel_frames[0], "AvatarRect must return to Daniel Frame 0")
	print("[PASS] Return switch to Daniel (Role 6) verified")
	
	print("--- ALL ANIMATED AVATAR & VISIBILITY VERIFICATIONS PASSED (100%) ---")
	get_tree().quit(0)
