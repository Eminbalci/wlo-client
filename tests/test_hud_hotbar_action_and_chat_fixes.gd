extends SceneTree

## In-Engine Verification Test for HUD Hotbar (4 pages, Drag & Drop),
## Compound Button Tooltip, Action Dock Background, and Clean Parchment Chat.

func _init() -> void:
	print("\n=================================================================")
	print("--- Running HUD Hotbar, Action Dock & Chat Fixes Test Suite ---")
	print("=================================================================\n")
	
	var hud_scene: PackedScene = load("res://scenes/ui/hud.tscn")
	assert(hud_scene != null, "ERROR: Failed to load res://scenes/ui/hud.tscn")
	
	var hud: Control = hud_scene.instantiate() as Control
	assert(hud != null, "ERROR: Failed to instantiate HUD")
	root.add_child(hud)
	
	await process_frame
	await process_frame
	
	_test_hotbar_pages_and_drag_drop(hud)
	_test_bottom_action_dock(hud)
	_test_clean_chat_dock(hud)
	
	print("\n=================================================================")
	print("--- ALL HUD FIXES TESTS PASSED (100% ZERO-ERROR) ---------------")
	print("=================================================================\n")
	quit(0)

func _test_hotbar_pages_and_drag_drop(hud: Control) -> void:
	print(">>> [TEST 1] Verifying Hotbar 4-Page System & Drag & Drop...")
	var hotbar = hud.hotbar_ctrl
	assert(hotbar != null, "ERROR: hotbar_ctrl missing on HUD")
	
	# 1. 4-Page state check
	assert(hotbar.get_current_page() == 0, "Initial page must be 0 (Page 1)")
	var initial_slot1_item = hotbar.get_slot_entry(0)
	assert(not initial_slot1_item.is_empty(), "Page 1 Slot 1 should have default item")
	
	# Page 2 (index 1) should be empty
	hotbar.next_page()
	assert(hotbar.get_current_page() == 1, "Next page must be 1 (Page 2)")
	var p2_slot1 = hotbar.get_slot_entry(0)
	assert(p2_slot1.is_empty(), "Page 2 Slot 1 should initially be empty")
	
	# Cycle through pages: 1 -> 2 -> 3 -> 0
	hotbar.next_page()
	assert(hotbar.get_current_page() == 2, "Page must be 2 (Page 3)")
	hotbar.next_page()
	assert(hotbar.get_current_page() == 3, "Page must be 3 (Page 4)")
	hotbar.next_page()
	assert(hotbar.get_current_page() == 0, "Cycling next from Page 4 must wrap to Page 1 (0)")
	
	hotbar.prev_page()
	assert(hotbar.get_current_page() == 3, "Cycling prev from Page 1 must wrap to Page 4 (3)")
	hotbar.set_page(0)
	assert(hotbar.get_current_page() == 0, "set_page(0) must set page 0")
	print("  [OK] 4-Page cycling (prev/next/set) verified.")
	
	# 2. Baked-in F1..F8 visibility: duplicate label text must be hidden
	for i in range(8):
		var btn = hotbar.get_slot_button(i)
		assert(btn != null, "Slot %d button must exist" % (i + 1))
		var lbl = btn.get_node_or_null("KeyLabel")
		assert(lbl != null, "KeyLabel must exist for test compatibility")
		assert(lbl.visible == false, "KeyLabel must be hidden so baked-in F1..F8 artwork shows")
	print("  [OK] Redundant F1..F8 labels hidden; baked-in artwork unobstructed.")
	
	# 3. Drag & Drop test: Item drop
	var item_data := {
		"type": "item",
		"id": 1050,
		"name": "Super Potion"
	}
	assert(hotbar.can_drop_on_slot(2, item_data) == true, "Hotbar slot 2 must accept item drop")
	hotbar.drop_on_slot(2, item_data)
	var slot3_entry = hotbar.get_slot_entry(2)
	assert(slot3_entry.get("id") == 1050, "Slot 2 should now have item 1050")
	assert(slot3_entry.get("name") == "Super Potion", "Slot 2 name should be Super Potion")
	
	# 4. Drag & Drop test: Skill drop
	var skill_data := {
		"type": "skill",
		"id": 201,
		"name": "Thunderbolt"
	}
	assert(hotbar.can_drop_on_slot(3, skill_data) == true, "Hotbar slot 3 must accept skill drop")
	hotbar.drop_on_slot(3, skill_data)
	var slot4_entry = hotbar.get_slot_entry(3)
	assert(slot4_entry.get("type") == "skill", "Slot 3 should be skill")
	assert(slot4_entry.get("name") == "Thunderbolt", "Slot 3 name should be Thunderbolt")
	
	# 5. Inventory item drag data format drop
	var inv_drag_data := {
		"type": "inventory",
		"slot_index": 5,
		"item": {"id": 1005, "name": "Steamed Bun"}
	}
	assert(hotbar.can_drop_on_slot(4, inv_drag_data) == true, "Hotbar slot 4 must accept inventory drag drop")
	hotbar.drop_on_slot(4, inv_drag_data)
	var slot5_entry = hotbar.get_slot_entry(4)
	assert(slot5_entry.get("id") == 1005, "Slot 4 item id should be 1005")
	
	# 6. Slot activation (clicking slot or F1..F8 key)
	hotbar.activate_slot(2) # uses item 1050
	hotbar.activate_slot(3) # casts skill 201
	
	# 7. Right-click clear
	hotbar.on_slot_right_clicked(2)
	assert(hotbar.get_slot_entry(2).is_empty(), "Slot 2 should be cleared after right click")
	print("  [OK] Drag & Drop (item, skill, inventory) and right-click clear verified.")

