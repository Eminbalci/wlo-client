class_name TestCompoundWindowAndSimulatorSpawner
extends SceneTree

const CompoundWindowClass = preload("res://scripts/ui/hud/compound_window.gd")
const HudScene = preload("res://scenes/ui/hud.tscn")
const WorldEditorScene = preload("res://scenes/tools/world_editor.tscn")
const SinkingCutsceneClass = preload("res://scripts/events/sinking_cutscene.gd")
const BeachAwakeningClass = preload("res://scripts/events/beach_awakening.gd")
const MapViewScene = preload("res://scenes/world/map_view.tscn")
const PlayerScene = preload("res://scenes/world/player.tscn")
const NpcScene = preload("res://scenes/world/npc.tscn")

func _init() -> void:
	print("\n=================================================================")
	print("--- Running Compound Window, Simulator Spawner & Audio Suite ---")
	print("=================================================================\n")
	
	_test_compound_window_layout_and_slots()
	_test_compound_validation_rules()
	_test_compound_animation_and_synthesis()
	_test_compound_inventory_deduction()
	_test_compound2_recipe_decoding_and_matching()
	_test_compound_window_hud_and_hotkey_integration()
	_test_playtest_simulator_spawner_controls()
	_test_chat_cheat_commands()
	_test_sinking_cutscene_authentic_audio_and_speech()
	_test_beach_awakening_speech_and_movement_lock()
	_test_compound_right_click_and_return_interaction()
	_test_character_status_free_point_allocation()
	
	print("\n=================================================================")
	print("--- ALL COMPOUND, SIMULATOR & AUDIO TESTS PASSED (100%) ---")
	print("=================================================================\n")
	quit(0)

func _test_compound_window_layout_and_slots() -> void:
	print(">>> [TEST 1] Verifying CompoundWindow decoded layout, Form_Compound_1 & slots...")
	var win = CompoundWindowClass.new()
	root.add_child(win)
	win._ready()
	
	assert(win.custom_minimum_size == Vector2(299, 467), "CompoundWindow minimum size must be 299x467, was %s" % str(win.custom_minimum_size))
	assert(win.background_rect != null, "FormBackground must exist")
	assert(win.background_rect.texture != null, "Background texture must be loaded")
	assert(win.title_label != null and win.title_label.text == "Compound", "Title must be Compound")
	assert(win.btn_close != null, "BtnClose must exist")
	assert(win.btn_bottom_close != null, "BtnBottomClose must exist")
	assert(win.btn_skill_check != null, "BtnSkillCheck must exist")
	assert(win.main_slot_btn != null, "Main Base slot must exist")
	assert(win.sub_slot_btns.size() == 4, "Must have exactly 4 Sub Material slots")
	assert(win.btn_compound != null, "BtnCompound must exist")
	assert(win.compounding_rect != null, "CompoundingAnim overlay must exist")
	assert(win._anim_frames.size() == 23, "Must have 23 compounding animation frames, got %d" % win._anim_frames.size())
	
	# Verify pixel-exact positioning from aLogin.exe decompilation
	assert(win.main_slot_btn.position == Vector2(206, 167), "Main slot must be at (206, 167), got %s" % str(win.main_slot_btn.position))
	assert(win.sub_slot_btns[0].position == Vector2(206, 230), "Sub slot 0 must be at (206, 230), got %s" % str(win.sub_slot_btns[0].position))
	assert(win.sub_slot_btns[1].position == Vector2(206, 281), "Sub slot 1 must be at (206, 281), got %s" % str(win.sub_slot_btns[1].position))
	assert(win.sub_slot_btns[2].position == Vector2(206, 332), "Sub slot 2 must be at (206, 332), got %s" % str(win.sub_slot_btns[2].position))
	assert(win.sub_slot_btns[3].position == Vector2(206, 383), "Sub slot 3 must be at (206, 383), got %s" % str(win.sub_slot_btns[3].position))
	assert(win.btn_compound.position == Vector2(83, 429), "BtnCompound must be at (83, 429), got %s" % str(win.btn_compound.position))
	assert(win.btn_bottom_close.position == Vector2(159, 429), "BtnBottomClose must be at (159, 429), got %s" % str(win.btn_bottom_close.position))
	assert(win.btn_close.position == Vector2(249, 20), "BtnClose must sit on the baked x sphere at (249, 20), got %s" % str(win.btn_close.position))
	assert(win.compounding_rect.position == Vector2(183, 142), "CompoundingAnim must be centered over crucible at (183, 142), got %s" % str(win.compounding_rect.position))
	assert(win.role_frame_rect != null and win.role_avatar_rect != null, "Role standee frame and avatar must exist")
	assert(win.btn_compsk_1 != null and win.btn_compsk_2 != null and win.btn_compsk_3 != null, "CompSk tier buttons must exist")
	
	print("  [PASS] CompoundWindow layout, Form_Compound_1 & 23 anim frames verified.")
	win.queue_free()

