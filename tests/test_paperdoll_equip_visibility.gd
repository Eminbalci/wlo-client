extends SceneTree

func _init() -> void:
	print("--- Running Test Paperdoll Equipment Visibility ---")
	
	var loader = root.get_node_or_null("ArchiveLoader")
	if not loader:
		var cls = load("res://scripts/core/archive_loader.gd")
		loader = cls.new()
		root.add_child(loader)
	
	# Test 1: Role 2 (Betty) with default gear (empty dictionary)
	var frames_default = loader.get_player_composite_frames(2, {})
	assert(frames_default.size() >= 64, "Default Betty composite should have >= 64 frames, got %d" % frames_default.size())
	print("PASS: Default Betty composite loaded >= 64 frames.")
	
	# Test 2: Unequipped clothes (body = "")
	var frames_unequipped = loader.get_player_composite_frames(2, {"body": ""})
	assert(frames_unequipped.size() >= 64, "Unequipped clothes must NOT produce empty frames! got %d" % frames_unequipped.size())
	print("PASS: Unequipped clothes maintains visible composite frames.")
	
	# Test 3: Null body slot (simulates unequip)
	var frames_null = loader.get_player_composite_frames(2, {"body": null, "shoes": null, "head": null})
	assert(frames_null.size() >= 64, "Stripped character must NOT be invisible! got %d" % frames_null.size())
	print("PASS: Completely unequipped character has base body & hair visible (>= 64 frames).")
	
	# Test 4: Equipping invalid/non-existent item into clothes
	var frames_invalid = loader.get_player_composite_frames(2, {"body": "unknown_item_9999.jmp"})
	assert(frames_invalid.size() >= 64, "Equipping unmapped item must NOT cause character invisibility! got %d" % frames_invalid.size())
	print("PASS: Equipping unmapped clothes falls back to base body without turning invisible.")
	
	# Test 5: Equipping valid clothes
	var frames_clothed = loader.get_player_composite_frames(2, {"body": "002e.jma:2300.jmp", "shoes": "002s.jma:2400.jmp"})
	assert(frames_clothed.size() >= 64, "Equipped clothes should have >= 64 frames, got %d" % frames_clothed.size())
	print("PASS: Equipping valid clothes and shoes produces clothed frames.")
	
	# Test 6: Verify pixel content is not blank transparent
	var test_tex = frames_null[32] # Stand south
	var test_img = test_tex.get_image()
	assert(test_img != null, "Image must exist")
	var has_non_transparent = false
	for y in range(test_img.get_height()):
		for x in range(test_img.get_width()):
			if test_img.get_pixel(x, y).a > 0.1:
				has_non_transparent = true
				break
		if has_non_transparent:
			break
	assert(has_non_transparent == true, "Character composite must have visible non-transparent pixels!")
	print("PASS: Character composite verified to contain visible opaque pixels (not invisible).")
	
	print("--- ALL PAPERDOLL VISIBILITY TESTS PASSED ---")
	quit(0)
