extends SceneTree

## Server state that arrived before the world scene was built still decides where it starts.

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
	print("--- World Start From Server Suite ---")
	await process_frame
	var net := root.get_node("NetSession")
	var holder := Node.new()
	root.add_child(holder)
	var client := NetworkClient.new()
	holder.add_child(client)
	net.adopt(client)
	# The packets arrive while the login screen is still switching scenes, before the HUD exists.
	client.packet_received.emit(3, PackedByteArray([3, 19, 39, 0, 0, 1, 33, 39, 18, 4, 51, 4]))
	var inv := PackedByteArray([23, 5, 1, 246, 132, 2, 0])
	inv.resize(2 + 31)
	client.packet_received.emit(23, inv)
	client.packet_received.emit(5, PackedByteArray([5, 3, 3, 201, 0, 0, 0, 121, 0, 5, 0, 5, 0, 5, 0, 5, 0, 5, 0, 7, 6, 0, 0, 0, 201, 0, 121, 0, 161, 1]))

	var inst: Node = (load("res://scenes/world/map_view.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	for i in range(40):
		await create_timer(0.05).timeout
	var hud = inst.get("hud")
	_record(hud.current_map_id == 10017, "the scene starts on the server's map even though the packet came first")
	_record(hud.player.global_position.distance_to(Vector2(1042, 1075)) < 2.0, "the player starts at the server's position")
	_record(int(hud.inventory_ctrl.inventory_data[0].get("id", 0)) == 34038 and int(hud.inventory_ctrl.inventory_data[0].get("count", 0)) == 2, "the bag starts from the server's inventory")
	_record(int(root.get_node("/root/GameDatabase").active_character.get("level", 0)) == 7, "the active character starts with the server's level")
	inst.queue_free()
	client.queue_free()
	holder.queue_free()
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
