extends SceneTree

## The auto player wanders the Go way: eight offsets of radius 160 in the Go order, and never while walking.

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
	print("--- Auto Player Wander Suite ---")
	await process_frame
	var inst: Node = (load("res://scenes/world/map_view.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	for i in range(60):
		await process_frame
	var hud = inst.get("hud")
	_record(hud.AUTO_WANDER_RADIUS == 160.0, "the wander radius is the Go value 160")
	_record(hud.AUTO_WANDER_OFFSETS.size() == 8, "eight wander offsets")
	_record(hud.AUTO_WANDER_OFFSETS[0] == Vector2(-1, 0) and hud.AUTO_WANDER_OFFSETS[2] == Vector2(1, 0), "offsets follow the Go order: left, up, right, down, then diagonals")
	var moved: bool = hud.auto_player_wander()
	_record(typeof(moved) == TYPE_BOOL, "wander returns a result without error")
	if hud.player:
		hud.player.set("is_moving", true)
		_record(not hud.auto_player_wander(), "no wander while the player is walking")
	if hud.player:
		hud.player.set("is_moving", false)
		hud._auto_wander_next_ms = Time.get_ticks_msec() + 5000
		_record(not hud.auto_player_wander(), "no second wander inside the one-second pause")
	inst.queue_free()
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
