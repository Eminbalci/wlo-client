extends SceneTree

## Top bar actions: player_battle opens the World PK window, trade opens the Business menu.

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
	print("--- Top Bar Business / World PK Suite ---")
	await process_frame
	var inst: Node = (load("res://scenes/world/map_view.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	for i in range(60):
		await process_frame
	var hud = inst.get("hud")
	var bar = hud.get("top_action_bar")
	bar._on_action_requested("player_battle")
	_record(hud.world_pk_window != null and hud.world_pk_window.visible, "the player_battle action opens World PK")
	bar._on_action_requested("trade")
	_record(hud.business_window != null and hud.business_window.visible, "the trade action opens the Business menu")
	bar._on_action_requested("trade")
	_record(not hud.business_window.visible, "a second trade action closes it")
	hud.business_window.open()
	hud.business_window._trade_items.pressed.emit()
	_record(not hud.business_window.visible, "Trade Items closes the Business menu")
	inst.queue_free()
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
