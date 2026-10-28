class_name NetworkManager
extends Node

const ServerNotice = preload("res://scripts/network/server_notice.gd")

## Authentic Wonderland Online Live Network Client & Protocol Coordinator.
## Targets live production game servers (e.g. Rhodes1 20.187.103.41:6414).
##
## Protocol Specifications:
## 1. Framing:
##    - Magic Header: 0x44F4 (2 bytes little-endian: 0xF4, 0x44)
##    - Payload Length: uint16 little-endian (2 bytes)
##    - Payload: [Length] bytes
## 2. Cryptography:
##    - Entire wire stream (Header, Length, Payload) is XOR-encrypted symmetrically with static key 0xAD.
##    - Wire byte = plaintext byte ^ 0xAD.
##    - Plaintext byte = wire byte ^ 0xAD.
##    - Every valid packet on wire begins with bytes 0x59, 0xE9 (0xF4 ^ 0xAD = 0x59, 0x44 ^ 0xAD = 0xE9).
## 3. Keepalive / Ping:
##    - Packet: Action 0xBA, Sub 0x10, 0x00. Auto-pong response keeps session alive.
## 4. Authentication:
##    - Action 0x3F, Sub 0x04, ClientVersion (0xBE, 0x04 = 1214), len(user), user, len(pass), pass, extra bytes.

# ==============================================================================
# Signals
# ==============================================================================
signal connected_to_server(host: String, port: int)
signal connection_failed(reason: String)
signal disconnected
signal network_error(error_message: String)
signal state_changed(old_state: State, new_state: State)

signal frame_received(payload: PackedByteArray)
signal packet_received(action_code: int, sub_code: int, payload: PackedByteArray)

signal login_succeeded(user_id: int)
signal login_failed(reason: String, error_code: int)

signal character_list_received(characters: Array[Dictionary])
signal character_selected(slot: int, character_data: Dictionary)
signal character_creation_requested(slot: int)
signal character_creation_ack(status: int)

signal world_entered(world_info: Dictionary)

signal ping_received(payload: PackedByteArray)
signal ping_updated(latency_ms: int)

signal player_walk_received(target_x: int, target_y: int, walk_info: Dictionary)
signal entity_pos_received(entity_id: int, pos_info: Dictionary)
signal chat_broadcast_received(channel_id: int, sender_id: int, message: String, chat_info: Dictionary)
signal warp_received(map_id: int, target_x: int, target_y: int, warp_info: Dictionary)
signal npc_dialogue_received(dialogue_id: int, npc_id: int, dialogue_info: Dictionary)
signal item_pickup_received(item_id: int, count: int, pickup_info: Dictionary)
signal trade_event_received(sub_code: int, trade_info: Dictionary)
signal battle_packet_received(action_code: int, sub_code: int, battle_info: Dictionary)

# ==============================================================================
# Constants & Enums
# ==============================================================================
enum State {
	DISCONNECTED,
	CONNECTING,
	CONNECTED,
	AUTHENTICATING,
	LOGGED_IN,
	CHARACTER_SELECT,
	CREATING_CHARACTER,
	ENTERING_WORLD,
	IN_WORLD
}

const DEFAULT_HOST: String = "20.187.103.41" # Rhodes1
const DEFAULT_PORT: int = 6414

const MAGIC_BYTE_0: int = 0xF4
const MAGIC_BYTE_1: int = 0x44
const MAGIC_HEADER: int = 0x44F4 # uint16 little-endian: 0xF4, 0x44

const WIRE_BYTE_0: int = 0x59 # 0xF4 ^ 0xAD
const WIRE_BYTE_1: int = 0xE9 # 0x44 ^ 0xAD
const WIRE_MAGIC_HEADER: int = 0xE959 # uint16 little-endian: 0x59, 0xE9

const STATIC_XOR_KEY: int = 0xAD
const HEADER_SIZE: int = 4
const MAX_PAYLOAD_SIZE: int = 16384
const CLIENT_VERSION: int = 1214 # 0x04BE (little-endian: 0xBE, 0x04)

# Live In-Game Opcodes (Bridge Daemon Parity)
const OPCODE_PLAYER_WALK: int = 0x0106       # Bytes: [0x06, 0x01, step_mode, x_lo, x_hi, y_lo, y_hi]
const OPCODE_ENTITY_POS: int = 0x0101        # Bytes: [0x01, 0x01, uint32 entity_id / pos]
const OPCODE_PING: int = 0x3E2D              # Bytes: [0x3E, 0x2D, uint32 ping_id / timestamp]
const OPCODE_CHAT_BROADCAST: int = 0x230C    # Bytes: [0x23, 0x0C, channel_id, uint32 sender_id, msg...]

