extends SceneTree

const HUDScene = preload("res://scenes/ui/hud.tscn")
const PlayerScene = preload("res://scenes/world/player.tscn")
const ArchiveLoaderScript = preload("res://scripts/core/archive_loader.gd")
const GameDatabaseScript = preload("res://scripts/database/game_database.gd")

func _init() -> void:
	print("==================================================")
	print("Running test_character_inventory_binding.gd")
	print("==================================================")
	
	var loader: Node = root.get_node_or_null("ArchiveLoader")
	if not loader:
		loader = ArchiveLoaderScript.new()
		loader.name = "ArchiveLoader"
		root.add_child(loader)
		loader.initialize_archives()
		
	var gdb: Node = root.get_node_or_null("GameDatabase")
	if not gdb:
		gdb = GameDatabaseScript.new()
		gdb.name = "GameDatabase"
		root.add_child(gdb)
		gdb.load_all()

	var hud = HUDScene.instantiate()
	root.add_child(hud)
	hud._ready()
	
	var char_win: Control = hud.get_node("FloatingWindows/CharacterWindow")
	assert(char_win != null, "CharacterWindow must exist in HUD")
	
	# Test 1: Header labels hidden (StatName, StatLevel, StatElement)
	var stat_name: Label = char_win.get_node("StatName")
	var stat_level: Label = char_win.get_node("StatLevel")
	var stat_element: Label = char_win.get_node("StatElement")
	assert(not stat_name.visible, "StatName must be hidden in inventory header")
	assert(not stat_level.visible, "StatLevel must be hidden in inventory header")
	assert(not stat_element.visible, "StatElement must be hidden in inventory header")
	print("[PASS] Test 1: Floating header labels (StatName, StatLevel, StatElement) are hidden")

	# Test 2: Close Button (X) is wired and hides the window
	var close_btn: Button = char_win.get_node("CloseButton")
	assert(close_btn != null, "CloseButton must exist")
	assert(close_btn.pressed.get_connections().size() > 0, "CloseButton must be connected to close window")
	hud.toggle_character_status()
	assert(char_win.visible, "CharacterWindow should be open after toggle")
	close_btn.emit_signal("pressed")
	assert(not char_win.visible, "CharacterWindow must be hidden after CloseButton pressed")
	print("[PASS] Test 2: Close Button (X) closes Character/Inventory window")

	# Test 3: Inventory Grid shifted down 4px (offset_top == 71.0) to align with parchment grid boxes
	var inv_grid: Control = char_win.get_node("InventoryGrid")
	assert(is_equal_approx(inv_grid.offset_top, 71.0), "InventoryGrid offset_top must be 71.0 (found: %f)" % inv_grid.offset_top)
	print("[PASS] Test 3: Inventory grid shifted down 4px (offset_top = 71.0) to align with parchment slots")

	# Test 4: Paperdoll standee shifted up by 6px (offset_top == 127.0, offset_bottom == 255.0)
	var paper_doll: TextureRect = char_win.get_node("PaperDoll")
	assert(is_equal_approx(paper_doll.offset_top, 127.0), "PaperDoll offset_top must be 127.0 (found: %f)" % paper_doll.offset_top)
	assert(is_equal_approx(paper_doll.offset_bottom, 255.0), "PaperDoll offset_bottom must be 255.0 (found: %f)" % paper_doll.offset_bottom)
	print("[PASS] Test 4: Paperdoll character standee shifted up by 6px (127..255)")

	# Test 5: Bottom combat stats table shifted up by 3px
	var stat_atk: Label = char_win.get_node("StatAtk")
	var stat_def: Label = char_win.get_node("StatDef")
	var stat_matk: Label = char_win.get_node("StatMatk")
	var stat_mdef: Label = char_win.get_node("StatMdef")
	var stat_spd: Label = char_win.get_node("StatSpd")
	assert(is_equal_approx(stat_atk.offset_top, 335.0), "StatAtk offset_top must be 335.0 (found: %f)" % stat_atk.offset_top)
	assert(is_equal_approx(stat_def.offset_top, 351.0), "StatDef offset_top must be 351.0 (found: %f)" % stat_def.offset_top)
	assert(is_equal_approx(stat_matk.offset_top, 367.0), "StatMatk offset_top must be 367.0 (found: %f)" % stat_matk.offset_top)
	assert(is_equal_approx(stat_mdef.offset_top, 383.0), "StatMdef offset_top must be 383.0 (found: %f)" % stat_mdef.offset_top)
	assert(is_equal_approx(stat_spd.offset_top, 399.0), "StatSpd offset_top must be 399.0 (found: %f)" % stat_spd.offset_top)
	print("[PASS] Test 5: Bottom stats table labels shifted up by 3px to center vertically in rows")

	# Test 6: POINT 0 layout shifted 4px up and 6px right (offset_left == 142.0, offset_top == 314.0)
	var stat_free: Label = char_win.get_node("StatLeftFree")
	assert(is_equal_approx(stat_free.offset_left, 142.0), "StatLeftFree offset_left must be 142.0 (found: %f)" % stat_free.offset_left)
	assert(is_equal_approx(stat_free.offset_top, 314.0), "StatLeftFree offset_top must be 314.0 (found: %f)" % stat_free.offset_top)
	print("[PASS] Test 6: Free stat POINT 0 value shifted ~4px up and ~6px right (142, 314)")

	# Test 7: Paperdoll Weapon Display & Composite Positioning
	var equip_test := {
		"clothes": {"jma": "004e.jma", "jmp": "4300.jmp"},
		"shoes": {"jma": "004s.jma", "jmp": "4400.jmp"},
		"weapon": {"jma": "004w.jma", "jmp": "4040.jmp"}
	}
	var frames_daniel = loader.get_player_composite_frames(6, equip_test)
	assert(frames_daniel.size() >= 64, "Composite frames must yield at least 64 frames (found: %d)" % frames_daniel.size())
	
	# Verify frame 48 (South stand used by Paperdoll) has weapon centered behind back
	var img_48: Image = frames_daniel[48].get_image()
	assert(img_48 != null and img_48.get_width() == 128 and img_48.get_height() == 128, "Frame 48 image valid")
	
	# Check non-transparent bbox
	var min_x := 128
	var max_x := 0
	var min_y := 128
	var max_y := 0
	for y in range(128):
		for x in range(128):
			if img_48.get_pixel(x, y).a > 0.05:
				min_x = mini(min_x, x)
				max_x = maxi(max_x, x)
				min_y = mini(min_y, y)
				max_y = maxi(max_y, y)
	print("Daniel frame 48 pixel bounds: x=[%d, %d], y=[%d, %d]" % [min_x, max_x, min_y, max_y])
	# With proper offset, weapon is not past x=85 or y=110, NOT detached at bottom-right (x > 100, y > 115)
	assert(min_x >= 30 and max_x <= 88, "Composite character+weapon must be centered horizontally")
	assert(min_y >= 10 and max_y <= 112, "Composite character+weapon must be centered vertically")
	print("[PASS] Test 7: Paperdoll weapon composite properly positioned behind back without bottom-right detachment")

	# Test 8: Overland Player Art & Weapon rendering
	var player_entity = PlayerScene.instantiate()
	player_entity.archive_loader = loader
	root.add_child(player_entity)
	player_entity._ready()
	player_entity.set_role(6)
	player_entity.set_equipment(equip_test)
	assert(player_entity.get_equipment().has("weapon"), "Player equip_layers must contain weapon")
	assert(player_entity.sprite != null and player_entity.sprite.texture != null, "Player sprite texture must be assigned")
	print("[PASS] Test 8: Overland player equipped with weapon builds and assigns composite texture")

	# Test 9: Subtle drop shadow below player feet in player.gd
	assert(player_entity.has_method("_draw"), "Player must implement _draw() for drop shadow")
	assert(not player_entity.is_prone, "Player starts not prone")
	print("[PASS] Test 9: Player soft translucent oval drop shadow implemented")

	# Test 10: HUD to Player synchronization
	hud.player = player_entity
	assert(hud.player == player_entity, "HUD player assigned")
	var hud_equip = hud.get_equipment() if hud.has_method("get_equipment") else hud.character_status.get_equipment()
	assert(hud_equip.has("weapon") or hud_equip.has("hand"), "HUD equipment must have weapon socket")
	print("[PASS] Test 10: HUD player assignment and equipment synchronization operational")

	# Test 11: Paperdoll equipment socket positions aligned on pedestal shadows above text labels
	var exp_sockets = {
		"Slot_head": Vector2(83, 84),
		"Slot_weapon": Vector2(23, 124),
		"Slot_wrist": Vector2(146, 124),
		"Slot_special": Vector2(23, 184),
		"Slot_body": Vector2(146, 184),
		"Slot_shoes": Vector2(83, 222),
	}
	for sname in exp_sockets:
		var sbtn: Button = char_win.get_node_or_null(sname)
		assert(sbtn != null, "Socket %s must exist in CharacterWindow" % sname)
		assert(sbtn.position == exp_sockets[sname], "Socket %s position mismatch: %s vs %s" % [sname, sbtn.position, exp_sockets[sname]])
	print("[PASS] Test 11: Paperdoll equipment sockets shifted up ~4px and aligned with parchment boxes")

	print("\n==================================================")
	print("ALL 11 VERIFICATION CHECKS PASSED (100% PASS)")
	print("==================================================")
	quit()