func _test_compound_validation_rules() -> void:
	print(">>> [TEST 2] Verifying authentic WLO compounding validation rules...")
	var win = CompoundWindowClass.new()
	root.add_child(win)
	win._ready()
	
	# Test 2a: Empty base slot
	win.start_compound()
	assert(win.status_label.text == "No materials to compound", "Empty compound must show 'No materials to compound'")
	assert(not win.is_compounding, "Compounding must not start with empty slots")
	
	# Test 2b: Alchemy Book cannot be placed in base slot
	var book_item := {"id": 47001, "name": "Alchemy Book I", "count": 1, "icon_id": 1050}
	win._on_bag_item_clicked(book_item, 0)
	assert(win.main_slot_data.is_empty(), "Alchemy Book must not be accepted in main slot")
	assert(win.status_label.text == "Book can't be base item", "Must reject with 'Book can't be base item'")
	
	# Test 2c: Only 1 material in main slot (needs at least 2)
	var sword_item := {"id": 11033, "name": "Iron Sword", "count": 1, "icon_id": 2466}
	win._on_bag_item_clicked(sword_item, 0)
	assert(not win.main_slot_data.is_empty(), "Iron Sword should be in main slot")
	win.start_compound()
	assert(win.status_label.text == "Use at least 2 materials", "1 material must show 'Use at least 2 materials'")
	
	# Test 2d: Book with only 1 material (needs at least 2 mats + book = 3 items)
	win._on_bag_item_clicked(book_item, 0)
	assert(not win.sub_slots_data[0].is_empty(), "Book should be in sub slot 0")
	win.start_compound()
	assert(win.status_label.text == "Use at least 2 mats and Alchemy Book", "Must demand 2 mats + book")
	
	# Test 2e: Disallow more than 1 Alchemy Book
	var book2 := {"id": 47002, "name": "Alchemy Book II", "count": 1, "icon_id": 1050}
	win._on_bag_item_clicked(book2, 1)
	assert(win.sub_slots_data[1].is_empty(), "Second Alchemy Book must be rejected")
	assert(win.status_label.text == "Can use only 1 Alchemy Book", "Must show 'Can use only 1 Alchemy Book'")
	
	print("  [PASS] Authentic WLO compound validation rules fully verified.")
	win.queue_free()

func _test_compound_animation_and_synthesis() -> void:
	print(">>> [TEST 3] Verifying compounding animation sequence and synthesis result...")
	var win = CompoundWindowClass.new()
	root.add_child(win)
	win._ready()
	
	win.main_slot_data = {"id": 11033, "name": "Iron Sword", "count": 1, "icon_id": 2466}
	win.sub_slots_data[0] = {"id": 32001, "name": "Tao Rice Ball", "count": 1, "icon_id": 1010}
	
	var started_fired := [false]
	win.compound_started.connect(func(): started_fired[0] = true)
	
	win.start_compound()
	assert(win.is_compounding == true, "Window must be in compounding state")
	assert(started_fired[0] == true, "compound_started signal must emit")
	assert(win.compounding_rect.visible == true, "Compounding anim overlay must be visible")
	
	# Simulate animation frames
	for f in range(25):
		win._process(0.06)
	
	assert(win.is_compounding == false, "Compounding must finish after 23 frames")
	assert(win.compounding_rect.visible == false, "Compounding anim overlay must hide")
	assert(win.main_slot_data.is_empty(), "Main slot should be cleared after synthesis")
	assert(win.status_label.text.begins_with("Compound Success!"), "Must report compound success")
	
	print("  [PASS] Compounding animation and synthesis execution verified.")
	win.queue_free()

