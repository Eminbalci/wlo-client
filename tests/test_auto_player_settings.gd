extends SceneTree

## Auto-combat controller settings model: defaults, check toggles, digit-only fields, thresholds, discard.

const AutoPlayerSettings = preload("res://scripts/ui/hud/auto_player_settings.gd")

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
	print("--- Auto Player Settings Suite ---")
	await process_frame
	var s := AutoPlayerSettings.new()
	_record(s.checks.size() == 11 and s.checks[10] and not s.checks[0], "defaults: remote information on, the rest off")
	_record(s.fields == ["1", "50", "3", "3", "0"] and s.thresholds == [50, 50, 50, 50], "defaults match the Go editors and sliders")
	s.toggle_check(0)
	_record(s.checks[0], "a check toggles on")
	s.toggle_check(99)
	_record(s.checks.size() == 11, "an out-of-range check is ignored")
	s.set_field(1, "a1b2c3d4e5")
	_record(s.fields[1] == "1234", "fields keep digits only and at most four")
	s.set_field(4, "")
	_record(s.field_int(4) == 0, "an empty field reads 0")
	s.set_threshold(2, 150)
	_record(s.thresholds[2] == 100, "thresholds clamp to 100")
	s.set_threshold(3, -4)
	_record(s.thresholds[3] == 0, "thresholds clamp to 0")
	s.set_discard(1, 34058)
	s.set_discard(2, -3)
	_record(s.discard[1] == 34058 and s.discard[2] == 0, "discard slots hold item ids and clear negatives")
	s.reset()
	_record(not s.checks[0] and s.discard[1] == 0 and s.field_int(1) == 50, "reset restores the defaults")
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
