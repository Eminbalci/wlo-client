extends SceneTree

## The world scene starts from the inventory and spawn point the server sent.

var _checks := 0
var _failed := 0


func _init() -> void:
	_run()


func _record(ok: bool, label: String) -> void:
	_checks += 1
	print(("  [PASS] " if ok else "  [FAIL] ") + label)
	if not ok:
		_failed += 1


func _run() -> void:
	print("--- World State From Server Suite ---")
	await process_frame
	var net := root.get_node("NetSession")
	var holder := Node.new()
	root.add_child(holder)
	var client := NetworkClient.new()
	holder.add_child(client)
	net.adopt(client)
	var inv := PackedByteArray([23, 5])
	for e in [[1, 34038, 1], [3, 32176, 50]]:
		var entry := PackedByteArray([e[0], e[1] & 0xFF, (e[1] >> 8) & 0xFF, e[2], 0])
		entry.resize(31)
		inv.append_array(entry)
	client.packet_received.emit(23, inv)
	_record(net.inventory.size() == 2 and net.inventory[3].count == 50, "NetSession keeps the inventory entries it receives")

	# AC23:5 adds to a stack of the same item; AC23:9 removes from it and empties the slot at zero.
	var more := PackedByteArray([23, 5, 3, 0xB0, 0x7D, 5, 0])
	more.resize(2 + 31)
	client.packet_received.emit(23, more)
	_record(net.inventory[3].count == 55, "an addition to the same item grows the stack")
	client.packet_received.emit(23, PackedByteArray([23, 9, 3, 5]))
	_record(net.inventory[3].count == 50, "a removal shrinks the stack")
	client.packet_received.emit(23, PackedByteArray([23, 9, 1, 1]))
	_record(not net.inventory.has(1), "removing the whole stack empties the slot")
	var restore := PackedByteArray([23, 5, 1, 246, 132, 1, 0])
	restore.resize(2 + 31)
	client.packet_received.emit(23, restore)

	var inst: Node = (load("res://scenes/world/map_view.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	for i in range(60):
		await create_timer(0.05).timeout
	var hud = inst.get("hud")
	var bag = hud.inventory_ctrl.inventory_data
	_record(int(bag[0].get("id", 0)) == 34038 and int(bag[2].get("id", 0)) == 32176 and int(bag[2].get("count", 0)) == 50, "the HUD bag starts from the server's items")
	_record(bag[1].is_empty() and bag[3].is_empty(), "slots the server did not send are empty, not the local demo items")

	var map_id: int = hud.current_map_id
	var spawn := PackedByteArray([3, 19, 39, 0, 0, 1, map_id & 0xFF, (map_id >> 8) & 0xFF, 120, 3, 56, 4])
	client.packet_received.emit(3, spawn)
	_record(hud.player.global_position == Vector2(888, 1080), "a spawn on this map moves the player there")
	var missing := PackedByteArray([3, 19, 39, 0, 0, 1, 49, 117, 10, 0, 10, 0])
	var before: Vector2 = hud.player.global_position
	client.packet_received.emit(3, missing)
	_record(hud.player.global_position == before and hud.current_map_id == map_id, "a spawn on a map the game does not have leaves the scene alone")
	var other := PackedByteArray([3, 19, 39, 0, 0, 1, 33, 39, 18, 4, 51, 4])
	client.packet_received.emit(3, other)
	for i in range(10):
		await create_timer(0.05).timeout
	_record(hud.current_map_id == 10017, "a spawn on a map the game has loads that map")
	_record(hud.player.global_position.distance_to(Vector2(1042, 1075)) < 2.0, "and puts the player at the server's position")
	var stats := PackedByteArray([5, 3, 2, 209, 0, 0, 0, 142, 0, 7, 0, 8, 0, 6, 0, 10, 0, 9, 0, 3, 6, 0, 0, 0, 209, 0, 142, 0, 161, 1])
	client.packet_received.emit(5, stats)
	var rec: Dictionary = root.get_node("/root/GameDatabase").active_character
	_record(int(rec.str) == 6 and int(rec.con) == 7 and int(rec.int) == 8 and int(rec.wis) == 9 and int(rec.agi) == 10 and int(rec.level) == 3 and rec.element == "Water", "the server's attributes, level and element land on the active character")
	var shown: Label = hud.character_status_ctrl.stat_str
	_record(shown != null and shown.text.contains("6"), "the status window shows the server's strength")
	inst.queue_free()
	client.queue_free()
	holder.queue_free()
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
