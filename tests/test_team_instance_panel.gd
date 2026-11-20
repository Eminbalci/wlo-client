extends SceneTree

## The Instance tab shows the instance panel inside the team window; the Party tab hides it.

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
	print("--- Team Instance Panel Suite ---")
	await process_frame
	var inst: Node = (load("res://scenes/world/map_view.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	for i in range(60):
		await process_frame
	var hud = inst.get("hud")
	var team = hud.team_window
	team.tab_changed.emit(1)
	var panel = hud.instance_window
	_record(panel != null and panel.get_parent() == team and panel.visible, "the Instance tab shows the panel inside the team window")
	_record(panel._room_label.text == "Not in an instance room", "the panel starts with no room")
	panel.handle_packet(85, 4, PackedByteArray([85, 4, 233, 3, 0, 0, 49, 117, 1, 4]))
	_record(panel._room_label.text.begins_with("Room 1001") and panel._enter_button.disabled, "a joined room shows its id and disables Enter")
	team.tab_changed.emit(0)
	_record(not panel.visible, "the Party tab hides the panel")
	inst.queue_free()
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
