extends SceneTree

## A walk the player starts is sent to the server as an AC6:1 packet.

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
	print("--- Walk To Server Suite ---")
	await process_frame
	_record(NetworkManager.build_walk_payload(1100, 1200) == PackedByteArray([6, 1, 3, 76, 4, 176, 4]), "the walk packet is AC6:1 with direction and little-endian x and y")
	_record(NetworkManager.build_walk_payload(70000, -5) == PackedByteArray([6, 1, 3, 255, 255, 0, 0]), "coordinates are clamped to u16")

	var inst: Node = (load("res://scenes/world/map_view.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	for i in range(60):
		await create_timer(0.05).timeout
	var hud = inst.get("hud")
	var sent := []
	hud.walk_sink = func(p: PackedByteArray) -> void: sent.append(p)
	var target: Vector2 = hud.player.global_position + Vector2(-160, 0)
	var ok: bool = hud.player.set_target_world_position(target)
	_record(ok and sent.size() == 1, "an accepted walk is forwarded once")
	_record(sent.size() == 1 and sent[0] == NetworkManager.build_walk_payload(int(target.x), int(target.y)), "with the target as its destination")
	hud.player.set_target_world_position(Vector2(-99999, -99999), false)
	_record(sent.size() == 1, "a walk the game refuses is not sent")
	inst.queue_free()
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
