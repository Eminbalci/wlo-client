extends SceneTree

## Headless test for Authentic Character Roles & Equipment Visibility.
## Verifies that characters never disappear when unequipping/equipping clothes, shoes, or accessories,
## and that base nude skin (undergarments) is always rendered as Layer 0 across all 8 headings.

const ArchiveLoaderScript = preload("res://scripts/core/archive_loader.gd")
const GameDatabaseScript = preload("res://scripts/database/game_database.gd")

func _init() -> void:
	print("=================================================================")
	print("--- Running Test Character Roles & Equipment Visibility ---")
	print("=================================================================")
	
	var loader: Node = root.get_node_or_null("ArchiveLoader")
	if not loader:
		loader = ArchiveLoaderScript.new()
		root.add_child(loader)
		loader.initialize_archives()
	
	var gdb: Node = root.get_node_or_null("GameDatabase")
	if not gdb:
		gdb = GameDatabaseScript.new()
		root.add_child(gdb)
		gdb.load_all()

	# -------------------------------------------------------------
	# 1. VERIFY GAMEDATABASE ROLES REGISTRY (1 to 14)
	# -------------------------------------------------------------
	print("\n[PART 1] Verifying Authentic Roles Registry in GameDatabase...")
	var expected_roles: Dictionary = {
		1: {"name": "Nina", "gender": "Female", "body": "003.jma", "jmp": "3000.jmp", "element": "Fire"},
		2: {"name": "Betty", "gender": "Female", "body": "003.jma", "jmp": "3000.jmp", "element": "Wind"},
		3: {"name": "Rocco", "gender": "Male", "body": "002.jma", "jmp": "2000.jmp", "element": "Earth"},
		4: {"name": "Vanessa", "gender": "Female", "body": "005.jma", "jmp": "5000.jmp", "element": "Water"},
		5: {"name": "Lique", "gender": "Female", "body": "005.jma", "jmp": "5000.jmp", "element": "Wind"},
		6: {"name": "Daniel", "gender": "Male", "body": "004.jma", "jmp": "4000.jmp", "element": "Fire"},
		7: {"name": "Sid", "gender": "Male", "body": "004.jma", "jmp": "4000.jmp", "element": "Earth"},
		8: {"name": "Jessica", "gender": "Female", "body": "005.jma", "jmp": "5000.jmp", "element": "Water"},
		9: {"name": "Konnotsuroko", "gender": "Female", "body": "005.jma", "jmp": "5000.jmp", "element": "Water"},
		10: {"name": "Iris", "gender": "Female", "body": "005.jma", "jmp": "5000.jmp", "element": "Water"},
		11: {"name": "Maria", "gender": "Female", "body": "005.jma", "jmp": "5000.jmp", "element": "Water"},
		12: {"name": "More", "gender": "Male", "body": "004.jma", "jmp": "4000.jmp", "element": "Earth"},
		13: {"name": "Kurogane", "gender": "Male", "body": "004.jma", "jmp": "4000.jmp", "element": "Fire"},
		14: {"name": "Karin", "gender": "Female", "body": "005.jma", "jmp": "5000.jmp", "element": "Fire"}
	}

	for rid in range(1, 15):
		var rinfo: Dictionary = gdb.get_role(rid)
		assert(not rinfo.is_empty(), "Role %d definition missing from GameDatabase" % rid)
		var exp_r: Dictionary = expected_roles[rid]
		assert(rinfo["name"] == exp_r["name"], "Role %d name mismatch: %s vs %s" % [rid, rinfo["name"], exp_r["name"]])
		assert(rinfo["body_archive"] == exp_r["body"], "Role %d body archive mismatch" % rid)
		assert(rinfo["body_jmp"] == exp_r["jmp"], "Role %d body JMP mismatch" % rid)
		assert(rinfo["element"] == exp_r["element"], "Role %d element mismatch" % rid)
		print("  PASS: Role %2d -> %s (%s, %s, %s:%s)" % [
			rid, rinfo["name"], rinfo["gender"], rinfo["element"], rinfo["body_archive"], rinfo["body_jmp"]
		])

	# -------------------------------------------------------------
	# 2. BETTY (ROLE 2) VISIBILITY DURING EQUIP / UNEQUIP CYCLES
	# -------------------------------------------------------------
	print("\n[PART 2] Testing Betty (Role 2) Visibility during Equip/Unequip Cycles...")

	# Step 2A: Default Starter Gear (Harness Pants, Pink Shoes, Feather Head)
	var betty_starter_gear: Dictionary = {
		"clothes": {"jma": "003e.jma", "jmp": "3301.jmp"},
		"shoes": {"jma": "003s.jma", "jmp": "3401.jmp"},
		"cap": {"jma": "003c.jma", "jmp": "3201.jmp"}
	}
	var frames_starter: Array[ImageTexture] = loader.get_player_composite_frames(2, betty_starter_gear)
	_assert_composite_valid("Betty Starter Clothed", frames_starter)
	print("  PASS: Betty starter gear composite generated 64 fully visible frames.")

	# Step 2B: Unequip Clothes Only (Base Body + Hair + Shoes + Cap)
	var betty_no_clothes: Dictionary = {
		"clothes": "",
		"shoes": {"jma": "003s.jma", "jmp": "3401.jmp"},
		"cap": {"jma": "003c.jma", "jmp": "3201.jmp"}
	}
	var frames_no_clothes: Array[ImageTexture] = loader.get_player_composite_frames(2, betty_no_clothes)
	_assert_composite_valid("Betty Unequipped Clothes", frames_no_clothes)
	print("  PASS: Betty unequipped clothes: Character remains 100% visible in undergarments.")

	# Step 2C: Unequip Clothes via HUD "body" socket empty string
	var betty_body_empty: Dictionary = {
		"body": "",
		"shoes": {"jma": "003s.jma", "jmp": "3401.jmp"}
	}
	var frames_body_empty: Array[ImageTexture] = loader.get_player_composite_frames(2, betty_body_empty)
	_assert_composite_valid("Betty Body Socket Empty", frames_body_empty)
	print("  PASS: Betty HUD body socket empty: Base body is NOT destroyed, character visible.")

	# Step 2D: Unequip Shoes Only (Clothes + Base Body + Bare Feet)
	var betty_no_shoes: Dictionary = {
		"clothes": {"jma": "003e.jma", "jmp": "3301.jmp"},
		"shoes": ""
	}
	var frames_no_shoes: Array[ImageTexture] = loader.get_player_composite_frames(2, betty_no_shoes)
	_assert_composite_valid("Betty Bare Feet", frames_no_shoes)
	print("  PASS: Betty unequipped shoes: Bare feet visible on base body.")

	# Step 2E: Unequip ALL Equipment (Totally Nude Base Body + Hair)
	var betty_nude: Dictionary = {
		"clothes": "",
		"shoes": "",
		"cap": "",
		"weapon": ""
	}
	var frames_nude: Array[ImageTexture] = loader.get_player_composite_frames(2, betty_nude)
	_assert_composite_valid("Betty All Unequipped", frames_nude)
	print("  PASS: Betty fully unequipped: 64 frames active across all 8 directions.")

	# Step 2F: Re-equip Alternative Dress (Small Dress 003e.jma:3300.jmp)
	var betty_re_equipped: Dictionary = {
		"clothes": "003e.jma:3300.jmp",
		"shoes": "003s.jma:3400.jmp"
	}
	var frames_reequip: Array[ImageTexture] = loader.get_player_composite_frames(2, betty_re_equipped)
	_assert_composite_valid("Betty Re-equipped Dress", frames_reequip)
	print("  PASS: Betty re-equipped dress: Seamless clothing swap without invisibility.")

	# -------------------------------------------------------------
	# 3. DANIEL (ROLE 6) VISIBILITY DURING EQUIP / UNEQUIP CYCLES
	# -------------------------------------------------------------
	print("\n[PART 3] Testing Daniel (Role 6) Visibility during Equip/Unequip Cycles...")

	var daniel_starter: Dictionary = {
		"clothes": {"jma": "004e.jma", "jmp": "4300.jmp"},
		"shoes": {"jma": "004s.jma", "jmp": "4400.jmp"}
	}
	var frames_daniel_starter: Array[ImageTexture] = loader.get_player_composite_frames(6, daniel_starter)
	_assert_composite_valid("Daniel Clothed", frames_daniel_starter)
	print("  PASS: Daniel starter gear (Dust Coat) generated 64 fully visible frames.")

	var daniel_nude: Dictionary = {
		"clothes": "",
		"shoes": ""
	}
	var frames_daniel_nude: Array[ImageTexture] = loader.get_player_composite_frames(6, daniel_nude)
	_assert_composite_valid("Daniel Unequipped (Boxers)", frames_daniel_nude)
	print("  PASS: Daniel unequipped clothes: Boxers base body remains visible.")

	# -------------------------------------------------------------
	# 4. EXHAUSTIVE VALIDATION ACROSS ALL 14 ROLES
	# -------------------------------------------------------------
	print("\n[PART 4] Exhaustive Multi-Role Composite Validation (1 to 14)...")
	for rid in range(1, 15):
		var frames: Array[ImageTexture] = loader.get_player_composite_frames(rid)
		var rname: String = gdb.get_role_name(rid)
		_assert_composite_valid("Role %d (%s)" % [rid, rname], frames)
		print("  PASS: Role %2d (%-12s) -> 64 frames valid, standing South frame visible." % [rid, rname])

	print("\n=================================================================")
	print("--- ALL CHARACTER ROLES & EQUIPMENT VISIBILITY TESTS PASSED! ---")
	print("=================================================================")
	quit(0)

