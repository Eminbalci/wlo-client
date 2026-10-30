extends SceneTree

## Headless checks for GpsWindow (TGPSForm 0x13df70).
const G = preload("res://scripts/ui/hud/gps_window.gd")

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("  [PASS] %s" % msg)
	else:
		_failed += 1
		printerr("  [FAIL] %s" % msg)

func _finish() -> void:
	print("SUMMARY: %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _init() -> void:
	if FileAccess.file_exists(G.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(G.SAVE_PATH))
	call_deferred("_run")

func _run() -> void:
	var win: GpsWindow = load("res://scenes/ui/hud/gps_window.tscn").instantiate()
	root.add_child(win)
	await process_frame
	_check(win.size == Vector2(223, 223) and win.position == Vector2(290, 200), "form (290,200) 223x223")
	_check(win.background.texture != null, "Form_GPS texture")
	_check(win.btn_set_point.position == Vector2(82, 120) and win.btn_set_point.size == Vector2(56, 20), "SetPoint (82,120)")
	_check(win.btn_transmi.position == Vector2(82, 145), "Transmi (82,145)")
	_check(win.btn_close.position == Vector2(82, 170), "close_1 (82,170)")
	_check(win.btn_arrow_left.position == Vector2(22, 80) and win.btn_arrow_left.size == Vector2(14, 13), "ArrowL (22,80) 14x13")
	_check(win.btn_arrow_right.position == Vector2(188, 80), "ArrowR (188,80)")
	_check(win.close_button.position == Vector2(173, 25) and win.close_button.size == Vector2(17, 17), "Close_s (173,25) 17x17")
	win.open()
	_check(win.map_label.text == G.EMPTY_TEXT, "empty slot text")
	_check(not win.btn_arrow_left.visible, "arrows hidden for single-slot GPS")
	win.set_current_position(10001, 512, 384, "Test Town")
	var saved: Array = []
	win.point_saved.connect(func(s, _p): saved.append(s))
	win.btn_set_point.pressed.emit()
	_check(saved.is_empty() and win.confirm_label.visible, "first SetPoint asks for confirmation")
	win.btn_set_point.pressed.emit()
	_check(saved == [1], "second press saves slot 1")
	_check(win.map_label.text == "Test Town" and win.x_label.text == "X: 512" and win.y_label.text == "Y: 384", "slot text drawn")
	var tp: Array = []
	win.teleport_requested.connect(func(_s, p): tp.append(int(p.map_id)))
	win.btn_transmi.pressed.emit()
	_check(tp == [10001], "Transmi emits teleport_requested")
	win.open(0x8593)
	_check(win.btn_arrow_left.visible and win.btn_arrow_right.visible, "arrows shown for item 0x8593")
	for i in 6:
		win.step_slot(1)
	_check(win.current_slot == 5, "slot clamps at 5")
	for i in 6:
		win.step_slot(-1)
	_check(win.current_slot == 1, "slot clamps at 1")
	var win2: GpsWindow = G.new()
	root.add_child(win2)
	await process_frame
	_check(int(win2.get_point(1).get("map_id", 0)) == 10001, "slot persisted to user://")
	win.close()
	_check(not win.visible, "close hides")
	_finish()
