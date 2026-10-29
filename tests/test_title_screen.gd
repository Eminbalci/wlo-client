extends SceneTree

## The title screen builds Single Player / Multiplayer / Quit and points each to its scene.

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
	print("--- Title Screen Suite ---")
	var packed := load("res://scenes/ui/title_screen.tscn") as PackedScene
	_record(packed != null, "title_screen.tscn loads")
	var screen: Control = packed.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame

	_record(screen.get("single_player_button") != null, "Single Player button exists")
	_record(screen.get("multiplayer_button") != null, "Multiplayer button exists")
	if screen.get("single_player_button") != null:
		_record(screen.single_player_button.text == "SINGLE PLAYER", "Single Player label")
		_record(screen.multiplayer_button.text == "MULTIPLAYER", "Multiplayer label")
	_record(screen.SINGLE_PLAYER_SCENE == "res://scenes/ui/single_player_slots.tscn", "Single Player targets the slot screen")
	_record(screen.MULTIPLAYER_SCENE == "res://scenes/ui/login_screen.tscn", "Multiplayer targets the login screen")
	_record(ResourceLoader.exists(screen.MULTIPLAYER_SCENE), "Multiplayer target scene exists")
	_record(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/ui/title_screen.tscn", "Title is the main scene")

	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
