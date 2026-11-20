extends SceneTree

## The login screen applies the server's character list (live capture) and moves to character select.

const LoginScreenScene = preload("res://scenes/ui/login_screen.tscn")
const LIVE_LIST := [63, 1, 1, 9, 67, 108, 111, 110, 101, 84, 101, 115, 116, 1, 3, 201, 0, 0, 0, 201, 0, 0, 0, 121, 0, 0, 0, 121, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
const ACCOUNT := "loginlisttest"

var _checks := 0
var _failed := 0


func _init() -> void:
	_run()


func _record(ok: bool, label: String) -> void:
	_checks += 1
	print(("  [PASS] " if ok else "  [FAIL] ") + label)
	if not ok:
		_failed += 1


func _run() -> void:
	print("--- Login Screen Server List Suite ---")
	await process_frame
	CharacterManager.clear_all_characters(ACCOUNT)
	var screen = LoginScreenScene.instantiate()
	root.add_child(screen)
	for i in range(10):
		await process_frame
	screen.current_account = ACCOUNT
	screen.goto_state(screen.FlowState.LOGIN_DIALOG)
	screen._on_packet_received(63, PackedByteArray([63, 2, 19, 39, 0, 0]))
	_record(screen.current_state == screen.FlowState.LOGIN_DIALOG, "a login-OK packet does not read as a failed login or change the screen")
	screen._on_packet_received(63, PackedByteArray(LIVE_LIST))
	_record(screen.current_state == screen.FlowState.CHARACTER_SELECT, "the server list moves the screen to character select")
	var c0: Dictionary = CharacterManager.get_character_in_slot(0, ACCOUNT)
	_record(c0.get("name", "") == "CloneTest" and c0.get("server", false) == true and c0.get("element", "") == "Fire", "the server character is saved locally with its element")
	_record(CharacterManager.get_characters(ACCOUNT).size() == 1, "no starter sample is seeded online")
	CharacterManager.clear_all_characters(ACCOUNT)
	screen.queue_free()
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
