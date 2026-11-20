extends SceneTree

## The HUD opens the World PK window once and reuses it.

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
	print("--- World PK HUD Suite ---")
	await process_frame
	var inst: Node = (load("res://scenes/world/map_view.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	for i in range(60):
		await process_frame
	var hud = inst.get("hud")
	hud.open_world_pk()
	_record(hud.world_pk_window != null and hud.world_pk_window.visible, "the HUD opens the World PK window")
	var first = hud.world_pk_window
	hud.open_world_pk()
	_record(hud.world_pk_window == first, "a second open reuses the window")
	inst.queue_free()
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