static func get_login_extra_bytes() -> PackedByteArray:
	return PackedByteArray([0x07, 0x53, 0x60, 0x60, 0x63, 0x67, 0x63, 0x61, 0x65])

static func get_ping_packet() -> PackedByteArray:
	return PackedByteArray([0xBA, 0x10, 0x00])

# ==============================================================================
# State Variables
# ==============================================================================
var peer: StreamPeerTCP = StreamPeerTCP.new()

var current_state: State = State.DISCONNECTED:
	set(value):
		if current_state != value:
			var prev := current_state
			current_state = value
			print("[NetworkManager] State: %s -> %s" % [_state_to_string(prev), _state_to_string(value)])
			state_changed.emit(prev, value)

var current_host: String = ""
var current_port: int = 0
var is_connected: bool = false
var connect_timeout: float = 5.0
var auto_respond_to_ping: bool = true
var keepalive_interval: float = 20.0

var cached_user_id: int = 0
var cached_characters: Array[Dictionary] = []
var pending_username: String = ""
var pending_password: String = ""
var selected_slot: int = 1

var _connecting: bool = false
var _connection_timer: float = 0.0
var _keepalive_timer: float = 0.0
var _ping_start_ms: int = 0

# Decrypted plaintext accumulator buffer
var _rx_plain_buffer: PackedByteArray = PackedByteArray()

# ==============================================================================
# Lifecycle & Polling
# ==============================================================================
func _ready() -> void:
	pass

func _process(delta: float) -> void:
	peer.poll()
	var status := peer.get_status()

	if _connecting:
		_connection_timer += delta
		if status == StreamPeerTCP.STATUS_CONNECTED:
			_connecting = false
			is_connected = true
			_rx_plain_buffer.clear()
			current_state = State.CONNECTED
			print("[NetworkManager] Connected to %s:%d" % [current_host, current_port])
			connected_to_server.emit(current_host, current_port)
			if not pending_username.is_empty():
				_send_login_packet()
		elif status == StreamPeerTCP.STATUS_ERROR or _connection_timer >= connect_timeout:
			_connecting = false
			is_connected = false
			peer.disconnect_from_host()
			current_state = State.DISCONNECTED
			var err_msg := "Failed to connect to %s:%d (Status: %d, Timeout: %s)" % [
				current_host, current_port, status, str(_connection_timer >= connect_timeout)
			]
			print("[NetworkManager] %s" % err_msg)
			connection_failed.emit(err_msg)
		return

	if is_connected:
		if status != StreamPeerTCP.STATUS_CONNECTED:
			print("[NetworkManager] Disconnected from server (status: %d)." % status)
			is_connected = false
			_connecting = false
			peer.disconnect_from_host()
			current_state = State.DISCONNECTED
			disconnected.emit()
			return

		# Read non-blocking chunks from socket
		var available := peer.get_available_bytes()
		if available > 0:
			var read_res := peer.get_data(available)
			if read_res[0] == OK:
				var raw_bytes: PackedByteArray = read_res[1]
				# In-place symmetric XOR 0xAD transforms wire stream into plaintext
				var plain_bytes := xor_transform(raw_bytes, STATIC_XOR_KEY)
				_rx_plain_buffer.append_array(plain_bytes)
				_process_frame_accumulator()
			else:
				var err_msg := "Socket read failed with code %d" % read_res[0]
				network_error.emit(err_msg)

		# Keepalive ping
		if current_state == State.IN_WORLD or current_state == State.CHARACTER_SELECT:
			_keepalive_timer += delta
			if _keepalive_timer >= keepalive_interval:
				_keepalive_timer = 0.0
				send_ping()

