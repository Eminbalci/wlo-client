class_name RideData
extends RefCounted

## Parser and kinematics offset provider for Wonderland Online pet riding mechanics.
## Loads and indexes assets/data/AdjustRidePetPos.txt to provide authentic 8-directional
## mounting offsets (StandPosX/Y, MovePosX/Y) and poses (sit/ride) for player characters.

const ADJUST_RIDE_PATH: String = "res://assets/data/AdjustRidePetPos.txt"

static var _cached_entries: Dictionary = {}
static var _is_initialized: bool = false

## Initializes and parses AdjustRidePetPos.txt into memory
static func ensure_initialized() -> void:
	if _is_initialized:
		return
	_is_initialized = true
	_cached_entries.clear()

	var file_path := ADJUST_RIDE_PATH
	if not FileAccess.file_exists(file_path):
		# Fallback to local disk path if needed
		file_path = "assets/data/AdjustRidePetPos.txt"
		if not FileAccess.file_exists(file_path):
			push_warning("[RideData] AdjustRidePetPos.txt not found at %s" % file_path)
			return

	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_warning("[RideData] Could not open %s" % file_path)
		return

	var text := file.get_as_text()
	file.close()

	_parse_adjust_ride_text(text)

static func _parse_adjust_ride_text(text: String) -> void:
	var sections := text.split("NpcPic=")
	for i in range(1, sections.size()):
		var section := sections[i]
		var lines := section.split("\n")
		if lines.is_empty():
			continue

		var pic_id_str := lines[0].strip_edges()
		if pic_id_str.is_empty():
			continue
		var pic_id: int = pic_id_str.to_int()

		var entry := {
			"pic_id": pic_id,
			"pose": "sit",
			"fixed_pos_on_first": true,
			"sexes": {}
		}

		var cur_sex: String = "1"
		for line_idx in range(1, lines.size()):
			var line := lines[line_idx].strip_edges()
			if line.is_empty() or line.begins_with("//"):
				continue
			if not line.contains("="):
				continue

			var parts := line.split("=", true, 1)
			var k := parts[0].strip_edges()
			var v := parts[1].strip_edges()

			match k:
				"Pose":
					entry["pose"] = v.to_lower()
				"FixedPosOnFirst":
					entry["fixed_pos_on_first"] = v.to_lower() == "true"
				"Sex":
					cur_sex = v
					if not entry["sexes"].has(cur_sex):
						entry["sexes"][cur_sex] = {}
				"StandPosX", "StandPosY", "MovePosX", "MovePosY":
					if not entry["sexes"].has(cur_sex):
						entry["sexes"][cur_sex] = {}
					var arr: Array[int] = []
					for num_str in v.split(","):
						arr.append(num_str.strip_edges().to_int())
					entry["sexes"][cur_sex][k] = arr

		_cached_entries[pic_id] = entry

## Resolves the character sex/body index (1..4) from role_id
static func get_sex_for_role(role_id: int) -> int:
	match role_id:
		1, 3, 5, 7, 11:
			return 1 # Adult Male (Daniel, Sid, etc.)
		2, 4, 9, 10:
			return 2 # Adult Female (Betty, Jessica, etc.)
		13, 14:
			return 3 # Boy (Moritaka, etc.)
		6, 8, 12:
			return 4 # Girl (Nina, etc.)
		_:
			return 1

## Checks whether a pet model or sprite ID has an explicit riding profile
static func has_ride_profile(pic_id: int) -> bool:
	ensure_initialized()
	return _cached_entries.has(pic_id)

## Returns the raw ride specification dictionary for a given NPC model
static func get_ride_spec(pic_id: int) -> Dictionary:
	ensure_initialized()
	if _cached_entries.has(pic_id):
		return _cached_entries[pic_id]
	return {}

## Computes the exact (x, y) sprite offset for the rider atop the mount.
## Positive StandPosY/MovePosY translates to negative Y (drawn above mount ground feet).
static func get_rider_offset(pic_id: int, role_id: int, heading: int, is_moving: bool) -> Vector2:
	ensure_initialized()
	var h: int = posmod(heading, 8)
	var sex_key := str(get_sex_for_role(role_id))

	if _cached_entries.has(pic_id):
		var entry: Dictionary = _cached_entries[pic_id]
		var sexes: Dictionary = entry.get("sexes", {})
		var sex_data: Dictionary = sexes.get(sex_key, sexes.get("1", {}))

		var pos_x_key := "MovePosX" if is_moving else "StandPosX"
		var pos_y_key := "MovePosY" if is_moving else "StandPosY"

		var arr_x: Array = sex_data.get(pos_x_key, [])
		var arr_y: Array = sex_data.get(pos_y_key, [])

		if arr_x.size() > h and arr_y.size() > h:
			var ox: float = float(arr_x[h])
			# In WLO, PosY values are height above mount base, so upward offset is -PosY
			var oy: float = -float(arr_y[h])
			return Vector2(ox, oy)

	# Authentic generic fallback for unlisted rideable pets (e.g. S. Monkey 1103)
	var default_x: Array[float] = [0.0, 3.0, 5.0, 3.0, 0.0, -3.0, -5.0, -3.0]
	var ox: float = default_x[h]
	var oy: float = -32.0 if is_moving else -30.0
	return Vector2(ox, oy)

## Returns the mount speed factor (default 1.35x overland speedup)
static func get_mount_speed(base_speed: float = 120.0) -> float:
	return base_speed * 1.35
