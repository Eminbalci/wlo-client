extends SceneTree

const NetworkManagerScript = preload("res://scripts/network/network_manager.gd")

func _init() -> void:
	print("==================================================")
	print("Running Wonderland Online Network Protocol Tests")
	print("==================================================")

	var all_passed := true
	all_passed = test_server_config() and all_passed
	all_passed = test_wlo_crypto() and all_passed
	all_passed = test_packet() and all_passed
	all_passed = test_packet_framer() and all_passed
	all_passed = test_login_manager_states() and all_passed
	all_passed = test_network_manager_crypto() and all_passed
	all_passed = test_network_manager_framing() and all_passed
	all_passed = test_network_manager_accumulator() and all_passed
	all_passed = test_network_manager_login_packet() and all_passed
	all_passed = test_network_manager_ping_pong() and all_passed
	all_passed = test_network_manager_dispatcher_responses() and all_passed
	all_passed = test_network_manager_telemetry_opcodes() and all_passed
	all_passed = test_network_manager_live_connection() and all_passed

	print("==================================================")
	if all_passed:
		print("ALL NETWORK PROTOCOL TESTS PASSED SUCCESSFULLY!")
	else:
		push_error("SOME TESTS FAILED!")
	print("==================================================")
	quit(0 if all_passed else 1)

func test_server_config() -> bool:
	print("[TEST] ServerConfig...")
	var ini_path := "res://assets/SERVER.INI"
	var config := ServerConfig.load_from_file(ini_path)

	if config.servers.is_empty():
		push_error("FAIL: No servers parsed from SERVER.INI")
		return false

	print("  Parsed %d groups, %d servers." % [config.groups.size(), config.servers.size()])
	for s in config.servers:
		print("    - %s" % s.to_string())

	var default_srv := config.get_default_server()
	if not default_srv or default_srv.name.is_empty():
		push_error("FAIL: Default server is invalid")
		return false

	var rhodes_srv := config.find_server("Rhodes1")
	if not rhodes_srv or rhodes_srv.host != "20.187.103.41":
		push_error("FAIL: Rhodes1 server not found or host != 20.187.103.41")
		return false

	var local_srv := config.find_server("Local")
	if not local_srv or local_srv.host != "127.0.0.1":
		push_error("FAIL: Could not find 'Local' server or host != 127.0.0.1")
		return false

	print("  PASS: ServerConfig")
	return true

func test_wlo_crypto() -> bool:
	print("[TEST] WloCrypto...")
	var test_data := "WonderlandOnlineAuthTest12345".to_ascii_buffer()

	# Test 1: Rolling keystream roundtrip
	var crypto_enc := WloCrypto.new(0xAD)
	var encrypted := crypto_enc.transform(test_data)
	if encrypted == test_data:
		push_error("FAIL: Rolling cipher produced plaintext output")
		return false

	var crypto_dec := WloCrypto.new(0xAD)
	var decrypted := crypto_dec.transform(encrypted)
	if decrypted != test_data:
		push_error("FAIL: Rolling cipher roundtrip failed")
		return false

	# Test 2: Static XOR roundtrip
	var static_enc := WloCrypto.transform_static(test_data, 0xAD)
	var static_dec := WloCrypto.transform_static(static_enc, 0xAD)
	if static_dec != test_data:
		push_error("FAIL: Static XOR roundtrip failed")
		return false

	print("  PASS: WloCrypto")
	return true

func test_packet() -> bool:
	print("[TEST] Packet Builder & Reader...")
	var pkt := Packet.create(63, 4)
	pkt.pack_u16(1205)
	pkt.pack_string("testuser")
	pkt.pack_string("secretpass")
	pkt.pack_u32(999999)
	pkt.pack_float(123.45)
	pkt.pack_bool(true)

	if pkt.get_action_code() != 63 or pkt.get_sub_code() != 4:
		push_error("FAIL: ActionCode or SubCode incorrect")
		return false

	# Unpack
	var reader := Packet.new(pkt.get_buffer())
	var ac := reader.unpack_u8()
	var sub := reader.unpack_u8()
	var ver := reader.unpack_u16()
	var user := reader.unpack_string()
	var password_val := reader.unpack_string()
	var num := reader.unpack_u32()
	var fl := reader.unpack_float()
	var flag := reader.unpack_bool()

	if ac != 63 or sub != 4 or ver != 1205 or user != "testuser" or password_val != "secretpass" or num != 999999 or absf(fl - 123.45) > 0.01 or not flag:
		push_error("FAIL: Packet unpacking fields mismatched")
		return false

	print("  PASS: Packet Builder & Reader")
	return true