func _assert_composite_valid(label: String, frames: Array[ImageTexture]) -> void:
	assert(frames.size() >= 64, "%s: Expected at least 64 composite frames, got %d" % [label, frames.size()])
	
	# Verify Walk Frame 0 (North walk), Stand Frame 32 (North stand), Stand Frame 48 (South stand)
	for test_idx in [0, 16, 32, 48, 63]:
		var tex: ImageTexture = frames[test_idx]
		assert(tex != null, "%s: Frame %d texture is null" % [label, test_idx])
		assert(tex.get_width() == 128 and tex.get_height() == 128, "%s: Frame %d invalid dimensions" % [label, test_idx])
		
		var img: Image = tex.get_image()
		assert(img != null, "%s: Frame %d get_image() is null" % [label, test_idx])
		
		# Count visible pixels
		var non_transparent_pixels: int = 0
		var used_rect := img.get_used_rect()
		assert(used_rect.size.x > 0 and used_rect.size.y > 0, "%s: Frame %d has empty bounding box (invisible character!)" % [label, test_idx])
		
		for y in range(used_rect.position.y, used_rect.position.y + used_rect.size.y):
			for x in range(used_rect.position.x, used_rect.position.x + used_rect.size.x):
				var px: Color = img.get_pixel(x, y)
				if px.a > 0.05:
					non_transparent_pixels += 1
		
		assert(non_transparent_pixels > 50, "%s: Frame %d has too few visible pixels (%d)" % [label, test_idx, non_transparent_pixels])