# ==============================================================================
# Frame Accumulator & Stream Parser
# ==============================================================================
func _process_frame_accumulator() -> void:
	while _rx_plain_buffer.size() >= HEADER_SIZE:
		# Search for magic header sentinel (0xF4, 0x44)
		if _rx_plain_buffer[0] != MAGIC_BYTE_0 or _rx_plain_buffer[1] != MAGIC_BYTE_1:
			var sync_idx: int = -1
			for i in range(1, _rx_plain_buffer.size() - 1):
				if _rx_plain_buffer[i] == MAGIC_BYTE_0 and _rx_plain_buffer[i + 1] == MAGIC_BYTE_1:
					sync_idx = i
					break
			if sync_idx >= 0:
				_rx_plain_buffer = _rx_plain_buffer.slice(sync_idx)
			else:
				if _rx_plain_buffer[_rx_plain_buffer.size() - 1] == MAGIC_BYTE_0:
					_rx_plain_buffer = _rx_plain_buffer.slice(_rx_plain_buffer.size() - 1)
				else:
					_rx_plain_buffer.clear()
				break

		# Validate payload length
		var payload_len := _rx_plain_buffer.decode_u16(2)
		if payload_len > MAX_PAYLOAD_SIZE:
			push_warning("[NetworkManager] Frame payload size %d exceeds max %d; discarding header" % [payload_len, MAX_PAYLOAD_SIZE])
			_rx_plain_buffer = _rx_plain_buffer.slice(HEADER_SIZE)
			continue

		var total_frame_len := HEADER_SIZE + payload_len
		if _rx_plain_buffer.size() < total_frame_len:
			# Awaiting remaining payload bytes in next chunk
			break

		# Extract complete payload
		var payload := _rx_plain_buffer.slice(HEADER_SIZE, total_frame_len)
		_rx_plain_buffer = _rx_plain_buffer.slice(total_frame_len)

		# Dispatch payload
		frame_received.emit(payload)
		_dispatch_payload(payload)

# ==============================================================================
# Payload Dispatcher
# ==============================================================================
func _dispatch_payload(payload: PackedByteArray) -> void:
	if payload.is_empty():
		return

	var action_code: int = payload[0]
	var sub_code: int = payload[1] if payload.size() > 1 else -1
	packet_received.emit(action_code, sub_code, payload)

	# 1. Ping / Keepalive Check (0x3E2D / 0x2D3E / Action 0xBA, Sub 0x10)
	if (action_code == 0x3E and sub_code == 0x2D) or (action_code == 0x2D and sub_code == 0x3E) or (action_code == 0xBA and sub_code == 0x10 and (payload.size() < 3 or payload[2] == 0x00)):
		ping_received.emit(payload)
		if _ping_start_ms > 0:
			var latency := Time.get_ticks_msec() - _ping_start_ms
			_ping_start_ms = 0
			ping_updated.emit(latency)
		if auto_respond_to_ping and is_connected:
			send_ping_pong(payload)
		return

	# 2. PLAYER_WALK Check: Opcode 0x0106 (bytes: 06 01 ...)
	if (action_code == 0x06 and sub_code == 0x01) or (action_code == 0x01 and sub_code == 0x06 and payload.size() >= 7):
		_handle_player_walk(payload)
		return

	# 3. CHAT_BROADCAST Check: Opcode 0x230C (bytes: 23 0C ...)
	if (action_code == 0x23 and sub_code == 0x0C) or (action_code == 0x0C and sub_code == 0x23):
		_handle_chat_broadcast(payload)
		return

	# 4. Main Protocol Handlers
	match action_code:
		0x01:
			_handle_ac1(sub_code, payload)
		0x02: # Action 0x02: Item Pickup & Inventory Updates (0x0217 / 0x0205)
			_handle_ac2(sub_code, payload)
		0x05: # Action 0x05: NPC Dialogue & Portals (0x0501 / 0x0500)
			_handle_ac5(sub_code, payload)
		0x07: # Action 0x07: Map Warping (0x0755)
			_handle_ac7(sub_code, payload)
		0x19, 0x1B: # Action 0x19 (Trade), Action 0x1B (Shop Purchase)
			_handle_trade(action_code, sub_code, payload)
		0x32, 0x33: # Action 0x32 (Battle Command/Events), Action 0x33 (Battle Stat Sync)
			_handle_battle(action_code, sub_code, payload)
		0x3F: # Action 63: Auth & Character Selection
			_handle_ac3f(sub_code, payload)
		0x00: # Action 00: Server Notices
			_handle_ac0(sub_code, payload)
		0x14, 0x03, 0x04:
			_handle_world_packet(action_code, sub_code, payload)
		_:
			pass

func _handle_player_walk(payload: PackedByteArray) -> void:
	var walk_data := unpack_player_walk(payload)
	if walk_data["valid"]:
		print("[NetworkManager] PLAYER_WALK (0x0106) -> target=(%d, %d), mode=%d" % [
			walk_data["target_x"], walk_data["target_y"], walk_data["step_mode"]
		])
		player_walk_received.emit(walk_data["target_x"], walk_data["target_y"], walk_data)