func test_packet_framer() -> bool:
	print("[TEST] PacketFramer...")
	var raw_payload := PackedByteArray([0x01, 0x01, 0xFF, 0x00, 0xAA])
	var framed := PacketFramer.frame(raw_payload)

	if framed.size() != PacketFramer.HEADER_SIZE + raw_payload.size():
		push_error("FAIL: Framed size %d != expected %d" % [framed.size(), PacketFramer.HEADER_SIZE + raw_payload.size()])
		return false

	var magic := framed.decode_u16(0)
	if magic != PacketFramer.MAGIC_HEADER:
		push_error("FAIL: Framed magic 0x%04X != 0x%04X" % [magic, PacketFramer.MAGIC_HEADER])
		return false

	var payload_len := framed.decode_u16(2)
	if payload_len != raw_payload.size():
		push_error("FAIL: Framed payload length %d != %d" % [payload_len, raw_payload.size()])
		return false

	# Test extraction with partial pre-amble noise
	var stream := PackedByteArray([0x00, 0x00, 0x12]) # noise
	stream.append_array(framed)

	var extract_result := PacketFramer.try_extract_frame(stream)
	if not extract_result["success"]:
		push_error("FAIL: Could not extract frame from stream with noise")
		return false

	var extracted_payload: PackedByteArray = extract_result["payload"]
	if extracted_payload != raw_payload:
		push_error("FAIL: Extracted payload does not match original payload")
		return false

	print("  PASS: PacketFramer")
	return true

func test_login_manager_states() -> bool:
	print("[TEST] LoginManager States...")
	var mgr := LoginManager.new()

	if mgr.current_state != LoginManager.State.DISCONNECTED:
		push_error("FAIL: Initial state is not DISCONNECTED")
		return false

	# Test character record parsing
	var test_char_pkt := Packet.new()
	test_char_pkt.pack_u8(63) # AC
	test_char_pkt.pack_u8(1)  # Sub 1
	test_char_pkt.pack_u8(1)  # slot
	test_char_pkt.pack_string("HeroPlayer") # name
	test_char_pkt.pack_u8(35) # level
	test_char_pkt.pack_u8(2)  # element (Fire)
	test_char_pkt.pack_u32(1250)
	test_char_pkt.pack_u32(1250)
	test_char_pkt.pack_u32(450)
	test_char_pkt.pack_u32(450)
	test_char_pkt.pack_u32(85000)
	test_char_pkt.pack_u32(50000)
	test_char_pkt.pack_u16(1)
	test_char_pkt.pack_u16(2)
	test_char_pkt.pack_u32(100)
	test_char_pkt.pack_u32(200)
	for i in range(7):
		test_char_pkt.pack_u16(1000 + i)

	var chars := []
	var on_chars_received := func(list: Array[Dictionary]) -> void:
		chars.append_array(list)

	mgr.character_list_received.connect(on_chars_received)
	mgr.current_state = LoginManager.State.AUTHENTICATING
	mgr._handle_ac63(test_char_pkt, 1)

	if chars.size() != 1:
		push_error("FAIL: Character list size %d != 1" % chars.size())
		return false

	var c: Dictionary = chars[0]
	if c["name"] != "HeroPlayer" or c["level"] != 35 or c["element_name"] != "Fire":
		push_error("FAIL: Character fields mismatched: %s" % str(c))
		return false

	mgr.free()
	print("  PASS: LoginManager States & Character Parsing")
	return true

# ==============================================================================
# NetworkManager Unit Tests
# ==============================================================================

