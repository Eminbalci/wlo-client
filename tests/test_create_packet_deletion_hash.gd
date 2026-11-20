extends SceneTree

## The create packet carries an optional trailing deletion-code hash; without it the bytes are unchanged.

const NetworkManagerScript = preload("res://scripts/network/network_manager.gd")

var _checks := 0
var _failed := 0


func _record(ok: bool, label: String) -> void:
	_checks += 1
	print(("  [PASS] " if ok else "  [FAIL] ") + label)
	if not ok:
		_failed += 1


func _init() -> void:
	_run()


func _run() -> void:
	print("--- Create Packet Deletion Hash Suite ---")
	await process_frame
	var base := NetworkManagerScript.build_create_payload(1, "Hero", 1, 3, 1, 2, 3, 4, 5, "")
	_record(base.size() == 3 + 1 + 4 + 7 and base[0] == 0x3F and base[1] == 0x03, "without a hash the create payload keeps its original size")
	var h := "a".repeat(64)
	var with_hash := NetworkManagerScript.build_create_payload(1, "Hero", 1, 3, 1, 2, 3, 4, 5, h)
	_record(with_hash.size() == base.size() + 1 + 64, "the hash is appended as a length-prefixed string")
	_record(with_hash[with_hash.size() - 65] == 64, "the length byte precedes the hash")
	var del := NetworkManagerScript.build_delete_payload(2, "secret1")
	_record(del == PackedByteArray([35, 2, 2, 0, 7, 115, 101, 99, 114, 101, 116, 49]), "the delete request is AC35:2 with the slot, an empty string and the code")
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
