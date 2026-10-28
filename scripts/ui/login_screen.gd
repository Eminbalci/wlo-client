class_name LoginScreen
extends Control

## Master Authentication and Character Flow Controller for Wonderland Online.
## Orchestrates the authentic 9-screen flow:
## 1. Server selection screen 1: main servers list
## 2. Server selection screen 2: subservers / channels list with ping lights
## 3. Login form: Account & Password
## 4. Dropdown list of saved accounts
## 5. Character selection screen with 4 character slots and details panel
## 6. Character create step 1: Base character / appearance (14 roles)
## 7. Character create step 2: Element selection (Earth, Water, Fire, Wind)
## 8. Character create step 3: Stat allocation (STR, CON, INT, WIS, AGI)
## 9. Character create step 4: Name input & confirmation
## -> Enter World transition into map_view.tscn

const NetworkClient = preload("res://scripts/network/network_client.gd")
const ServerConfig = preload("res://scripts/network/server_config.gd")
const CharacterManager = preload("res://scripts/ui/auth/character_manager.gd")
const SavedAccountsManager = preload("res://scripts/ui/auth/saved_accounts_manager.gd")
const Packet = preload("res://scripts/network/packet.gd")

const ServerSelectScript = preload("res://scripts/ui/auth/server_select.gd")
const LoginDialogScript = preload("res://scripts/ui/auth/login_dialog.gd")
const CharacterSelectScript = preload("res://scripts/ui/auth/character_select.gd")
const CharacterCreateScript = preload("res://scripts/ui/auth/character_create.gd")

const MAP_VIEW_SCENE_PATH: String = "res://scenes/world/map_view.tscn"
const BG_PATH: String = "pic/LogPic1.jpg"
const LOGO_PATH: String = "menu/Skins/default/Icon_LoginLogo_1.bmp"

enum FlowState {
	SERVER_SELECT,
	LOGIN_DIALOG,
	CHARACTER_SELECT,
	CHARACTER_CREATE
}

@onready var background_rect = $BackgroundRect
@onready var logo_rect = $LogoRect
@onready var server_select_node = $ServerSelect
@onready var login_dialog_node = $LoginDialog
@onready var character_select_node = $CharacterSelect
@onready var character_create_node = $CharacterCreate
@onready var offline_button = $OfflineButton
@onready var world_editor_button = get_node_or_null("WorldEditorButton")

var current_state: FlowState = FlowState.SERVER_SELECT
var current_server: ServerConfig.ServerEntry
var current_account: String = "default"
var _network: NetworkClient
var _is_offline_mode: bool = false

func _ready() -> void:
	_load_art()
	_setup_network()
	_connect_submodules()
	goto_state(FlowState.SERVER_SELECT)

func _load_art() -> void:
	var loader := get_node_or_null("/root/ArchiveLoader")
	if not loader:
		return

	var bg_tex: ImageTexture = loader.get_ui_texture(BG_PATH)
	if bg_tex and background_rect:
		background_rect.texture = bg_tex

	var logo_tex: ImageTexture = loader.get_ui_texture(LOGO_PATH)
	if logo_tex and logo_rect:
		logo_rect.texture = logo_tex

func _setup_network() -> void:
	_network = NetworkClient.new()
	add_child(_network)
	_network.connected_to_server.connect(_on_network_connected)
	_network.connection_failed.connect(_on_network_failed)
	_network.packet_received.connect(_on_packet_received)

