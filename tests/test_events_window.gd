extends SceneTree

## Events / Activities window verification suite.

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
	print("--- Events Window Suite ---")
	await process_frame
	await process_frame

	var win := EventsWindow.new()
	root.add_child(win)
	await process_frame

	_record(win != null, "EventsWindow instantiates")

	var sample_events: Array = [
		{"name": "Trial of Beasts", "start": "10:00", "end": "11:00", "status": "Open"},
		{"name": "Dragon Ridge Race", "start": "14:00", "end": "15:00", "status": "Upcoming"}
	]
	win.set_events(sample_events)

	var row0_label: Label = win.find_child("Cell_0_0", true, false)
	var row1_label: Label = win.find_child("Cell_1_0", true, false)
	var names_shown: bool = (
		row0_label != null and row0_label.text == "Trial of Beasts"
		and row1_label != null and row1_label.text == "Dragon Ridge Race"
	)
	_record(names_shown, "set_events with 2 rows shows both names in the table")

	win.open()
	_record(win.visible, "open() makes it visible")

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

	var teleport_called: Array[bool] = [false]
	win.teleport_pressed.connect(func() -> void:
		teleport_called[0] = true
	)

	var teleport_btn: Button = win.teleport_button
	if teleport_btn != null:
		teleport_btn.pressed.emit()
		_record(teleport_called[0], "Teleport emits teleport_pressed")
	else:
		_record(false, "Teleport emits teleport_pressed")

	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	win.queue_free()
	quit(1 if _failed > 0 else 0)
