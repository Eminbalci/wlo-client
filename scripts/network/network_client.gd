class_name NetworkClient
extends Node

## Asynchronous TCP network client for the Wonderland Online protocol.
## Connects via StreamPeerTCP, handles 0x44F4 framing and rolling keystream encryption.

const WloCrypto = preload("res://scripts/network/wlo_crypto.gd")
const PacketFramer = preload("res://scripts/network/packet_framer.gd")
const PacketClass = preload("res://scripts/network/packet.gd")

signal connected
signal connected_to_server
signal connection_failed
signal connection_error(error_message: String)
signal disconnected
signal packet_received(action_code: int, payload: PackedByteArray)

var _peer := StreamPeerTCP.new()
var _crypto_send = WloCrypto.new()
var _crypto_recv = WloCrypto.new()
var _receive_buffer := PackedByteArray()

var is_connected: bool = false
var _connecting: bool = false

func is_connected_to_server() -> bool:
	return is_connected

func _process(_delta: float) -> void:
	_peer.poll()
	var status := _peer.get_status()
	
	if _connecting:
		if status == StreamPeerTCP.STATUS_CONNECTED:
			_connecting = false
			is_connected = true
			_crypto_send.reset()
			_crypto_recv.reset()
			_receive_buffer.clear()
			connected.emit()
			connected_to_server.emit()
			print("[NetworkClient] Connected to server successfully.")
		elif status == StreamPeerTCP.STATUS_ERROR:
			_connecting = false
			is_connected = false
			connection_failed.emit()
			connection_error.emit("TCP connection error")
			print("[NetworkClient] Failed to connect to server.")
	
	if is_connected:
		if status != StreamPeerTCP.STATUS_CONNECTED:
			is_connected = false
			disconnected.emit()
			print("[NetworkClient] Disconnected from server.")
			return
		
		var available := _peer.get_available_bytes()
		if available > 0:
			var bytes := _peer.get_data(available)
			if bytes[0] == OK:
				_receive_buffer.append_array(bytes[1])
				_process_incoming_stream()

func connect_to_server(host: String, port: int) -> Error:
	_connecting = true
	is_connected = false
	var err := _peer.connect_to_host(host, port)
	if err != OK:
		_connecting = false
		connection_failed.emit()
		connection_error.emit("Failed to connect to %s:%d, err: %d" % [host, port, err])
	return err

func disconnect_from_server() -> void:
	_peer.disconnect_from_host()
	is_connected = false
	_connecting = false

func send_packet(packet_or_ac, sub_code: int = -1, data: PackedByteArray = PackedByteArray()) -> void:
	if not is_connected:
		push_warning("Cannot send packet: Not connected.")
		return
	
	var raw_payload := PackedByteArray()
	if packet_or_ac is PacketClass:
		raw_payload = packet_or_ac.get_buffer()
	elif packet_or_ac is int:
		raw_payload.append(packet_or_ac)
		if sub_code >= 0:
			raw_payload.append(sub_code)
		raw_payload.append_array(data)
	elif packet_or_ac is PackedByteArray:
		raw_payload = packet_or_ac
	
	# Authentic wire framing: [0xF4, 0x44] [uint16 len] [payload] ^ 0xAD
	var wire_frame: PackedByteArray = NetworkManager.build_wire_frame(raw_payload, NetworkManager.STATIC_XOR_KEY)
	_peer.put_data(wire_frame)

func _process_incoming_stream() -> void:
	while true:
		# Check authentic XOR 0xAD wire framing first
		var frame_result: Dictionary = PacketFramer.try_extract_wire_frame(_receive_buffer, NetworkManager.STATIC_XOR_KEY)
		if not frame_result["success"]:
			# Fallback to plain framing if wire extraction fails
			frame_result = PacketFramer.try_extract_frame(_receive_buffer)
			if not frame_result["success"]:
				if frame_result["consumed_bytes"] > 0:
					_receive_buffer = _receive_buffer.slice(frame_result["consumed_bytes"])
				break
			var enc: PackedByteArray = frame_result["payload"]
			var con: int = frame_result["consumed_bytes"]
			_receive_buffer = _receive_buffer.slice(con)
			var dec: PackedByteArray = _crypto_recv.transform(enc)
			if dec.size() >= 1:
				packet_received.emit(dec[0], dec)
			continue
		
		var payload: PackedByteArray = frame_result["payload"]
		var consumed: int = frame_result["consumed_bytes"]
		_receive_buffer = _receive_buffer.slice(consumed)
		
		if payload.size() >= 1:
			var action_code: int = payload[0]
			packet_received.emit(action_code, payload)
