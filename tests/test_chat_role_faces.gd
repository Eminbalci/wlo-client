extends SceneTree

## The chat line shows the sender's face: an explicit role id wins, otherwise a stable pick from the name.

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
	print("--- Chat Role Faces Suite ---")
	var hud: Control = (load("res://scenes/ui/hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	await process_frame
	await process_frame
	var NetworkManagerScript = load("res://scripts/network/network_manager.gd")
	var payload := PackedByteArray([0x23, 0x0C, 3, 1, 0, 0, 0])
	payload.append_array("hello".to_ascii_buffer())
	var parsed: Dictionary = NetworkManagerScript.unpack_chat_broadcast(payload)
	_check(parsed.has("role_id") and int(parsed["role_id"]) == 0, "The unpacked chat dictionary carries a role_id (0 = unknown)")

	hud.add_chat_message("Zed", "known role", "World", 3)
	var line: String = hud.chat_ctrl._chat_messages.back()["face"]
	_check(line.contains("avatar_role_3_0.png"), "An explicit role id picks that role's face")
	hud.add_chat_message("Zed", "same sender unknown role", "World")
	var line_a: String = hud.chat_ctrl._chat_messages.back()["face"]
	hud.add_chat_message("Zed", "again", "World")
	var line_b: String = hud.chat_ctrl._chat_messages.back()["face"]
	var face_a: String = line_a
	var face_b: String = line_b
	_check(face_a == face_b and face_a.contains("avatar_role_"), "Without a role the same name always gets the same face")
	hud.add_chat_message("System", "no face here", "System")
	_check(str(hud.chat_ctrl._chat_messages.back()["face"]) == "", "System lines have no face")

	print("\n--- %d TESTS, %d FAILED ---" % [_count, _failures])
	quit(1 if _failures > 0 else 0)