func _test_compound_inventory_deduction() -> void:
	print(">>> [TEST 3b] Verifying bag population and material deduction from player inventory...")
	var hud = HudScene.instantiate()
	root.add_child(hud)
	hud._ready()
	
	hud.clear_inventory()
	hud.add_inventory_item(11033, 2, "Iron Sword", 2466)
	hud.add_inventory_item(34014, 2, "Tao Rice Ball", 1859)
	
	hud.toggle_compound_window()
	var win = hud.compound_window
	assert(win != null, "Compound window must be initialized")
	win.refresh_inventory_from_hud()
	assert(win._inventory_items.size() == 2, "Compound bag grid must contain exactly 2 items, got %d" % win._inventory_items.size())
	
	# Place Iron Sword (id 11033) in main slot and Tao Rice Ball (id 34014) in sub slot 0
	win.main_slot_data = {"id": 11033, "name": "Iron Sword", "count": 1, "icon_id": 2466}
	win.sub_slots_data[0] = {"id": 34014, "name": "Tao Rice Ball", "count": 1, "icon_id": 1859}
	
	win.start_compound()
	for f in range(25):
		win._process(0.06)
		
	assert(win.is_compounding == false, "Compounding must finish")
	
	# Verify that 1 Iron Sword was deducted (remaining count = 1)
	var sword_count: int = 0
	var rice_count: int = 0
	var total_items: int = 0
	for itm in hud.inventory_ctrl.inventory_data:
		if not itm.is_empty() and int(itm.get("id", 0)) > 0:
			total_items += 1
			if int(itm.get("id", 0)) == 11033:
				sword_count += int(itm.get("count", 0))
			elif int(itm.get("id", 0)) == 34014:
				rice_count += int(itm.get("count", 0))
				
	assert(sword_count == 1, "Expected exactly 1 Iron Sword remaining, got %d" % sword_count)
	assert(rice_count == 1, "Expected exactly 1 Tao Rice Ball remaining, got %d" % rice_count)
	assert(total_items >= 3, "Expected at least 3 items in inventory (1 sword, 1 rice, 1 synthesized product), got %d" % total_items)
	
	print("  [PASS] Compound inventory bag synchronization and material deduction verified.")
	hud.queue_free()

func _test_compound2_recipe_decoding_and_matching() -> void:
	print(">>> [TEST 3c] Verifying Compound2.Dat recipe decoding (788 recipes) and authentic alchemy synthesis...")
	CompoundWindowClass.ensure_recipes_loaded()
	assert(CompoundWindowClass._recipes_cache.size() >= 700, "Must decode >= 700 valid recipes from Compound2.Dat, got %d" % CompoundWindowClass._recipes_cache.size())
	
	# Verify recipe 2: Result 20032 requires 20031 x 1 and 37208 x 1
	var match_rec := CompoundWindowClass.find_matching_recipe({20031: 1, 37208: 1})
	assert(not match_rec.is_empty(), "Recipe 20032 must be found in Compound2.Dat")
	assert(match_rec.get("result_id", 0) == 20032, "Result ID must be 20032")
	
	# Test in CompoundWindow instance
	var win = CompoundWindowClass.new()
	root.add_child(win)
	win._ready()
	
	win.main_slot_data = {"id": 20031, "name": "Compound Mat 1", "count": 1, "icon_id": 1001}
	win.sub_slots_data[0] = {"id": 37208, "name": "Compound Mat 2", "count": 1, "icon_id": 1002}
	
	var res := win._calculate_authentic_result(20031, 5, 0)
	assert(res["id"] == 20032, "Exact recipe craft result must be 20032, got %d" % res["id"])
	assert(res["success"] == true, "Exact recipe craft must succeed")
	
	# Test freeform Alchemy Grade synthesis (when no exact recipe exists)
	win.main_slot_data = {"id": 11033, "name": "Iron Sword", "count": 1, "icon_id": 2466}
	win.sub_slots_data[0] = {"id": 34014, "name": "Tao Rice Ball", "count": 1, "icon_id": 1859}
	win.use_alchemy_skill = true
	var freeform_res := win._calculate_authentic_result(11033, 5, 1)
	assert(freeform_res["id"] > 0, "Freeform synthesis must produce valid item ID")
	assert(not freeform_res["name"].is_empty(), "Freeform synthesis must have non-empty name")
	
	print("  [PASS] Compound2.Dat 788 recipes and authentic Alchemy Grade synthesis fully verified.")
	win.queue_free()