func _handle_entity_pos(payload: PackedByteArray) -> void:
	var pos_data := unpack_entity_pos(payload)
	if pos_data["valid"]:
		print("[NetworkManager] ENTITY_POS (0x0101) -> entity_id=%d (val1=%d, val2=%d)" % [
			pos_data["entity_id"], pos_data["val1"], pos_data["val2"]
		])
		entity_pos_received.emit(pos_data["entity_id"], pos_data)

func _handle_chat_broadcast(payload: PackedByteArray) -> void:
	var chat_data := unpack_chat_broadcast(payload)
	if chat_data["valid"]:
		print("[NetworkManager] CHAT_BROADCAST (0x230C) -> channel=%d, sender_id=%d, msg='%s'" % [
			chat_data["channel_id"], chat_data["sender_id"], chat_data["message"]
		])
		chat_broadcast_received.emit(chat_data["channel_id"], chat_data["sender_id"], chat_data["message"], chat_data)

func _handle_ac1(sub_code: int, payload: PackedByteArray) -> void:
	match sub_code:
		0x01: # ENTITY_POS (0x0101) if size >= 6, else Handshake ACK
			if payload.size() >= 6:
				_handle_entity_pos(payload)
			else:
				var status: int = payload[2] if payload.size() > 2 else 0
				print("[NetworkManager] Handshake ACK: status=%d" % status)
		0x03: # Character creation ack: Action 0x01, Sub 0x03, status (1 byte: 0x00 = success)
			var status: int = payload[2] if payload.size() > 2 else 0
			print("[NetworkManager] Character creation ACK received: status=%d" % status)
			character_creation_ack.emit(status)
			if status == 0:
				current_state = State.CREATING_CHARACTER
				character_creation_requested.emit(selected_slot)
		0x0C: # Login / Password error (e.g. account does not exist or wrong password)
			var err_code: int = payload[2] if payload.size() > 2 else 0
			_handle_login_failure("Login/Pwd error", err_code)
		0x06: # Invalid username or password
			_handle_login_failure("Login/Pwd error", 6)
		0x07: # Account banned or session expired
			_handle_login_failure("Account is banned or session timed out.", 7)

func _handle_ac2(sub_code: int, payload: PackedByteArray) -> void:
	# Action 0x02: Item Pickup (0x0217), Entity Update (0x0205)
	var item_id: int = payload.decode_u16(2) if payload.size() >= 4 else 0
	var count: int = payload[4] if payload.size() >= 5 else 1
	var info := {"action": 0x02, "sub_code": sub_code, "item_id": item_id, "count": count, "raw": payload}
	item_pickup_received.emit(item_id, count, info)

func _handle_ac5(sub_code: int, payload: PackedByteArray) -> void:
	# Action 0x05: NPC Dialogue (0x0501 / AC 20:1), Portal enter (0x0500)
	var dial_id: int = payload.decode_u16(2) if payload.size() >= 4 else 0
	var npc_id: int = payload.decode_u16(4) if payload.size() >= 6 else 0
	var info := {"action": 0x05, "sub_code": sub_code, "dialogue_id": dial_id, "npc_id": npc_id, "raw": payload}
	npc_dialogue_received.emit(dial_id, npc_id, info)

func _handle_ac7(sub_code: int, payload: PackedByteArray) -> void:
	# Action 0x07: Map Warp (0x0755)
	var map_id: int = payload.decode_u16(2) if payload.size() >= 4 else 0
	var tx: int = payload.decode_u16(4) if payload.size() >= 6 else 0
	var ty: int = payload.decode_u16(6) if payload.size() >= 8 else 0
	var info := {"action": 0x07, "sub_code": sub_code, "map_id": map_id, "target_x": tx, "target_y": ty, "raw": payload}
	warp_received.emit(map_id, tx, ty, info)

func _handle_trade(action_code: int, sub_code: int, payload: PackedByteArray) -> void:
	# Action 0x19 (Trade), 0x1B (Shop)
	var info := {"action": action_code, "sub_code": sub_code, "payload": payload}
	trade_event_received.emit(sub_code, info)

func _handle_battle(action_code: int, sub_code: int, payload: PackedByteArray) -> void:
	# Action 0x32 (Command 0x3201 / Round Events), 0x33 (Stat Updates 0x3301)
	var info := {"action": action_code, "sub_code": sub_code, "payload": payload}
	battle_packet_received.emit(action_code, sub_code, info)

