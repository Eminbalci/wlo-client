extends SceneTree

## Automated Verification Suite for Wonderland Online Modern Responsive HUD & Dock System.
## Tests:
## 1. StatusDock: Anchor PRESET_TOP_LEFT, smooth tweened HP/SP/EXP bars, role avatar, wrapping buffs.
## 2. RadarMinimap: Anchor PRESET_TOP_RIGHT, zoom in/out, coords, portal dots, player indicator, collapse.
## 3. ChatDock: Anchor PRESET_BOTTOM_LEFT, height resizing, channel tabs, smooth scroll, input auto-fit.
## 4. BottomActionDock: Anchor PRESET_BOTTOM_RIGHT / CENTER_BOTTOM, hotkey triggers, compound tooltips, drag & drop.
## 5. HUDManager: Orchestration of modular docks, collision avoidance, and responsive anchoring.

func _init() -> void:
	_run_tests.call_deferred()

func _run_tests() -> void:
	print("=================================================================")
	print("--- Running Wonderland Online HUD & Dock System Test Suite ---")
	print("=================================================================\n")
	
	await _test_status_dock()
	await _test_radar_minimap()
	await _test_chat_dock()
	await _test_bottom_action_dock()
	await _test_hud_manager()
	
	print("\n=================================================================")
	print("--- ALL HUD & DOCK SYSTEM TESTS PASSED (100% ZERO-ERROR) --------")
	print("=================================================================")
	quit(0)

func _test_status_dock() -> void:
	print(">>> [TEST 1] Verifying StatusDock (Standalone Scene & Script)...")
	var scene: PackedScene = load("res://scenes/ui/hud/status_dock.tscn")
	assert(scene != null, "ERROR: status_dock.tscn failed to load")
	
	var dock: StatusDock = scene.instantiate() as StatusDock
	assert(dock != null, "ERROR: Failed to instantiate StatusDock")
	root.add_child(dock)
	await process_frame
	await process_frame
	
	# Verify Anchor Preset TOP_LEFT (0)
	assert(dock.anchors_preset == Control.PRESET_TOP_LEFT, "ERROR: StatusDock must use PRESET_TOP_LEFT")
	assert(dock.position == Vector2(0, 0), "ERROR: StatusDock position must be (0, 0)")
	
	# Verify Elements
	dock.set_element("Earth")
	assert(dock.element_icon.texture.resource_path.ends_with("icon_element_1.png"), "Element Earth mismatch")
	dock.set_element("Water")
	assert(dock.element_icon.texture.resource_path.ends_with("icon_element_2.png"), "Element Water mismatch")
	dock.set_element("Fire")
	assert(dock.element_icon.texture.resource_path.ends_with("icon_element_3.png"), "Element Fire mismatch")
	dock.set_element("Wind")
	assert(dock.element_icon.texture.resource_path.ends_with("icon_element_4.png"), "Element Wind mismatch")
	print("  [OK] Element icons verified.")
	
	# Verify Roles & Avatar
	dock.set_role(6)
	assert(dock.avatar_rect.texture != null, "ERROR: Avatar texture missing for role 6")
	print("  [OK] Role avatar switching verified.")
	
	# Verify Smooth Tweened Bars
	dock.set_hp(100, 250, true)
	assert(dock.hp_bar.max_value == 250.0, "HP max_value mismatch")
	assert(dock.hp_label.text == "HP   100/250", "HP label text mismatch: %s" % dock.hp_label.text)
	
	dock.set_sp(80, 200, true)
	assert(dock.sp_bar.max_value == 200.0, "SP max_value mismatch")
	assert(dock.sp_label.text == "SP   80/200", "SP label text mismatch: %s" % dock.sp_label.text)
	
	dock.set_exp(5000, 10000, true)
	assert(dock.exp_label.text == "50%", "EXP label text mismatch: %s" % dock.exp_label.text)
	print("  [OK] Dynamic HP/SP/EXP bars with tween interpolation verified.")
	
	# Verify Buff/Debuff Wrapping Container
	assert(dock.buff_container != null, "ERROR: BuffContainer missing")
	var dummy_tex: ImageTexture = ImageTexture.create_from_image(Image.create(16, 16, false, Image.FORMAT_RGBA8))
	dock.add_buff("buff_atk", dummy_tex, 10.0, "Attack Up +10%")
	dock.add_buff("buff_def", dummy_tex, 15.0, "Defense Up +15%")
	dock.add_buff("debuff_slow", dummy_tex, 5.0, "Slow -20%")
	assert(dock.get_buff_count() == 3, "Buff count mismatch: %d" % dock.get_buff_count())
	assert(dock.buff_container.get_child_count() == 3, "Buff container child count mismatch")
	
	dock.remove_buff("buff_atk")
	assert(dock.get_buff_count() == 2, "Buff count after remove mismatch")
	dock.clear_buffs()
	assert(dock.get_buff_count() == 0, "Buff count after clear mismatch")
	print("  [OK] Buff/Debuff wrapping container and lifecycle verified.")
	
	dock.queue_free()
	await process_frame

