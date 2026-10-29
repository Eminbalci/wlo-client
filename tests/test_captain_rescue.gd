extends SceneTree

## After the captain's talk the ship sinks, Robinson pulls the player out (no Kelang conversation) and the player is released.

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


func _run() -> void:
	print("--- Captain Rescue Suite ---")
	await process_frame
	await process_frame
	var gdb = root.get_node("GameDatabase")
	gdb.active_character = {"name": "Daniel", "level": 3, "role_id": 6, "map_id": 10001, "gold": 500}
	var inst: Node = (load("res://scenes/world/map_view.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	for i in range(60):
		await process_frame
	inst.load_map(10001)
	for i in range(60):
		await process_frame

	var captain = null
	var entities = inst.get("entities")
	if entities:
		for c in entities.get_children():
			if c.get("npc_id") == 14003:
				captain = c
	_record(captain != null, "captain is on the ship deck")
	if captain == null:
		quit(1)
		return

	inst.call("_on_npc_interacted", captain)
	for i in range(30):
		await process_frame
	var hud = inst.get("hud")
	for step in range(12):
		if hud and hud.has_method("advance_dialogue"):
			hud.advance_dialogue()
		for i in range(20):
			await process_frame

	for i in range(4000):
		await process_frame
		if inst.get("map_renderer") and int(inst.get("map_renderer").current_map_id) == 10003:
			break

	_record(int(inst.get("map_renderer").current_map_id) == 10003, "the ship sinks and the player reaches the island (10003)")
	var active_npc = inst.get("_active_dialogue_npc")
	var kelang_talk := active_npc != null and str(active_npc.get("npc_name")).to_lower().contains("kelang")
	_record(not kelang_talk, "no Kelang conversation after the rescue")
	var player = inst.get("player")
	for i in range(4000):
		await process_frame
		if player and not bool(player.is_movement_locked):
			break
	_record(player != null and not bool(player.is_movement_locked), "player is released after Robinson pulls them out")

	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
