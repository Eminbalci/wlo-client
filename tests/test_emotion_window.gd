extends SceneTree

## Headless checks for EmotionWindow (chat emote panel built in 0x27d58c).

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
	var win: EmotionWindow = load("res://scenes/ui/hud/emotion_window.tscn").instantiate()
	root.add_child(win)
	await process_frame
	_check(win.size == Vector2(263, 69), "panel 263x69")
	_check(win.background.texture != null and win.background.texture.get_size() == Vector2(263, 69), "panel_expression_1 texture")
	_check(win.icons.size() == 31, "31 emote icons")
	_check(win.icons[0].position == Vector2(8, 7), "icon 1 (8,7)")
	_check(win.icons[9].position == Vector2(215, 7), "icon 10 (215,7)")
	_check(win.icons[10].position == Vector2(8, 27), "icon 11 (8,27)")
	_check(win.icons[29].position == Vector2(215, 47), "icon 30 (215,47)")
	_check(win.icons[30].position == Vector2(238, 47), "icon 31 (238,47)")
	_check(win.icons[0].size == Vector2(16, 16) and win.icons[0].texture_normal != null and win.icons[0].texture_hover != null, "icon frames")
	_check(win.icons[0].tooltip_text == "@|Arrogant" and win.icons[30].tooltip_text == "-PNod", "hints")
	_check(win.close_button.position == Vector2(241, 3) and win.close_button.size == Vector2(18, 18), "close (241,3)")
	win.open(Vector2(0, 500))
	_check(win.position == Vector2(492, 431), "placed at chat bar + (492,-69)")
	var codes: Array = []
	win.emote_selected.connect(func(c): codes.append(c))
	win.icons[6].pressed.emit()
	_check(codes == ["#07"] and not win.visible, "click emits #07 and closes")
	win.open()
	win.select_emote(31)
	_check(codes[-1] == "#31", "emote 31 code")
	win.toggle()
	win.toggle()
	_check(not win.visible, "toggle closes")
	_finish()