func _connect_submodules() -> void:
	# 1. ServerSelect signals
	if server_select_node:
		server_select_node.channel_selected.connect(_on_channel_selected)
		server_select_node.exit_requested.connect(_on_exit_requested)

	# 2. LoginDialog signals
	if login_dialog_node:
		login_dialog_node.login_submitted.connect(_on_login_submitted)
		login_dialog_node.prev_pressed.connect(_on_login_back_to_servers)

	# 3. CharacterSelect signals
	if character_select_node:
		character_select_node.character_selected.connect(_on_enter_world_with_character)
		character_select_node.create_requested.connect(_on_create_character_requested)
		character_select_node.back_requested.connect(_on_char_select_back_to_login)

	# 4. CharacterCreate signals
	if character_create_node:
		character_create_node.character_created.connect(_on_character_created)
		character_create_node.cancelled.connect(_on_character_create_cancelled)

	# 5. Offline button & World Editor button
	if offline_button:
		offline_button.pressed.connect(_on_offline_pressed)
	if world_editor_button:
		world_editor_button.pressed.connect(_on_world_editor_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			_on_offline_pressed()
		elif event.keycode == KEY_F12:
			_on_world_editor_pressed()

func _on_world_editor_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/tools/world_editor.tscn")

func goto_state(new_state: FlowState) -> void:
	current_state = new_state

	# Toggle visibility of components
	server_select_node.visible = (current_state == FlowState.SERVER_SELECT)
	login_dialog_node.visible = (current_state == FlowState.LOGIN_DIALOG)
	character_select_node.visible = (current_state == FlowState.CHARACTER_SELECT)
	character_create_node.visible = (current_state == FlowState.CHARACTER_CREATE)

	# Logo is visible during server selection and login
	if logo_rect:
		logo_rect.visible = (current_state == FlowState.SERVER_SELECT or current_state == FlowState.LOGIN_DIALOG)

	match current_state:
		FlowState.SERVER_SELECT:
			server_select_node.show_main_servers()
		FlowState.LOGIN_DIALOG:
			if current_server and login_dialog_node:
				login_dialog_node.set_server_info(current_server.group_title, current_server.name)
		FlowState.CHARACTER_SELECT:
			if character_select_node:
				character_select_node.account_name = current_account
				character_select_node.refresh_characters()
		FlowState.CHARACTER_CREATE:
			pass

# ==================== HANDLERS ====================

func _on_channel_selected(server_entry: ServerConfig.ServerEntry) -> void:
	current_server = server_entry
	goto_state(FlowState.LOGIN_DIALOG)

func _on_exit_requested() -> void:
	get_tree().quit()

func _on_login_back_to_servers() -> void:
	goto_state(FlowState.SERVER_SELECT)

func _on_login_submitted(account: String, _password_text: String, save_account: bool) -> void:
	current_account = account.strip_edges()
	if current_account.is_empty():
		current_account = "player1"
	if save_account:
		SavedAccountsManager.save_account(current_account)

	if _is_offline_mode:
		_transition_to_character_select()
		return

	if not current_server:
		current_server = ServerConfig.ServerEntry.new("Local", "127.0.0.1", 6414)

	# Connect or fallback
	if login_dialog_node and login_dialog_node.has_method("set_status"):
		login_dialog_node.set_status("Connecting to %s..." % current_server.get_endpoint_string())

	var err: Error = _network.connect_to_server(current_server.host, current_server.port)
	if err != OK:
		print("[LoginScreen] Connection failed (error %d). Transitioning to local character select." % err)
		_is_offline_mode = true
		_transition_to_character_select()
		return

	# Smooth fallback within 0.5s if server is offline or fails to connect
	var timer := get_tree().create_timer(0.5)
	timer.timeout.connect(func():
		if current_state == FlowState.LOGIN_DIALOG and not _network.is_connected_to_server():
			print("[LoginScreen] Server offline or timed out after 0.5s. Transitioning to local Character Select.")
			_is_offline_mode = true
			_transition_to_character_select()
	)

func _on_network_connected() -> void:
	if login_dialog_node and login_dialog_node.has_method("set_status"):
		login_dialog_node.set_status("Connected. Authenticating...")

	var pwd_text: String = ""
	if login_dialog_node and login_dialog_node.has_method("get_password"):
		pwd_text = login_dialog_node.get_password()

	# Authentic login packet: Action 0x3F, Sub 0x04, ClientVersion (1214), len(user), user, len(pass), pass, extra bytes
	var login_payload := PackedByteArray()
	login_payload.append(0x3F)
	login_payload.append(0x04)
	var ver_bytes := PackedByteArray()
	ver_bytes.resize(2)
	ver_bytes.encode_u16(0, NetworkManager.CLIENT_VERSION)
	login_payload.append_array(ver_bytes)

	var acc_bytes := current_account.to_ascii_buffer()
	login_payload.append(acc_bytes.size() & 0xFF)
	login_payload.append_array(acc_bytes)

	var pwd_bytes := pwd_text.to_ascii_buffer()
	login_payload.append(pwd_bytes.size() & 0xFF)
	login_payload.append_array(pwd_bytes)

	login_payload.append_array(NetworkManager.get_login_extra_bytes())
	_network.send_packet(login_payload)

func _on_network_failed() -> void:
	if login_dialog_node and login_dialog_node.has_method("set_status"):
		login_dialog_node.set_status("Unable to reach server. Entering local mode...")
	# Graceful fallback to local character select
	_is_offline_mode = true
	_transition_to_character_select()

func _on_packet_received(action_code: int, payload: PackedByteArray) -> void:
	# Keepalive Ping / Pong (0xBA, 0x10, 0x00)
	if action_code == 0xBA:
		_network.send_packet(NetworkManager.get_ping_packet())
		return

	# Error notices under Action 0x01
	if action_code == 0x01:
		var sub := payload[1] if payload.size() > 1 else -1
		if sub == 0x0C or sub == 0x06:
			if login_dialog_node and login_dialog_node.has_method("set_status"):
				login_dialog_node.set_status("Login/Pwd error")
			return

	# ActionCode 2 or 63 (0x3F) is Auth response
	if action_code == 2 or action_code == 63:
		var result: int = payload[0] if payload.size() > 0 else 1
		if result == 1 or payload.size() == 0:
			_transition_to_character_select()
		else:
			if login_dialog_node and login_dialog_node.has_method("set_status"):
				login_dialog_node.set_status("Login failed: Invalid credentials.")

func _on_offline_pressed() -> void:
	_is_offline_mode = true
	var acc: String = ""
	if login_dialog_node:
		if login_dialog_node.has_method("get_username"):
			acc = login_dialog_node.get_username()
		elif login_dialog_node.has_method("get_account_name"):
			acc = login_dialog_node.get_account_name()
	current_account = acc if not acc.is_empty() else "player1"
	if login_dialog_node and login_dialog_node.has_method("is_save_account_checked") and login_dialog_node.is_save_account_checked():
		SavedAccountsManager.save_account(current_account)
	_transition_to_character_select()

func _transition_to_character_select() -> void:
	if current_state == FlowState.CHARACTER_SELECT:
		return
	# Seed at least one sample character if account has none, for immediate previewing
	var existing := CharacterManager.get_characters(current_account)
	if existing.is_empty():
		var starter_char := CharacterManager.create_default_character(
			0, 6, current_account, "Fire", 12, 10, 8, 8, 10
		)
		CharacterManager.save_character(0, starter_char, current_account)

	goto_state(FlowState.CHARACTER_SELECT)

func _on_char_select_back_to_login() -> void:
	goto_state(FlowState.LOGIN_DIALOG)

func _on_create_character_requested(slot_index: int) -> void:
	if character_create_node:
		character_create_node.account_name = current_account
		character_create_node.start_wizard(slot_index)
	goto_state(FlowState.CHARACTER_CREATE)

func _on_character_created(char_data: Dictionary) -> void:
	var target_slot: int = int(char_data.get("slot_index", 0))
	if character_select_node:
		character_select_node.account_name = current_account
		character_select_node.selected_slot_index = target_slot
		if not char_data.is_empty():
			character_select_node.set_slot_character(target_slot, char_data)
	var gdb := get_node_or_null("/root/GameDatabase")
	if gdb and not char_data.is_empty():
		gdb.active_character = char_data
	goto_state(FlowState.CHARACTER_SELECT)
	if character_select_node:
		character_select_node.select_slot(target_slot)

func _on_character_create_cancelled() -> void:
	goto_state(FlowState.CHARACTER_SELECT)

func _on_enter_world_with_character(arg: Variant) -> void:
	var char_data: Dictionary = {}
	if arg is int:
		var slot_idx: int = arg
		char_data = CharacterManager.get_character(slot_idx, current_account)
		if char_data.is_empty():
			char_data = CharacterManager.get_character_in_slot(slot_idx, current_account)
		if char_data.is_empty():
			char_data = CharacterManager.get_character_in_slot(0, current_account)
		if char_data.is_empty():
			# Fallback starter character dictionary
			char_data = {
				"slot_index": slot_idx,
				"name": "Daniel",
				"role_id": 6,
				"role_name": "Daniel",
				"element": "Fire",
				"level": 10,
				"exp": 0,
				"hp": 245,
				"max_hp": 245,
				"sp": 180,
				"max_sp": 180,
				"str": 15,
				"con": 12,
				"int": 8,
				"wis": 8,
				"agi": 11,
				"reborn": false
			}
			CharacterManager.save_character(slot_idx, char_data, current_account)
	elif arg is Dictionary:
		char_data = arg
	else:
		push_warning("[LoginScreen] Unrecognized argument type in _on_enter_world_with_character: %s" % typeof(arg))
		char_data = CharacterManager.get_character_in_slot(0, current_account)
		if char_data.is_empty():
			char_data = {
				"slot_index": 0,
				"name": "Daniel",
				"role_id": 6,
				"role_name": "Daniel",
				"element": "Fire",
				"level": 10,
				"exp": 0,
				"hp": 245,
				"max_hp": 245,
				"sp": 180,
				"max_sp": 180,
				"str": 15,
				"con": 12,
				"int": 8,
				"wis": 8,
				"agi": 11,
				"reborn": false
			}

	var gdb := get_node_or_null("/root/GameDatabase")
	if gdb:
		gdb.active_character = char_data

	# Save character state if needed
	var target_slot: int = int(char_data.get("slot_index", 0))
	CharacterManager.save_character(target_slot, char_data, current_account)

	# Transition to main world map view
	var target_scene := MAP_VIEW_SCENE_PATH
	if not ResourceLoader.exists(target_scene) and ResourceLoader.exists("res://scenes/maps/map_10001_ship_deck.tscn"):
		target_scene = "res://scenes/maps/map_10001_ship_deck.tscn"

	print("[LoginScreen] Entering world with character: %s (slot %d) -> %s" % [char_data.get("name", "Unknown"), target_slot, target_scene])
	LoadingScreen.go_to(get_tree(), target_scene)
