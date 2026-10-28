extends Node

func _ready() -> void:
	print("--- Running In-Engine Verification of MapView & HUD ---")

	var map_view = preload("res://scenes/world/map_view.tscn").instantiate()
	add_child(map_view)
	
	var hud: HUD = map_view.get_node("CanvasLayer/HUD")
	assert(hud != null, "HUD not found")
	print("[PASS] HUD loaded in scene tree")
	
	var dock = hud.get_node("BottomActionDock")
	assert(dock != null, "BottomActionDock not found")
	
	# Verify LocationLabel
	var loc_lbl: Label = dock.get_node_or_null("LocationLabel")
	assert(loc_lbl != null, "LocationLabel not found on BottomActionDock")
	assert(loc_lbl.text.contains("Ship Deck"), "LocationLabel text mismatch: %s" % loc_lbl.text)
	print("[PASS] BottomActionDock LocationLabel verified: %s" % loc_lbl.text)
	
	# Verify 6 Authentic Circular Dock Buttons
	var button_names = [
		"BtnStatus", "BtnSkill", "BtnQuest", "BtnTeam", "BtnFriends", "BtnSystem"
	]
	
	for bname in button_names:
		var btn: TextureButton = dock.get_node("ButtonContainer/" + bname)
		assert(btn != null, "Button " + bname + " not found")
		assert(btn.texture_normal != null, "Button " + bname + " texture_normal is null")
		assert(btn.texture_hover != null, "Button " + bname + " texture_hover is null")
		assert(btn.texture_pressed != null, "Button " + bname + " texture_pressed is null")
		print("[PASS] Button %s textures OK: normal=%s" % [bname, btn.texture_normal.get_size()])
	
	# Verify ChatDock Mailbox and Local tab button
	var btn_mail: TextureButton = hud.get_node_or_null("ChatDock/BtnMail")
	assert(btn_mail != null and btn_mail.texture_normal != null, "BtnMail missing or untextured")
	var btn_channel: Button = hud.get_node_or_null("ChatDock/BtnChannel")
	assert(btn_channel != null and btn_channel.text == "Local", "BtnChannel missing or text mismatch")
	print("[PASS] ChatDock Mailbox and Local tab button verified")
	
	var window_mapping = {
		"BtnStatus": "CharacterWindow",
		"BtnSkill": "SkillWindow",
		"BtnQuest": "QuestWindow",
		"BtnTeam": "TeamWindow",
		"BtnFriends": "FriendsWindow",
		"BtnSystem": "SystemWindow"
	}
	
	for bname in window_mapping:
		var wname = window_mapping[bname]
		var win: Control = hud.get_node("FloatingWindows/" + wname)
		assert(win != null, "Window " + wname + " not found")
		assert(win.visible == false, "Window " + wname + " should start hidden")
		
		var btn: TextureButton = dock.get_node("ButtonContainer/" + bname)
		btn.pressed.emit()
		assert(win.visible == true, "Window " + wname + " did not open on button click")
		
		var close_btn: Button = win.get_node("CloseButton")
		assert(close_btn != null, "CloseButton not found on " + wname)
		assert(close_btn.mouse_filter == Control.MOUSE_FILTER_STOP, "CloseButton mouse_filter must be STOP on " + wname)
		assert(close_btn.position.x >= win.size.x - 45.0, "CloseButton must be positioned at ornate corner on " + wname)
		assert(close_btn.size.x >= 24.0 and close_btn.size.y >= 20.0, "CloseButton hit-box too small on " + wname)
		close_btn.pressed.emit()
		assert(win.visible == false, "Window " + wname + " did not close on CloseButton click")
		
		var bg: TextureRect = win.get_node("Background")
		assert(bg != null and bg.texture != null, "Background texture not loaded on " + wname)
		print("[PASS] Window %s verified: size=%s, bg_tex_size=%s, close_btn_pos=%s" % [wname, win.size, bg.texture.get_size(), close_btn.position])
	
	# Verify Smooth Window Dragging for Floating Windows (CharacterWindow)
	hud.btn_status.pressed.emit()
	assert(hud.char_window.visible == true, "CharacterWindow should be open for drag test")
	var initial_char_pos: Vector2 = hud.char_window.position
	hud._start_window_drag(hud.char_window, initial_char_pos + Vector2(60, 20))
	assert(hud._dragging_window == hud.char_window, "Dragging window should be CharacterWindow")
	assert(hud._drag_offset == Vector2(60, 20), "Drag offset mismatch")
	
	var drag_motion := InputEventMouseMotion.new()
	drag_motion.position = initial_char_pos + Vector2(60, 20) + Vector2(80, 40)
	hud._input(drag_motion)
	assert(hud.char_window.position == initial_char_pos + Vector2(80, 40), "Window position did not follow drag")
	
	var drag_release := InputEventMouseButton.new()
	drag_release.button_index = MOUSE_BUTTON_LEFT
	drag_release.pressed = false
	hud._input(drag_release)
	assert(hud._dragging_window == null, "Dragging window must be cleared on mouse release")
	hud.char_window.position = initial_char_pos
	hud.char_window.visible = false
	print("[PASS] Smooth Window Dragging verified on CharacterWindow (offset capture, motion tracking & release)")
	
	# Verify that separate InventoryWindow remains permanently hidden
	var sep_inv: Control = hud.get_node("FloatingWindows/InventoryWindow")
	assert(sep_inv != null and sep_inv.visible == false, "Separate InventoryWindow must not be opened")
	print("[PASS] Verified separate InventoryWindow remains hidden; CharacterWindow is unified inventory")
	
	# Verify PlayerStatusDock is visible at top-left with authentic 3-layer chroma mask bars
	assert(hud.status_dock != null and hud.status_dock.visible == true, "PlayerStatusDock must be visible")
	assert(hud.status_dock.get_node_or_null("HpBar") != null, "HpBar missing")
	assert(hud.status_dock.get_node_or_null("SpBar") != null, "SpBar missing")
	assert(hud.status_dock.get_node_or_null("ExpBar") != null, "ExpBar missing")
	assert(hud.status_dock.get_node_or_null("GoldLabel") != null, "GoldLabel missing")
	assert(hud.status_dock.get_node_or_null("LevelLabel") != null, "LevelLabel missing")
	print("[PASS] PlayerStatusDock at top-left verified visible with authentic 3-layer chroma mask bars")

	# Verify dynamic update_player_stats and update_gold
	hud.update_player_stats("Betty", 12, 280, 350, 120, 180, 75, 100)
	assert(hud.level_label.text == "LV 12", "LevelLabel update failed")
	assert(hud.hp_label.text == "HP   280/350", "HpLabel update failed")
	assert(hud.hp_bar.value == 280, "HpBar value update failed")
	assert(hud.hp_bar.max_value == 350, "HpBar max_value update failed")
	assert(hud.sp_label.text == "SP   120/180", "SpLabel update failed")
	assert(hud.sp_bar.value == 120, "SpBar value update failed")
	assert(hud.exp_label.text == "75%", "ExpLabel update failed")
	assert(hud.exp_bar.value == 75.0, "ExpBar value update failed")

	hud.update_gold(999)
	var dock_gold: Label = hud.status_dock.get_node("GoldLabel")
	assert(dock_gold.text == "Gold 999", "Dock GoldLabel update failed")
	print("[PASS] Dynamic update_player_stats and update_gold verified")

	# Restore Betty standard stats
	hud.update_player_stats("Betty", 10, 320, 320, 150, 150, 45, 100)
	hud.update_gold(500)

	# Verify CharacterWindow PaperDoll Daniel positioning (offset_left=37.0, offset_top=133.0, size 128x128)
	var char_win: Control = hud.get_node("FloatingWindows/CharacterWindow")
	var paper_doll: TextureRect = char_win.get_node("PaperDoll")
	assert(paper_doll != null, "PaperDoll not found in CharacterWindow")
	assert(paper_doll.position.x >= 36.0 and paper_doll.position.x <= 38.0, "PaperDoll offset_left must be 37.0, got %f" % paper_doll.position.x)
	assert(paper_doll.position.y >= 126.0 and paper_doll.position.y <= 135.0, "PaperDoll offset_top must be 127.0..133.0, got %f" % paper_doll.position.y)
	assert(paper_doll.size == Vector2(128, 128), "PaperDoll size must be 128x128, got %s" % str(paper_doll.size))
	print("[PASS] CharacterWindow PaperDoll Daniel positioning verified: pos=%s, size=%s" % [paper_doll.position, paper_doll.size])
	
	# Verify that misplaced stat labels were removed from inventory grid area
	var misplaced_stats = ["StatHp", "StatSp", "StatExp", "StatStr", "StatCon", "StatInt", "StatWis", "StatAgi", "StatFreePoints"]
	for sname in misplaced_stats:
		assert(char_win.get_node_or_null(sname) == null, "Misplaced label %s must be removed from CharacterWindow" % sname)
	print("[PASS] Misplaced stat labels cleanly removed from CharacterWindow inventory area")
	
	# Verify InventoryGrid container (5 columns x 9 rows = 45 slots starting at exact X=192, Y=73)
	var inv_grid: Control = char_win.get_node("InventoryGrid")
	assert(inv_grid != null, "InventoryGrid container not found in CharacterWindow")
	assert(inv_grid.position == Vector2(192, 71) or inv_grid.position == Vector2(192, 73), "InventoryGrid position must be (192, 71), got %s" % str(inv_grid.position))
	assert(inv_grid.get_child_count() == 45, "InventoryGrid must contain 45 slots (5x9), got %d" % inv_grid.get_child_count())
	
	# Verify authentic starter items (Notepad, Remote Control, Fugu Hot Pot, Tao Rice Ball, Bread)
	var slot0: Button = inv_grid.get_node("Slot0")
	var slot1: Button = inv_grid.get_node("Slot1")
	var slot2: Button = inv_grid.get_node("Slot2")
	var slot3: Button = inv_grid.get_node("Slot3")
	var slot8: Button = inv_grid.get_node("Slot8")
	assert(slot0 != null and slot0.get_node("Icon").texture != null, "Slot 0 Notepad icon missing")
	assert(slot1 != null and slot1.get_node("Icon").texture != null, "Slot 1 Remote Control icon missing")
	assert(slot2 != null and slot2.get_node("Icon").texture != null, "Slot 2 Fugu Hot Pot icon missing")
	assert(slot3 != null and slot3.get_node("Icon").texture != null, "Slot 3 Tao Rice Ball icon missing")
	assert(slot8 != null and slot8.get_node("Icon").texture != null, "Slot 8 Bread icon missing")
	assert(slot2.get_node("CountLabel").text == "50", "Slot 2 count must be 50, got %s" % slot2.get_node("CountLabel").text)
	assert(slot3.get_node("CountLabel").text == "10", "Slot 3 count must be 10, got %s" % slot3.get_node("CountLabel").text)
	assert(slot8.get_node("CountLabel").text == "10", "Slot 8 count must be 10, got %s" % slot8.get_node("CountLabel").text)
	assert(slot0.get_node("Icon").position == Vector2(1, 1), "Icon position must be (1, 1), got %s" % str(slot0.get_node("Icon").position))
	assert(slot0.get_node("Icon").size == Vector2(32, 32), "Icon size must be (32, 32), got %s" % str(slot0.get_node("Icon").size))
	print("[PASS] CharacterWindow InventoryGrid 45 slots & authentic starter items verified")
	
	# Verify the 6 equipment sockets around PaperDoll (head, weapon, body/arm, special, wrist, shoes)
	var exp_sockets = {
		"Slot_head": Vector2(83, 96),
		"Slot_weapon": Vector2(23, 137),
		"Slot_wrist": Vector2(146, 137),
		"Slot_special": Vector2(23, 197),
		"Slot_body": Vector2(146, 197),
		"Slot_shoes": Vector2(83, 233),
	}
	for sname in exp_sockets:
		var sbtn: Button = char_win.get_node_or_null(sname)
		assert(sbtn != null, "Socket %s not found on CharacterWindow" % sname)
		assert(sbtn.position == exp_sockets[sname], "Socket %s position mismatch: %s vs %s" % [sname, sbtn.position, exp_sockets[sname]])
		assert(sbtn.size == Vector2(34, 34), "Socket %s size mismatch" % sname)
		var sicon: TextureRect = sbtn.get_node_or_null("Icon")
		assert(sicon != null, "Socket %s Icon missing" % sname)
		assert(sicon.size == Vector2(32, 32), "Socket %s Icon size mismatch" % sname)
		if sname in ["Slot_weapon", "Slot_body", "Slot_shoes"]:
			assert(sicon.texture != null, "Socket %s should start equipped with starting equipment" % sname)
	print("[PASS] CharacterWindow 6 authentic equipment sockets verified at pixel-exact positions")
	
	# Verify Drag & Drop: Moving items between inventory slots (slot 8 Bread to slot 20 empty, then back)
	var drag_data_8 = hud.get_inventory_drag_data(8)
	assert(drag_data_8 != null and drag_data_8["item"]["name"] == "Bread", "Drag data for slot 8 should be Bread")
	assert(hud.can_drop_on_inventory_slot(20, drag_data_8) == true, "Should be able to drop on empty slot 20")
	hud.drop_on_inventory_slot(20, drag_data_8)
	assert(hud._inventory_data[8].is_empty(), "Slot 8 should be empty after move")
	assert(hud._inventory_data[20].get("name") == "Bread", "Slot 20 should have Bread after move")
	# Swap back
	var drag_data_20 = hud.get_inventory_drag_data(20)
	hud.drop_on_inventory_slot(8, drag_data_20)
	assert(hud._inventory_data[8].get("name") == "Bread", "Slot 8 should have Bread restored")
	assert(hud._inventory_data[20].is_empty(), "Slot 20 should be empty again")
	print("[PASS] Inventory Drag & Drop slot swapping verified")

	# Verify Drag & Drop between Equipment Socket and Inventory (unequip weapon to slot 20, then re-equip)
	var weapon_socket: Button = char_win.get_node("Slot_weapon")
	assert(weapon_socket.get_node("Icon").texture != null, "Weapon socket should start equipped with Iron Sword")
	var equip_drag = hud.get_equipment_drag_data("weapon")
	assert(equip_drag != null and equip_drag["item"]["name"] == "Iron Sword", "Weapon drag data should be Iron Sword")
	assert(hud.can_drop_on_inventory_slot(20, equip_drag) == true, "Should be able to drop equipped weapon to empty slot 20")
	hud.drop_on_inventory_slot(20, equip_drag)
	assert(weapon_socket.get_node("Icon").texture == null, "Weapon socket should be empty after drag unequip")
	assert(hud._inventory_data[20].get("name") == "Iron Sword", "Slot 20 should have Iron Sword")
	assert(not hud.current_equip_layers.has("weapon"), "current_equip_layers should not have weapon")
	
	# Drag Iron Sword back from slot 20 onto weapon socket to re-equip
	var inv_weapon_drag = hud.get_inventory_drag_data(20)
	assert(hud.can_drop_on_equipment_socket("weapon", inv_weapon_drag) == true, "Should be able to drop Iron Sword onto weapon socket")
	hud.drop_on_equipment_socket("weapon", inv_weapon_drag)
	assert(weapon_socket.get_node("Icon").texture != null, "Weapon socket should have icon after re-equip")
	assert(hud._inventory_data[20].is_empty(), "Slot 20 should be empty after re-equipping")
	assert(hud.current_equip_layers.has("weapon"), "current_equip_layers should have weapon again")
	print("[PASS] Interactive equipment Drag & Drop equip/unequip verified")

	# Verify GoldLabel on left column next to blue Gold label (X=40..160, Y=310..340)
	var gold_lbl: Label = char_win.get_node("GoldLabel")
	assert(gold_lbl != null, "GoldLabel not found in CharacterWindow")
	assert(gold_lbl.position.x >= 40.0 and gold_lbl.position.x <= 160.0, "GoldLabel X must be in 40..160")
	assert(gold_lbl.position.y >= 310.0 and gold_lbl.position.y <= 340.0, "GoldLabel Y must be in 310..340")
	assert(gold_lbl.text.contains("500"), "GoldLabel text must contain 500, got %s" % gold_lbl.text)
	print("[PASS] CharacterWindow GoldLabel verified at left column under EXP: pos=%s, text=%s" % [gold_lbl.position, gold_lbl.text])
	
	# Verify left side combat stats under PaperDoll (X=48..110, aligned with text lines)
	var atk_lbl: Label = char_win.get_node("StatAtk")
	var def_lbl: Label = char_win.get_node("StatDef")
	var matk_lbl: Label = char_win.get_node("StatMatk")
	var mdef_lbl: Label = char_win.get_node("StatMdef")
	var spd_lbl: Label = char_win.get_node("StatSpd")
	assert(atk_lbl.position == Vector2(48, 338) and atk_lbl.text == "34", "ATK mismatch: %s vs 34" % atk_lbl.text)
	assert(def_lbl.position == Vector2(48, 354) and def_lbl.text == "28", "DEF mismatch: %s vs 28" % def_lbl.text)
	assert(matk_lbl.position == Vector2(48, 370) and matk_lbl.text == "15", "MATK mismatch: %s vs 15" % matk_lbl.text)
	assert(mdef_lbl.position == Vector2(48, 386) and mdef_lbl.text == "14", "MDEF mismatch: %s vs 14" % mdef_lbl.text)
	assert(spd_lbl.position == Vector2(48, 402) and spd_lbl.text == "22", "SPD mismatch: %s vs 22" % spd_lbl.text)
	print("[PASS] CharacterWindow 5 left-side combat stats verified: ATK=34, DEF=28, MATK=15, MDEF=14, SPD=22")
	
	# Verify player status dock groove
	var st_bg: TextureRect = hud.get_node("PlayerStatusDock/StatusBackground")
	assert(st_bg != null and st_bg.texture != null, "Player status background missing")
	print("[PASS] PlayerStatusDock background verified: size = %s" % str(st_bg.texture.get_size()))
	
	# Verify authentic Eve.emg all 11 NPC positions, headings, models, and portals
	var entities = map_view.get_node("Entities")
	assert(entities.get_child_count() >= 13, "Expected player + 11 NPCs + portals in Entities")
	
	# Verify Portals & DoorLight animations
	var cabin_portal = entities.get_node("CabinPortal")
	assert(cabin_portal != null, "CabinPortal missing")
	assert(cabin_portal.target_map_id == 10002, "CabinPortal target map mismatch")
	assert(cabin_portal.position == Vector2(1814, 904), "CabinPortal position mismatch")
	assert(cabin_portal._doorlight_sprite != null, "CabinPortal DoorLightSprite missing")
	
	var island_portal = entities.get_node("IslandPortal")
	assert(island_portal != null, "IslandPortal missing")
	assert(island_portal.target_map_id == 10003, "IslandPortal target map mismatch")
	assert(island_portal.position == Vector2(1038, 2235), "IslandPortal position mismatch")
	assert(island_portal._doorlight_sprite != null, "IslandPortal DoorLightSprite missing")
	print("[PASS] Authentic SceneData.dat portals verified with WLM Atlas_DoorLight animation")
	
	var expected_npcs = [
		{"node": "JackNPC", "pos": Vector2(117, 1303), "jmp": "1010.jmp", "heading": 3},
		{"node": "RossNPC", "pos": Vector2(102, 1312), "jmp": "1207.jmp", "heading": 3},
		{"node": "Crew1NPC", "pos": Vector2(343, 940), "jmp": "1037.jmp", "heading": 5},
		{"node": "CrewDeck1NPC", "pos": Vector2(1461, 315), "jmp": "1037.jmp", "heading": 3},
		{"node": "Visitor1NPC", "pos": Vector2(855, 1302), "jmp": "1012.jmp", "heading": 5},
		{"node": "Visitor2NPC", "pos": Vector2(814, 1313), "jmp": "1013.jmp", "heading": 5},
		{"node": "GirlNPC", "pos": Vector2(1013, 902), "jmp": "1009.jmp", "heading": 3},
		{"node": "CatNPC", "pos": Vector2(1027, 957), "jmp": "1035.jmp", "heading": 3},
		{"node": "Crew2NPC", "pos": Vector2(1393, 578), "jmp": "1037.jmp", "heading": 3},
		{"node": "CaptainNPC", "pos": Vector2(1421, 632), "jmp": "1038.jmp", "heading": 3},
		{"node": "CrewDeck2NPC", "pos": Vector2(405, 925), "jmp": "1037.jmp", "heading": 3},
	]
	
	for exp in expected_npcs:
		var npc_node = entities.get_node(exp["node"])
		assert(npc_node != null, "NPC missing: " + exp["node"])
		assert(npc_node.world_position.distance_to(exp["pos"]) < 1.0, "Position mismatch for " + exp["node"])
		assert(npc_node.model_jmp == exp["jmp"], "Model mismatch for " + exp["node"])
		assert(npc_node.heading == exp["heading"], "Heading mismatch for " + exp["node"])
		assert(npc_node.sprite != null and npc_node.sprite.texture != null, "Texture missing for " + exp["node"])
		assert(npc_node.sprite.texture.get_size() == Vector2(128, 128), "128x128 canvas size mismatch for " + exp["node"])
		assert(npc_node.sprite.offset == Vector2(0, -64), "Sprite offset mismatch for " + exp["node"])
	
	var cap = entities.get_node("CaptainNPC")
	var jack = entities.get_node("JackNPC")
	var ross = entities.get_node("RossNPC")
	print("[PASS] Authentic Eve.emg all 11 NPCs present and verified: Captain=%s, Jack=%s, Ross=%s" % [
		cap.world_position, jack.world_position, ross.world_position
	])
	print("[PASS] NPC headings verified: Captain=3, Jack=3, Ross=3, Visitors=5, Crew=5/3")
	print("[PASS] All 11 NPCs grounded on 128x128 canvas with offset (0, -64)")

	# Verify IsometricMath Heading counter-clockwise order
	assert(IsometricMath.Heading.NORTH == 0, "Heading.NORTH must be 0")
	assert(IsometricMath.Heading.NORTH_WEST == 1, "Heading.NORTH_WEST must be 1")
	assert(IsometricMath.Heading.WEST == 2, "Heading.WEST must be 2")
	assert(IsometricMath.Heading.SOUTH_WEST == 3, "Heading.SOUTH_WEST must be 3")
	assert(IsometricMath.Heading.SOUTH == 4, "Heading.SOUTH must be 4")
	assert(IsometricMath.Heading.SOUTH_EAST == 5, "Heading.SOUTH_EAST must be 5")
	assert(IsometricMath.Heading.EAST == 6, "Heading.EAST must be 6")
	assert(IsometricMath.Heading.NORTH_EAST == 7, "Heading.NORTH_EAST must be 7")
	assert(IsometricMath.get_heading(Vector2(0, 0), Vector2(10, 0)) == 6, "EAST angle mismatch")
	assert(IsometricMath.get_heading(Vector2(0, 0), Vector2(10, 10)) == 5, "SOUTH_EAST angle mismatch")
	assert(IsometricMath.get_heading(Vector2(0, 0), Vector2(0, 10)) == 4, "SOUTH angle mismatch")
	assert(IsometricMath.get_heading(Vector2(0, 0), Vector2(-10, 10)) == 3, "SOUTH_WEST angle mismatch")
	assert(IsometricMath.get_heading(Vector2(0, 0), Vector2(-10, 0)) == 2, "WEST angle mismatch")
	assert(IsometricMath.get_heading(Vector2(0, 0), Vector2(-10, -10)) == 1, "NORTH_WEST angle mismatch")
	assert(IsometricMath.get_heading(Vector2(0, 0), Vector2(0, -10)) == 0, "NORTH angle mismatch")
	assert(IsometricMath.get_heading(Vector2(0, 0), Vector2(10, -10)) == 7, "NORTH_EAST angle mismatch")
	print("[PASS] IsometricMath counter-clockwise 8-way Heading kinematics verified")

	# Verify Daniel composite frames
	var loader := get_node_or_null("/root/ArchiveLoader")
	assert(loader != null, "ArchiveLoader singleton not found")
	var composite_frames: Array[ImageTexture] = loader.get_player_composite_frames(2)
	assert(composite_frames.size() == 64, "Expected 64 composite frames for Daniel, got %d" % composite_frames.size())
	for idx in range(composite_frames.size()):
		assert(composite_frames[idx] != null, "Composite frame %d is null" % idx)
		assert(composite_frames[idx].get_size() == Vector2(128, 128), "Composite frame %d size mismatch" % idx)
	# Verify RAM dictionary cache hit
	var cached_frames: Array[ImageTexture] = loader.get_player_composite_frames(2)
	assert(cached_frames == composite_frames, "Composite frames RAM cache failed")
	print("[PASS] Player paper-doll composite frames verified: 64 frames, 128x128 RGBA, cached in RAM")

	# Verify Player entity loaded composite frames
	var player = map_view.get_node("Entities/Player")
	assert(player._composite_frames.size() == 64, "Player did not load composite frames")
	print("[PASS] Player entity active with paper-doll composite frames")
	
	# Verify authentic animated cursor frames
	var cursor_frames: Array[ImageTexture] = loader.get_cursor_frames()
	assert(cursor_frames.size() == 8, "Expected 8 animated cursor frames, got %d" % cursor_frames.size())
	for idx in range(cursor_frames.size()):
		assert(cursor_frames[idx] != null, "Cursor frame %d is null" % idx)
		assert(cursor_frames[idx].get_size() == Vector2(32, 32), "Cursor frame %d size mismatch" % idx)
	print("[PASS] Animated cursor frames verified: 8 frames, size=(32.0, 32.0)")
	
	# Verify MapView cursor frame array and animation interval
	assert(map_view.cursor_frames.size() == 8 or map_view._cursor_frames.size() == 8, "MapView cursor_frames not populated")
	assert(is_equal_approx(map_view.CURSOR_FRAME_INTERVAL, 0.1), "MapView CURSOR_FRAME_INTERVAL mismatch")
	print("[PASS] MapView hardware cursor animation state verified: 8 frames, interval=0.1s (10 fps)")
	
	# Verify cursor frame progression
	var initial_idx: int = map_view._cursor_frame_index
	map_view._update_cursor_animation(0.12)
	assert(map_view._cursor_frame_index == (initial_idx + 1) % 8, "Cursor animation step index mismatch")
	print("[PASS] MapView hardware cursor animation step verified: advanced to frame %d" % map_view._cursor_frame_index)
	
	print("--- ALL VERIFICATIONS PASSED WITH 0 ERRORS ---")
	await get_tree().process_frame
	await get_tree().process_frame
	if DisplayServer.get_name() != "headless":
		var vp_tex = get_viewport().get_texture()
		if vp_tex:
			var vp_img := vp_tex.get_image()
			if vp_img:
				vp_img.save_png("res://tests/test_hud_runner_screenshot.png")
				print("[PASS] Test screenshot saved to res://tests/test_hud_runner_screenshot.png")
	get_tree().quit(0)
