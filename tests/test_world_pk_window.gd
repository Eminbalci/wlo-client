extends SceneTree

## World PK window drawing: tab switching, rankings rows, chance bar width, settings confirm/cancel.

const WorldPkWindow = preload("res://scripts/ui/hud/world_pk_window.gd")
const WorldPkState = preload("res://scripts/ui/hud/world_pk_state.gd")

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
	print("--- World PK Window Suite ---")
	await process_frame
	var w = WorldPkWindow.new()
	root.add_child(w)
	await process_frame
	w.state.rank = 4
	w.state.wins = 12
	w.state.chances = 5
	w.refresh()
	_record(w._rank_label.text == "4" and w._wins_label.text == "12", "the PVP tab shows rank and wins")
	_record(is_equal_approx(w._bar.size.x, 70.0), "five of ten chances fill 70 px of the bar")

	for i in 6:
		w.state.entries.append({"name": "P%d" % i, "level": 20 + i, "wins": i})
	w.state.select_tab(WorldPkState.TAB_RANKINGS)
	w.refresh()
	_record(w._rows[0].visible and w._rows[0].text.begins_with("1. P0") and w._rows[3].visible, "the rankings tab shows four rows")
	_record(w._page_label.text == "1/2", "the rankings page label shows page and total")
	_record(not w._rank_label.visible, "PVP details are hidden on the rankings tab")

	w.state.select_tab(WorldPkState.TAB_SETTINGS)
	w.refresh()
	_record(w._offline_check.visible and not w._confirm.visible, "the settings tab shows the toggle with no pending change")
	w._offline_check.button_pressed = false
	_record(w._confirm.visible and w._cancel.visible, "a changed toggle shows Confirm and Cancel")
	w._cancel.pressed.emit()
	_record(not w.state.settings_dirty() and w.state.allow_offline, "Cancel restores the toggle")
	w._offline_check.button_pressed = false
	w._confirm.pressed.emit()
	_record(not w.state.allow_offline, "Confirm saves the toggle")

	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)

