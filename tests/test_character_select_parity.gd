extends SceneTree

const CharacterSelectScene = preload("res://scenes/ui/auth/character_select.tscn")
const LoginScreenScene = preload("res://scenes/ui/login_screen.tscn")
const CharacterManager = preload("res://scripts/ui/auth/character_manager.gd")
const SavedAccountsManager = preload("res://scripts/ui/auth/saved_accounts_manager.gd")

var total_tests: int = 0
var passed_tests: int = 0

func _init() -> void:
	print("\n==================================================")
	print("STARTING CHARACTER SELECT PARITY & FLOW VERIFICATION")
	print("==================================================")
	
	call_deferred("_run_all_tests")

func _assert_test(condition: bool, description: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("[PASS] %s" % description)
	else:
		push_error("[FAIL] %s" % description)
		print("[FAIL] %s" % description)

func _run_all_tests() -> void:
	var cs_inst: CharacterSelect = CharacterSelectScene.instantiate()
	root.add_child(cs_inst)
	cs_inst.account_name = "test_parity_account"
	CharacterManager.clear_all_characters(cs_inst.account_name)

	# 1. Screen resolution, 2-Card Centered Layout & Separated Leave Button Parity
	print("\n>>> 1. Testing 2-Card Centered Layout and Separated Leave Button Parity...")
	var bg_rect = cs_inst.get_node_or_null("BackgroundRect") as TextureRect
	_assert_test(bg_rect != null and bg_rect.texture != null, "BackgroundRect exists with texture")
	if bg_rect and bg_rect.texture:
		_assert_test(bg_rect.texture.resource_path.ends_with("LogPic1.jpg"), "Background texture is authentic LogPic1.jpg")

	var card0 = cs_inst.get_node_or_null("CardSlot0") as Control
	var card1 = cs_inst.get_node_or_null("CardSlot1") as Control
	_assert_test(card0 != null and card1 != null, "Both CardSlot0 and CardSlot1 exist side-by-side")
	if card0 and card1:
		_assert_test(card0.anchor_left == 0.5 and card0.anchor_top == 0.5 and card1.anchor_left == 0.5 and card1.anchor_top == 0.5, "Both CardSlot0 and CardSlot1 are center-anchored (anchors_preset = 8)")
		_assert_test(card0.size == Vector2(337, 352) and card1.size == Vector2(337, 352), "Both cards have dimensions 337x352")
		_assert_test(card0.offset_left < 0.0 and card1.offset_left > 0.0, "CardSlot0 is on the left of center and CardSlot1 is on the right of center")

	var btn_back = cs_inst.get_node_or_null("BtnBack") as TextureButton
	_assert_test(btn_back != null and btn_back.get_parent() == cs_inst, "BtnBack ([ Leave ]) is separated outside the character cards")
	if btn_back:
		_assert_test(btn_back.anchor_left == 0.5 and btn_back.anchor_top == 0.5, "BtnBack is center-anchored below the 2 cards")
		_assert_test(btn_back.texture_normal != null and btn_back.texture_normal.resource_path.contains("btn_leave"), "BtnBack uses authentic [ Leave ] texture")

	# 2. Empty Slot Card Parity
	print("\n>>> 2. Testing Empty Slot Card Parity...")
	cs_inst.select_slot(1)
	var card_bg = cs_inst.card_bg
	_assert_test(card_bg != null and card_bg.texture.resource_path.ends_with("Form_SelectRole_Empty_R.jpg"), "Empty slot displays Form_SelectRole_Empty_R.jpg")
	
	var btn_create = cs_inst.btn_create
	_assert_test(btn_create != null and btn_create.visible and not btn_create.disabled, "Empty slot shows active [ Create ] button")
	if btn_create:
		_assert_test(btn_create.texture_normal != null and btn_create.texture_hover != null and btn_create.texture_pressed != null, "BtnCreateChar has full 3-state textures")

	var create_emitted := [false, -1]
	cs_inst.create_requested.connect(func(slot):
		create_emitted[0] = true
		create_emitted[1] = slot
	)
	cs_inst._on_slot_create_pressed(1)
	_assert_test(create_emitted[0] and create_emitted[1] == 1, "Clicking [ Create ] emits create_requested(slot_idx)")

	var back_emitted := [false]
	cs_inst.back_requested.connect(func(): back_emitted[0] = true)
	cs_inst._on_back_pressed()
	_assert_test(back_emitted[0], "Clicking [ Leave ] emits back_requested()")

	# 3. Occupied Slot Card Parity
	print("\n>>> 3. Testing Occupied Slot Card Parity...")
	var hero_data := {
		"slot_index": 0,
		"first_name": "Satoru",
		"last_name": "Gojo",
		"name": "Satoru Gojo",
		"role_id": 6,
		"role_name": "Daniel",
		"element": "Fire",
		"level": 1,
		"gold": 0,
		"exp": 0,
		"hp": 245,
		"max_hp": 245,
		"sp": 180,
		"max_sp": 180
	}
	CharacterManager.save_character(0, hero_data, cs_inst.account_name)
	cs_inst.refresh_characters()
	cs_inst.select_slot(0)

	_assert_test(cs_inst.card_bg != null and cs_inst.card_bg.texture.resource_path.ends_with("Form_SelectRole_Info_R.jpg"), "Occupied slot 0 displays Form_SelectRole_Info_R.jpg")
	var card1_bg = card1.get_node_or_null("CardBg") as TextureRect
	_assert_test(card1_bg != null and card1_bg.texture.resource_path.ends_with("Form_SelectRole_Empty_R.jpg"), "Empty slot 1 simultaneously displays Form_SelectRole_Empty_R.jpg")
	
	var name_lbl = cs_inst.name_label_node
	_assert_test(name_lbl != null and name_lbl.text == "Satoru Gojo", "Character Name formatted as 'First Last' (Satoru Gojo)")

	var lvl_lbl = cs_inst.level_label_node
	_assert_test(lvl_lbl != null and lvl_lbl.text == "1", "Level displayed as 1")

	var gold_lbl = cs_inst.gold_label_node
	_assert_test(gold_lbl != null and gold_lbl.text == "0", "Gold displayed as 0")

	var exp_lbl = cs_inst.exp_label_node
	var exp_bar = cs_inst.exp_bar_node
	_assert_test(exp_lbl != null and exp_lbl.text == "0%" and exp_bar != null and exp_bar.value == 0, "EXP displayed as 0% with progress bar")

	var bust_rect = cs_inst.bust_rect
	_assert_test(bust_rect != null and bust_rect.texture != null, "Face bust portrait loaded in top-left parchment frame")

	var elem_icon = cs_inst.element_icon
	_assert_test(elem_icon != null and elem_icon.visible and elem_icon.texture.resource_path.ends_with("icon_element_3.png"), "Element Coin badge matches Fire affinity")

	var btn_login = cs_inst.btn_login
	var btn_del = cs_inst.btn_del
	_assert_test(btn_login != null and btn_login.visible and not btn_login.disabled, "[ Select ] (Login) button active for occupied slot")
	_assert_test(btn_del != null and btn_del.visible and not btn_del.disabled, "[ Delete ] button active for occupied slot")
	_assert_test(cs_inst.btn_create.visible == false, "[ Create ] button hidden for occupied slot")

	var selected_emitted := [false, -1]
	cs_inst.character_selected.connect(func(slot):
		selected_emitted[0] = true
		selected_emitted[1] = slot
	)
	cs_inst._on_slot_login_pressed(0)
	_assert_test(selected_emitted[0] and selected_emitted[1] == 0, "Clicking [ Select ] emits character_selected(slot_idx)")

	# 4. Sprite Walk-in-Place & Heading Rotation Parity
	print("\n>>> 4. Testing Walking in Place & Rotation Parity...")
	_assert_test(cs_inst._slot_rotations.get(0, -1) == 3, "Default heading is South-West (Heading 3)")
	
	cs_inst._anim_timer = 0.0
	cs_inst._update_slot_sprite_preview(0)
	var prev_rect = cs_inst.sprite_preview_rect
	_assert_test(prev_rect != null and prev_rect.texture != null, "SpritePreview displays walking composite texture")

	cs_inst._rotate_slot_character(0, -1)
	_assert_test(cs_inst._slot_rotations.get(0) == 2, "BtnTurnL rotates heading CCW: 3 -> 2 (West)")
	cs_inst._rotate_slot_character(0, -1)
	_assert_test(cs_inst._slot_rotations.get(0) == 1, "BtnTurnL rotates heading CCW: 2 -> 1 (North-West)")
	cs_inst._rotate_slot_character(0, -1)
	_assert_test(cs_inst._slot_rotations.get(0) == 0, "BtnTurnL rotates heading CCW: 1 -> 0 (North)")
	cs_inst._rotate_slot_character(0, -1)
	_assert_test(cs_inst._slot_rotations.get(0) == 7, "BtnTurnL wraps around to 7 (North-East)")

	cs_inst._rotate_slot_character(0, 1)
	_assert_test(cs_inst._slot_rotations.get(0) == 0, "BtnTurnR rotates heading CW: 7 -> 0")
	cs_inst._rotate_slot_character(0, 3)
	_assert_test(cs_inst._slot_rotations.get(0) == 3, "Returned to South-West (Heading 3)")

	# 5. Audio Integration (wav0151.wav)
	print("\n>>> 5. Testing Audio Integration (wav0151.wav)...")
	_assert_test(cs_inst._sfx_stream != null and cs_inst._sfx_stream.resource_path.ends_with("wav0151.wav"), "SFX stream loaded authentic wav0151.wav")
	_assert_test(cs_inst._sfx_player != null and cs_inst._sfx_player.name == "CharSelectSFX", "Internal CharSelectSFX audio stream player instantiated")

	# 6. Backward Compatibility Accessors
	print("\n>>> 6. Testing Backward Compatibility Accessors...")
	_assert_test(cs_inst.slot_tabs.size() == 2, "slot_tabs returns array of 2 cards")
	_assert_test(cs_inst.card_slot_0 != null, "card_slot_0 accessor valid")
	_assert_test(cs_inst.card_slot_1 != null, "card_slot_1 accessor valid")
	_assert_test(cs_inst.btn_prev != null, "btn_prev accessor valid")
	_assert_test(cs_inst.btn_leave != null, "btn_leave accessor valid")
	_assert_test(cs_inst.btn_turn_l != null, "btn_turn_l accessor valid")
	_assert_test(cs_inst.btn_turn_r != null, "btn_turn_r accessor valid")
	_assert_test(cs_inst.char_name_label != null, "char_name_label accessor valid")
	_assert_test(cs_inst.element_label != null, "element_label accessor valid")
	_assert_test(cs_inst.btn_enter_world != null, "btn_enter_world accessor valid")
	_assert_test(cs_inst.preview_rect != null, "preview_rect accessor valid")
	_assert_test(cs_inst._get_card_node(0) == cs_inst.card_slot_0, "_get_card_node(0) accessor valid")
	_assert_test(cs_inst._get_card_node(1) == cs_inst.card_slot_1, "_get_card_node(1) accessor valid")

	cs_inst.queue_free()

	# 7. Flow Integration with LoginScreen
	print("\n>>> 7. Testing Flow Integration with LoginScreen...")
	var ls_inst: LoginScreen = LoginScreenScene.instantiate()
	root.add_child(ls_inst)
	ls_inst.current_account = "flow_test_user"
	CharacterManager.clear_all_characters(ls_inst.current_account)

	ls_inst.goto_state(LoginScreen.FlowState.CHARACTER_SELECT)
	_assert_test(ls_inst.character_select_node.visible, "LoginScreen transitioned to CHARACTER_SELECT")

	ls_inst._on_create_character_requested(1)
	_assert_test(ls_inst.character_create_node.visible, "LoginScreen transitioned to CHARACTER_CREATE")
	_assert_test(ls_inst.character_create_node.target_slot == 1, "CharacterCreate wizard configured for slot 1")

	var new_hero := {
		"slot_index": 1,
		"first_name": "Rocco",
		"last_name": "Valiant",
		"name": "Rocco Valiant",
		"role_id": 3,
		"element": "Earth",
		"level": 1,
		"gold": 0,
		"exp": 0
	}
	CharacterManager.save_character(1, new_hero, ls_inst.current_account)
	ls_inst._on_character_created(new_hero)

	_assert_test(ls_inst.character_select_node.visible, "CharacterSelect visible after character creation")
	_assert_test(ls_inst.character_select_node.selected_slot_index == 1, "CharacterSelect automatically selects target slot 1")
	
	var active_char: Dictionary = ls_inst.character_select_node.get_selected_character()
	_assert_test(active_char.get("name") == "Rocco Valiant", "CharacterSelect automatically refreshes and displays newly created character in slot 1")
	_assert_test(active_char.get("element") == "Earth", "Newly created character has correct element")

	ls_inst.queue_free()
	CharacterManager.clear_all_characters("test_parity_account")
	CharacterManager.clear_all_characters("flow_test_user")

	print("\n==================================================")
	print("CHARACTER SELECT PARITY TEST SUMMARY: %d / %d PASSED" % [passed_tests, total_tests])
	print("==================================================")

	if passed_tests == total_tests:
		quit(0)
	else:
		quit(1)