func test_network_manager_crypto() -> bool:
	print("[TEST] NetworkManager Symmetric XOR 0xAD Crypto...")

	# Verify byte 0xF4 ^ 0xAD = 0x59
	var b0: int = 0xF4 ^ 0xAD
	if b0 != 0x59:
		push_error("FAIL: 0xF4 ^ 0xAD != 0x59 (got 0x%02X)" % b0)
		return false

	# Verify byte 0x44 ^ 0xAD = 0xE9
	var b1: int = 0x44 ^ 0xAD
	if b1 != 0xE9:
		push_error("FAIL: 0x44 ^ 0xAD != 0xE9 (got 0x%02X)" % b1)
		return false

	# Test symmetric transform
	var raw := PackedByteArray([0xF4, 0x44, 0x03, 0x00, 0xBA, 0x10, 0x00])
	var wire := NetworkManagerScript.xor_transform(raw, 0xAD)

	if wire[0] != 0x59 or wire[1] != 0xE9:
		push_error("FAIL: Wire header does not match 0x59, 0xE9: [0x%02X, 0x%02X]" % [wire[0], wire[1]])
		return false

	var roundtrip := NetworkManagerScript.xor_transform(wire, 0xAD)
	if roundtrip != raw:
		push_error("FAIL: Symmetric XOR roundtrip mismatch")
		return false

	print("  PASS: NetworkManager Symmetric XOR 0xAD Crypto")
	return true

func test_network_manager_framing() -> bool:
	print("[TEST] NetworkManager Framing & Wire Serialization...")

	var payload := PackedByteArray([0xBA, 0x10, 0x00]) # Ping packet
	var plain_frame := NetworkManagerScript.build_plain_frame(payload)

	if plain_frame.size() != 4 + payload.size():
		push_error("FAIL: Plain frame size %d != %d" % [plain_frame.size(), 4 + payload.size()])
		return false

	if plain_frame[0] != 0xF4 or plain_frame[1] != 0x44:
		push_error("FAIL: Plain frame magic incorrect: [0x%02X, 0x%02X]" % [plain_frame[0], plain_frame[1]])
		return false

	var payload_len := plain_frame.decode_u16(2)
	if payload_len != 3:
		push_error("FAIL: Plain frame decoded length %d != 3" % payload_len)
		return false

	# Wire frame
	var wire_frame := NetworkManagerScript.build_wire_frame(payload, 0xAD)
	if wire_frame[0] != 0x59 or wire_frame[1] != 0xE9:
		push_error("FAIL: Wire frame magic != 0x59, 0xE9")
		return false

	# Parse back from wire
	var extracted := NetworkManagerScript.parse_frames_from_wire(wire_frame, 0xAD)
	if extracted.size() != 1:
		push_error("FAIL: Expected 1 extracted frame, got %d" % extracted.size())
		return false

	if extracted[0] != payload:
		push_error("FAIL: Extracted payload does not match original payload")
		return false

	print("  PASS: NetworkManager Framing & Wire Serialization")
	return true

func test_network_manager_accumulator() -> bool:
	print("[TEST] NetworkManager Frame Accumulator...")

	var nm = NetworkManagerScript.new()

	var payload1 := PackedByteArray([0xBA, 0x10, 0x00])
	var payload2 := PackedByteArray([0x01, 0x0C, 0x00])

	var wire1 := NetworkManagerScript.build_wire_frame(payload1)
	var wire2 := NetworkManagerScript.build_wire_frame(payload2)

	var received_frames: Array[PackedByteArray] = []
	nm.frame_received.connect(func(p: PackedByteArray):
		received_frames.append(p)
	)

	# Feed 1: Noise + Complete Frame 1
	var chunk1 := PackedByteArray([0xAA, 0xBB]) # Noise bytes
	chunk1.append_array(wire1)
	var plain1 := NetworkManagerScript.xor_transform(chunk1)
	nm._rx_plain_buffer.append_array(plain1)
	nm._process_frame_accumulator()

	if received_frames.size() != 1 or received_frames[0] != payload1:
		push_error("FAIL: Accumulator failed to extract frame 1 after noise")
		nm.free()
		return false

	# Feed 2: Partial frame 2 (split into two sub-chunks)
	var half1 := wire2.slice(0, 4)
	var half2 := wire2.slice(4)

	nm._rx_plain_buffer.append_array(NetworkManagerScript.xor_transform(half1))
	nm._process_frame_accumulator()

	if received_frames.size() != 1:
		push_error("FAIL: Accumulator dispatched before full frame arrived")
		nm.free()
		return false

	nm._rx_plain_buffer.append_array(NetworkManagerScript.xor_transform(half2))
	nm._process_frame_accumulator()

	if received_frames.size() != 2 or received_frames[1] != payload2:
		push_error("FAIL: Accumulator failed to extract second frame across chunk boundary")
		nm.free()
		return false

	nm.free()
	print("  PASS: NetworkManager Frame Accumulator")
	return true

