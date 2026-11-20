extends SceneTree

## The runner maps fight and stop decisions onto the battle's auto-battle, and reports moves and supplies.

const AutoPlayerRunner = preload("res://scripts/ui/hud/auto_player_runner.gd")
const AutoPlayerController = preload("res://scripts/ui/hud/auto_player_controller.gd")

var _checks := 0
var _failed := 0


class FakeBattle extends RefCounted:
	var auto := false

	func set_auto_battle(enabled: bool) -> void:
		auto = enabled


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
	print("--- Auto Player Runner Suite ---")
	await process_frame
	var r := AutoPlayerRunner.new()
	var battle := FakeBattle.new()
	r.apply({"action": AutoPlayerController.ACTION_FIGHT}, battle)
	_record(battle.auto, "a fight decision turns auto-battle on")
	r.apply({"action": AutoPlayerController.ACTION_STOP, "reason": AutoPlayerController.STOP_TIME}, battle)
	_record(not battle.auto and r.last_stop_reason == AutoPlayerController.STOP_TIME, "a stop turns auto-battle off and keeps the reason")
	var moved := [0]
	var used := [0]
	r.on_move = func() -> void: moved[0] += 1
	r.on_use_supply = func() -> void: used[0] += 1
	r.apply({"action": AutoPlayerController.ACTION_MOVE}, battle)
	r.apply({"action": AutoPlayerController.ACTION_USE_SUPPLY}, battle)
	_record(moved[0] == 1 and used[0] == 1, "move and supply decisions reach their callables")
	r.apply({"action": AutoPlayerController.ACTION_NONE}, null)
	_record(moved[0] == 1 and used[0] == 1, "an idle decision does nothing")
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
