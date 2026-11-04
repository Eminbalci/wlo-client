extends SceneTree

## Lucky Draw / Chance window verification suite.

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
	print("--- Lucky Draw Window Suite ---")
	await process_frame
	await process_frame

	var win := LuckyDrawWindow.new()
	root.add_child(win)
	await process_frame

	_record(win != null, "LuckyDrawWindow instantiates")

	win.set_draws_left(3)
	var draws_shown: bool = (
		win.draws_left == 3
		and win.draws_left_label != null
		and "3" in win.draws_left_label.text
	)
	_record(draws_shown, "set_draws_left(3) shows 3")

	win.open()
	_record(win.visible, "open() makes it visible")

	var draw_called: Array[bool] = [false]
	win.draw_pressed.connect(func() -> void:
		draw_called[0] = true
	)

	var draw_btn: Button = win.draw_button
	if draw_btn != null:
		draw_btn.pressed.emit()
		_record(draw_called[0], "Draw emits draw_pressed")
	else:
		_record(false, "Draw emits draw_pressed")

	var closed_called: Array[bool] = [false]
	win.closed.connect(func() -> void:
		closed_called[0] = true
	)

	var close_btn: Button = win.close_button
	if close_btn != null:
		close_btn.pressed.emit()
		_record(closed_called[0] and not win.visible, "Close emits closed and hides")
	else:
		_record(false, "Close emits closed and hides")

	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	win.queue_free()
	quit(1 if _failed > 0 else 0)