func _handle_ac3f(sub_code: int, payload: PackedByteArray) -> void:
	match sub_code:
		0x02: # User ID assignment / Login OK / Slot confirmation
			if payload.size() >= 6:
				cached_user_id = payload.decode_u32(2)
				print("[NetworkManager] Login succeeded! User ID: %d" % cached_user_id)
				current_state = State.LOGGED_IN
				login_succeeded.emit(cached_user_id)
			elif payload.size() >= 3:
				var res := payload[2]
				if res == 0:
					print("[NetworkManager] Login succeeded (status 0).")
					current_state = State.LOGGED_IN
					login_succeeded.emit(0)
				else:
					_handle_login_failure("Authentication failed with error code %d" % res, res)
		0x01: # Character List payload
			var chars := _parse_character_list(payload)
			cached_characters = chars
			current_state = State.CHARACTER_SELECT
			print("[NetworkManager] Received character list (%d characters)." % chars.size())
			character_list_received.emit(chars)

## Action 0 carries the server's notices; the texts come from the real client's table (server_notice.gd).
## Only the codes that end a login attempt are acted on here.
const LOGIN_ENDING_NOTICES: Array[int] = [3, 17, 19, 32, 36, 45, 53, 62, 64, 65, 75, 79, 80]

func _handle_ac0(sub_code: int, _payload: PackedByteArray) -> void:
	if sub_code == ServerNotice.DELETE_SUCCESS:
		print("[NetworkManager] Character deleted.")
	elif LOGIN_ENDING_NOTICES.has(sub_code):
		_handle_login_failure(ServerNotice.text_for(sub_code), sub_code)

func _handle_world_packet(action_code: int, sub_code: int, payload: PackedByteArray) -> void:
	if current_state == State.ENTERING_WORLD or current_state == State.CHARACTER_SELECT or current_state == State.LOGGED_IN:
		current_state = State.IN_WORLD
		var world_info := {
			"action_code": action_code,
			"sub_code": sub_code,
			"payload": payload,
			"payload_size": payload.size()
		}
		print("[NetworkManager] Entered game world! Action 0x%02X, Sub 0x%02X" % [action_code, sub_code])
		world_entered.emit(world_info)

func _handle_login_failure(reason: String, error_code: int) -> void:
	print("[NetworkManager] Login failed: %s (code: %d)" % [reason, error_code])
	current_state = State.DISCONNECTED
	disconnect_from_host()
	login_failed.emit(reason, error_code)

# ==============================================================================
# Public Client APIs
# ==============================================================================

## Connects to the target server endpoint.
func connect_to_host(host: String = DEFAULT_HOST, port: int = DEFAULT_PORT) -> Error:
	current_host = host
	current_port = port
	_connecting = true
	is_connected = false
	_connection_timer = 0.0
	current_state = State.CONNECTING
	var err := peer.connect_to_host(host, port)
	if err != OK:
		_connecting = false
		current_state = State.DISCONNECTED
		connection_failed.emit("Failed to initiate TCP connection to %s:%d, code %d" % [host, port, err])
	return err

## Disconnects the socket.
func disconnect_from_host() -> void:
	peer.disconnect_from_host()
	is_connected = false
	_connecting = false
	_rx_plain_buffer.clear()
	current_state = State.DISCONNECTED

## Initiates authentic login authentication sequence.
func login(account: String, password: String, host: String = DEFAULT_HOST, port: int = DEFAULT_PORT) -> Error:
	pending_username = account.strip_edges()
	pending_password = password.strip_edges()

	if is_connected:
		return _send_login_packet()

	return connect_to_host(host, port)

## Sends the authentic Action 0x3F Sub 0x04 login packet.
func _send_login_packet() -> Error:
	var payload := PackedByteArray()
	payload.append(0x3F) # Action 0x3F
	payload.append(0x04) # Subcode 0x04

	# Version uint16 (0xBE, 0x04 = 1214)
	var ver_bytes := PackedByteArray()
	ver_bytes.resize(2)
	ver_bytes.encode_u16(0, CLIENT_VERSION)
	payload.append_array(ver_bytes)

	# Account (1-byte length followed by ASCII)
	var acc_bytes := pending_username.to_ascii_buffer()
	payload.append(acc_bytes.size() & 0xFF)
	payload.append_array(acc_bytes)

	# Password (1-byte length followed by ASCII)
	var pwd_bytes := pending_password.to_ascii_buffer()
	payload.append(pwd_bytes.size() & 0xFF)
	payload.append_array(pwd_bytes)

	# Extra signature bytes: 0x07, 0x53, 0x60, 0x60, 0x63, 0x67, 0x63, 0x61, 0x65
	payload.append_array(get_login_extra_bytes())

	current_state = State.AUTHENTICATING
	print("[NetworkManager] Sending authentic Login packet for '%s' (%d bytes)..." % [pending_username, payload.size()])
	return send_raw_payload(payload)

