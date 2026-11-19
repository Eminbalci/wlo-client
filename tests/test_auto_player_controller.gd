extends SceneTree

## Auto-combat decision step: fight, supplies, stop conditions and idle.

const AutoPlayerSettings = preload("res://scripts/ui/hud/auto_player_settings.gd")
const AutoPlayerController = preload("res://scripts/ui/hud/auto_player_controller.gd")

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
	print("--- Auto Player Controller Suite ---")
	await process_frame
	var s := AutoPlayerSettings.new()
	var idle := {"hp_percent": 100, "supplies": 3, "in_battle": false}
	var battle := {"hp_percent": 100, "supplies": 3, "in_battle": true}
	_record(AutoPlayerController.decide(s, idle).action == AutoPlayerController.ACTION_NONE, "nothing enabled: idle")
	s.toggle_check(0)
	_record(AutoPlayerController.decide(s, battle).action == AutoPlayerController.ACTION_FIGHT, "fight on: attacks in battle")
	s.toggle_check(1)
	_record(AutoPlayerController.decide(s, idle).action == AutoPlayerController.ACTION_MOVE, "move on: walks outside battle")
	s.toggle_check(2)
	s.set_threshold(0, 50)
	var low := {"hp_percent": 40, "supplies": 2, "in_battle": true}
	_record(AutoPlayerController.decide(s, low).action == AutoPlayerController.ACTION_USE_SUPPLY, "supply on: uses a supply below the threshold")
	var high := {"hp_percent": 60, "supplies": 2, "in_battle": false}
	_record(AutoPlayerController.decide(s, high).action == AutoPlayerController.ACTION_MOVE, "supply on: no supply above the threshold")
	s.toggle_check(3)
	var empty := {"hp_percent": 20, "supplies": 0, "in_battle": true}
	var stop := AutoPlayerController.decide(s, empty)
	_record(stop.action == AutoPlayerController.ACTION_STOP and stop.reason == AutoPlayerController.STOP_NO_SUPPLIES, "no supplies left: stops")
	s.toggle_check(4)
	var dead := {"player_dead": true, "in_battle": false}
	_record(AutoPlayerController.decide(s, dead).reason == AutoPlayerController.STOP_PLAYER_DEATH, "player death stops when checked")
	s.toggle_check(6)
	s.set_field(1, "2")
	var late := {"seconds_elapsed": 120, "in_battle": false}
	_record(AutoPlayerController.decide(s, late).reason == AutoPlayerController.STOP_TIME, "time limit stops after the set minutes")
	var early := {"seconds_elapsed": 60, "in_battle": false}
	_record(AutoPlayerController.decide(s, early).action != AutoPlayerController.ACTION_STOP, "before the limit it keeps going")
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
