extends SceneTree

## Single-player state round trip: inventory, gold, quest steps and position survive save + reload.

var _checks := 0
var _failed := 0


func _init() -> void:
	_run()


func _record(ok: bool, label: String) -> void:
	_checks += 1
	if ok:
		print("  [PASS] " + label)
	else:
		_failed += 1
		print("  [FAIL] " + label)


func _world() -> Node:
	var scene := load("res://scenes/world/map_view.tscn") as PackedScene
	var inst: Node = scene.instantiate()
	root.add_child(inst)
	for i in range(40):
		await process_frame
	return inst


func _run() -> void:
	print("--- Single Player State Suite ---")
	await process_frame
	await process_frame
	SaveGame.delete_slot(0)
	var gdb: Node = root.get_node_or_null("GameDatabase")
	_record(gdb != null, "GameDatabase autoload exists")
	if gdb == null:
		quit(1)
		return

	gdb.active_character = {"name": "Daniel", "level": 3, "role_id": 6, "map_id": 10002, "gold": 500, "save_slot": 0}
	SaveGame.write_slot(0, gdb.active_character)

	var first: Node = await _world()
	var hud: Node = first.get("hud")
	_record(hud != null, "world builds a HUD")
	var seed_inv: Array[Dictionary] = [{"id": 30028, "count": 2, "name": "Hill Pepper"}]
	hud._inventory_data = seed_inv
	hud.update_gold(777)
	first.get("_quest_steps")[12018] = 2
	first.player.global_position = Vector2(321.0, 210.0)
	first._save_to_slot()
	first.queue_free()
	await process_frame
	await process_frame

	var saved := SaveGame.read_slot(0)
	_record(not saved.is_empty(), "slot 0 is written")
	var inv: Array = saved.get("inventory", [])
	_record(inv.size() == 1 and int(inv[0].get("id", 0)) == 30028 and int(inv[0].get("count", 0)) == 2, "inventory saved (Hill Pepper x2)")
	_record(int(saved.get("gold", 0)) == 777, "gold saved")
	_record(int(saved.get("quest_steps", {}).get("12018", 0)) == 2, "quest step saved")
	var pos := SaveGame.array_to_vec(saved.get("position", []))
	_record(pos.distance_to(Vector2(321.0, 210.0)) < 1.0, "position saved")

	gdb.active_character = saved.duplicate(true)
	var second: Node = await _world()
	var hud2: Node = second.get("hud")
	var inv2: Array = hud2._inventory_data
	_record(inv2.size() >= 1 and int(inv2[0].get("id", 0)) == 30028, "reload restores the inventory")
	_record(hud2.get_gold() == 777, "reload restores gold")
	_record(int(second.get("_quest_steps").get(12018, 0)) == 2, "reload restores the quest step")

	second.queue_free()
	SaveGame.delete_slot(0)
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
