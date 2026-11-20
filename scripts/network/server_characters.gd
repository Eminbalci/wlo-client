class_name ServerCharacters
extends RefCounted

## Turns the server's character list (AC63:1) into the local character records that the select
## screen and the world scene read (CharacterManager format). Server slots are 1..2, local 0..1.
## The list carries no attribute points, so str/con/int/wis/agi keep the local record's values when
## one exists and default to 10 otherwise. The record is marked "server": true.

static func to_local(server_char: Dictionary, existing: Dictionary = {}) -> Dictionary:
	var role_id := int(server_char.get("body", 1))
	var record := {
		"slot_index": clampi(int(server_char.get("slot", 1)) - 1, 0, 1),
		"name": str(server_char.get("name", "")),
		"role_id": role_id,
		"role_name": str(existing.get("role_name", "Adventurer")),
		"element": str(server_char.get("element_name", "Fire")),
		"level": int(server_char.get("level", 1)),
		"exp": int(server_char.get("total_exp", 0)),
		"hp": int(server_char.get("cur_hp", 1)),
		"max_hp": int(server_char.get("full_hp", 1)),
		"sp": int(server_char.get("cur_sp", 1)),
		"max_sp": int(server_char.get("full_sp", 1)),
		"gold": int(server_char.get("gold", 0)),
		"head": int(server_char.get("head", 1)),
		"str": int(existing.get("str", 10)),
		"con": int(existing.get("con", 10)),
		"int": int(existing.get("int", 10)),
		"wis": int(existing.get("wis", 10)),
		"agi": int(existing.get("agi", 10)),
		"reborn": bool(existing.get("reborn", false)),
		"server": true,
	}
	for key in ["deletion_code_hash", "first_name", "family_name", "hair_style", "hair_color", "skin_tone", "created_at"]:
		if existing.has(key):
			record[key] = existing[key]
	return record


## Replaces the account's local characters with the server's list. Returns the number saved.
static func apply_list(payload: PackedByteArray, account: String) -> int:
	var chars := NetworkManager.parse_character_list(payload)
	var previous := {}
	for slot in [0, 1]:
		previous[slot] = CharacterManager.get_character_in_slot(slot, account)
	CharacterManager.clear_all_characters(account)
	for c in chars:
		var local_slot := clampi(int(c.get("slot", 1)) - 1, 0, 1)
		var record := to_local(c, previous.get(local_slot, {}))
		CharacterManager.save_character(local_slot, record, account)
	return chars.size()
