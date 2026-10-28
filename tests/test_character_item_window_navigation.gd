extends SceneTree

const HUDScene = preload("res://scenes/ui/hud.tscn")
const HUDCharacterStatus = preload("res://scripts/ui/hud/hud_character_status.gd")
const HUDInventory = preload("res://scripts/ui/hud/hud_inventory.gd")

func _init() -> void:
	_run_all_tests()

func _run_all_tests() -> void:
	print("\n=================================================================")
	print("--- Running Character & Item Window Navigation Test Suite ---")
	print("=================================================================\n")

	await _test_header_navigation_and_shoes_toggle()

	print("\n=================================================================")
	print("--- ALL CHARACTER & ITEM WINDOW NAVIGATION TESTS PASSED ---")
	print("=================================================================\n")
	quit(0)

func _test_header_navigation_and_shoes_toggle() -> void:
	print(">>> [TEST 1] Verifying Header Page Arrows & Shoes Mode Toggle...")
	var hud = HUDScene.instantiate()
	root.add_child(hud)
	await process_frame
	await process_frame

	var char_ctrl = hud.character_status
	assert(char_ctrl != null, "ERROR: CharacterStatus controller must exist")
	var inv_ctrl = hud.inventory_ctrl
	assert(inv_ctrl != null, "ERROR: Inventory controller must exist")

	# 1. Header Buttons Existence
	assert(char_ctrl.header_buttons.has("TitlePrev"), "ERROR: TitlePrev button missing")
	assert(char_ctrl.header_buttons.has("TitleNext"), "ERROR: TitleNext button missing")
	assert(char_ctrl.header_buttons.has("ShoesPrev"), "ERROR: ShoesPrev button missing")
	assert(char_ctrl.header_buttons.has("ShoesNext"), "ERROR: ShoesNext button missing")
	assert(char_ctrl.header_buttons.has("Potential"), "ERROR: Potential button missing")
	assert(char_ctrl.header_buttons.has("Close"), "ERROR: Close button missing")

	# 2. Inventory Page Navigation
	assert(char_ctrl.current_inventory_page == 0, "ERROR: Initial inventory page should be 0")
	assert(inv_ctrl.current_page == 0, "ERROR: Inventory controller page should be 0")

	var page_box := [-1]
	char_ctrl.inventory_page_changed.connect(func(p: int): page_box[0] = p)

	# Click TitleNext
	char_ctrl._on_title_next_pressed()
	assert(char_ctrl.current_inventory_page == 1, "ERROR: Page should advance to 1")
	assert(inv_ctrl.current_page == 1, "ERROR: Inventory controller page should sync to 1")
	assert(page_box[0] == 1, "ERROR: inventory_page_changed signal should emit 1")

	# Try to advance beyond max pages (should clamp)
	char_ctrl._on_title_next_pressed()
	assert(char_ctrl.current_inventory_page == 1, "ERROR: Page should remain clamped at 1")

	# Click TitlePrev
	char_ctrl._on_title_prev_pressed()
	assert(char_ctrl.current_inventory_page == 0, "ERROR: Page should return to 0")
	assert(inv_ctrl.current_page == 0, "ERROR: Inventory controller page should return to 0")

	# 3. Shoes View Mode Toggle
	assert(char_ctrl.shoes_view_mode == 0, "ERROR: Default shoes view mode should be 0 (Normal)")
	var shoes_mode_box := [-1]
	char_ctrl.shoes_view_mode_changed.connect(func(m: int): shoes_mode_box[0] = m)

	# Toggle shoes view to 1 (Riding / Mount gear)
	char_ctrl._on_shoes_toggle_pressed()
	assert(char_ctrl.shoes_view_mode == 1, "ERROR: Shoes view mode should toggle to 1")
	assert(shoes_mode_box[0] == 1, "ERROR: shoes_view_mode_changed should emit 1")
	var shoes_btn = char_ctrl.char_window.get_node_or_null("Slot_shoes") as Button
	if shoes_btn:
		assert("Riding" in shoes_btn.tooltip_text, "ERROR: Shoes slot tooltip should reflect Riding gear")

	# Toggle shoes view back to 0 (Normal footwear)
	char_ctrl._on_shoes_toggle_pressed()
	assert(char_ctrl.shoes_view_mode == 0, "ERROR: Shoes view mode should toggle back to 0")
	assert(shoes_mode_box[0] == 0, "ERROR: shoes_view_mode_changed should emit 0")
	if shoes_btn:
		assert("Boots" in shoes_btn.tooltip_text or "Shoes" in shoes_btn.tooltip_text, "ERROR: Shoes slot tooltip should reflect normal boots")

	# 4. Potential Button Interaction
	char_ctrl._on_potential_button_pressed()
	# Verify no crash and potential label remains formatted
	assert(char_ctrl.header_potential.text == "0", "ERROR: Potential label should display level")

	hud.queue_free()
	await process_frame
	print("  PASS: Header page navigation, shoes mode toggle, and potential interaction verified.")
