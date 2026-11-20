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
	var other := PackedByteArray([3, 19, 39, 0, 0, 1, 1, 0, 10, 0, 10, 0])
	var before: Vector2 = hud.player.global_position
	client.packet_received.emit(3, other)
	_record(hud.player.global_position == before, "a spawn on another map leaves the player alone")
	inst.queue_free()
	client.queue_free()
	holder.queue_free()
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
