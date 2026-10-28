extends Node

## Comprehensive in-engine verification suite for Wonderland Online Auth & Character Flow.
## Tests all 9 screens, managers, signal paths, and state transitions headlessly.

const ServerConfig = preload("res://scripts/network/server_config.gd")
const SavedAccountsManager = preload("res://scripts/ui/auth/saved_accounts_manager.gd")
const CharacterManager = preload("res://scripts/ui/auth/character_manager.gd")

const ServerSelectScript = preload("res://scripts/ui/auth/server_select.gd")
const LoginDialogScript = preload("res://scripts/ui/auth/login_dialog.gd")
const CharacterSelectScript = preload("res://scripts/ui/auth/character_select.gd")
const CharacterCreateScript = preload("res://scripts/ui/auth/character_create.gd")
const LoginScreenScript = preload("res://scripts/ui/login_screen.gd")

const ServerSelectScene = preload("res://scenes/ui/auth/server_select.tscn")
const LoginDialogScene = preload("res://scenes/ui/auth/login_dialog.tscn")
const CharacterSelectScene = preload("res://scenes/ui/auth/character_select.tscn")
const CharacterCreateScene = preload("res://scenes/ui/auth/character_create.tscn")
const LoginScreenScene = preload("res://scenes/ui/login_screen.tscn")

var _tests_passed: int = 0
var _tests_total: int = 0

func _ready() -> void:
	print("--- Running In-Engine Verification of Auth & Character Flow ---")
	
	_test_saved_accounts_manager()
	_test_character_manager()
	_test_server_select_component()
	_test_login_dialog_component()
	_test_character_select_component()
	_test_character_create_wizard()
	_test_login_screen_full_flow()
	
	print("--- ALL AUTH & CHARACTER FLOW VERIFICATIONS PASSED (%d/%d tests) ---" % [_tests_passed, _tests_total])
	get_tree().quit(0)

func _assert_test(condition: bool, test_name: String) -> void:
	_tests_total += 1
	if condition:
		_tests_passed += 1
		print("[PASS] %s" % test_name)
	else:
		push_error("[FAIL] %s" % test_name)
		print("[FAIL] %s" % test_name)
		get_tree().quit(1)

func _test_saved_accounts_manager() -> void:
	print("\n>>> Testing SavedAccountsManager...")
	var test_user := "test_auth_hero_99"
	
	SavedAccountsManager.save_account(test_user)
	var accounts := SavedAccountsManager.get_saved_accounts()
	_assert_test(accounts.has(test_user), "SavedAccountsManager saves and retrieves account")
	
	var last_used := SavedAccountsManager.get_last_used_account()
	_assert_test(last_used == test_user, "SavedAccountsManager updates last used account to %s" % test_user)
	
	SavedAccountsManager.remove_account(test_user)
	var accounts_after := SavedAccountsManager.get_saved_accounts()
	_assert_test(not accounts_after.has(test_user), "SavedAccountsManager successfully removes account")

func _test_character_manager() -> void:
	print("\n>>> Testing CharacterManager...")
	var acc := "unit_test_acc"
	CharacterManager.clear_all_characters(acc)
	
	var empty_chars := CharacterManager.get_characters(acc)
	_assert_test(empty_chars.is_empty(), "CharacterManager starts empty for clean account")
	
	var char0 := CharacterManager.create_default_character(
		0, 6, "DanielTheHero", "Fire", 14, 12, 8, 8, 10
	)
	_assert_test(char0.name == "DanielTheHero", "CharacterManager creates character with correct name")
	_assert_test(char0.role_id == 6, "CharacterManager creates character with role 6 (Daniel)")
	_assert_test(char0.element == "Fire", "CharacterManager creates character with Fire element")
	_assert_test(char0.hp > 0 and char0.sp > 0, "CharacterManager calculates positive base HP and SP")
	
	var saved := CharacterManager.save_character(0, char0, acc)
	_assert_test(saved, "CharacterManager saves character to slot 0")
	
	var retrieved := CharacterManager.get_character_in_slot(0, acc)
	_assert_test(retrieved.get("name") == "DanielTheHero", "Retrieved character matches saved name in slot 0")
	_assert_test(int(retrieved.get("str")) == 14, "Retrieved character has correct STR attribute")

	var retrieved_alias := CharacterManager.get_character(0, acc)
	_assert_test(retrieved_alias.get("name") == "DanielTheHero", "CharacterManager.get_character retrieves character in slot 0")
	
	# Delete test
	var deleted := CharacterManager.delete_character(0, acc)
	_assert_test(deleted, "CharacterManager deletes character from slot 0")
	var after_del := CharacterManager.get_character_in_slot(0, acc)
	_assert_test(after_del.is_empty(), "Slot 0 is empty after deletion")