## Requests character creation on the server: Action 0x3F, Sub 0x02, slot.
func send_request_create_character(slot: int = 1) -> Error:
	selected_slot = slot
	var payload := PackedByteArray([0x3F, 0x02, slot & 0xFF])
	print("[NetworkManager] Requesting character creation for slot %d..." % slot)
	return send_raw_payload(payload)

## Submits new character creation attributes to the server.
func send_create_character(slot: int, char_name: String, role_id: int, element: int, str_v: int, con_v: int, int_v: int, wis_v: int, agi_v: int) -> Error:
	var payload := PackedByteArray()
	payload.append(0x3F)
	payload.append(0x03)
	payload.append(slot & 0xFF)
	var name_bytes := char_name.to_ascii_buffer()
	payload.append(name_bytes.size() & 0xFF)
	payload.append_array(name_bytes)
	payload.append(role_id & 0xFF)
	payload.append(element & 0xFF)
	payload.append(str_v & 0xFF)
	payload.append(con_v & 0xFF)
	payload.append(int_v & 0xFF)
	payload.append(wis_v & 0xFF)
	payload.append(agi_v & 0xFF)
	print("[NetworkManager] Submitting new character '%s' in slot %d..." % [char_name, slot])
	return send_raw_payload(payload)

## Selects an existing character slot to enter the game world: Action 0x3F, Sub 0x02.
func send_select_character(slot: int) -> Error:
	selected_slot = slot
	current_state = State.ENTERING_WORLD
	var payload := PackedByteArray([0x3F, 0x02, slot & 0xFF])
	print("[NetworkManager] Selecting character slot %d to enter world..." % slot)
	return send_raw_payload(payload)

## Sends keepalive ping (Action 0xBA, Sub 0x10, 0x00).
func send_ping() -> Error:
	_ping_start_ms = Time.get_ticks_msec()
	return send_raw_payload(get_ping_packet())

## Responds with ping pong.
## If an incoming ping payload is supplied, echoes it (e.g. 0x3E2D), otherwise sends standard 0xBA10.
func send_ping_pong(incoming_ping: PackedByteArray = PackedByteArray()) -> Error:
	if incoming_ping.size() >= 2:
		if (incoming_ping[0] == 0x3E and incoming_ping[1] == 0x2D) or (incoming_ping[0] == 0x2D and incoming_ping[1] == 0x3E):
			return send_raw_payload(incoming_ping)
	return send_raw_payload(get_ping_packet())

## Sends authentic PLAYER_WALK packet (Opcode 0x0106, wire bytes [0x06, 0x01, step_mode, target_x_le, target_y_le, ...]).
func send_player_walk(target_x: int, target_y: int, step_mode: int = 3, extra_steps: PackedByteArray = PackedByteArray()) -> Error:
	var payload := PackedByteArray()
	payload.append(0x06) # Action 0x06
	payload.append(0x01) # Sub 0x01 (Opcode 0x0106 PLAYER_WALK)
	payload.append(step_mode & 0xFF)

	var coords := PackedByteArray()
	coords.resize(4)
	coords.encode_u16(0, target_x)
	coords.encode_u16(2, target_y)
	payload.append_array(coords)

	if not extra_steps.is_empty():
		payload.append_array(extra_steps)
	else:
		# Standard WLO default walk trail from live capture
		payload.append_array(PackedByteArray([0x04, 0x04, 0x01, 0xC8, 0x01, 0xFD, 0x01, 0x01, 0x00]))

	print("[NetworkManager] Sending PLAYER_WALK (0x0106) to (%d, %d)..." % [target_x, target_y])
	return send_raw_payload(payload)

## Sends authentic CHAT_BROADCAST message (Opcode 0x230C).
func send_chat_broadcast(channel_id: int, message: String) -> Error:
	var payload := PackedByteArray()
	payload.append(0x23) # Action 0x23
	payload.append(0x0C) # Sub 0x0C (Opcode 0x230C)
	payload.append(channel_id & 0xFF)
	var text_bytes := message.to_ascii_buffer()
	payload.append_array(text_bytes)
	print("[NetworkManager] Sending CHAT_BROADCAST (0x230C) on channel %d: '%s'..." % [channel_id, message])
	return send_raw_payload(payload)

