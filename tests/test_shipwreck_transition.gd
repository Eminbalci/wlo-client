extends SceneTree

## Eve scene transition type 1 on the starter ships (10014..10018) starts the shipwreck and lands the player on 10035.

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
	print("--- Shipwreck Transition Suite ---")
	await process_frame
	await process_frame
	var gdb = root.get_node("GameDatabase")
	gdb.active_character = {"name": "Daniel", "level": 3, "role_id": 6, "map_id": 10014, "gold": 0}

	var inst: Node = (load("res://scenes/world/map_view.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	for i in range(60):
		await process_frame
	inst.load_map(10014)
	for i in range(60):
		await process_frame
	_record(int(inst.get("map_renderer").current_map_id) == 10014, "starter ship 10014 is loaded")

	inst.call("_apply_script_actions", [{"transition": 1}])
	for i in range(20):
		await process_frame
	_record(bool(inst.get("_sinking_triggered")), "transition 1 starts the shipwreck")
	_record(int(inst.get("_sinking_target_map")) == 10035, "the shipwreck lands on 10035")

	for i in range(4000):
		await process_frame
		if int(inst.get("map_renderer").current_map_id) == 10035:
			break
	_record(int(inst.get("map_renderer").current_map_id) == 10035, "the player reaches 10035 after the sinking")

	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