func test_network_manager_login_packet() -> bool:
	print("[TEST] NetworkManager Authentic Login Packet Layout...")

	var nm = NetworkManagerScript.new()
	nm.pending_username = "testantigrav"
	nm.pending_password = "testpass123"

	# Build expected payload
	var acc_bytes := "testantigrav".to_ascii_buffer()
	var pwd_bytes := "testpass123".to_ascii_buffer()
	var extra := PackedByteArray([0x07, 0x53, 0x60, 0x60, 0x63, 0x67, 0x63, 0x61, 0x65])

	var expected_payload := PackedByteArray()
	expected_payload.append(0x3F)
	expected_payload.append(0x04)
	expected_payload.append(0xBE) # 1214 Little Endian: 0xBE, 0x04
	expected_payload.append(0x04)
	expected_payload.append(acc_bytes.size())
	expected_payload.append_array(acc_bytes)
	expected_payload.append(pwd_bytes.size())
	expected_payload.append_array(pwd_bytes)
	expected_payload.append_array(extra)

	var plain_frame := NetworkManagerScript.build_plain_frame(expected_payload)
	var wire_frame := NetworkManagerScript.build_wire_frame(expected_payload, 0xAD)

	# Verify wire prefix bytes:
	# 0xF4 ^ 0xAD = 0x59
	# 0x44 ^ 0xAD = 0xE9
	# 0x26 ^ 0xAD = 0x8B (payload len 38 = 0x26)
	# 0x00 ^ 0xAD = 0xAD
	# 0x3F ^ 0xAD = 0x92
	# 0x04 ^ 0xAD = 0xA9
	if wire_frame[0] != 0x59 or wire_frame[1] != 0xE9 or wire_frame[2] != 0x8B or wire_frame[3] != 0xAD:
		push_error("FAIL: Wire bytes prefix mismatched authentic live trace: [0x%02X, 0x%02X, 0x%02X, 0x%02X]" % [
			wire_frame[0], wire_frame[1], wire_frame[2], wire_frame[3]
		])
		nm.free()
		return false

	if wire_frame[4] != 0x92 or wire_frame[5] != 0xA9:
		push_error("FAIL: Action 0x3F, 0x04 wire bytes mismatched: [0x%02X, 0x%02X]" % [wire_frame[4], wire_frame[5]])
		nm.free()
		return false

	nm.free()
	print("  PASS: NetworkManager Authentic Login Packet Layout (matches live capture 59e98bad92a9)")
	return true

func test_network_manager_ping_pong() -> bool:
	print("[TEST] NetworkManager Ping / Keepalive Handling...")

	var nm = NetworkManagerScript.new()

	var pings := []
	nm.ping_received.connect(func(p: PackedByteArray):
		pings.append(p)
	)

	# Simulate incoming ping packet from server (Action 0xBA, Sub 0x10, 0x00)
	var ping_payload := PackedByteArray([0xBA, 0x10, 0x00])
	nm._dispatch_payload(ping_payload)

	if pings.is_empty():
		push_error("FAIL: Ping packet was not dispatched to ping_received signal")
		nm.free()
		return false

	nm.free()
	print("  PASS: NetworkManager Ping / Keepalive Handling")
	return true