## Encapsulates an arbitrary payload into an authentic 0x44F4 framed packet,
## encrypts the entire stream with static XOR 0xAD, and sends it to the server.
func send_raw_payload(payload: PackedByteArray) -> Error:
	if not is_connected:
		push_warning("[NetworkManager] Cannot send packet: Socket not connected.")
		return ERR_CONNECTION_ERROR

	var wire_bytes := build_wire_frame(payload, STATIC_XOR_KEY)
	var err := peer.put_data(wire_bytes)
	if err != OK:
		network_error.emit("Socket put_data error: %d" % err)
	return err

## Sends a packet using action code and optional sub-code.
func send_packet(action_code: int, sub_code: int = -1, data: PackedByteArray = PackedByteArray()) -> Error:
	var payload := PackedByteArray()
	payload.append(action_code & 0xFF)
	if sub_code >= 0:
		payload.append(sub_code & 0xFF)
	payload.append_array(data)
	return send_raw_payload(payload)

# ==============================================================================
# Cryptographic & Wire Serialization Utilities
# ==============================================================================

## Symmetric byte-by-byte static XOR transformation.
## Note: Decryption and Encryption are the exact same operation!
static func xor_transform(buffer: PackedByteArray, key: int = STATIC_XOR_KEY) -> PackedByteArray:
	var out := buffer.duplicate()
	for i in range(out.size()):
		out[i] ^= key
	return out

## In-place static XOR transformation.
static func xor_transform_in_place(buffer: PackedByteArray, key: int = STATIC_XOR_KEY) -> void:
	for i in range(buffer.size()):
		buffer[i] ^= key

## Builds an unencrypted plaintext frame: [0xF4, 0x44] [uint16 len] [payload].
static func build_plain_frame(payload: PackedByteArray) -> PackedByteArray:
	var frame := PackedByteArray()
	frame.resize(HEADER_SIZE + payload.size())
	frame[0] = MAGIC_BYTE_0 # 0xF4
	frame[1] = MAGIC_BYTE_1 # 0x44
	frame.encode_u16(2, payload.size())
	for i in range(payload.size()):
		frame[HEADER_SIZE + i] = payload[i]
	return frame

## Builds a wire frame encrypted with static XOR 0xAD.
## Result begins with [0x59, 0xE9].
static func build_wire_frame(payload: PackedByteArray, key: int = STATIC_XOR_KEY) -> PackedByteArray:
	var plain := build_plain_frame(payload)
	return xor_transform(plain, key)

## Parses and extracts all complete payloads from a raw wire byte sequence.
static func parse_frames_from_wire(wire_data: PackedByteArray, key: int = STATIC_XOR_KEY) -> Array[PackedByteArray]:
	var plain := xor_transform(wire_data, key)
	var payloads: Array[PackedByteArray] = []
	var offset: int = 0
	while offset + HEADER_SIZE <= plain.size():
		if plain[offset] == MAGIC_BYTE_0 and plain[offset + 1] == MAGIC_BYTE_1:
			var payload_len := plain.decode_u16(offset + 2)
			var total_len := HEADER_SIZE + payload_len
			if offset + total_len <= plain.size():
				payloads.append(plain.slice(offset + HEADER_SIZE, offset + total_len))
				offset += total_len
				continue
		offset += 1
	return payloads

# ==============================================================================
# Live In-Game Opcode Struct Unpackers (Bridge Daemon Parity)
# ==============================================================================

## Unpacks 0x0106 PLAYER_WALK payload: step_mode (uint8), target_x (uint16), target_y (uint16).
static func unpack_player_walk(payload: PackedByteArray) -> Dictionary:
	var res := {
		"valid": false,
		"step_mode": 0,
		"target_x": 0,
		"target_y": 0,
		"extra_steps": PackedByteArray()
	}
	if payload.size() < 7:
		return res
	res["valid"] = true
	res["step_mode"] = payload[2]
	res["target_x"] = payload.decode_u16(3)
	res["target_y"] = payload.decode_u16(5)
	if payload.size() > 7:
		res["extra_steps"] = payload.slice(7)
	return res