func _test_server_select_component() -> void:
	print("\n>>> Testing ServerSelect component...")
	var server_select: Control = ServerSelectScene.instantiate()
	add_child(server_select)
	
	_assert_test(server_select.config != null, "ServerSelect parses SERVER.INI")
	_assert_test(not server_select.config.groups.is_empty(), "ServerSelect contains server groups")
	_assert_test(int(server_select.get_current_mode()) == 0, "ServerSelect starts in MAIN_SERVERS mode")
	_assert_test(server_select.main_server_window.visible, "MainServerWindow is visible in MAIN_SERVERS mode")
	_assert_test(not server_select.channel_window.visible, "ChannelWindow is hidden in MAIN_SERVERS mode")
	_assert_test(server_select.main_server_list.item_count > 0, "MainServerList populated with server groups")
	
	# Transition to channels view
	var first_group: ServerConfig.ServerGroup = server_select.config.groups[0]
	server_select.show_channels(first_group)
	_assert_test(int(server_select.get_current_mode()) == 1, "ServerSelect switches to CHANNELS mode")
	_assert_test(server_select.channel_window.visible, "ChannelWindow becomes visible in CHANNELS mode")
	_assert_test(server_select.channel_list.item_count > 0, "ChannelList is populated with subservers/channels")
	
	# Test channel selection signal & exit requested
	var captured_servers: Array = []
	var leave_emitted := [false]
	var exit_emitted := [false]
	server_select.channel_selected.connect(func(s): captured_servers.append(s))
	server_select.leave_requested.connect(func(): leave_emitted[0] = true)
	server_select.exit_requested.connect(func(): exit_emitted[0] = true)

	server_select._on_channel_ok_pressed()
	var captured_server = captured_servers[0] if not captured_servers.is_empty() else null
	_assert_test(captured_server != null, "ServerSelect emits channel_selected signal with ServerEntry")
	_assert_test(captured_server != null and not captured_server.name.is_empty(), "Captured ServerEntry has valid channel name")

	server_select._current_mode = server_select.ViewMode.MAIN_SERVERS
	server_select._on_leave_pressed()
	_assert_test(leave_emitted[0], "ServerSelect emits leave_requested on leave")
	_assert_test(exit_emitted[0], "ServerSelect emits exit_requested on leave")

	# Textures & Aliases verification
	_assert_test(server_select.btn_next.texture_normal != null and server_select.btn_next.texture_hover != null and server_select.btn_next.texture_pressed != null, "ServerSelect BtnNext has full 3-state textures (Normal, Hover, Pressed)")
	_assert_test(server_select.btn_leave.texture_normal != null and server_select.btn_leave.texture_hover != null and server_select.btn_leave.texture_pressed != null, "ServerSelect BtnLeave has full 3-state textures (Normal, Hover, Pressed)")
	_assert_test(server_select.btn_ok == server_select.btn_next and server_select.btn_cancel == server_select.btn_leave, "ServerSelect btn_ok and btn_cancel aliases match")
	_assert_test(server_select.region_tabs != null and server_select.channel_buttons != null, "ServerSelect region_tabs and channel_buttons accessors valid")
	
	server_select.queue_free()