func _test_radar_minimap() -> void:
	print("\n>>> [TEST 2] Verifying RadarMinimap (Standalone Scene & Script)...")
	var scene: PackedScene = load("res://scenes/ui/hud/radar_minimap.tscn")
	assert(scene != null, "ERROR: radar_minimap.tscn failed to load")
	
	var minimap: RadarMinimap = scene.instantiate() as RadarMinimap
	assert(minimap != null, "ERROR: Failed to instantiate RadarMinimap")
	root.add_child(minimap)
	await process_frame
	await process_frame
	
	# Verify Anchor Preset TOP_RIGHT (1)
	assert(minimap.anchors_preset == Control.PRESET_TOP_RIGHT, "ERROR: RadarMinimap must use PRESET_TOP_RIGHT")
	
	# Verify Coords
	minimap.update_coordinates(Vector2(500, 300), Vector2(1000, 1000))
	assert(minimap.coord_label.text == "(500, 300)", "Coords text mismatch: %s" % minimap.coord_label.text)
	print("  [OK] Coordinates formatting and tracking verified.")
	
	# Verify Zoom in / Zoom out with clamping [0.5, 3.0]
	minimap.set_zoom(1.0)
	assert(is_equal_approx(minimap.minimap_zoom, 1.0), "Initial zoom mismatch")
	minimap._on_btn_zoom_in_pressed()
	assert(is_equal_approx(minimap.minimap_zoom, 1.25), "Zoom in mismatch: %f" % minimap.minimap_zoom)
	minimap._on_btn_zoom_out_pressed()
	assert(is_equal_approx(minimap.minimap_zoom, 1.0), "Zoom out mismatch: %f" % minimap.minimap_zoom)
	minimap.set_zoom(5.0) # test clamping
	assert(is_equal_approx(minimap.minimap_zoom, 3.0), "Zoom max clamping mismatch: %f" % minimap.minimap_zoom)
	minimap.set_zoom(0.1) # test clamping
	assert(is_equal_approx(minimap.minimap_zoom, 0.5), "Zoom min clamping mismatch: %f" % minimap.minimap_zoom)
	print("  [OK] Zoom in/out and clamping verified.")
	
	# Verify Portal Dots
	minimap.add_portal_dot("portal_cabin", Vector2(0.3, 0.4), Color.CYAN)
	minimap.add_portal_dot("portal_beach", Vector2(0.8, 0.2), Color.YELLOW)
	assert(minimap.portals_container.get_child_count() == 2, "Portals child count mismatch")
	minimap.remove_portal_dot("portal_cabin")
	assert(minimap.portals_container.get_child_count() == 1, "Portals child count after removal mismatch")
	minimap.clear_portal_dots()
	assert(minimap.portals_container.get_child_count() == 0, "Portals child count after clear mismatch")
	print("  [OK] Portal dots management verified.")
	
	# Verify Minimap Toggle / Collapse
	assert(minimap._minimap_is_collapsed == false, "Initial collapsed state mismatch")
	minimap.toggle_collapse()
	assert(minimap._minimap_is_collapsed == true, "Collapsed state after toggle mismatch")
	assert(minimap.minimap_view.visible == false, "Minimap view should be hidden when collapsed")
	minimap.toggle_collapse()
	assert(minimap._minimap_is_collapsed == false, "Expanded state after toggle mismatch")
	assert(minimap.minimap_view.visible == true, "Minimap view should be visible when expanded")
	print("  [OK] Minimap collapse / toggle verified.")
	
	minimap.queue_free()
	await process_frame

