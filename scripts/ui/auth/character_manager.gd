class_name CharacterManager
extends RefCounted

## Manages persistent player character slots for the Wonderland Online client.
## Stored in user://characters.json.
## Supports up to 4 character slots (0..3).

const STORAGE_PATH: String = "user://characters.json"
const MAX_SLOTS: int = 4

static func get_all_data() -> Dictionary:
	if not FileAccess.file_exists(STORAGE_PATH):
		return {}

	var file := FileAccess.open(STORAGE_PATH, FileAccess.READ)
	if not file:
		return {}

	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}

	var data = json.data
	return data if data is Dictionary else {}

static func get_characters(account_name: String = "") -> Dictionary:
	var key := account_name.strip_edges().to_lower()
	if key.is_empty():
		key = "default"

	var all_data := get_all_data()
	if all_data.has(key) and all_data[key] is Dictionary:
		return all_data[key].duplicate(true)

	# Return empty dictionary or initialize slots
	return {}

static func get_character(slot_index: int, account_name: String = "") -> Dictionary:
	return get_character_in_slot(slot_index, account_name)

static func get_character_in_slot(slot_index: int, account_name: String = "") -> Dictionary:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return {}

	var chars := get_characters(account_name)
	var slot_key := str(slot_index)
	if chars.has(slot_key) and chars[slot_key] is Dictionary:
		return chars[slot_key].duplicate(true)

	return {}

static func save_character(slot_index: int, char_data: Dictionary, account_name: String = "") -> bool:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		push_error("[CharacterManager] Invalid slot index: %d" % slot_index)
		return false

	var key := account_name.strip_edges().to_lower()
	if key.is_empty():
		key = "default"

	var all_data := get_all_data()
	if not all_data.has(key) or not (all_data[key] is Dictionary):
		all_data[key] = {}

	var slot_key := str(slot_index)
	var to_save := char_data.duplicate(true)
	to_save["slot_index"] = slot_index
	to_save["updated_at"] = Time.get_unix_time_from_system()

	all_data[key][slot_key] = to_save

	var file := FileAccess.open(STORAGE_PATH, FileAccess.WRITE)
	if not file:
		push_error("[CharacterManager] Failed to open characters.json for writing.")
		return false

	file.store_string(JSON.stringify(all_data, "\t"))
	return true

static func delete_character(slot_index: int, account_name: String = "") -> bool:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return false

	var key := account_name.strip_edges().to_lower()
	if key.is_empty():
		key = "default"

	var all_data := get_all_data()
	if not all_data.has(key) or not (all_data[key] is Dictionary):
		return false

	var slot_key := str(slot_index)
	if all_data[key].has(slot_key):
		all_data[key].erase(slot_key)
		var file := FileAccess.open(STORAGE_PATH, FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(all_data, "\t"))
			return true

	return false

static func create_default_character(
	slot_index: int,
	role_id: int,
	char_name: String,
	element: String = "Fire",
	str_stat: int = 10,
	con_stat: int = 10,
	int_stat: int = 10,
	wis_stat: int = 10,
	agi_stat: int = 10
) -> Dictionary:
	var role_name := "Adventurer"
	var db := Engine.get_singleton("GameDatabase") if Engine.has_singleton("GameDatabase") else null
	if not db:
		db = (Engine.get_main_loop() as SceneTree).root.get_node_or_null("GameDatabase") if (Engine.get_main_loop() is SceneTree) else null

	if db and db.has_method("get_role_name"):
		var rn = db.get_role_name(role_id)
		if not rn.is_empty():
			role_name = rn

	var hp_base: int = 150 + con_stat * 4
	var sp_base: int = 100 + wis_stat * 3

	return {
		"slot_index": slot_index,
		"name": char_name.strip_edges(),
		"role_id": role_id,
		"role_name": role_name,
		"element": element,
		"level": 1,
		"exp": 0,
		"hp": hp_base,
		"max_hp": hp_base,
		"sp": sp_base,
		"max_sp": sp_base,
		"str": str_stat,
		"con": con_stat,
		"int": int_stat,
		"wis": wis_stat,
		"agi": agi_stat,
		"reborn": false,
		"created_at": Time.get_unix_time_from_system()
	}

static func clear_all_characters(account_name: String = "") -> void:
	var key := account_name.strip_edges().to_lower()
	if key.is_empty():
		key = "default"

	var all_data := get_all_data()
	if all_data.has(key):
		all_data[key] = {}
		var file := FileAccess.open(STORAGE_PATH, FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(all_data, "\t"))
