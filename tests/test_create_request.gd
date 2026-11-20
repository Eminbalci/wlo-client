extends SceneTree

## The server create packet built from a locally created character.

const CreateRequest = preload("res://scripts/network/create_request.gd")

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
	print("--- Create Request Suite ---")
	await process_frame
	_record(CreateRequest.element_code("Fire") == 3 and CreateRequest.element_code("wind") == 4 and CreateRequest.element_code("EARTH") == 1, "element names map to the server codes")
	_record(CreateRequest.element_code("nonsense") == 3, "an unknown element falls back to Fire")
	_record(CreateRequest.server_slot(0) == 1 and CreateRequest.server_slot(1) == 2 and CreateRequest.server_slot(9) == 2, "local slots map to server slots 1..2")
	var data := {"slot_index": 1, "name": "Hero", "role_id": 2, "element": "Water", "str": 5, "con": 6, "int": 7, "wis": 8, "agi": 9, "deletion_code_hash": "f".repeat(64)}
	var p := CreateRequest.payload_from_character(data)
	_record(p[0] == 0x3F and p[1] == 0x03 and p[2] == 2, "the header and server slot are set")
	_record(p[3] == 4 and p.slice(4, 8).get_string_from_ascii() == "Hero", "the name is length-prefixed")
	_record(p[8] == 2 and p[9] == 2, "role and element code follow the name")
	_record(p.slice(10, 15) == PackedByteArray([5, 6, 7, 8, 9]), "the five stats follow in STR CON INT WIS AGI order")
	_record(p[15] == 64 and p.size() == 16 + 64, "the deletion hash is appended as a trailing string")
	var no_hash := CreateRequest.payload_from_character({"slot_index": 0, "name": "Hero"})
	_record(no_hash.size() == 15, "no hash leaves the original packet size")
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
