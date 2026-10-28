extends SceneTree

const CharacterCreateScene = preload("res://scenes/ui/auth/character_create.tscn")
const CharacterManager = preload("res://scripts/ui/auth/character_manager.gd")

func _init() -> void:
	print("==================================================================")
	print("--- Running 1:1 Character Creation Wizard (Daydream Flow) Test ---")
	print("==================================================================")

	# 1. Initialize GameDatabase and ArchiveLoader singletons
	var game_db = root.get_node_or_null("GameDatabase")
	if not game_db:
		var db_cls = load("res://scripts/database/game_database.gd")
		game_db = db_cls.new()
		game_db.name = "GameDatabase"
		root.add_child(game_db)

	var loader = root.get_node_or_null("ArchiveLoader")
	if not loader:
		var cls = load("res://scripts/core/archive_loader.gd")
		loader = cls.new()
		loader.name = "ArchiveLoader"
		root.add_child(loader)
		loader.initialize_archives()

	# 2. Instantiate CharacterCreate
	var cc: Control = CharacterCreateScene.instantiate()
	assert(cc != null, "CharacterCreate scene must instantiate cleanly")
	cc.account_name = "test_wizard_user"
	root.add_child(cc)
	print("cc in tree, background_rect = ", cc.background_rect)
	if cc.background_rect == null:
		print("calling _ready() manually...")
		cc._ready()
	print("after _ready, background_rect = ", cc.background_rect)
	if cc.background_rect:
		print("texture = ", cc.background_rect.texture)

	# 3. Geometry & Background Verification
	print("\n[PART 1] Verifying Screen Geometry, Background & Window Positioning...")
	assert(cc.background_rect != null and cc.background_rect.texture != null, "Background texture must be loaded")
	assert(cc.background_rect.texture.resource_path.ends_with("LogPic1.jpg"), "Background texture must be LogPic1.jpg")
	assert(cc.window_root.position == Vector2(30, 124), "Window must be centered at (X: 30, Y: 124)")
	assert(cc.window_root.size == Vector2(740, 352), "Window size must be 740x352")
	print("  PASS: Screen geometry and LogPic1 background verified.")

	# 4. Step 1: Role Carousel & Radar Chart & Preview
	print("\n[PART 2] Verifying Step 1 (Role Carousel, Radar Chart, Lore & Preview)...")
	cc.start_wizard(0)
	assert(cc.current_step == 1, "Must start on Step 1")
	assert(cc.step1_container.visible, "Step 1 container must be visible")
	assert(cc.selected_role_id == 6, "Default role must be 6 (Daniel)")
	assert(cc.step1_role_name.text.contains("Daniel"), "Role name must contain Daniel")
	assert(cc.step1_role_standee.texture != null, "Role standee illustration must be loaded")
	assert(cc.step1_radar_chart != null, "RadarChart node must exist")
	assert(cc.step1_radar_chart.stats["str"] == 14, "Daniel base STR in radar must be 14")

	# Role cycling
	cc.select_next_role()
	assert(cc.selected_role_id == 7, "Next role must be 7 (Sid)")
	assert(cc.step1_role_name.text.contains("Sid"), "Role name must update to Sid")
	assert(cc.step1_radar_chart.stats["str"] == 13, "Sid base STR in radar must be 13")

	cc.select_prev_role()
	assert(cc.selected_role_id == 6, "Prev role must return to 6 (Daniel)")

	# Walking sprite and turn buttons
	assert(cc.walking_sprite != null, "Walking sprite node must exist")
	var initial_heading: int = cc._current_direction
	assert(initial_heading == IsometricMath.Heading.SOUTH_WEST, "Default direction must be SOUTH_WEST (3)")

	cc._turn_character(1) # Turn CW
	assert(cc._current_direction == (initial_heading + 1) % 8, "Turning +1 must advance direction by one")
	cc._turn_character(-1) # Turn CCW
	assert(cc._current_direction == initial_heading, "Turning -1 must return to default direction")

	# Hat toggle
	assert(cc._show_hat == true, "Hat toggle default is true")
	cc._toggle_hat()
	assert(cc._show_hat == false, "Hat toggle must toggle to false")
	cc._toggle_hat()
	assert(cc._show_hat == true, "Hat toggle must toggle back to true")

	# 5. Validation Rejection: Empty Name Alert & Modal Dialog
	print("\n[PART 3] Verifying Empty Name Validation & Modal Error Popup...")
	cc.first_name_input.text = ""
	cc.family_name_input.text = ""
	cc._on_step1_continue()

	assert(cc.modal_error_popup.visible == true, "Empty name must display modal error popup")
	assert(cc.modal_message_label.text.length() > 0, "Modal message must contain validation text")
	assert(cc.current_step == 1, "Wizard must remain on Step 1 when validation fails")

	# Dismiss modal
	cc._dismiss_modal_error()
	assert(cc.modal_error_popup.visible == false, "Modal popup must close on dismissal")

	# Set valid names and proceed to Step 2
	cc.first_name_input.text = "Satoru"
	cc.family_name_input.text = "Gojo"
	cc._on_step1_continue()
	assert(cc.current_step == 2, "Wizard must advance to Step 2 with valid name")
	assert(cc.step2_container.visible == true, "Step 2 container must be visible")
	print("  PASS: Validation, modal popup, and Step 2 advancement verified.")

	# 6. Step 2: Appearance Customization (Tabs, Change, Sliders, Preview)
	print("\n[PART 4] Verifying Step 2 (Appearance Tabs, Change, Sliders, Live Tinting)...")
	# 4 Tabs
	assert(cc.tab_hair != null and cc.tab_body != null and cc.tab_eyes != null and cc.tab_wear != null, "All 4 appearance tabs must exist")
	cc._select_tab(1) # Body
	assert(cc._active_tab == 1, "Active tab must switch to Body")
	cc._select_tab(0) # Hair
	assert(cc._active_tab == 0, "Active tab must return to Hair")

	# Hair style change
	assert(cc.selected_hair_style == 1, "Default hair style is 1")
	cc._cycle_hair_style(1)
	assert(cc.selected_hair_style == 2, "Cycling hair style must update to 2")
	assert(cc.style_val_label.text.contains("Style 2"), "Style label must show Style 2")

	# RGB Color Sliders
	cc._on_slider_changed("r", 200.0)
	cc._on_slider_changed("g", 100.0)
	cc._on_slider_changed("b", 50.0)
	assert(is_equal_approx(cc.selected_hair_color.r, 200.0 / 255.0), "Red channel must match slider")
	assert(is_equal_approx(cc.selected_hair_color.g, 100.0 / 255.0), "Green channel must match slider")
	assert(is_equal_approx(cc.selected_hair_color.b, 50.0 / 255.0), "Blue channel must match slider")

	# Reset to default
	cc._reset_active_tab_color()
	assert(is_equal_approx(cc.selected_hair_color.r, 0.9), "Default hair color r is 0.9")

	# Full name display
	assert(cc.step2_full_name.text == "Satoru Gojo", "Full name must display First Last in Step 2 preview")

	# Return to Step 1 and back to Step 2
	cc.goto_step(1)
	assert(cc.current_step == 1, "Navigating back returns to Step 1")
	cc.goto_step(2)
	assert(cc.current_step == 2, "Navigating forward advances to Step 2")
	print("  PASS: Appearance controls, sliders, and live preview verified.")

	# 7. Step 3: Elements & Finish
	print("\n[PART 5] Verifying Step 3 (Element Affinities, Coin Badge, Character Creation)...")
	cc.goto_step(3)
	assert(cc.current_step == 3, "Wizard must advance to Step 3")
	assert(cc.step3_container.visible == true, "Step 3 container must be visible")

	for elem: String in ["Earth", "Water", "Fire", "Wind"]:
		cc.select_element(elem)
		assert(cc.selected_element == elem, "Selected element must update to %s" % elem)
		assert(cc.element_desc_label.text.contains(elem), "Element desc label must describe %s" % elem)
		assert(cc.step3_elem_coin.texture != null, "Element coin badge must be loaded for %s" % elem)

	assert(cc.step3_full_name.text == "Satoru Gojo", "Full name must display in Step 3 preview")

	# Finish character creation
	var created_data: Array = []
	cc.character_created.connect(func(c): created_data.append(c))
	cc._on_confirm_create()

	assert(created_data.size() == 1, "character_created signal must be emitted")
	var new_char: Dictionary = created_data[0]
	assert(new_char.get("name") == "Satoru Gojo", "Created character name must be Satoru Gojo")
	assert(new_char.get("element") == "Wind", "Created character element must be Wind")
	assert(new_char.get("role_id") == 6, "Created character role_id must be 6")
	assert(new_char.get("first_name") == "Satoru", "Character data must store first_name")
	assert(new_char.get("family_name") == "Gojo", "Character data must store family_name")

	# Verify persistence
	var saved_char := CharacterManager.get_character_in_slot(0, cc.account_name)
	assert(saved_char.get("name") == "Satoru Gojo", "Character must be persisted via CharacterManager")
	print("  PASS: Element selection, persistence, and creation signal verified.")

	# 8. Backward Compatibility Verification
	print("\n[PART 6] Verifying Backward Compatibility (test_all_client_buttons & test_auth_flow)...")
	assert(cc.step1_btn_next.texture_normal != null and cc.step1_btn_next.texture_hover != null and cc.step1_btn_next.texture_pressed != null, "step1_btn_next 3-state textures non-null")
	assert(cc.step1_btn_cancel.texture_normal != null and cc.step1_btn_cancel.texture_hover != null and cc.step1_btn_cancel.texture_pressed != null, "step1_btn_cancel 3-state textures non-null")
	assert(cc.step4_btn_ok.texture_normal != null and cc.step4_btn_ok.texture_hover != null and cc.step4_btn_ok.texture_pressed != null, "step4_btn_ok 3-state textures non-null")
	assert(cc.btn_finish == cc.step4_btn_ok, "btn_finish alias must match step4_btn_ok")
	assert(cc.btn_cancel == cc.step1_btn_cancel, "btn_cancel alias must match step1_btn_cancel")
	assert(cc.name_input == cc.first_name_input, "name_input alias must reference first_name_input")

	cc.goto_step(4)
	assert(cc.step4_container.visible == true, "Step 4 compatibility container accessible")

	cc._modify_stat("str", 1)
	assert(cc.bonus_points["str"] == 1, "_modify_stat compatibility verified")

	# Clean up
	CharacterManager.clear_all_characters(cc.account_name)
	cc.queue_free()

	print("\n==================================================================")
	print("--- ALL CHARACTER CREATION WIZARD TESTS PASSED (0 ERRORS) ---")
	print("==================================================================")
	quit(0)
