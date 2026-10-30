extends SceneTree

## Headless checks for WorldMapWindow (TGlobaForm 0x13f5d8 / TMagicMap 0x22193c).

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
	call_deferred("_run")

func _run() -> void:
	var win: WorldMapWindow = load("res://scenes/ui/hud/world_map_window.tscn").instantiate()
	root.add_child(win)
	await process_frame
	_check(win.size == Vector2(667, 538), "form 667x538")
	_check(win.position == Vector2(30, 30), "form at (30,30)")
	_check(win.background.texture != null and win.background.texture.get_size() == Vector2(667, 538), "GlobaMap texture 667x538")
	_check(win.close_button.position == Vector2(647, 3) and win.close_button.size == Vector2(18, 18), "close at (W-20,3) 18x18")
	_check(win.close_button.texture_normal != null, "close sprite loaded")
	_check(win.markers.size() == 41, "41 GlobaBtn markers, got %d" % win.markers.size())
	var china: Dictionary = win.find_location("China")
	_check(china.get("pixel") == Vector2(434, 144), "China (6900,3050) -> (434,144), got %s" % str(china.get("pixel")))
	_check(win.markers[0].position == Vector2(434, 144) and win.markers[0].size == Vector2(18, 17), "marker 1 rect")
	_check(win.markers[0].tooltip_text == "China (6900,3050)", "hint text China")
	var rome: Dictionary = win.find_location("Rome")
	_check(rome.hint == "Rome (Med. Sea2635,2242)", "Med. Sea hint verbatim: %s" % rome.hint)
	_check(win.markers[0].texture_normal != null and win.markers[0].texture_hover != null, "marker frames loaded")
	var got: Array = []
	win.location_selected.connect(func(_i, loc): got.append(loc.name))
	win.markers[1].pressed.emit()
	_check(got == ["Calcutta"], "marker click emits location_selected")
	win.set_magic_map_mode(true)
	await process_frame
	_check(win.markers.size() == 40 and win.find_location("Chang'an").size() > 0, "magic map table 40 points")
	var tp: Array = []
	win.teleport_requested.connect(func(i, _loc): tp.append(i))
	win.markers[0].pressed.emit()
	_check(tp == [1], "magic map emits teleport_requested")
	var closed := [false]
	win.window_closed.connect(func(): closed[0] = true)
	win.close_button.pressed.emit()
	_check(not win.visible and closed[0], "close hides and emits")
	win.open()
	_check(win.visible, "open shows")
	_finish()