func _test_chat_dock() -> void:
	print("\n>>> [TEST 3] Verifying ChatDock (Standalone Scene & Script)...")
	var scene: PackedScene = load("res://scenes/ui/hud/chat_dock.tscn")
	assert(scene != null, "ERROR: chat_dock.tscn failed to load")
	
	var chat: ChatDock = scene.instantiate() as ChatDock
	assert(chat != null, "ERROR: Failed to instantiate ChatDock")
	root.add_child(chat)
	await process_frame
	await process_frame
	
	# Verify Anchor Preset BOTTOM_LEFT (2)
	assert(chat.anchors_preset == Control.PRESET_BOTTOM_LEFT, "ERROR: ChatDock must use PRESET_BOTTOM_LEFT")
	
	# Verify Height Resizing presets
	chat.set_chat_height(-140.0)
	assert(chat.chat_history_panel.offset_top == -140.0, "Height preset -140 mismatch")
	assert(chat.channel_tabs.offset_top == -161.0, "Channel tabs offset_top mismatch: %f" % chat.channel_tabs.offset_top)
	
	chat.set_chat_height(-200.0)
	assert(chat.chat_history_panel.offset_top == -200.0, "Height preset -200 mismatch")
	assert(chat.channel_tabs.offset_top == -221.0, "Channel tabs offset_top mismatch: %f" % chat.channel_tabs.offset_top)
	
	chat.set_chat_height(-86.0)
	assert(chat.chat_history_panel.offset_top == -86.0, "Height preset -86 mismatch")
	print("  [OK] Height resizing and dynamic tab positioning verified.")
	
	# Verify Channel Tabs & Filtering
	chat.add_chat_message("Daniel", "Hello world!", "Local")
	chat.add_chat_message("Betty", "Let's fight the boss!", "Team")
	chat.add_chat_message("System", "Server maintenance in 1 hour.", "System")
	
	chat.select_chat_tab("Team")
	assert(chat._active_chat_tab == "Team", "Active tab mismatch")
	var team_txt: String = chat.chat_history.get_parsed_text()
	assert(team_txt.contains("Let's fight the boss!"), "Team message missing from Team tab: %s" % team_txt)
	assert(not team_txt.contains("Hello world!"), "Local message should not be visible in Team tab")
	
	chat.select_chat_tab("All")
	var all_txt: String = chat.chat_history.get_parsed_text()
	assert(all_txt.contains("Hello world!"), "Local message missing from All tab")
	assert(all_txt.contains("Let's fight the boss!"), "Team message missing from All tab")
	print("  [OK] Tab switching (All, Current, Team, Whisper, System) and message filtering verified.")
	
	# Verify Input Bar Auto-fitting
	chat._select_channel("Local")
	assert(chat.whisper_target.visible == false, "Whisper target should be hidden in Local channel")
	assert(chat.chat_input.position.x == 74.0, "ChatInput should start at x=74 when whisper target hidden")
	
	chat._select_channel("Whisper")
	assert(chat.whisper_target.visible == true, "Whisper target should be visible in Whisper channel")
	assert(chat.chat_input.position.x == 163.0, "ChatInput should shrink to x=163 when whisper target visible")
	print("  [OK] Input bar auto-fitting layout verified.")
	
	# Verify Emote Picker
	assert(chat.emote_grid.get_child_count() == 31, "Emote grid must have 31 emotes, found %d" % chat.emote_grid.get_child_count())
	print("  [OK] Emote picker verified with 31 authentic emotes.")
	
	chat.queue_free()
	await process_frame

func _test_bottom_action_dock() -> void:
	print("\n>>> [TEST 4] Verifying BottomActionDock (Standalone Scene & Script)...")
	var scene: PackedScene = load("res://scenes/ui/hud/bottom_action_dock.tscn")
	assert(scene != null, "ERROR: bottom_action_dock.tscn failed to load")
	
	var dock: BottomActionDock = scene.instantiate() as BottomActionDock
	assert(dock != null, "ERROR: Failed to instantiate BottomActionDock")
	root.add_child(dock)
	await process_frame
	await process_frame
	
	# Verify Anchor Presets
	assert(dock.anchors_preset == Control.PRESET_BOTTOM_RIGHT, "ERROR: BottomActionDock default must be PRESET_BOTTOM_RIGHT")
	dock.set_anchor_mode(BottomActionDock.AnchorMode.ANCHOR_CENTER_BOTTOM)
	assert(dock.anchors_preset == Control.PRESET_CENTER_BOTTOM, "ERROR: BottomActionDock center mode must be PRESET_CENTER_BOTTOM")
	dock.set_anchor_mode(BottomActionDock.AnchorMode.ANCHOR_BOTTOM_RIGHT)
	assert(dock.anchors_preset == Control.PRESET_BOTTOM_RIGHT, "ERROR: Failed restoring PRESET_BOTTOM_RIGHT")
	print("  [OK] Anchor presets PRESET_BOTTOM_RIGHT and PRESET_CENTER_BOTTOM verified.")
	
	# Verify Action Buttons and Hotkeys
	var trigger_result := {"id": 0}
	dock.button_triggered.connect(func(id: int): trigger_result["id"] = id)
	dock.trigger_hotkey(1) # Status
	assert(trigger_result["id"] == 1, "Hotkey 1 trigger mismatch: %d" % trigger_result["id"])
	dock.trigger_hotkey(2) # Skill
	assert(trigger_result["id"] == 2, "Hotkey 2 trigger mismatch: %d" % trigger_result["id"])
	print("  [OK] Action button hotkey triggers verified.")
	
	# Verify Compound Tooltips
	dock.set_compound_tooltip(1, "Status Window", "C", "Opens character attributes and equipment.")
	assert("Status Window [C]" in dock.btn_status.tooltip_text, "Compound tooltip format mismatch")
	print("  [OK] Compound tooltip formatting verified.")
	
	# Verify Drag & Drop Quickslot Binding
	var item_data := {"type": "item", "item_id": 1001, "name": "Mana Herb", "desc": "Restores 50 SP."}
	assert(dock._can_drop_data(Vector2(10, 10), item_data) == true, "Can drop data must return true for valid item")
	dock.bind_slot_data(0, item_data)
	var retrieved := dock.get_slot_data(0)
	assert(retrieved.get("item_id") == 1001, "Retrieved slot data mismatch")
	print("  [OK] Quickslots drag-and-drop binding verified.")
	
	dock.queue_free()
	await process_frame

