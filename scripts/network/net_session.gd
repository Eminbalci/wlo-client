extends Node

## The live server connection, kept alive across scene changes (autoload "NetSession").
## The login screen hands its connected NetworkClient over with adopt() before it switches to the
## world scene; windows in the world then send through send() and receive replies through the
## packet_received signal. Without a handed-over connection the game stays offline: is_online() is
## false and send() does nothing.

signal packet_received(action_code: int, payload: PackedByteArray)
## Emitted when the spawn point or the inventory the server sent changes.
signal world_state_changed

## What the server sent on world entry, kept so the world scene can start from it even though the
## packets arrive while the scene is still loading. inventory maps slot (1..50) to {slot, id, count, damage}.
var spawn: Dictionary = {}
var inventory: Dictionary = {}

var _client: NetworkClient = null


## Takes over a connected client from its current parent so it survives the scene change.
func adopt(client: NetworkClient) -> void:
	if client == null:
		return
	if _client != null and is_instance_valid(_client) and _client != client:
		_client.queue_free()
	var parent := client.get_parent()
	if parent != null and parent != self:
		parent.remove_child(client)
	if client.get_parent() != self:
		add_child(client)
	_client = client
	spawn = {}
	inventory = {}
	if not client.packet_received.is_connected(_on_client_packet):
		client.packet_received.connect(_on_client_packet)


func is_online() -> bool:
	return _client != null and is_instance_valid(_client) and _client.is_connected_to_server()


## Sends a payload to the server. Returns false when there is no live connection.
func send(payload: PackedByteArray) -> bool:
	if not is_online():
		return false
	_client.send_packet(payload)
	return true


func _on_client_packet(action_code: int, payload: PackedByteArray) -> void:
	if action_code == 3:
		var parsed := WorldEntry.parse_spawn(payload)
		if not parsed.is_empty():
			spawn = parsed
			world_state_changed.emit()
	elif action_code == 23 and payload.size() > 1 and payload[1] == 5:
		var entries := WorldEntry.parse_inventory(payload)
		for e in entries:
			inventory[e.slot] = e
		if not entries.is_empty():
			world_state_changed.emit()
	packet_received.emit(action_code, payload)