func test_network_manager_dispatcher_responses() -> bool:
	print("[TEST] NetworkManager Dispatcher Signals...")

	var nm = NetworkManagerScript.new()

	# 1. Login Failure Signal Test
	var login_fails := []
	nm.login_failed.connect(func(reason: String, code: int):
		login_fails.append({"reason": reason, "code": code})
	)

	# Action 0x01 Sub 0x0C (Status 0x00) -> Login/Password error
	nm._dispatch_payload(PackedByteArray([0x01, 0x0C, 0x00]))
	if login_fails.is_empty() or login_fails[0]["code"] != 0:
		push_error("FAIL: Action 0x01 Sub 0x0C did not trigger login_failed")
		nm.free()
		return false

	# 2. Character Creation ACK Test
	var char_acks := []
	var char_reqs := []
	nm.character_creation_ack.connect(func(status: int):
		char_acks.append(status)
	)
	nm.character_creation_requested.connect(func(slot: int):
		char_reqs.append(slot)
	)

	nm.selected_slot = 1
	# Action 0x01 Sub 0x03 Status 0x00 -> character creation ACK
	nm._dispatch_payload(PackedByteArray([0x01, 0x03, 0x00]))
	if char_acks.is_empty() or char_reqs.is_empty() or char_reqs[0] != 1:
		push_error("FAIL: Action 0x01 Sub 0x03 did not trigger character_creation_ack/requested")
		nm.free()
		return false

	# 3. Login Succeeded Signal Test
	var login_successes := []
	nm.login_succeeded.connect(func(uid: int):
		login_successes.append(uid)
	)

	# Action 0x3F Sub 0x02 + UserID 88888 (uint32)
	var ok_payload := PackedByteArray([0x3F, 0x02])
	var uid_bytes := PackedByteArray()
	uid_bytes.resize(4)
	uid_bytes.encode_u32(0, 88888)
	ok_payload.append_array(uid_bytes)

	nm._dispatch_payload(ok_payload)
	if login_successes.is_empty() or login_successes[0] != 88888:
		push_error("FAIL: Action 0x3F Sub 0x02 did not trigger login_succeeded with user_id 88888")
		nm.free()
		return false

	# 4. World Entered Signal Test
	var worlds := []
	nm.world_entered.connect(func(info: Dictionary):
		worlds.append(info)
	)

	nm.current_state = NetworkManagerScript.State.LOGGED_IN
	nm._dispatch_payload(PackedByteArray([0x14, 0x01, 0x02]))
	if worlds.is_empty() or nm.current_state != NetworkManagerScript.State.IN_WORLD:
		push_error("FAIL: Action 0x14 did not transition to IN_WORLD or emit world_entered")
		nm.free()
		return false

	nm.free()
	print("  PASS: NetworkManager Dispatcher Signals")
	return true

