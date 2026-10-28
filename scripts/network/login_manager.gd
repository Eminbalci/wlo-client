class_name LoginManager
extends Node

const ServerNotice = preload("res://scripts/network/server_notice.gd")
## Notice sub codes that end a login attempt (wrong password, banned, locked, version, busy ...).
const LOGIN_ENDING_NOTICES: Array[int] = [3, 17, 19, 32, 36, 45, 53, 62, 64, 65, 75, 79, 80]

## Authentication and session coordinator for Wonderland Online.
## Implements the complete login lifecycle state machine:
## Handshake (AC 1) -> Authentication (AC 63) -> Character Selection -> World Entry (AC 20/5).

enum State {
	DISCONNECTED,
	CONNECTING,
	HANDSHAKING,
	AUTHENTICATING,
	CHARACTER_SELECT,
	CREATING_CHARACTER,
	ENTERING_WORLD,
	IN_WORLD
}

signal state_changed(old_state: State, new_state: State)
signal handshake_succeeded(server_tick: int)
signal login_succeeded(user_id: int)
signal login_failed(reason: String, error_code: int)
signal character_list_received(characters: Array[Dictionary])
signal character_selected(slot: int, character_data: Dictionary)
signal character_creation_requested(slot: int)
signal world_entered(world_info: Dictionary)
signal ping_updated(latency_ms: int)
signal network_error(error_message: String)

const DEFAULT_CLIENT_VERSION: int = 1205
const PING_INTERVAL_SECONDS: float = 20.0

@export var network_client: NetworkClient

var current_state: State = State.DISCONNECTED:
	set(value):
		if current_state != value:
			var prev := current_state
			current_state = value
			print("[LoginManager] State: %s -> %s" % [_state_name(prev), _state_name(value)])
			state_changed.emit(prev, value)

var cached_user_id: int = 0
var cached_characters: Array[Dictionary] = []
var pending_username: String = ""
var pending_password: String = ""
var client_version: int = DEFAULT_CLIENT_VERSION

var _ping_timer: float = 0.0
var _ping_start_ms: int = 0
var _selected_slot: int = 1

func _ready() -> void:
	if not network_client:
		network_client = NetworkClient.new()
		add_child(network_client)

	network_client.connected.connect(_on_network_connected)
	network_client.disconnected.connect(_on_network_disconnected)
	network_client.packet_received.connect(_on_packet_received)
	network_client.connection_error.connect(_on_network_error)

func _process(delta: float) -> void:
	if current_state == State.IN_WORLD or current_state == State.CHARACTER_SELECT:
		_ping_timer += delta
		if _ping_timer >= PING_INTERVAL_SECONDS:
			_ping_timer = 0.0
			send_ping()

# ==============================================================================
# Public API
# ==============================================================================

## Begins the authentication sequence against the specified server endpoint.
func connect_and_login(host: String, port: int, username: String, password: String, version: int = DEFAULT_CLIENT_VERSION) -> void:
	pending_username = username.strip_edges()
	pending_password = password.strip_edges()
	client_version = version
	cached_characters.clear()
	cached_user_id = 0

	if pending_username.length() < 3 or pending_username.length() > 16:
		login_failed.emit("Username must be between 3 and 16 characters.", 1)
		return

	if pending_password.length() < 4 or pending_password.length() > 16:
		login_failed.emit("Password must be between 4 and 16 characters.", 1)
		return

	current_state = State.CONNECTING
	var err := network_client.connect_to_server(host, port)
	if err != OK:
		current_state = State.DISCONNECTED
		network_error.emit("Failed to initiate connection to %s:%d" % [host, port])

## Selects a character slot (1 or 2) to enter the game world.
func select_character(slot: int) -> void:
	if current_state != State.CHARACTER_SELECT:
		push_warning("[LoginManager] Cannot select character: Not in CHARACTER_SELECT state.")
		return

	_selected_slot = slot
	current_state = State.ENTERING_WORLD

	# Send AC 63 Sub 2 with selected character slot
	var pkt := Packet.create(63, 2)
	pkt.pack_u8(slot)
	network_client.send_packet(pkt)
	print("[LoginManager] Selected character slot %d, awaiting world server transfer..." % slot)

