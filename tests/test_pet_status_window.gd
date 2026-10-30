extends SceneTree

## Headless checks for PetStatusWindow (Form_PetStatus, aLogin.exe 0x327a20 / 0x327d9c / 0x327f50).

const PetStatusScene = preload("res://scenes/ui/hud/pet_status_window.tscn")

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
	var win: PetStatusWindow = PetStatusScene.instantiate()
	root.add_child(win)
	await process_frame
	_check(win.size == Vector2(49, 65), "window is 49x65 (Form_PetStatus.bmp)")
	var bg := win.get_node("Background") as TextureRect
	_check(bg.texture != null and bg.texture.get_size() == Vector2(49, 65), "background skin loaded")
	var expected := {"BtnRest": Vector2(3, 3), "BtnBattle": Vector2(3, 22), "BtnRide": Vector2(3, 42)}
	for n in expected:
		var b := win.get_node_or_null(n) as Button
		_check(b != null and b.position == expected[n] and b.size == Vector2(43, 20), "%s at %s, 43x20" % [n, expected[n]])
		_check(b != null and b.get_theme_stylebox("normal") is StyleBoxTexture, "%s uses the sliced skin" % n)
	_check(PetStatusWindow.popup_position(Vector2(100, 50), 1) == Vector2(344, 62), "slot 1 anchored at team + (244, 77-65)")
	_check(PetStatusWindow.popup_position(Vector2(100, 50), 3) == Vector2(344, 130), "row pitch 34")

	var got: Array = []
	win.pet_mode_selected.connect(func(slot: int, mode: int, pet: Dictionary) -> void: got.append([slot, mode, pet.get("name", "")]))
	var closed: Array = [0]
	win.window_closed.connect(func() -> void: closed[0] += 1)
	var pet := {"id": 8090, "name": "Roca"}
	win.open_at(Vector2(100, 50), 2, pet)
	_check(win.visible and win.position == Vector2(344, 96), "open_at shows the popup beside row 2")
	(win.get_node("BtnBattle") as Button).pressed.emit()
	_check(got.size() == 1 and got[0] == [2, PetStatusWindow.MODE_BATTLE, "Roca"], "Battle emits (slot 2, mode 1)")
	_check(not win.visible and closed[0] == 1, "popup hides after a choice")
	_check(PetStatusWindow.team_action_for_mode(PetStatusWindow.MODE_REST) == "dismiss", "Rest maps to team dismiss")
	_check(PetStatusWindow.team_action_for_mode(PetStatusWindow.MODE_RIDE) == "ride", "Ride maps to team ride")

	var refused: Array = []
	win.action_refused.connect(func(m: String) -> void: refused.append(m))
	win.populate(1, pet, false, true)
	win.open_window()
	_check(not win.choose_mode(PetStatusWindow.MODE_RIDE) and refused == [PetStatusWindow.MSG_CANT_MOUNT], "mount block refuses Ride")
	win.populate(1, pet, true)
	_check(not win.choose_mode(PetStatusWindow.MODE_REST) and refused.back() == PetStatusWindow.MSG_IN_TRAINING, "training refuses")
	_check(got.size() == 1, "refusals emit no mode")

	print("SUMMARY: %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)