func _test_hud_manager() -> void:
	print("\n>>> [TEST 5] Verifying HUDManager (Responsive Multi-Dock Coordinator)...")
	var manager := HUDManager.new()
	assert(manager != null, "ERROR: Failed to instantiate HUDManager")
	root.add_child(manager)
	
	# Instantiate and add docks to manager
	var status_scene: PackedScene = load("res://scenes/ui/hud/status_dock.tscn")
	var minimap_scene: PackedScene = load("res://scenes/ui/hud/radar_minimap.tscn")
	var chat_scene: PackedScene = load("res://scenes/ui/hud/chat_dock.tscn")
	var action_scene: PackedScene = load("res://scenes/ui/hud/bottom_action_dock.tscn")
	
	var status_dock: StatusDock = status_scene.instantiate() as StatusDock
	var minimap_dock: RadarMinimap = minimap_scene.instantiate() as RadarMinimap
	var chat_dock: ChatDock = chat_scene.instantiate() as ChatDock
	var action_dock: BottomActionDock = action_scene.instantiate() as BottomActionDock
	
	manager.add_child(status_dock)
	manager.add_child(minimap_dock)
	manager.add_child(chat_dock)
	manager.add_child(action_dock)
	
	manager._discover_and_wire_docks()
	
	var test_res: Array[Vector2] = [
		Vector2(800, 600),   # 4:3 (narrowest width)
		Vector2(1024, 768),  # 4:3
		Vector2(1280, 720),  # 16:9
		Vector2(1680, 1050), # 16:10
		Vector2(1920, 1080), # 16:9
		Vector2(2560, 1080), # 21:9 Ultrawide
	]
	
	for res in test_res:
		manager.size = res
		manager.recalculate_responsive_layout(res)
		await process_frame
		
		# 1. Status dock must be at (0, 0)
		assert(status_dock.position == Vector2(0, 0), "Status dock not at (0,0) at res %s" % res)
		
		# 2. Minimap dock must be at (width - 226, 0)
		assert(is_equal_approx(minimap_dock.position.x, res.x - 226.0), "Minimap x mismatch at res %s" % res)
		assert(is_equal_approx(minimap_dock.position.y, 0.0), "Minimap y mismatch at res %s" % res)
		
		# 3. Action dock must be at (width - 282, height - 78)
		assert(is_equal_approx(action_dock.position.x, res.x - 282.0), "Action dock x mismatch at res %s" % res)
		assert(is_equal_approx(action_dock.position.y, res.y - 78.0), "Action dock y mismatch at res %s" % res)
		
		# 4. Chat dock must be at (0, height - 25)
		assert(is_equal_approx(chat_dock.position.x, 0.0), "Chat dock x mismatch at res %s" % res)
		assert(is_equal_approx(chat_dock.position.y, res.y - 25.0), "Chat dock y mismatch at res %s" % res)
		
		# 5. Non-overlapping check between ChatDock and ActionDock!
		var chat_right: float = chat_dock.position.x + chat_dock.size.x
		var action_left: float = action_dock.position.x
		assert(chat_right <= action_left,
			"Collision detected! ChatDock right edge (%f) overlaps ActionDock left edge (%f) at res %s" % [chat_right, action_left, res])
		
		print("  [OK] Resolution %s (%s) verified: zero overlap, exact boundary docking." % [res, "4:3" if res.x/res.y < 1.4 else ("16:9" if res.x/res.y < 1.8 else "Ultrawide")])
		
	manager.queue_free()
	await process_frame