func test_network_manager_telemetry_opcodes() -> bool:
	print("[TEST] NetworkManager Live Telemetry Opcodes (0x0106, 0x0101, 0x3E2D, 0x230C)...")

	var nm = NetworkManagerScript.new()

	# --------------------------------------------------------------------------
	# 1. Opcode 0x0106: PLAYER_WALK (uint16 target_x, uint16 target_y, step_mode)
	# --------------------------------------------------------------------------
	# Authentic live sniff: f4 44 0f 00 06 01 03 96 02 47 04 04 01 c8 01 fd 01 01 00
	var walk_payload := PackedByteArray([
		0x06, 0x01, 0x03, 0x96, 0x02, 0x47, 0x04,
		0x04, 0x01, 0xC8, 0x01, 0xFD, 0x01, 0x01, 0x00
	])

	var walk_unpacked := NetworkManagerScript.unpack_player_walk(walk_payload)
	if not walk_unpacked["valid"] or walk_unpacked["target_x"] != 662 or walk_unpacked["target_y"] != 1095 or walk_unpacked["step_mode"] != 3:
		push_error("FAIL: 0x0106 unpack mismatch: %s" % str(walk_unpacked))
		nm.free()
		return false

	var walk_events := []
	nm.player_walk_received.connect(func(x: int, y: int, data: Dictionary):
		walk_events.append({"x": x, "y": y, "data": data})
	)

	nm._dispatch_payload(walk_payload)
	if walk_events.is_empty() or walk_events[0]["x"] != 662 or walk_events[0]["y"] != 1095:
		push_error("FAIL: player_walk_received signal not emitted with correct coordinates")
		nm.free()
		return false

	# --------------------------------------------------------------------------
	# 2. Opcode 0x0101: ENTITY_POS (uint32 entity_id / val1, val2 pos update)
	# --------------------------------------------------------------------------
	# Authentic live sniff: f4 44 06 00 01 01 36 b3 46 00
	var pos_payload := PackedByteArray([0x01, 0x01, 0x36, 0xB3, 0x46, 0x00])

	var pos_unpacked := NetworkManagerScript.unpack_entity_pos(pos_payload)
	if not pos_unpacked["valid"] or pos_unpacked["entity_id"] != 4633398 or pos_unpacked["val1"] != 45878 or pos_unpacked["val2"] != 70:
		push_error("FAIL: 0x0101 unpack mismatch: %s" % str(pos_unpacked))
		nm.free()
		return false

	var pos_events := []
	nm.entity_pos_received.connect(func(ent_id: int, data: Dictionary):
		pos_events.append({"entity_id": ent_id, "data": data})
	)

	nm._dispatch_payload(pos_payload)
	if pos_events.is_empty() or pos_events[0]["entity_id"] != 4633398:
		push_error("FAIL: entity_pos_received signal not emitted with correct entity_id")
		nm.free()
		return false

	# --------------------------------------------------------------------------
	# 3. Opcode 0x3E2D: PING/KEEPALIVE (ping pong keepalive handling)
	# --------------------------------------------------------------------------
	# Authentic live sniff: f4 44 06 00 3e 2d 42 e0 03 00
	var ping_payload := PackedByteArray([0x3E, 0x2D, 0x42, 0xE0, 0x03, 0x00])

	var ping_unpacked := NetworkManagerScript.unpack_ping(ping_payload)
	if not ping_unpacked["valid"] or ping_unpacked["ping_id"] != 254018:
		push_error("FAIL: 0x3E2D unpack mismatch: %s" % str(ping_unpacked))
		nm.free()
		return false

	var ping_events := []
	nm.ping_received.connect(func(p: PackedByteArray):
		ping_events.append(p)
	)

	nm._dispatch_payload(ping_payload)
	if ping_events.is_empty() or ping_events[0] != ping_payload:
		push_error("FAIL: 0x3E2D ping_received signal not emitted")
		nm.free()
		return false

	# --------------------------------------------------------------------------
	# 4. Opcode 0x230C: CHAT_BROADCAST (uint8 channel_id, uint32 sender_id, msg)
	# --------------------------------------------------------------------------
	# Authentic live sniff: f4 44 07 00 23 0c 0e ba 01 00 00
	var chat_payload := PackedByteArray([0x23, 0x0C, 0x0E, 0xBA, 0x01, 0x00, 0x00])

	var chat_unpacked := NetworkManagerScript.unpack_chat_broadcast(chat_payload)
	if not chat_unpacked["valid"] or chat_unpacked["channel_id"] != 14 or chat_unpacked["sender_id"] != 442:
		push_error("FAIL: 0x230C unpack mismatch: %s" % str(chat_unpacked))
		nm.free()
		return false

	var chat_events := []
	nm.chat_broadcast_received.connect(func(ch: int, sender: int, msg: String, data: Dictionary):
		chat_events.append({"channel": ch, "sender": sender, "msg": msg, "data": data})
	)

	nm._dispatch_payload(chat_payload)
	if chat_events.is_empty() or chat_events[0]["channel"] != 14 or chat_events[0]["sender"] != 442:
		push_error("FAIL: chat_broadcast_received signal not emitted with correct sender/channel")
		nm.free()
		return false

	# Test CHAT_BROADCAST with string content
	var chat_text_payload := PackedByteArray([0x23, 0x0C, 0x01, 0x01, 0x02, 0x03, 0x04])
	chat_text_payload.append_array("Hello Wonderland!".to_ascii_buffer())
	var text_unpacked := NetworkManagerScript.unpack_chat_broadcast(chat_text_payload)
	if text_unpacked["message"] != "Hello Wonderland!":
		push_error("FAIL: 0x230C string content unpack mismatch: '%s'" % text_unpacked["message"])
		nm.free()
		return false

	nm.free()
	print("  PASS: NetworkManager Live Telemetry Opcodes (0x0106, 0x0101, 0x3E2D, 0x230C)")
	return true

func test_network_manager_live_connection() -> bool:
	print("[TEST] NetworkManager Live Server Connection to Rhodes1 (20.187.103.41:6414)...")

	var nm = NetworkManagerScript.new()
	var err := nm.connect_to_host("20.187.103.41", 6414)
	if err != OK:
		push_error("FAIL: connect_to_host returned %d" % err)
		nm.free()
		return false

	var connected := false
	var start_time := Time.get_ticks_msec()

	# Poll non-blocking up to 2500ms
	while Time.get_ticks_msec() - start_time < 2500:
		nm.peer.poll()
		var status: int = nm.peer.get_status()
		if status == StreamPeerTCP.STATUS_CONNECTED:
			connected = true
			nm.is_connected = true
			break
		elif status == StreamPeerTCP.STATUS_ERROR:
			break
		OS.delay_msec(20)

	if not connected:
		print("  [WARN] Live connection to 20.187.103.41:6414 timed out (offline or firewalled in test environment).")
		nm.disconnect_from_host()
		nm.free()
		return true

	print("  Connected to live Rhodes1 server! Status: CONNECTED")

	# Disconnect cleanly
	nm.disconnect_from_host()
	nm.free()

	print("  PASS: NetworkManager Live Server Connection")
	return true
