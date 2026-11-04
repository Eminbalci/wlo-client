extends SceneTree

## Gold / Money management window verification suite.

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
	print("--- Gold Window Suite ---")
	await process_frame
	await process_frame

	var win := GoldWindow.new()
	root.add_child(win)
	await process_frame

	_record(win != null, "instantiate GoldWindow")

	win.set_gold(1234)
	_record(win.gold_label != null and win.gold_label.text == "1234", "set_gold(1234) shows 1234 in its amount label")

	win.open()
	_record(win.visible, "open() makes it visible")

	var closed_called: Array[bool] = [false]
	win.closed.connect(func() -> void:
		closed_called[0] = true
	)

	var close_btn: Button = win.get_action_button("Close")
	if close_btn != null:
		close_btn.pressed.emit()
		_record(closed_called[0] and not win.visible, "Close button emits closed and hides it")
	else:
		_record(false, "Close button emits closed and hides it")

	var last_action: Array[String] = [""]
	win.action_pressed.connect(func(action: String) -> void:
		last_action[0] = action
	)

	var action_btn: Button = win.get_action_button("Trade Item")
	if action_btn != null:
		action_btn.pressed.emit()
		_record(last_action[0] == action_btn.text, "a button press emits action_pressed with the text")
	else:
		_record(false, "a button press emits action_pressed with the text")

	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
