class_name SaveGame
extends RefCounted

const SAVE_DIR := "user://saves"
const SLOT_COUNT := 5
const VERSION := 1


static func slot_path(slot: int) -> String:
	return SAVE_DIR + "/slot_" + str(slot) + ".json"


static func has_slot(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


static func write_slot(slot: int, snapshot: Dictionary) -> bool:
	var global_dir := ProjectSettings.globalize_path(SAVE_DIR)
	if not DirAccess.dir_exists_absolute(global_dir):
		DirAccess.make_dir_recursive_absolute(global_dir)

	var copy: Dictionary = snapshot.duplicate(true)
	copy["version"] = VERSION
	copy["saved_at"] = int(Time.get_unix_time_from_system())

	var path := slot_path(slot)
	var tmp_path := path + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_warning("SaveGame: failed to open temporary save file at " + tmp_path)
		return false

	file.store_string(JSON.stringify(copy, "\t"))
	file.close()

	var global_path := ProjectSettings.globalize_path(path)
	var global_tmp := ProjectSettings.globalize_path(tmp_path)

	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(global_path)

	var err := DirAccess.rename_absolute(global_tmp, global_path)
	return err == OK


static func read_slot(slot: int) -> Dictionary:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var content := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(content)
	if not (parsed is Dictionary):
		return {}

	var data: Dictionary = parsed
	if data.get("version", -1) != VERSION:
		return {}

	return data


static func delete_slot(slot: int) -> bool:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return true

	var err := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return err == OK


static func slot_summary(slot: int) -> Dictionary:
	var data := read_slot(slot)
	if data.is_empty():
		return {}

	return {
		"name": str(data.get("name", "")),
		"level": int(data.get("level", 1)),
		"map_id": int(data.get("map_id", 0)),
		"saved_at": int(data.get("saved_at", 0))
	}


static func vec_to_array(v: Vector2) -> Array:
	return [v.x, v.y]


static func array_to_vec(a: Variant) -> Vector2:
	if a is Array and (a as Array).size() >= 2:
		return Vector2(float(a[0]), float(a[1]))
	return Vector2.ZERO