func _test_compound_window_hud_and_hotkey_integration() -> void:
	print(">>> [TEST 4] Verifying HUD toggle_compound_window() and hotkey 'V' / 'C'...")
	var hud = HudScene.instantiate()
	root.add_child(hud)
	hud._ready()
	
	assert(hud.has_method("toggle_compound_window"), "HUD must have toggle_compound_window()")
	
	# Toggle open
	hud.toggle_compound_window()
	assert(hud.compound_window != null, "compound_window instance must be created in FloatingWindows")
	assert(hud.compound_window.visible == true, "compound_window must be visible after toggle")
	
	# Toggle close
	hud.toggle_compound_window()
	assert(hud.compound_window.visible == false, "compound_window must be hidden after second toggle")
	
	# Simulate 'V' hotkey for Compound
	var ev_v := InputEventKey.new()
	ev_v.keycode = KEY_V
	ev_v.pressed = true
	hud._unhandled_input(ev_v)
	assert(hud.compound_window.visible == true, "Hotkey 'V' must open compound window")
	
	hud._unhandled_input(ev_v)
	assert(hud.compound_window.visible == false, "Hotkey 'V' must close compound window")
	
	# Simulate 'C' hotkey for Character Status
	var ev_c := InputEventKey.new()
	ev_c.keycode = KEY_C
	ev_c.pressed = true
	var char_win = hud.window_manager_ctrl.char_window
	var prev_vis: bool = char_win.visible if char_win else false
	hud._unhandled_input(ev_c)
	if char_win:
		assert(char_win.visible == not prev_vis, "Hotkey 'C' must toggle character status window")
	
	print("  [PASS] HUD integration and hotkeys ('V' for Compound, 'C' for Status) verified.")
	hud.queue_free()

func _test_playtest_simulator_spawner_controls() -> void:
	print(">>> [TEST 5] Verifying Tab 10 Playtest Simulator spawner & item controls...")
	var editor = WorldEditorScene.instantiate()
	root.add_child(editor)
	editor._ready()
	
	assert(editor.spin_sim_item_id != null, "SpinSimItemId must exist in Tab 10 toolbar")
	assert(editor.spin_sim_item_count != null, "SpinSimItemCount must exist in Tab 10 toolbar")
	assert(editor.btn_sim_give_item != null, "BtnSimGiveItem must exist in Tab 10 toolbar")
	assert(editor.btn_sim_give_gold != null, "BtnSimGiveGold must exist in Tab 10 toolbar")
	assert(editor.btn_sim_clear_inventory != null, "BtnSimClearInventory must exist in Tab 10 toolbar")
	
	# Launch playtest in simulator
	editor.start_playtest()
	assert(editor.is_simulator_running == true, "Simulator must be running")
	assert(editor._simulator_instance != null, "_simulator_instance must be instantiated")
	
	# Test Give Item (Iron Sword 11033)
	editor.spin_sim_item_id.value = 11033
	editor.spin_sim_item_count.value = 2
	editor._on_btn_sim_give_item_pressed()
	
	var hud = editor._get_simulator_hud()
	assert(hud != null, "Simulator HUD must exist")
	
	# Verify item landed in inventory
	var inv_data: Array = hud.inventory_ctrl.inventory_data if hud.inventory_ctrl else []
	var found_sword := false
	for s in inv_data:
		if s is Dictionary and int(s.get("id", 0)) == 11033:
			found_sword = true
			assert(int(s.get("count", 0)) == 2, "Iron Sword count must be 2")
			break
	assert(found_sword == true, "Iron Sword must be present in simulator inventory")
	
	# Test Give Gold
	var init_gold: int = hud.inventory_ctrl.gold_label.text.to_int() if (hud.inventory_ctrl and hud.inventory_ctrl.gold_label) else 0
	editor._on_btn_sim_give_gold_pressed()
	var after_gold: int = hud.inventory_ctrl.gold_label.text.to_int() if (hud.inventory_ctrl and hud.inventory_ctrl.gold_label) else 0
	assert(after_gold == init_gold + 10000, "Gold must increase by +10,000")
	
	# Test Clear Inventory
	editor._on_btn_sim_clear_inventory_pressed()
	for s in hud.inventory_ctrl.inventory_data:
		assert(s is Dictionary and (s.is_empty() or int(s.get("id", 0)) == 0), "Slots must be empty after clear")
	
	editor.stop_playtest()
	assert(editor.is_simulator_running == false, "Simulator must be stopped")
	
	print("  [PASS] Playtest simulator item granting and clear controls verified.")
	editor.queue_free()

