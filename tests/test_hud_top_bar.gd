extends SceneTree

## Top-right action icon row of the real client (Btn_1..Btn_9 skins).

var _count: int = 0
var _failures: int = 0


func _init() -> void:
	_run()


func _check(ok: bool, label: String) -> void:
	_count += 1
	if ok:
		print("  [PASS] ", label)
	else:
		_failures += 1
		print("  [FAIL] ", label)


func _run() -> void:
	print("--- HUD Top Action Bar Suite ---")
	var hud: Control = (load("res://scenes/ui/hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	await process_frame
	await process_frame
	var bar = hud.top_action_bar
	_check(bar != null, "HUD builds the top action bar")
	_check(bar.buttons.size() == 10, "Ten icons are shown")
	var textured := true
	for btn in bar.buttons:
		textured = textured and btn.texture_normal != null and btn.texture_hover != null and btn.texture_pressed != null
		textured = textured and btn.size.x >= 36.0 and btn.size.y >= 33.0 and btn.size.y <= 36.0
	_check(textured, "Every icon has its three frames")
	var first: TextureButton = bar.buttons[1]
	_check(first.texture_normal.get_image().get_pixel(0, 0).a == 0.0, "The skin's green chroma key is transparent")
	_check(hud.get_node("RadarMinimapDock").offset_top == 40.0, "The minimap sits below the icon row")

	var team_before: bool = hud.window_manager_ctrl.team_window.visible
	bar.buttons[4].pressed.emit()
	_check(hud.window_manager_ctrl.team_window.visible != team_before, "The two-figure icon toggles the team window")
	bar.buttons[4].pressed.emit()

	var fight_before: bool = hud.window_manager_ctrl.fight_window.visible
	bar.buttons[1].pressed.emit()
	_check(hud.window_manager_ctrl.fight_window.visible != fight_before, "The crossed-swords icon toggles the battle settings window")
	bar.buttons[1].pressed.emit()

	var messages_before: int = hud.chat_ctrl._chat_messages.size()
	bar.buttons[5].pressed.emit()
	_check(hud.chat_ctrl._chat_messages.size() > messages_before, "An icon without a system yet explains that in chat")

	print("\n--- %d TESTS, %d FAILED ---" % [_count, _failures])
	quit(1 if _failures > 0 else 0)