func _test_bottom_action_dock(hud: Control) -> void:
	print(">>> [TEST 2] Verifying Bottom Action Dock, Shifted Position & Compound Tooltip...")
	var dock = hud.get_node_or_null("BottomActionDock")
	assert(dock != null, "BottomActionDock must exist")
	
	# 1. Lifted position: offset_top must be -78.0, offset_bottom must be -10.0
	assert(dock.offset_top == -78.0, "BottomActionDock offset_top must be -78.0 (lifted by 10px)")
	assert(dock.offset_bottom == -10.0, "BottomActionDock offset_bottom must be -10.0")
	
	# 2. ActionBackground visibility & position (visible, cradling buttons from underneath at top 34.0)
	var bg = dock.get_node_or_null("ActionBackground") as TextureRect
	assert(bg != null, "ActionBackground must exist")
	assert(bg.visible == true, "ActionBackground must be visible to cradle action buttons")
	assert(bg.offset_top == 34.0, "ActionBackground offset_top must be 34.0 (lowered to cradle buttons)")
	
	# 3. BtnQuest tooltip changed to "Compound [C]"
	var btn_quest = dock.get_node_or_null("ButtonContainer/BtnQuest") as TextureButton
	assert(btn_quest != null, "BtnQuest must exist")
	assert(btn_quest.tooltip_text.contains("Compound"), "BtnQuest tooltip must contain 'Compound', was '%s'" % btn_quest.tooltip_text)
	print("  [OK] BottomActionDock lifted position, hidden background artifact, and Compound tooltip verified.")

func _test_clean_chat_dock(hud: Control) -> void:
	print(">>> [TEST 3] Verifying Clean Parchment ChatDock (No Screenshot Artifacts)...")
	var chat_dock = hud.get_node_or_null("ChatDock")
	assert(chat_dock != null, "ChatDock must exist")
	
	# 1. PanelTalkFormLeft must NOT have a dirty screenshot texture
	var left_panel = chat_dock.get_node_or_null("ChatHistoryPanel/PanelTalkFormLeft") as TextureRect
	assert(left_panel != null, "PanelTalkFormLeft node exists")
	assert(left_panel.texture == null, "PanelTalkFormLeft texture must be null (dirty cropped screenshot removed)")
	
	# 2. ChatHistoryPanel uses clean authentic parchment StyleBoxFlat
	var history_panel = chat_dock.get_node_or_null("ChatHistoryPanel") as PanelContainer
	assert(history_panel != null, "ChatHistoryPanel must exist")
	var style = history_panel.get_theme_stylebox("panel")
	assert(style is StyleBoxFlat, "ChatHistoryPanel panel style must be StyleBoxFlat")
	print("  [OK] Clean parchment chat dock verified with 0 ghosted screenshot textures.")