## Sends a ping / keepalive packet (AC 0).
func send_ping() -> void:
	if not network_client.is_connected_to_server():
		return
	_ping_start_ms = Time.get_ticks_msec()
	var pkt := Packet.create(0)
	network_client.send_packet(pkt)

## Cancels current login attempt and disconnects from server.
func cancel_login() -> void:
	network_client.disconnect_from_server()
	current_state = State.DISCONNECTED

# ==============================================================================
# Internal Network Handlers
# ==============================================================================

func _on_network_connected() -> void:
	print("[LoginManager] Connected to server. Initiating Handshake (AC 1:1)...")
	current_state = State.HANDSHAKING
	_send_handshake()

func _on_network_disconnected() -> void:
	print("[LoginManager] Disconnected from server.")
	current_state = State.DISCONNECTED

func _on_network_error(error_message: String) -> void:
	print("[LoginManager] Network error: %s" % error_message)
	current_state = State.DISCONNECTED
	network_error.emit(error_message)

func _send_handshake() -> void:
	# AC 1 Sub 1: Handshake request with client version
	var pkt := Packet.create(1, 1)
	pkt.pack_u16(client_version)
	network_client.send_packet(pkt)

func _send_login_request() -> void:
	print("[LoginManager] Sending Login Request (AC 63:4) for user '%s'..." % pending_username)
	current_state = State.AUTHENTICATING
	# AC 63 Sub 4: Login Request
	var pkt := Packet.create(63, 4)
	pkt.pack_u16(client_version)
	pkt.pack_string(pending_username)
	pkt.pack_string(pending_password)
	network_client.send_packet(pkt)

func _on_packet_received(action_code: int, payload: PackedByteArray) -> void:
	var packet := Packet.new(payload)
	var sub_code := packet.get_sub_code()

	match action_code:
		0:
			_handle_ac0(packet, sub_code)
		1:
			_handle_ac1(packet, sub_code)
		63:
			_handle_ac63(packet, sub_code)
		20, 5, 3, 4:
			_handle_world_packets(packet, action_code, sub_code)
		_:
			# Other game packets pass through
			pass

func _handle_ac0(packet: Packet, sub_code: int) -> void:
	# Latency calculation
	if _ping_start_ms > 0:
		var elapsed := Time.get_ticks_msec() - _ping_start_ms
		_ping_start_ms = 0
		ping_updated.emit(elapsed)

	# Server notices under AC 0: texts from the real client's table (server_notice.gd)
	if sub_code == ServerNotice.DELETE_SUCCESS:
		print("[LoginManager] Character deleted.")
	elif LOGIN_ENDING_NOTICES.has(sub_code):
		_fail_login(ServerNotice.text_for(sub_code), sub_code)

func _handle_ac1(packet: Packet, sub_code: int) -> void:
	match sub_code:
		1:
			# Handshake response: [AC 1, Sub 1, Status, ServerTick (4B)]
			packet.set_read_offset(2) # Skip AC and SubCode
			var status := packet.unpack_u8()
			var tick := packet.unpack_u32()
			print("[LoginManager] Handshake ACK: status=%d, server_tick=%d" % [status, tick])
			handshake_succeeded.emit(tick)
			_send_login_request()
		3:
			# Character creation requested by server for empty slot
			print("[LoginManager] Character creation prompt received from server.")
			current_state = State.CREATING_CHARACTER
			character_creation_requested.emit(_selected_slot)
		6:
			_fail_login("Login/Pwd error", 1)
		7:
			_fail_login("Session timed out or account is banned.", 5)

