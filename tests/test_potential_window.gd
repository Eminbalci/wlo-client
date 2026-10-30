extends SceneTree

## Headless checks for PotentialWindow (Form_Potential_1 0x1e4d48 / Form_Potential_2 0x1e7b48).

const PotentialScene = preload("res://scenes/ui/hud/potential_window.tscn")

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


class FakeStatus:
	extends RefCounted
	var current_name: String = "Daniel"
	var current_level: int = 10
	var current_potential: int = 3
	var current_str: int = 10
	var current_con: int = 11
	var current_int: int = 6
	var current_wis: int = 7
	var current_agi: int = 18


class FakeTeam:
	extends RefCounted
	func _pet_entries() -> Array[Dictionary]:
		return [{"name": "Roca", "level": 12}, {"name": "Kelang", "level": 15, "potential": 12}]


func _run() -> void:
	var win: PotentialWindow = PotentialScene.instantiate()
	root.add_child(win)
	await process_frame
	_check(win.size == Vector2(299, 520), "awaken window 299x520")
	var bg := win.get_node("Background") as TextureRect
	_check(bg.texture != null and bg.texture.get_size() == Vector2(299, 520), "Form_Potential_1 skin")
	_check(bg.texture.get_image().get_pixel(0, 0).a == 0.0, "chroma key removed (corner transparent)")
	_check(win.close_button.position == Vector2(249, 26) and win.close_button.size == Vector2(18, 18), "Btn_Close_s_1 at (249,26)")
	_check(win.ok_button.position == Vector2(87, 473) and win.cancel_button.position == Vector2(163, 473), "OK / Cancel at y 473")
	_check(win.row_buttons.size() == 5 and win.row_buttons[4].position == Vector2(32, 214), "5 rows, pitch 34 from (32,78)")
	_check(win.mark_rects.size() == 12 and win.mark_rects[0].position == Vector2(201, 259), "12 potential marks")
	_check(win.item_slot.position == Vector2(56, 366), "pill slot at (56,366)")
	_check(win.stat_value_labels[0].position == Vector2(60, 274) and win.stat_value_labels[4].position == Vector2(60, 338), "stat values at (60, 274+16i)")

	win.populate_from_game(FakeStatus.new(), FakeTeam.new())
	_check(win.entries.size() == 3, "player + 2 pets")
	_check(win.row_name_labels[0].text == "Daniel" and win.row_level_labels[0].text == "10", "player row name / level")
	_check(win.row_potential_labels[0].text == "3" and win.row_max_labels[0].text == "/12", "potential N/12")
	_check(win.stat_value_labels[1].text == "11", "CON from character status")
	var lit := 0
	for m in win.mark_rects:
		lit += 1 if m.visible else 0
	_check(lit == 3, "3 marks lit for potential 3")
	_check(win.row_buttons[3].disabled, "empty row disabled")

	var confirmed: Array = []
	var refused: Array = []
	win.potential_confirmed.connect(func(m: int, i: int, e: Dictionary) -> void: confirmed.append([m, i, e["name"]]))
	win.action_refused.connect(func(msg: String) -> void: refused.append(msg))
	win.ok_button.pressed.emit()
	_check(confirmed == [[1, 0, "Daniel"]], "OK confirms selected row")
	win.row_buttons[2].pressed.emit()
	_check(win.selected_index == 2, "row click selects")
	win.ok_button.pressed.emit()
	_check(refused == ["Reached max potential"], "max potential refused")

	win.populate(win.entries.duplicate(), {"str": 10}, {"str": 2})
	_check(win.stat_delta_labels[0].text == "+2" and win.stat_delta_labels[0].position.x == 86.0, "+N delta at x 86")

	win.set_mode(PotentialWindow.MODE_RETURN)
	win.populate([{"name": "Daniel", "level": 10, "potential": 0}, {"name": "Roca", "level": 12, "potential": 4}], {"str": 9}, {"str": 4})
	_check(win.size == Vector2(299, 460), "return window 299x460")
	_check(win.ok_button.position == Vector2(87, 414) and win.row_buttons.size() == 4, "return: buttons y 414, 4 rows")
	_check(win.mark_rects[0].position == Vector2(207, 221) and win.item_slot.position == Vector2(74, 328), "return marks / slot")
	_check(win.stat_value_labels[0].position == Vector2(66, 236) and win.stat_delta_labels[0].text == "-4", "return stats and -N")
	win.select_row(0)
	win.ok_button.pressed.emit()
	_check(refused.back() == "No potential on this", "return refuses potential 0")

	var closed: Array = [0]
	win.window_closed.connect(func() -> void: closed[0] += 1)
	win.open_window()
	win.cancel_button.pressed.emit()
	_check(not win.visible and closed[0] == 1, "Cancel closes and signals")
	win.open_window()
	win.close_button.pressed.emit()
	_check(not win.visible and closed[0] == 2, "close sphere closes")

	print("SUMMARY: %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)
