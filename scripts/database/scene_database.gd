class_name SceneDatabase
extends RefCounted

## Decodes and caches the 131-byte scene binary records from SceneData.dat or authoritative all_scenes.json.
## Resolves map IDs, reversed scene names, and background music IDs.

class SceneRecord:
	var map_id: int = 0
	var name: String = ""
	var bgm_name: String = ""
	var bgm_id: int = 0

	func _init(p_id: int = 0, p_name: String = "", p_bgm: String = "", p_bgm_id: int = 0) -> void:
		map_id = p_id
		name = p_name
		bgm_name = p_bgm
		bgm_id = p_bgm_id

var _scenes: Dictionary = {} # int (map_id) -> SceneRecord

static func decode_scene_id(raw_word: int) -> int:
	return ((raw_word ^ 0xea6c) - 9) & 0xffff

static func clean_ascii(bytes: PackedByteArray) -> String:
	var nul_idx := bytes.find(0)
	if nul_idx != -1:
		bytes = bytes.slice(0, nul_idx)
	var filtered := PackedByteArray()
	for b in bytes:
		if (b >= 32 and b <= 126) or b > 127:
			filtered.append(b)
	if filtered.is_empty():
		return ""
	return filtered.get_string_from_ascii().strip_edges()

func load_from_json(json_path: String) -> bool:
	if not FileAccess.file_exists(json_path):
		return false
	var file := FileAccess.open(json_path, FileAccess.READ)
	if not file:
		return false
	var content := file.get_as_text()
	var parsed = JSON.parse_string(content)
	if parsed == null or not (parsed is Dictionary or parsed is Array):
		return false
	
	_scenes.clear()
	if parsed is Dictionary:
		for k in parsed.keys():
			var entry: Dictionary = parsed[k]
			var mid: int = int(entry.get("map_id", int(k)))
			var sname: String = entry.get("name", "Map_%d" % mid)
			var sbgm: String = entry.get("bgm_name", "")
			var sbgm_id: int = int(entry.get("bgm_id", 0))
			_scenes[mid] = SceneRecord.new(mid, sname, sbgm, sbgm_id)
	elif parsed is Array:
		for entry in parsed:
			if entry is Dictionary:
				var mid: int = int(entry.get("map_id", 0))
				var sname: String = entry.get("name", "Map_%d" % mid)
				var sbgm: String = entry.get("bgm_name", "")
				var sbgm_id: int = int(entry.get("bgm_id", 0))
				_scenes[mid] = SceneRecord.new(mid, sname, sbgm, sbgm_id)
	
	return not _scenes.is_empty()

func load_from_file(file_path: String) -> bool:
	# Try pre-extracted authoritative JSON first if available
	var json_alt := "res://assets/data/all_scenes.json"
	if file_path.ends_with(".json"):
		return load_from_json(file_path)
	elif FileAccess.file_exists(json_alt):
		if load_from_json(json_alt):
			return true
	
	if not FileAccess.file_exists(file_path):
		push_error("SceneData.dat not found: %s" % file_path)
		return false
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return false
	
	var data := file.get_buffer(file.get_length())
	var rec_size: int = 131
	var total_records: int = data.size() / rec_size
	
	_scenes.clear()
	
	for i in range(total_records):
		var offset: int = i * rec_size
		if offset + rec_size > data.size():
			break
		
		var rec: PackedByteArray = data.slice(offset, offset + rec_size)
		var raw_map_id: int = rec.decode_u16(0)
		var map_id: int = decode_scene_id(raw_map_id)
		
		var name_len: int = rec[2]
		var name: String = ""
		if name_len > 0 and name_len <= 20:
			var name_bytes := rec.slice(23 - name_len, 23)
			name_bytes.reverse()
			name = clean_ascii(name_bytes)
		else:
			var name_bytes := rec.slice(3, 23)
			name_bytes.reverse()
			name = clean_ascii(name_bytes)
		
		var bgm_len: int = rec[25]
		var bgm: String = ""
		if bgm_len > 0 and bgm_len <= 7:
			var bgm_bytes := rec.slice(26, 26 + bgm_len)
			bgm_bytes.reverse()
			bgm = clean_ascii(bgm_bytes)
		else:
			var bgm_bytes := rec.slice(26, 33)
			bgm_bytes.reverse()
			bgm = clean_ascii(bgm_bytes)
		
		var bgm_num: int = 0
		if bgm.begins_with("BGM") or bgm.begins_with("bgm"):
			bgm_num = bgm.substr(3).to_int()
		
		var scene := SceneRecord.new(map_id, name if not name.is_empty() else ("Map_%d" % map_id), bgm, bgm_num)
		_scenes[map_id] = scene
	
	return not _scenes.is_empty()

func get_scene(map_id: int) -> SceneRecord:
	return _scenes.get(map_id)

func get_all_scenes() -> Dictionary:
	return _scenes

func get_total_scenes() -> int:
	return _scenes.size()

func get_all_map_ids() -> Array[int]:
	var ids: Array[int] = []
	for k in _scenes.keys():
		ids.append(int(k))
	ids.sort()
	return ids

func get_map_summary(map_id: int) -> Dictionary:
	var s: SceneRecord = _scenes.get(map_id)
	if not s:
		return {}
	return {
		"map_id": s.map_id,
		"name": s.name,
		"bgm_name": s.bgm_name,
		"bgm_id": s.bgm_id
	}

func search_maps_by_name(query: String) -> Array[Dictionary]:
	var res: Array[Dictionary] = []
	var q := query.strip_edges().to_lower()
	for mid in get_all_map_ids():
		var s: SceneRecord = _scenes[mid]
		if q.is_empty() or s.name.to_lower().contains(q):
			res.append(get_map_summary(mid))
	return res