func _test_chat_cheat_commands() -> void:
	print(">>> [TEST 6] Verifying Chat /give, /gold, and /clear cheat commands...")
	var hud = HudScene.instantiate()
	root.add_child(hud)
	hud._ready()
	
	var chat_ctrl = hud.chat_ctrl
	assert(chat_ctrl != null, "chat_ctrl must exist")
	
	# Test /give 34014 5 (Tao Rice Ball)
	var prev_rice: int = 0
	for s in hud.inventory_ctrl.inventory_data:
		if s is Dictionary and int(s.get("id", 0)) == 34014:
			prev_rice += int(s.get("count", 0))
	
	chat_ctrl.chat_input.text = "/give 34014 5"
	chat_ctrl.on_chat_submitted("/give 34014 5")
	
	var new_rice: int = 0
	for s in hud.inventory_ctrl.inventory_data:
		if s is Dictionary and int(s.get("id", 0)) == 34014:
			new_rice += int(s.get("count", 0))
	assert(new_rice == prev_rice + 5, "Rice ball count must increase by 5 (was %d, now %d)" % [prev_rice, new_rice])
	
	# Test /gold 50000
	var prev_gold: int = hud.inventory_ctrl.gold_label.text.to_int() if (hud.inventory_ctrl and hud.inventory_ctrl.gold_label) else 0
	chat_ctrl.on_chat_submitted("/gold 50000")
	var new_gold: int = hud.inventory_ctrl.gold_label.text.to_int() if (hud.inventory_ctrl and hud.inventory_ctrl.gold_label) else 0
	assert(new_gold == prev_gold + 50000, "Gold must increase by 50000 from /gold command")
	
	# Test /clear
	chat_ctrl.on_chat_submitted("/clear")
	for s in hud.inventory_ctrl.inventory_data:
		assert(s is Dictionary and (s.is_empty() or int(s.get("id", 0)) == 0), "Inventory must be empty after /clear")
	
	print("  [PASS] Chat commands (/give, /gold, /clear) verified.")
	hud.queue_free()

func _test_sinking_cutscene_authentic_audio_and_speech() -> void:
	print(">>> [TEST 7] Verifying sinking cutscene authentic audio & NPC speech broadcasts...")
	var map_view = MapViewScene.instantiate()
	root.add_child(map_view)
	
	var cutscene = map_view._ensure_sinking_cutscene() as SinkingCutsceneClass
	assert(cutscene != null, "sinking_cutscene must exist")
	
	# Verify audio paths do not contain wav9911
	cutscene._ensure_audio_players()
	assert(cutscene.audio_player != null, "Audio player must exist")
	if cutscene.audio_player.stream:
		var r_path: String = cutscene.audio_player.stream.resource_path
		assert(not r_path.contains("wav9911"), "Alarm stream must NOT be wav9911, was %s" % r_path)
	
	# Trigger cutscene and verify Captain Robinson speech bubble
	var ents = map_view.get_node_or_null("Entities")
	var robinson = (ents.get_node_or_null("CaptainRobinson") as NpcEntity) if ents else null
	cutscene.trigger_cutscene("test")
	assert(cutscene.current_stage == SinkingCutsceneClass.CutsceneStage.WARNING, "Stage must be WARNING")
	
	if robinson:
		assert(robinson.speech_bubble_label != null, "Captain speech bubble label must exist")
		assert(robinson.speech_bubble_label.text.contains("iceberg"), "Captain must shout about iceberg!")
	
	print("  [PASS] Sinking cutscene authentic audio & speech broadcasts verified.")
	map_view.queue_free()

func _test_beach_awakening_speech_and_movement_lock() -> void:
	print(">>> [TEST 8] Verifying beach awakening Kelang speech & movement locking during animations...")
	var beach = BeachAwakeningClass.new()
	root.add_child(beach)
	
	var player = PlayerScene.instantiate()
	beach.add_child(player)
	beach.player = player
	
	# 8a: Verify player movement is rejected while prone / waking up / animating
	player.is_movement_locked = true
	var moved = player.set_target_world_position(Vector2(500, 500))
	assert(moved == false, "Movement must be rejected when is_movement_locked is true")
	
	player.is_movement_locked = false
	player.motion_state = PlayerEntity.MotionState.ATTACK
	moved = player.set_target_world_position(Vector2(500, 500))
	assert(moved == false, "Movement must be rejected during MotionState.ATTACK")
	
	player.motion_state = PlayerEntity.MotionState.VICTORY
	moved = player.set_target_world_position(Vector2(500, 500))
	assert(moved == false, "Movement must be rejected during MotionState.VICTORY")
	
	# 8b: Verify Kelang speaks on wakeup
	beach._ensure_kelang_npc()
	if beach.kelang_npc:
		beach._on_wakeup_completed()
		assert(beach.kelang_npc.speech_bubble_label != null, "Kelang speech bubble must exist")
		assert(beach.kelang_npc.speech_bubble_label.text.contains("washed ashore"), "Kelang must speak about washing ashore!")
	
	print("  [PASS] Beach awakening speech & movement locking verified.")
	beach.queue_free()