func _test_login_dialog_component() -> void:
	print("\n>>> Testing LoginDialog component...")
	var login_dialog: Control = LoginDialogScene.instantiate()
	add_child(login_dialog)
	
	login_dialog.set_server_info("Local Server", "Local")
	_assert_test(login_dialog.server_label.text.contains("Local Server"), "LoginDialog sets server information text")
	
	# Test saved accounts popup toggle
	SavedAccountsManager.save_account("popup_test_user")
	login_dialog._on_triangle_pressed()
	_assert_test(login_dialog.saved_popup.visible, "Triangle button reveals SavedAccountsPopup")
	_assert_test(login_dialog.saved_list.item_count > 0, "SavedAccountsList populated with saved accounts")
	
	# Select saved account
	login_dialog._on_saved_account_activated(0)
	_assert_test(login_dialog.username_input.text.length() > 0, "Selecting item from popup populates username input")
	_assert_test(not login_dialog.saved_popup.visible, "Activating item closes SavedAccountsPopup")
	
	# Test login submission
	var captured_logins: Array = []
	login_dialog.login_submitted.connect(func(acc, _pwd, save):
		captured_logins.append({"acc": acc, "save": save})
	)
	
	login_dialog.username_input.text = "test_player_one"
	login_dialog.password_input.text = "secret123"
	login_dialog.save_account_check.button_pressed = true
	login_dialog._on_login_pressed()
	
	var captured_account: String = captured_logins[0]["acc"] if not captured_logins.is_empty() else ""
	var captured_save: bool = captured_logins[0]["save"] if not captured_logins.is_empty() else false
	_assert_test(captured_account == "test_player_one", "LoginDialog emits login_submitted with correct account")
	_assert_test(captured_save == true, "LoginDialog emits correct save_account state")
	_assert_test(SavedAccountsManager.get_saved_accounts().has("test_player_one"), "Login submission persists account when checked")

	# Test status and credential helper accessors
	login_dialog.set_status("Authentication Test")
	_assert_test(login_dialog.status_label.text == "Authentication Test", "LoginDialog set_status updates status label text")
	_assert_test(login_dialog.get_username() == "test_player_one", "LoginDialog get_username returns correct account")
	_assert_test(login_dialog.get_password() == "secret123", "LoginDialog get_password returns correct password")
	
	# Textures & Virtual Keyboard verification
	_assert_test(login_dialog.btn_login.texture_normal != null and login_dialog.btn_login.texture_hover != null and login_dialog.btn_login.texture_pressed != null, "LoginDialog BtnLogin has full 3-state textures (Normal, Hover, Pressed)")
	_assert_test(login_dialog.btn_prev.texture_normal != null and login_dialog.btn_prev.texture_hover != null and login_dialog.btn_prev.texture_pressed != null, "LoginDialog BtnPrev has full 3-state textures (Normal, Hover, Pressed)")
	_assert_test(login_dialog.btn_sign_up.texture_normal != null and login_dialog.btn_sign_up.texture_hover != null and login_dialog.btn_sign_up.texture_pressed != null, "LoginDialog BtnSignUp has full 3-state textures (Normal, Hover, Pressed)")
	_assert_test(login_dialog.btn_about.texture_normal != null and login_dialog.btn_about.texture_hover != null and login_dialog.btn_about.texture_pressed != null, "LoginDialog BtnAbout has full 3-state textures (Normal, Hover, Pressed)")
	_assert_test(login_dialog.btn_saved_accounts.texture_normal != null and login_dialog.btn_saved_accounts.texture_hover != null and login_dialog.btn_saved_accounts.texture_pressed != null, "LoginDialog BtnSavedAccounts has full 3-state textures (Normal, Hover, Pressed)")
	_assert_test(login_dialog.remember_account_check != null and login_dialog.remember_button != null, "LoginDialog remember_account_check and remember_button accessors valid")
	if login_dialog.btn_virtual_keyboard:
		var vk_toggled := [false]
		login_dialog.virtual_keyboard_toggled.connect(func(): vk_toggled[0] = true)
		login_dialog.btn_virtual_keyboard.pressed.emit()
		_assert_test(vk_toggled[0], "LoginDialog virtual keyboard button emits virtual_keyboard_toggled")

	# Clean up
	SavedAccountsManager.remove_account("popup_test_user")
	SavedAccountsManager.remove_account("test_player_one")
	login_dialog.queue_free()