## Unpacks 0x0101 ENTITY_POS payload: entity_id (uint32) / val1 (uint16), val2 (uint16).
static func unpack_entity_pos(payload: PackedByteArray) -> Dictionary:
	var res := {
		"valid": false,
		"entity_id": 0,
		"val1": 0,
		"val2": 0
	}
	if payload.size() < 6:
		return res
	res["valid"] = true
	res["entity_id"] = payload.decode_u32(2)
	res["val1"] = payload.decode_u16(2)
	res["val2"] = payload.decode_u16(4)
	return res

## Unpacks 0x3E2D PING/KEEPALIVE payload: ping_id / timestamp (uint32).
static func unpack_ping(payload: PackedByteArray) -> Dictionary:
	var res := {
		"valid": false,
		"ping_id": 0
	}
	if payload.size() < 2:
		return res
	res["valid"] = true
	if payload.size() >= 6:
		res["ping_id"] = payload.decode_u32(2)
	return res

## Unpacks 0x230C CHAT_BROADCAST payload: channel_id (uint8), sender_id (uint32), message (String).
static func unpack_chat_broadcast(payload: PackedByteArray) -> Dictionary:
	var res := {
		"valid": false,
		"channel_id": 0,
		"sender_id": 0,
		"message": "",
		# Role (1..14) whose face is drawn in front of the line. The wire packet carries only the sender id,
		# so this stays 0 (unknown) until the receiver resolves it from the sender's entity record.
		"role_id": 0
	}
	if payload.size() < 2:
		return res
	res["valid"] = true
	if payload.size() > 2:
		res["channel_id"] = payload[2]
	if payload.size() >= 7:
		res["sender_id"] = payload.decode_u32(3)
	if payload.size() > 7:
		res["message"] = payload.slice(7).get_string_from_ascii()
	return res

# ==============================================================================
# Internal Character Record Parsing
# ==============================================================================
func _parse_character_list(payload: PackedByteArray) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	var offset: int = 2 # Skip ActionCode (0x3F) and SubCode (0x01)

	while offset + 10 <= payload.size():
		var slot := payload[offset]
		offset += 1

		# Name (length-prefixed ASCII)
		if offset >= payload.size():
			break
		var name_len := payload[offset]
		offset += 1
		if offset + name_len > payload.size():
			break
		var char_name := payload.slice(offset, offset + name_len).get_string_from_ascii()
		offset += name_len

		if offset + 34 > payload.size():
			break

		var level := payload[offset]
		var element := payload[offset + 1]
		offset += 2

		var cur_hp := payload.decode_u32(offset)
		var full_hp := payload.decode_u32(offset + 4)
		var cur_sp := payload.decode_u32(offset + 8)
		var full_sp := payload.decode_u32(offset + 12)
		var total_exp := payload.decode_u32(offset + 16)
		var gold := payload.decode_u32(offset + 20)
		offset += 24

		var body := payload.decode_u16(offset)
		var head := payload.decode_u16(offset + 2)
		offset += 4

		var col1 := payload.decode_u32(offset)
		var col2 := payload.decode_u32(offset + 4)
		offset += 8

		# Equipment (7 items, uint16 each)
		var equipment: Array[int] = []
		for i in range(7):
			if offset + 2 <= payload.size():
				equipment.append(payload.decode_u16(offset))
				offset += 2
			else:
				equipment.append(0)

		list.append({
			"slot": slot,
			"name": char_name,
			"level": level,
			"element": element,
			"element_name": _element_id_to_name(element),
			"cur_hp": cur_hp,
			"full_hp": full_hp,
			"cur_sp": cur_sp,
			"full_sp": full_sp,
			"total_exp": total_exp,
			"gold": gold,
			"body": body,
			"head": head,
			"color1": col1,
			"color2": col2,
			"equipment": equipment
		})

	return list

func _element_id_to_name(elem_id: int) -> String:
	match elem_id:
		1: return "Water"
		2: return "Fire"
		3: return "Wind"
		4: return "Earth"
		_: return "None"

func _state_to_string(st: State) -> String:
	match st:
		State.DISCONNECTED: return "DISCONNECTED"
		State.CONNECTING: return "CONNECTING"
		State.CONNECTED: return "CONNECTED"
		State.AUTHENTICATING: return "AUTHENTICATING"
		State.LOGGED_IN: return "LOGGED_IN"
		State.CHARACTER_SELECT: return "CHARACTER_SELECT"
		State.CREATING_CHARACTER: return "CREATING_CHARACTER"
		State.ENTERING_WORLD: return "ENTERING_WORLD"
		State.IN_WORLD: return "IN_WORLD"
		_: return "UNKNOWN"
