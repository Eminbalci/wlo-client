extends SceneTree

## Witch Doctor / Clinic: Eve opcode 7 (d1 6 or 7) offers a full rest; Yes restores HP and SP.

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
	print("--- Clinic Rest Suite ---")
	await process_frame
	await process_frame

	var op_rest := {"opcode": 7, "d1": 6, "d2": 0, "d3": 0, "d4": 0, "dw": [0, 0, 0]}
	var sub := {"index": 1, "cond_byte": 6, "words": [0, 0, 0, 0, 0, 256], "ops": [op_rest]}
	var pages_actions := NpcEventScript.branch_script(sub, Callable())
	var has_rest := false
	for a in pages_actions["actions"]:
		if a is Dictionary and a.has("rest"):
			has_rest = true
	_record(has_rest, "Eve opcode 7 with d1 6 produces a rest action")

	var inst: Node = (load("res://scenes/world/map_view.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	for i in range(60):
		await process_frame
	var hud = inst.get("hud")
	var ccs = hud.character_status_ctrl
	ccs.current_hp = 10
	ccs.current_sp = 5

	inst.call("_apply_script_actions", [{"rest": 6}])
	for i in range(5):
		await process_frame
	_record(ccs.current_hp == 10, "the rest is only offered: HP unchanged before Yes")

	inst.call("_on_rest_choice", 0, "Yes.")
	for i in range(5):
		await process_frame
	_record(ccs.current_hp == ccs.current_max_hp, "Yes restores HP to full (%d)" % ccs.current_hp)
	_record(ccs.current_sp == ccs.current_max_sp, "Yes restores SP to full (%d)" % ccs.current_sp)

	inst.call("_on_rest_choice", 1, "No.")
	_record(ccs.current_hp == ccs.current_max_hp, "No changes nothing")

	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