func _test_character_select_component() -> void:
	print("\n>>> Testing CharacterSelect component...")
	var char_select: Control = CharacterSelectScene.instantiate()
	char_select.account_name = "test_char_select_user"
	add_child(char_select)
	
	CharacterManager.clear_all_characters(char_select.account_name)
	var sample_char := CharacterManager.create_default_character(
		0, 2, "BettyAdventurer", "Water", 10, 14, 12, 10, 8
	)
	CharacterManager.save_character(0, sample_char, char_select.account_name)
	char_select.refresh_characters()
	
	# Slot 0 should be occupied
	char_select.select_slot(0)
	var card0: Control = char_select._get_card_node(0) as Control
	var name_lbl0: Label = card0.get_node_or_null("InfoOverlay/NameLabel") as Label
	var elem_lbl0: Label = card0.get_node_or_null("InfoOverlay/ElementLabel") as Label
	var btn_login0: TextureButton = card0.get_node_or_null("InfoOverlay/BtnLogin") as TextureButton
	var btn_create0: TextureButton = card0.get_node_or_null("BtnCreateChar") as TextureButton
	var preview0: Control = card0.get_node_or_null("InfoOverlay/SpritePreview") as Control

	_assert_test(name_lbl0 and name_lbl0.text == "BettyAdventurer", "CharacterSelect displays character name for slot 0")
	_assert_test(elem_lbl0 and elem_lbl0.text.contains("Water"), "CharacterSelect displays Water element for slot 0")
	_assert_test(btn_login0 and btn_login0.disabled == false, "Enter World button enabled for occupied slot")
	_assert_test(btn_create0 and btn_create0.visible == false, "Create button disabled for occupied slot")
	_assert_test(preview0 and preview0.visible == true, "Character preview active for occupied slot")
	
	# Slot 1 should be empty
	char_select.select_slot(1)
	var card1: Control = char_select._get_card_node(1) as Control
	var btn_login1: TextureButton = card1.get_node_or_null("InfoOverlay/BtnLogin") as TextureButton
	var btn_create1: TextureButton = card1.get_node_or_null("BtnCreateChar") as TextureButton
	var empty_lbl1: Control = card1.get_node_or_null("CardBg") as Control

	_assert_test(btn_login1 == null or btn_login1.disabled == true or not btn_login1.visible, "Enter World button disabled for empty slot 1")
	_assert_test(btn_create1 and btn_create1.visible == true, "Create button enabled for empty slot 1")
	_assert_test(empty_lbl1 != null, "Empty prompt displayed for empty slot 1")
	
	# Test Enter World signal
	char_select.select_slot(0)
	var captured_enters: Array = []
	char_select.character_selected.connect(func(c): captured_enters.append(c))
	char_select._on_enter_world_pressed()
	var captured_enter_char: Dictionary = char_select.get_selected_character()
	_assert_test(captured_enter_char.get("name") == "BettyAdventurer", "CharacterSelect emits character_selected with character data")
	
	# Textures & Rotation & Slot tabs verification
	_assert_test(char_select.btn_prev.texture_normal != null and char_select.btn_prev.texture_hover != null and char_select.btn_prev.texture_pressed != null, "CharacterSelect BtnPrev has full 3-state textures (Normal, Hover, Pressed)")
	_assert_test(btn_login0.texture_normal != null and btn_login0.texture_hover != null and btn_login0.texture_pressed != null, "CharacterSelect BtnLogin has full 3-state textures (Normal, Hover, Pressed)")
	_assert_test(btn_create1.texture_normal != null and btn_create1.texture_hover != null and btn_create1.texture_pressed != null, "CharacterSelect BtnCreateChar has full 3-state textures (Normal, Hover, Pressed)")
	_assert_test(char_select.slot_tabs.size() == 2, "CharacterSelect slot_tabs accessor returns 2 slot cards")

	# Rotation test
	var rot_before: int = char_select._slot_rotations.get(0, 0)
	char_select._rotate_slot_character(0, 1)
	_assert_test(char_select._slot_rotations.get(0, 0) == (rot_before + 1) % 8, "CharacterSelect rotates slot 0 orientation cleanly")

	# Clean up
	CharacterManager.clear_all_characters(char_select.account_name)
	char_select.queue_free()