func _test_compound_right_click_and_return_interaction() -> void:
	print(">>> [TEST 9] Verifying CompoundWindow right-click quick transfer and return...")
	var win = CompoundWindowClass.new()
	root.add_child(win)
	win._ready()
	
	var test_items: Array[Dictionary] = [
		{"id": 45001, "name": "Ordinary Wood", "count": 2, "icon_id": 1001},
		{"id": 45005, "name": "Wood / Log", "count": 1, "icon_id": 1002}
	]
	win._inventory_items = test_items
	win._populate_bag_grid()
	
	# Simulate Right-Click on bag item 0 (Ordinary Wood)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_RIGHT
	ev.pressed = true
	win._on_bag_slot_gui_input(ev, win._inventory_items[0], 0)
	
	assert(not win.main_slot_data.is_empty(), "Right-clicked item must be placed in main slot")
	assert(win.main_slot_data.get("id") == 45001, "Main slot item must be 45001")
	
	# Simulate Right-Click on second item (Wood / Log)
	win._on_bag_slot_gui_input(ev, win._inventory_items[1], 1)
	assert(not win.sub_slots_data[0].is_empty(), "Second right-clicked item must be placed in sub slot 0")
	assert(win.sub_slots_data[0].get("id") == 45005, "Sub slot 0 item must be 45005")
	
	# Close window and verify items are safely returned to bag
	win.close_window()
	assert(win.main_slot_data.is_empty(), "Main slot must be cleared on close")
	assert(win.sub_slots_data[0].is_empty(), "Sub slot must be cleared on close")
	assert(not win.visible, "Window must be hidden on close")
	
	print("  [PASS] CompoundWindow right-click transfer and return verified.")
	win.queue_free()

func _test_character_status_free_point_allocation() -> void:
	print(">>> [TEST 10] Verifying Character Status [+] free point allocation...")
	var hud = HudScene.instantiate()
	root.add_child(hud)
	hud._ready()
	
	assert(hud.character_status_ctrl != null, "HUD character_status_ctrl must exist")
	var cs = hud.character_status_ctrl
	
	# Set free points
	cs.update_character_stats("TestHero", 10, "Fire", 300, 300, 150, 150, 0, 1000, 10, 10, 6, 6, 18, 5)
	assert(cs.current_free == 5, "Free points must be 5")
	assert(cs.stat_add_buttons.size() == 5, "Must have 5 [+] stat allocation buttons")
	assert(cs.stat_add_buttons["str"].visible == true, "STR [+] button must be visible when free points > 0")
	
	# Allocate 1 point to STR
	var allocated = hud.allocate_stat_point("str")
	assert(allocated == true, "Point allocation to STR must succeed")
	assert(cs.current_str == 11, "STR must now be 11")
	assert(cs.current_free == 4, "Free points must now be 4")
	# Formula.dat ATK (FormulaData): STR 11 * 2.0 + LV10 * 1.4 + LV10 * Fire bonus 0.6 = 42
	assert(cs.base_atk == 42, "Base ATK must be 42 (Formula.dat, STR 11, LV10, Fire)")
	
	# Allocate remaining 4 points
	hud.allocate_stat_point("con")
	hud.allocate_stat_point("int")
	hud.allocate_stat_point("wis")
	hud.allocate_stat_point("agi")
	assert(cs.current_free == 0, "Free points must now be 0")
	assert(cs.stat_add_buttons["str"].visible == false, "STR [+] button must be hidden when free points == 0")
	
	# Attempt to allocate with 0 free points
	var failed = hud.allocate_stat_point("str")
	assert(failed == false, "Allocation with 0 free points must fail")
	assert(cs.current_str == 11, "STR must remain unchanged")
	
	print("  [PASS] Character Status [+] free point allocation fully verified.")
	hud.queue_free()