func _handle_ac63(packet: Packet, sub_code: int) -> void:
	packet.set_read_offset(2) # Skip AC and SubCode
	match sub_code:
		2:
			# AC 63 Sub 2: UserID assignment on login, or login state response
			if current_state == State.AUTHENTICATING:
				if packet.get_remaining_bytes() >= 4:
					cached_user_id = packet.unpack_u32()
					print("[LoginManager] Authentication successful! User ID: %d" % cached_user_id)
					login_succeeded.emit(cached_user_id)
				else:
					# Status code
					var err_code := packet.unpack_u8()
					if err_code != 0:
						_fail_login("Authentication failed with error code %d" % err_code, err_code)
		1:
			# AC 63 Sub 1: Character List payload
			print("[LoginManager] Receiving character list...")
			cached_characters.clear()

			while packet.get_remaining_bytes() >= 10:
				var char_info := _parse_character_record(packet)
				if not char_info.is_empty():
					cached_characters.append(char_info)

			print("[LoginManager] Parsed %d character(s)." % cached_characters.size())
			current_state = State.CHARACTER_SELECT
			character_list_received.emit(cached_characters)

func _parse_character_record(packet: Packet) -> Dictionary:
	var slot := packet.unpack_u8()
	var char_name := packet.unpack_string()
	var level := packet.unpack_u8()
	var element := packet.unpack_u8()
	var cur_hp := packet.unpack_u32()
	var full_hp := packet.unpack_u32()
	var cur_sp := packet.unpack_u32()
	var full_sp := packet.unpack_u32()
	var total_exp := packet.unpack_u32()
	var gold := packet.unpack_u32()
	var body := packet.unpack_u16()
	var head := packet.unpack_u16()
	var color_code1 := packet.unpack_u32()
	var color_code2 := packet.unpack_u32()

	var equipment: Array[int] = []
	for i in range(7):
		if packet.get_remaining_bytes() >= 2:
			equipment.append(packet.unpack_u16())
		else:
			equipment.append(0)

	var record := {
		"slot": slot,
		"name": char_name,
		"level": level,
		"element": element,
		"element_name": _get_element_name(element),
		"cur_hp": cur_hp,
		"full_hp": full_hp,
		"cur_sp": cur_sp,
		"full_sp": full_sp,
		"total_exp": total_exp,
		"gold": gold,
		"body": body,
		"head": head,
		"color1": color_code1,
		"color2": color_code2,
		"equipment": equipment
	}
	return record

func _handle_world_packets(packet: Packet, action_code: int, sub_code: int) -> void:
	if current_state == State.ENTERING_WORLD or current_state == State.CHARACTER_SELECT:
		current_state = State.IN_WORLD
		var info := {
			"action_code": action_code,
			"sub_code": sub_code,
			"packet_size": packet.size()
		}
		print("[LoginManager] Entered game world! First packet: AC %d:%d" % [action_code, sub_code])
		world_entered.emit(info)

func _fail_login(reason: String, error_code: int) -> void:
	print("[LoginManager] Login failed: %s (code %d)" % [reason, error_code])
	current_state = State.DISCONNECTED
	network_client.disconnect_from_server()
	login_failed.emit(reason, error_code)

func _get_element_name(element_id: int) -> String:
	match element_id:
		1: return "Water"
		2: return "Fire"
		3: return "Wind"
		4: return "Earth"
		_: return "None"

func _state_name(st: State) -> String:
	match st:
		State.DISCONNECTED: return "DISCONNECTED"
		State.CONNECTING: return "CONNECTING"
		State.HANDSHAKING: return "HANDSHAKING"
		State.AUTHENTICATING: return "AUTHENTICATING"
		State.CHARACTER_SELECT: return "CHARACTER_SELECT"
		State.CREATING_CHARACTER: return "CREATING_CHARACTER"
		State.ENTERING_WORLD: return "ENTERING_WORLD"
		State.IN_WORLD: return "IN_WORLD"
		_: return "UNKNOWN"