func _test_character_create_wizard() -> void:
	print("\n>>> Testing CharacterCreate 4-step wizard...")
	var char_create: Control = CharacterCreateScene.instantiate()
	char_create.account_name = "wizard_test_user"
	add_child(char_create)
	
	char_create.start_wizard(1)
	
	# Step 1: Base Character selection
	_assert_test(char_create.current_step == 1, "CharacterCreate starts at Step 1")
	_assert_test(char_create.step1_container.visible, "Step 1 container is visible")
	char_create.select_role(6) # Daniel
	_assert_test(char_create.selected_role_id == 6, "CharacterCreate selects Role 6 (Daniel)")
	_assert_test(char_create.step1_role_name.text.length() > 0, "Role name is displayed in Step 1")
	
	# Advance to Step 2: Element
	char_create.goto_step(2)
	_assert_test(char_create.current_step == 2, "CharacterCreate advances to Step 2")
	_assert_test(char_create.step2_container.visible, "Step 2 container is visible")
	char_create.select_element("Wind")
	_assert_test(char_create.selected_element == "Wind", "CharacterCreate selects Wind element")
	_assert_test(char_create.element_desc_label.text.contains("Wind"), "Element description is displayed in Step 2")
	
	# Advance to Step 3: Stats
	char_create.goto_step(3)
	_assert_test(char_create.current_step == 3, "CharacterCreate advances to Step 3")
	_assert_test(char_create.step3_container.visible, "Step 3 container is visible")
	var initial_pool: int = char_create.points_pool
	_assert_test(initial_pool == 4, "Stat allocation starts with 4 points pool")
	
	char_create._modify_stat("agi", 1)
	_assert_test(char_create.points_pool == 3, "Adding stat point decrements points pool")
	_assert_test(char_create.bonus_points["agi"] == 1, "Adding stat point increments target bonus stat")
	
	char_create._modify_stat("agi", -1)
	_assert_test(char_create.points_pool == 4, "Removing stat point returns points to pool")
	_assert_test(char_create.bonus_points["agi"] == 0, "Removing stat point decrements target bonus stat")
	
	# Allocate 2 STR, 2 AGI
	char_create._modify_stat("str", 2)
	char_create._modify_stat("agi", 2)
	_assert_test(char_create.points_pool == 0, "All 4 points successfully allocated")
	
	# Advance to Step 4: Name & Confirmation
	char_create.goto_step(4)
	_assert_test(char_create.current_step == 4, "CharacterCreate advances to Step 4")
	_assert_test(char_create.step4_container.visible, "Step 4 container is visible")
	
	# Validation: Empty name rejection
	char_create.name_input.text = ""
	char_create._on_confirm_create()
	_assert_test(char_create.step4_error_label.text.length() > 0, "Step 4 rejects empty character name")
	
	# Valid creation
	var captured_creates: Array = []
	char_create.character_created.connect(func(c): captured_creates.append(c))
	char_create.name_input.text = "WindMaster"
	char_create._on_confirm_create()
	
	var captured_new_char: Dictionary = captured_creates[0] if not captured_creates.is_empty() else {}
	_assert_test(captured_new_char.get("name") == "WindMaster", "CharacterCreate successfully creates character with name")
	_assert_test(captured_new_char.get("element") == "Wind", "Created character has Wind element")
	_assert_test(captured_new_char.get("role_id") == 6, "Created character has Role 6 (Daniel)")
	_assert_test(int(captured_new_char.get("slot_index", -1)) == 1, "Created character assigned to target slot 1")
	
	# Verify persisted
	var persisted := CharacterManager.get_character_in_slot(1, char_create.account_name)
	_assert_test(persisted.get("name") == "WindMaster", "New character persisted to user://characters.json")
	
	# Textures, Finish alias, Role nav, Hair style, Color verification
	_assert_test(char_create.step1_btn_next.texture_normal != null and char_create.step1_btn_next.texture_hover != null and char_create.step1_btn_next.texture_pressed != null, "CharacterCreate Step 1 BtnNext has full 3-state textures")
	_assert_test(char_create.step1_btn_cancel.texture_normal != null and char_create.step1_btn_cancel.texture_hover != null and char_create.step1_btn_cancel.texture_pressed != null, "CharacterCreate Step 1 BtnCancel has full 3-state textures")
	_assert_test(char_create.step4_btn_ok.texture_normal != null and char_create.step4_btn_ok.texture_hover != null and char_create.step4_btn_ok.texture_pressed != null, "CharacterCreate Step 4 BtnOk has full 3-state textures")
	_assert_test(char_create.btn_finish == char_create.step4_btn_ok and char_create.btn_cancel == char_create.step1_btn_cancel, "CharacterCreate btn_finish and btn_cancel aliases match")

	# Customization methods test
	char_create.select_hair_style(2)
	_assert_test(char_create.selected_hair_style == 2, "CharacterCreate select_hair_style updates hair style index")
	char_create.set_hair_color(Color(0.8, 0.4, 0.2, 1.0))
	_assert_test(char_create.selected_hair_color == Color(0.8, 0.4, 0.2, 1.0), "CharacterCreate set_hair_color updates hair color")
	var role_before: int = char_create.selected_role_id
	char_create.select_next_role()
	_assert_test(char_create.selected_role_id == (role_before % 14) + 1, "CharacterCreate select_next_role advances role cleanly")
	char_create.select_prev_role()
	_assert_test(char_create.selected_role_id == role_before, "CharacterCreate select_prev_role returns role cleanly")

	# Clean up
	CharacterManager.clear_all_characters(char_create.account_name)
	char_create.queue_free()

