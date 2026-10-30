extends SceneTree

## Headless checks for PlayerTitleWindow (Form_PlayerTitle, aLogin.exe 0x2beb38).

const TitleScene = preload("res://scenes/ui/hud/player_title_window.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _check(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("  [PASS] %s" % msg)
	else:
		_failed += 1
		printerr("  [FAIL] %s" % msg)


func _run() -> void:
	var win: PlayerTitleWindow = TitleScene.instantiate()
	root.add_child(win)
	await process_frame
	_check(win.size == Vector2(250, 275) and win.position == Vector2(150, 100), "250x275 at screen (150,100)")
	var bg := win.get_node("Background") as TextureRect
	_check(bg.texture != null and bg.texture.get_image().get_pixel(0, 0).a == 0.0, "keyed Form_PlayerTitle skin")
	_check(win.close_button.position == Vector2(200, 26), "btn_close_s_1 at (200,26)")
	_check(win.apply_buttons.size() == 5 and win.apply_buttons[0].position == Vector2(165, 70) and win.apply_buttons[4].position == Vector2(165, 190), "Apply x5 at (165, 70+30i)")
	_check(win.arrow_left.position == Vector2(85, 219) and win.arrow_right.position == Vector2(144, 219), "arrows at (85|144, 219)")
	_check(win.bottom_close_button.position == Vector2(105, 246), "Btn_Close_2 at (105,246)")
	_check(win.title_defs.size() == 7 and win.title_defs[0]["kind"] == "text" and win.title_defs[1]["kind"] == "pic", "PlayerTitleData.txt: 7 titles, 0 text, 1..6 pic")
	_check(str(win.title_defs[1]["picture"]).ends_with("title_pic_1.png"), "pic title uses title_pic_1.png")

	win.populate([1, 2, 3], 2)
	_check(not win.arrow_left.visible, "arrows hidden with <= 5 titles")
	_check(win.apply_buttons[1].get_meta("skin_prefix") == "btn_apply_2", "applied row shows Btn_Apply2")
	_check(win.apply_buttons[3].visible == false, "rows beyond the list hidden")
	_check(win.picture_rects[0].visible and win.picture_rects[0].texture != null, "title picture drawn")

	var applied: Array = []
	win.title_applied.connect(func(id: int) -> void: applied.append(id))
	win.apply_buttons[0].pressed.emit()
	_check(applied.back() == 1 and win.get_applied_title_id() == 1, "Apply row 1 applies title 1")
	win.apply_buttons[0].pressed.emit()
	_check(applied.back() == 0, "Apply on the applied row clears it")

	win.populate([1, 2, 3, 4, 5, 6], 0)
	_check(win.arrow_left.visible and win.arrow_right.visible and win.page_count() == 2, "6 titles: arrows, 2 pages")
	win.arrow_right.pressed.emit()
	_check(win.page == 2 and win.apply_buttons[0].visible and not win.apply_buttons[1].visible, "page 2 shows one row")
	_check(win.page_digits.get_child_count() == 1 and win.page_digits.get_child(0).position == Vector2(103, 225), "page digit at (103,225)")
	win.apply_buttons[0].pressed.emit()
	_check(applied.back() == 6, "page 2 row 1 = title 6")

	var closed: Array = [0]
	win.window_closed.connect(func() -> void: closed[0] += 1)
	win.bottom_close_button.pressed.emit()
	_check(not win.visible and closed[0] == 1, "Close closes and signals")
	win.toggle_window()
	_check(win.visible, "toggle reopens")

	print("SUMMARY: %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)
