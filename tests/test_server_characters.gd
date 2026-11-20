extends SceneTree

## The server's character list becomes local character records; checked against a live capture.

const LIVE_LIST := [63, 1, 1, 9, 67, 108, 111, 110, 101, 84, 101, 115, 116, 1, 3, 201, 0, 0, 0, 201, 0, 0, 0, 121, 0, 0, 0, 121, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

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
	print("--- Server Characters Suite ---")
	await process_frame
	var payload := PackedByteArray(LIVE_LIST)
	var chars := NetworkManager.parse_character_list(payload)
	_record(chars.size() == 1 and chars[0].name == "CloneTest" and chars[0].level == 1, "the live list parses one character")
	_record(chars[0].element == 3 and chars[0].element_name == "Fire", "element 3 reads as Fire, as the server's Affinity")
	_record(NetworkManager.element_id_to_name(1) == "Earth" and NetworkManager.element_id_to_name(2) == "Water" and NetworkManager.element_id_to_name(4) == "Wind", "the element codes match the server's Affinity")

	var local := ServerCharacters.to_local(chars[0])
	_record(local.slot_index == 0 and local.name == "CloneTest" and local.element == "Fire", "server slot 1 becomes local slot 0 with name and element")
	_record(local.hp == 201 and local.max_hp == 201 and local.sp == 121 and local.exp == 6 and local.gold == 0, "vitals, exp and gold come from the list")
	_record(local.role_id == 1 and local.server == true, "the body becomes the role id and the record is marked as server-owned")
	_record(local.str == 10 and local.agi == 10, "attributes default to 10 when no local record exists")
	var merged := ServerCharacters.to_local(chars[0], {"str": 15, "deletion_code_hash": "abc", "role_name": "Daniel"})
	_record(merged.str == 15 and merged.deletion_code_hash == "abc" and merged.role_name == "Daniel", "attributes, hash and role name keep the local record's values")

	var account := "servercharstest"
	CharacterManager.clear_all_characters(account)
	CharacterManager.save_character(1, {"slot_index": 1, "name": "OldLocal"}, account)
	var saved := ServerCharacters.apply_list(payload, account)
	_record(saved == 1, "apply_list saves the server's character")
	_record(CharacterManager.get_character_in_slot(0, account).get("name", "") == "CloneTest", "the server character is in local slot 0")
	_record(CharacterManager.get_character_in_slot(1, account).is_empty(), "a local-only character absent on the server is removed")
	CharacterManager.clear_all_characters(account)
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