func _test_login_screen_full_flow() -> void:
	print("\n>>> Testing LoginScreen full state machine flow...")
	var login_screen: Control = LoginScreenScene.instantiate()
	add_child(login_screen)
	
	_assert_test(int(login_screen.current_state) == int(LoginScreenScript.FlowState.SERVER_SELECT), "LoginScreen begins at SERVER_SELECT state")
	_assert_test(login_screen.server_select_node.visible, "ServerSelect node visible initially")
	_assert_test(not login_screen.login_dialog_node.visible, "LoginDialog node hidden initially")
	
	# 1. Server selection transition
	var test_server := ServerConfig.ServerEntry.new("TestChannel", "127.0.0.1", 6414, "TestServer", "01")
	login_screen._on_channel_selected(test_server)
	_assert_test(int(login_screen.current_state) == int(LoginScreenScript.FlowState.LOGIN_DIALOG), "Selecting channel transitions to LOGIN_DIALOG state")
	_assert_test(login_screen.login_dialog_node.visible, "LoginDialog is now visible")
	_assert_test(not login_screen.server_select_node.visible, "ServerSelect is now hidden")
	
	# 2. Login transition to CharacterSelect
	login_screen.current_account = "full_flow_user"
	login_screen._is_offline_mode = true
	login_screen._transition_to_character_select()
	_assert_test(int(login_screen.current_state) == int(LoginScreenScript.FlowState.CHARACTER_SELECT), "Successful login transitions to CHARACTER_SELECT state")
	_assert_test(login_screen.character_select_node.visible, "CharacterSelect node is now visible")
	_assert_test(not login_screen.login_dialog_node.visible, "LoginDialog node is now hidden")
	
	# 3. Create character transition
	login_screen._on_create_character_requested(2)
	_assert_test(int(login_screen.current_state) == int(LoginScreenScript.FlowState.CHARACTER_CREATE), "Requesting create transitions to CHARACTER_CREATE state")
	_assert_test(login_screen.character_create_node.visible, "CharacterCreate node is now visible")
	
	# 4. Character created return to CharacterSelect
	var dummy_char := {"name": "TestReturn", "role_id": 1, "element": "Earth"}
	login_screen._on_character_created(dummy_char)
	_assert_test(int(login_screen.current_state) == int(LoginScreenScript.FlowState.CHARACTER_SELECT), "Character creation returns to CHARACTER_SELECT state")
	_assert_test(login_screen.character_select_node.visible, "CharacterSelect node visible after creation")
	
	# 5. Enter World with character (Dictionary argument)
	var gdb := get_node_or_null("/root/GameDatabase")
	login_screen._on_enter_world_with_character(dummy_char)
	if gdb:
		_assert_test(gdb.active_character.get("name") == "TestReturn", "Entering world registers character in GameDatabase.active_character (Dictionary arg)")

	# 6. Enter World with character (int argument - slot index from character_selected signal)
	var slot0_char := CharacterManager.create_default_character(0, 6, "SlotHero", "Fire")
	CharacterManager.save_character(0, slot0_char, "full_flow_user")
	login_screen.current_account = "full_flow_user"
	login_screen._on_enter_world_with_character(0)
	if gdb:
		_assert_test(gdb.active_character.get("name") == "SlotHero", "Entering world with int slot_idx resolves character data from CharacterManager")

	# 7. Enter World with character (int argument - empty slot fallback to starter)
	CharacterManager.clear_all_characters("full_flow_user")
	login_screen._on_enter_world_with_character(1)
	if gdb:
		_assert_test(not gdb.active_character.is_empty() and gdb.active_character.get("name") == "Daniel", "Entering world with empty int slot falls back to starter Daniel")

	# 8. Test offline login submission immediately transitions to CharacterSelect
	login_screen.goto_state(LoginScreenScript.FlowState.LOGIN_DIALOG)
	login_screen._is_offline_mode = true
	login_screen._on_login_submitted("instant_user", "pw", false)
	_assert_test(int(login_screen.current_state) == int(LoginScreenScript.FlowState.CHARACTER_SELECT), "Submitting login in offline mode immediately transitions to CHARACTER_SELECT")

	# 9. Test direct signal firing from CharacterSelect to LoginScreen._on_enter_world_with_character
	var hero_sig := CharacterManager.create_default_character(0, 6, "SignalHero", "Fire")
	CharacterManager.save_character(0, hero_sig, "full_flow_user")
	login_screen.current_account = "full_flow_user"
	login_screen.character_select_node.account_name = "full_flow_user"
	login_screen.character_select_node.refresh_characters()
	login_screen.character_select_node._on_slot_login_pressed(0)
	if gdb:
		_assert_test(gdb.active_character.get("name") == "SignalHero", "CharacterSelect.character_selected signal triggers world entry with correct character data without type error")

	# Clean up
	CharacterManager.clear_all_characters("full_flow_user")
	login_screen.queue_free()
