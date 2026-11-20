extends SceneTree

## The team window's Instance tab opens the HUD instance browser.

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
	print("--- Team Instance Tab Suite ---")
	await process_frame
	var inst: Node = (load("res://scenes/world/map_view.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	for i in range(60):
		await process_frame
	var hud = inst.get("hud")
	var team = hud.team_window
	_record(team.has_signal("instance_tab_selected"), "the team window exposes the Instance tab signal")
	team.instance_tab_selected.emit()
	_record(hud.instance_window != null, "the Instance tab creates the instance browser in the HUD")
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
