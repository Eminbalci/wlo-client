extends Control

## Test Suite for Dialogue Click Dismissal, Space/Enter Progression,
## Branching Choices, Avatar Bust Matching (TID), Window Titles,
## Global Multi-State Animated Cursors, Map 10002 & 10003 Portals, NPCs and Harvestables.

const GroundParser = preload("res://scripts/map/ground_parser.gd")
const GroundItem = preload("res://scripts/map/ground_item.gd")

func _ready() -> void:
	print("--- Running In-Engine Verification of Dialogue, Cursors, Titles, Portals & Cabins ---")
	
	# Load and instantiate HUD
	var hud_scene = preload("res://scenes/ui/hud.tscn")
	var hud = hud_scene.instantiate()
	add_child(hud)
	await get_tree().process_frame
	
	# -------------------------------------------------------------
	# 1. Verify Top-Left Status Dock Avatar Scale and Aperture Fit
	# -------------------------------------------------------------
	var avatar_rect: TextureRect = hud.avatar_rect
	var avatar_bg: ColorRect = hud.avatar_bg
	assert(avatar_rect != null, "AvatarRect missing from PlayerStatusDock")
	assert(avatar_bg != null, "AvatarBg missing from PlayerStatusDock")
	assert(avatar_rect.size == Vector2(64, 64), "AvatarRect size must be 64x64, got %s" % str(avatar_rect.size))
	assert(avatar_rect.position == Vector2(18, 18), "AvatarRect position must be (18, 18), got %s" % str(avatar_rect.position))
	assert(avatar_bg.size == Vector2(64, 64), "AvatarBg size must be 64x64, got %s" % str(avatar_bg.size))
	assert(avatar_bg.position == Vector2(18, 18), "AvatarBg position must be (18, 18), got %s" % str(avatar_bg.position))
	print("[PASS] Top-Left Avatar aperture scaling and positioning verified: pos=(18, 18), size=(64, 64)")
	
	# -------------------------------------------------------------
	# 2. Verify Window Title Labels Removed / Hidden on all Floating Windows
	# -------------------------------------------------------------
	var test_windows: Array[Control] = [
		hud.char_window, hud.skill_window, hud.quest_window,
		hud.team_window, hud.friends_window, hud.system_window, hud.inventory_window
	]
	for win in test_windows:
		assert(win != null, "Floating window is null")
		var title_node = win.get_node_or_null("TitleLabel")
		if title_node:
			assert(title_node.visible == false, "TitleLabel on window %s must be hidden, got visible=true" % win.name)
	print("[PASS] All redundant window title text labels verified hidden (Delphi skin bitmaps have baked titles)")
	
	# -------------------------------------------------------------
	# 3. Verify Dialogue Advancement and Dismissal (Click, Space, Enter)
	# -------------------------------------------------------------
	# 3a. Single-page dialogue advance/close via background click
	hud.show_dialogue("Captain Robinson", "Welcome aboard the cruise liner!")
	assert(hud.dialogue_dock.visible == true, "Dialogue dock must be visible after show_dialogue")
	
	var click_event = InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	click_event.position = Vector2(200, 500)
	hud.dialogue_bg.gui_input.emit(click_event)
	assert(hud.dialogue_dock.visible == false, "Dialogue dock must close after clicking on dialogue background")
	print("[PASS] Single-page dialogue dismissal on background click verified")
	
	# 3b. Multi-page dialogue sequence advance via screen unhandled click
	var seq_pages: Array[String] = ["First announcement: Welcome!", "Second announcement: Sea is calm."]
	hud.show_dialogue_sequence("Captain Robinson", seq_pages)
	assert(hud.dialogue_dock.visible == true, "Dialogue dock must be visible for sequence")
	assert(hud.dialogue_text.text == "First announcement: Welcome!", "Dialogue page 0 text mismatch")
	
	var screen_click = InputEventMouseButton.new()
	screen_click.button_index = MOUSE_BUTTON_LEFT
	screen_click.pressed = true
	screen_click.position = Vector2(400, 300)
	hud._unhandled_input(screen_click)
	assert(hud.dialogue_dock.visible == true, "Dialogue dock must still be visible on page 1")
	assert(hud.dialogue_text.text == "Second announcement: Sea is calm.", "Dialogue page 1 text mismatch")
	
	hud._unhandled_input(screen_click)
	assert(hud.dialogue_dock.visible == false, "Dialogue dock must close after last page click")
	print("[PASS] Multi-page dialogue sequence progression and dismissal on screen click verified")
	
	# 3c. Space key dialogue sequence progression and dismissal
	var seq_space: Array[String] = ["Space Page 1: Wind is blowing.", "Space Page 2: Waves are steady."]
	hud.show_dialogue_sequence("Captain Robinson", seq_space)
	assert(hud.dialogue_dock.visible == true, "Dialogue dock must be visible")
	assert(hud.dialogue_text.text == "Space Page 1: Wind is blowing.")
	
	var space_press = InputEventKey.new()
	space_press.keycode = KEY_SPACE
	space_press.pressed = true
	hud._unhandled_input(space_press)
	assert(hud.dialogue_dock.visible == true, "Dialogue dock must remain open on page 2")
	assert(hud.dialogue_text.text == "Space Page 2: Waves are steady.")
	
	hud._unhandled_input(space_press)
	assert(hud.dialogue_dock.visible == false, "Dialogue dock must close after Space key on final page")
	print("[PASS] Space key dialogue sequence progression and dismissal verified")
	
	# 3d. Enter key dialogue sequence progression and dismissal
	var seq_enter: Array[String] = ["Enter Page 1: Checking provisions.", "Enter Page 2: Kitchen is well-stocked."]
	hud.show_dialogue_sequence("Captain Robinson", seq_enter)
	assert(hud.dialogue_dock.visible == true, "Dialogue dock must be visible")
	
	var enter_press = InputEventKey.new()
	enter_press.keycode = KEY_ENTER
	enter_press.pressed = true
	hud._unhandled_input(enter_press)
	assert(hud.dialogue_dock.visible == true, "Dialogue dock must remain open on page 2")
	assert(hud.dialogue_text.text == "Enter Page 2: Kitchen is well-stocked.")
	
	var kp_enter_press = InputEventKey.new()
	kp_enter_press.keycode = KEY_KP_ENTER
	kp_enter_press.pressed = true
	hud._unhandled_input(kp_enter_press)
	assert(hud.dialogue_dock.visible == false, "Dialogue dock must close after Keypad Enter on final page")
	print("[PASS] Enter and Keypad Enter key dialogue sequence progression and dismissal verified")
	
	# -------------------------------------------------------------
	# 4. Verify Branching Dialogue Choice Display and Button Selection
	# -------------------------------------------------------------
	var choice_result := {
		"idx": -1,
		"text": ""
	}
	var choice_cb = func(idx: int, txt: String) -> void:
		choice_result["idx"] = idx
		choice_result["text"] = txt
	
	var choice_options: Array[String] = ["Can I have some food?", "Smells delicious!"]
	hud.show_dialogue("Chef", "Welcome to the kitchen! What can I get for you?", null, choice_options, [], choice_cb, 8021)
	assert(hud.dialogue_dock.visible == true, "Dialogue dock must be visible for branching dialog")
	assert(hud.branching_dock.visible == true, "Branching dock must be visible when choices are provided")
	assert(hud.choices_container.get_child_count() == 2, "Choices container must have exactly 2 buttons")
	
	var first_btn = hud.choices_container.get_child(0) as Button
	assert(first_btn != null, "Branching button must exist")
	assert(first_btn.text == "Can I have some food?", "First choice text mismatch, got: %s" % first_btn.text)
	
	# Simulate button click
	first_btn.pressed.emit()
	assert(choice_result["idx"] == 0, "Choice callback must receive index 0, got %d" % choice_result["idx"])
	assert(choice_result["text"] == "Can I have some food?", "Choice text mismatch, got: %s" % choice_result["text"])
	assert(hud.dialogue_dock.visible == false, "Dialogue dock must hide upon choice selection")
	print("[PASS] Branching dialogue choice display and interactive button selection verified")
	
	# -------------------------------------------------------------
	# 5. Verify NPC Authentic TID Avatar Bust Matching (008.jma)
	# -------------------------------------------------------------
	# 5a. Captain Robinson (TID 8025)
	hud.show_dialogue("Captain Robinson", "Keep a steady course!", null, [], [], Callable(), 8025)
	assert(hud.portrait_rect.visible == true, "Portrait rect must be visible")
	assert(hud.portrait_rect.texture != null, "Captain portrait texture must be non-null")
	assert(hud._portrait_frames.size() >= 2, "Captain portrait must have talking/blinking animation frames")
	hud.hide_dialogue()
	
	# 5b. Chef (TID 8021)
	hud.show_dialogue("Chef", "Dinner will be served soon!", null, [], [], Callable(), 8021)
	assert(hud.portrait_rect.visible == true, "Chef portrait rect must be visible")
	assert(hud.portrait_rect.texture != null, "Chef portrait texture must be non-null")
	assert(hud._portrait_frames.size() >= 2, "Chef portrait must have talking/blinking animation frames")
	hud.hide_dialogue()
	
	# 5c. Natasha (TID 8083)
	hud.show_dialogue("Natasha", "The sea air is so refreshing.", null, [], [], Callable(), 8083)
	assert(hud.portrait_rect.visible == true, "Natasha portrait rect must be visible")
	assert(hud.portrait_rect.texture != null, "Natasha portrait texture must be non-null")
	assert(hud._portrait_frames.size() >= 2, "Natasha portrait must have talking/blinking animation frames")
	hud.hide_dialogue()
	print("[PASS] Authentic TID avatar bust decoding verified (Captain=8025, Chef=8021, Natasha=8083)")
	
	# -------------------------------------------------------------
	# 6. Verify Map 10002 (Passenger Cabin) Staircase Portals
	# -------------------------------------------------------------
	var gp := GroundParser.new()
	var portals_10002 := gp.get_map_warp_portals(10002)
	assert(portals_10002.size() >= 2, "Map 10002 must have at least 2 portals (exit to deck + stairs to kitchen)")
	
	var portal_to_deck: Dictionary = {}
	var portal_to_kitchen: Dictionary = {}
	for p in portals_10002:
		if p.target_map_id == 10001:
			portal_to_deck = p
		elif p.target_map_id == 10003:
			portal_to_kitchen = p
	
	assert(not portal_to_deck.is_empty(), "Portal to Ship Deck (10001) must exist on Map 10002")
	assert(portal_to_deck.world_pos == Vector2(674, 1067), "Cabin exit portal position mismatch")
	assert(portal_to_deck.target_coords == Vector2(1814, 904), "Deck arrival coords mismatch")
	
	assert(not portal_to_kitchen.is_empty(), "Portal to Kitchen / Bunk (10003) must exist on Map 10002")
	assert(portal_to_kitchen.world_pos == Vector2(483, 631), "Stairs to kitchen portal position mismatch")
	assert(portal_to_kitchen.target_coords == Vector2(420, 360), "Kitchen arrival coords mismatch")
	print("[PASS] Map 10002 staircase portals verified: Up to Deck (10001 at 674, 1067), Down to Kitchen (10003 at 483, 631)")
	
	# -------------------------------------------------------------
	# 7. Verify Map 10003 Staircase Portal, NPCs & Ground Harvestables
	# -------------------------------------------------------------
	# 7a. Map 10003 staircase portal up to Cabin 10002
	var portals_10003 := gp.get_map_warp_portals(10003)
	var portal_up_to_cabin: Dictionary = {}
	for p in portals_10003:
		if p.target_map_id == 10002:
			portal_up_to_cabin = p
	assert(not portal_up_to_cabin.is_empty(), "Portal to Passenger Cabin (10002) must exist on Map 10003")
	assert(portal_up_to_cabin.world_pos == Vector2(420, 360), "Stairs up to cabin portal position mismatch")
	assert(portal_up_to_cabin.target_coords == Vector2(530, 670), "Cabin arrival coords mismatch")
	print("[PASS] Map 10003 staircase portal verified: Up to Cabin (10002 at 420, 360 -> 530, 670)")
	
	# 7b. Instantiate MapView and verify Map 10003 entity spawning
	var mv_scene = load("res://scenes/world/map_view.tscn")
	assert(mv_scene != null, "map_view.tscn must load")
	var map_view = mv_scene.instantiate()
	add_child(map_view)
	await get_tree().process_frame
	
	map_view._switch_map_entities(10003)
	assert(map_view._kitchen_entities.size() >= 6, "Kitchen must spawn at least 6 entities (3 NPCs + 3 harvestables)")
	
	var chef_npc: NpcEntity = null
	var kcrew_npc: NpcEntity = null
	var bcrew_npc: NpcEntity = null
	var apple_item: GroundItem = null
	var bread_item: GroundItem = null
	var cutlery_item: GroundItem = null
	
	for e in map_view._kitchen_entities:
		if e is NpcEntity:
			if e.npc_id == 12006:
				chef_npc = e
			elif e.npc_id == 14002:
				kcrew_npc = e
			elif e.npc_id == 14001:
				bcrew_npc = e
		elif e is GroundItem:
			if e.item_id == 41040:
				apple_item = e
			elif e.item_id == 32011:
				bread_item = e
			elif e.item_id == 10002:
				cutlery_item = e
	
	# Verify Chef NPC
	assert(chef_npc != null, "Chef NPC (12006) must exist in kitchen entities")
	assert(chef_npc.talk_id == 30170, "Chef talk_id must be 30170")
	assert(chef_npc.world_position == Vector2(780, 520), "Chef position mismatch")
	
	# Verify Kitchen Crew NPC
	assert(kcrew_npc != null, "Kitchen Crew NPC (14002) must exist in kitchen entities")
	assert(kcrew_npc.talk_id == 30173, "Kitchen Crew talk_id must be 30173")
	assert(kcrew_npc.world_position == Vector2(950, 480), "Kitchen Crew position mismatch")
	
	# Verify Bunk Crew NPC
	assert(bcrew_npc != null, "Bunk Crew NPC (14001) must exist in kitchen entities")
	assert(bcrew_npc.talk_id == 30174, "Bunk Crew talk_id must be 30174")
	assert(bcrew_npc.world_position == Vector2(620, 680), "Bunk Crew position mismatch")
	
	# Verify Ground Harvestables (Apple, Bread, Cutlery)
	assert(apple_item != null, "Apple GroundItem (41040) must exist in kitchen entities")
	assert(apple_item.position == Vector2(710, 560), "Apple position mismatch")
	assert(apple_item.icon_id == 1001, "Apple icon_id mismatch")
	
	assert(bread_item != null, "Bread GroundItem (32011) must exist in kitchen entities")
	assert(bread_item.position == Vector2(860, 540), "Bread position mismatch")
	assert(bread_item.icon_id == 1011, "Bread icon_id mismatch")
	
	assert(cutlery_item != null, "Cutlery GroundItem (10002) must exist in kitchen entities")
	assert(cutlery_item.position == Vector2(800, 600), "Cutlery position mismatch")
	assert(cutlery_item.icon_id == 1120, "Cutlery icon_id mismatch")
	print("[PASS] Map 10003 Kitchen NPCs (Chef, Kitchen Crew, Bunk Crew) & Harvestables (Apple, Bread, Cutlery) verified")
	
	# 7c. Test harvesting kitchen items into player inventory & HUD banner
	if map_view.player:
		map_view.player.world_position = apple_item.position + Vector2(25.0, 0.0)
		map_view.player.position = map_view.player.world_position
	var pickup_ok = map_view._execute_pickup(apple_item)
	assert(pickup_ok == true, "Picking up kitchen Apple must succeed")
	assert(apple_item.is_picked_up == true, "Apple must be marked as picked up")
	print("[PASS] In-world interactive kitchen ground item harvest executed cleanly")
	
	# -------------------------------------------------------------
	# 8. Verify Authentic TalkDatabase Dialogues & Branch Trees
	# -------------------------------------------------------------
	var gdb = get_node_or_null("/root/GameDatabase")
	assert(gdb != null and gdb.talks != null, "GameDatabase talks singleton must exist")
	
	# Peter (TalkID 30160 -> 30161 / 30162)
	var t_peter: Dictionary = gdb.talks.get_talk(30160)
	assert(not t_peter.is_empty(), "Talk 30160 must exist")
	assert(t_peter.speaker == "Peter", "Talk 30160 speaker must be Peter")
	assert(t_peter.choices.size() == 2, "Talk 30160 must have 2 branching choices")
	assert(t_peter.choices[0].next_talk_id == 30161, "Choice 1 must lead to 30161")
	assert(t_peter.choices[1].next_talk_id == 30162, "Choice 2 must lead to 30162")
	
	# John (TalkID 30163 -> 30164 / 30165)
	var t_john: Dictionary = gdb.talks.get_talk(30163)
	assert(not t_john.is_empty(), "Talk 30163 must exist")
	assert(t_john.speaker == "John", "Talk 30163 speaker must be John")
	assert(t_john.choices.size() == 2, "Talk 30163 must have 2 branching choices")
	assert(t_john.choices[0].next_talk_id == 30164, "Choice 1 must lead to 30164")
	assert(t_john.choices[1].next_talk_id == 30165, "Choice 2 must lead to 30165")
	
	# Natasha (TalkID 30166 -> 30167 / 30168)
	var t_natasha: Dictionary = gdb.talks.get_talk(30166)
	assert(not t_natasha.is_empty(), "Talk 30166 must exist")
	assert(t_natasha.speaker == "Natasha", "Talk 30166 speaker must be Natasha")
	assert(t_natasha.choices.size() == 2, "Talk 30166 must have 2 branching choices")
	assert(t_natasha.choices[0].next_talk_id == 30167, "Choice 1 must lead to 30167")
	assert(t_natasha.choices[1].next_talk_id == 30168, "Choice 2 must lead to 30168")
	
	# Chef (TalkID 30170 -> 30171 / 30172)
	var t_chef: Dictionary = gdb.talks.get_talk(30170)
	assert(not t_chef.is_empty(), "Talk 30170 must exist")
	assert(t_chef.speaker == "Chef", "Talk 30170 speaker must be Chef")
	assert(t_chef.choices.size() == 2, "Talk 30170 must have 2 branching choices")
	assert(t_chef.choices[0].next_talk_id == 30171, "Choice 1 must lead to 30171")
	assert(t_chef.choices[1].next_talk_id == 30172, "Choice 2 must lead to 30172")
	
	# Kitchen Crew (TalkID 30173) and Bunk Crew (TalkID 30174)
	var t_kcrew: Dictionary = gdb.talks.resolve_talk_for_npc(14002, 10003)
	assert(t_kcrew.id == 30173 and t_kcrew.speaker == "Kitchen Crew", "Kitchen Crew talk resolution mismatch")
	var t_bcrew: Dictionary = gdb.talks.resolve_talk_for_npc(14001, 10003)
	assert(t_bcrew.id == 30174 and t_bcrew.speaker == "Bunk Crew", "Bunk Crew talk resolution mismatch")
	print("[PASS] Authentic TalkDatabase dialogue trees & choice branches verified (Peter, John, Natasha, Chef, Crews)")
	
	# -------------------------------------------------------------
	# 9. Verify Chat History Panel Styling
	# -------------------------------------------------------------
	var chat_panel: PanelContainer = hud.chat_history_panel
	assert(chat_panel != null, "ChatHistoryPanel missing")
	var chat_style = chat_panel.get_theme_stylebox("panel")
	assert(chat_style is StyleBoxFlat, "ChatHistoryPanel style must be StyleBoxFlat, got %s" % str(chat_style))
	print("[PASS] ChatDock panel style verified")
	
	# -------------------------------------------------------------
	# 10. Verify CursorManager and Global Multi-State Animated Cursors
	# -------------------------------------------------------------
	var c_mgr = get_node_or_null("/root/CursorManager")
	assert(c_mgr != null, "CursorManager autoload missing")
	
	# Test NORMAL cursor (cursor1.ani - 8 frames)
	c_mgr.set_cursor_state(c_mgr.CursorType.NORMAL)
	assert(c_mgr.get_cursor_state() == c_mgr.CursorType.NORMAL, "Cursor state must be NORMAL")
	var normal_frames = c_mgr.get_active_frames()
	assert(normal_frames.size() == 8, "NORMAL cursor must have 8 frames, got %d" % normal_frames.size())
	assert(normal_frames[0].get_size() == Vector2(32, 32), "NORMAL cursor frame size mismatch")
	
	# Test TALK cursor (cursor3.ani - 6 frames)
	c_mgr.set_cursor_state(c_mgr.CursorType.TALK)
	assert(c_mgr.get_cursor_state() == c_mgr.CursorType.TALK, "Cursor state must be TALK")
	var talk_frames = c_mgr.get_active_frames()
	assert(talk_frames.size() == 6, "TALK cursor must have 6 frames, got %d" % talk_frames.size())
	
	# Test PORTAL cursor (cursor6.ani - 6 frames)
	c_mgr.set_cursor_state(c_mgr.CursorType.PORTAL)
	assert(c_mgr.get_cursor_state() == c_mgr.CursorType.PORTAL, "Cursor state must be PORTAL")
	var portal_frames = c_mgr.get_active_frames()
	assert(portal_frames.size() == 6, "PORTAL cursor must have 6 frames, got %d" % portal_frames.size())
	
	# Test HARVEST cursor (cursor4.ani - 1 frame)
	c_mgr.set_cursor_state(c_mgr.CursorType.HARVEST)
	assert(c_mgr.get_cursor_state() == c_mgr.CursorType.HARVEST, "Cursor state must be HARVEST")
	var harvest_frames = c_mgr.get_active_frames()
	assert(harvest_frames.size() == 1, "HARVEST cursor must have 1 frame, got %d" % harvest_frames.size())
	
	# Test ATTACK cursor (cursor2.ani - 8 frames)
	c_mgr.set_cursor_state(c_mgr.CursorType.ATTACK)
	assert(c_mgr.get_cursor_state() == c_mgr.CursorType.ATTACK, "Cursor state must be ATTACK")
	var attack_frames = c_mgr.get_active_frames()
	assert(attack_frames.size() == 8, "ATTACK cursor must have 8 frames, got %d" % attack_frames.size())
	
	# Test set_cursor_by_name string API
	c_mgr.set_cursor_by_name("npc")
	assert(c_mgr.get_cursor_state() == c_mgr.CursorType.TALK, "set_cursor_by_name('npc') must switch to TALK")
	c_mgr.set_cursor_by_name("portal")
	assert(c_mgr.get_cursor_state() == c_mgr.CursorType.PORTAL, "set_cursor_by_name('portal') must switch to PORTAL")
	c_mgr.set_cursor_by_name("pickup")
	assert(c_mgr.get_cursor_state() == c_mgr.CursorType.HARVEST, "set_cursor_by_name('pickup') must switch to HARVEST")
	c_mgr.set_cursor_by_name("sword")
	assert(c_mgr.get_cursor_state() == c_mgr.CursorType.ATTACK, "set_cursor_by_name('sword') must switch to ATTACK")
	c_mgr.reset_to_default()
	assert(c_mgr.get_cursor_state() == c_mgr.CursorType.NORMAL, "reset_to_default must return to NORMAL")
	
	# Test animation stepping
	var initial_frame = c_mgr.get_current_frame_index()
	c_mgr._process(0.12)
	assert(c_mgr.get_current_frame_index() == (initial_frame + 1) % 8, "Cursor animation step failed")
	print("[PASS] Global CursorManager all 5 authentic cursor states & 10 FPS animation loop verified")
	
	print("--- ALL VERIFICATIONS PASSED (100% SUCCESS) ---")
	get_tree().quit(0)
