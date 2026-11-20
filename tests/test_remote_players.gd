extends SceneTree

## Other players appear on the map from AC4 packets and walk from AC6:1 packets.

var _checks := 0
var _failed := 0


func _init() -> void:
	_run()


func _record(ok: bool, label: String) -> void:
	_checks += 1
	print(("  [PASS] " if ok else "  [FAIL] ") + label)
	if not ok:
		_failed += 1


func _appear(id: int, map_id: int, x: int, y: int, player_name: String) -> PackedByteArray:
	var p := PackedByteArray([4])
	var idb := PackedByteArray([0, 0, 0, 0])
	idb.encode_u32(0, id)
	p.append_array(idb)
	p.append_array(PackedByteArray([1, 3, 1, map_id & 0xFF, map_id >> 8, x & 0xFF, x >> 8, y & 0xFF, y >> 8, 0, 1]))
	for i in range(17):
		p.append(0)
	p.append(player_name.length())
	p.append_array(player_name.to_ascii_buffer())
	return p


func _run() -> void:
	print("--- Remote Players Suite ---")
	await process_frame
	var live := PackedByteArray([4, 19, 39, 0, 0, 1, 3, 1, 33, 39, 18, 4, 51, 4, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 82, 101, 109, 111, 116, 101, 84, 119, 111])
	var info := WorldEntry.parse_other_player(live)
	_record(info.get("char_id") == 10003 and info.get("map") == 10017 and info.get("x") == 1042 and info.get("y") == 1075, "the live appearance packet gives id, map and position")
	_record(info.get("name") == "RemoteTwo", "and the name")
	var walk := WorldEntry.parse_remote_walk(PackedByteArray([6, 1, 19, 39, 0, 0, 3, 76, 4, 96, 4]))
	_record(walk.get("char_id") == 10003 and walk.get("x") == 1100 and walk.get("y") == 1120, "the live walk packet gives id and destination")
	_record(WorldEntry.parse_remote_walk(PackedByteArray([6, 2, 19, 39, 0, 0, 3, 76, 4, 96, 4])).is_empty(), "another sub code is not a walk")

	var layer := RemotePlayers.new()
	root.add_child(layer)
	layer.own_id = 777
	layer.set_map(10017)
	_record(layer.handle_packet(4, _appear(5, 10017, 100, 200, "Ann")), "an appearance packet is accepted")
	_record(layer.players.has(5) and layer.players[5].node.position == Vector2(100, 200), "the marker appears at the reported position")
	_record(not layer.handle_packet(4, _appear(777, 10017, 1, 1, "Me")), "the player's own packet is ignored")
	_record(layer.handle_packet(6, PackedByteArray([6, 1, 5, 0, 0, 0, 3, 164, 0, 200, 0])), "a walk packet for a known player is accepted")
	for i in range(40):
		await create_timer(0.05).timeout
	_record(layer.players[5].node.position.distance_to(Vector2(164, 200)) < 1.0, "the marker glides to the walk destination")
	_record(not layer.handle_packet(6, PackedByteArray([6, 1, 9, 0, 0, 0, 3, 164, 0, 200, 0])), "a walk for an unknown player is ignored")
	layer.handle_packet(4, _appear(6, 10001, 5, 5, "Far"))
	_record(not layer.players[6].node.visible and layer.players[5].node.visible, "a player on another map is hidden")
	layer.set_map(10001)
	_record(layer.players[6].node.visible and not layer.players[5].node.visible, "changing the map shows the other map's players")
	var leave := PackedByteArray([12, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
	_record(WorldEntry.parse_presence(leave) == {"char_id": 6, "map": 0, "x": 0, "y": 0}, "the live leave packet has the player's id and map 0")
	_record(layer.handle_packet(12, leave) and not layer.players.has(6), "a map of 0 removes the marker")
	_record(not layer.handle_packet(12, leave), "a leave for an unknown player is ignored")
	_record(layer.handle_packet(12, PackedByteArray([12, 5, 0, 0, 0, 33, 39, 232, 3, 232, 3, 0, 0, 0])) and layer.players[5].target == Vector2(1000, 1000), "a presence with a map moves a known player")
	layer.queue_free()
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
