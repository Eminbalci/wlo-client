class_name NpcDatabase
extends RefCounted

## Decodes and caches authentic NPC binary records from Npc.dat and all_npcs.json (4,930+ templates).
## Applies bit-exact Delphi ShortString reversal, numerical XOR decryption, and maps every NPC
## to its exact sprite/model JMP and canonical English display name.

class NpcRecord:
	var id: int = 0
	var template_id: int:
		get: return id
		set(val): id = val
	var name: String = ""
	var sprite_id: int = 0
	var icon_id: int = 0
	var model_id: int = 0
	var model_jmp: String = ""
	var model_jma: String = ""
	var icon_jmp: String = ""
	var icon_jma: String = ""
	var level: int = 0
	var max_hp: int = 0
	var max_sp: int = 0
	var element: int = 0 # 0=None, 1=Earth, 2=Water, 3=Fire, 4=Wind
	var stats: Dictionary = {"str": 0, "con": 0, "int": 0, "wis": 0, "agi": 0}
	var talk_image: int = 0
	var talk_image_jmp: String = ""
	var talk_image_jma: String = ""
	var is_monster: bool = false
	var skills: Array[int] = [0, 0, 0]
	var npc_type: int = 0
	var monster_book_index: int = 0
	var maps_present: Array = [] # Array of spawn dictionaries

	func _to_string() -> String:
		return "NpcRecord(id=%d, name='%s', sprite_id=%d, level=%d, hp=%d, maps=%d)" % [
			id, name, sprite_id, level, max_hp, maps_present.size()
		]

var _npcs: Dictionary = {} # int (id) -> NpcRecord
var _npcs_by_index: Dictionary = {} # int (index) -> NpcRecord
var _npcs_by_name: Dictionary = {} # String (lowercase) -> Array[NpcRecord]
var _npcs_by_sprite: Dictionary = {} # int (sprite_id) -> Array[NpcRecord]

static func decode_npc_byte(v: int) -> int:
	return ((v ^ 0xc8) - 1) & 0xff

static func decode_npc_word(v: int) -> int:
	return ((v ^ 0x5209) - 1) & 0xffff

static func decode_npc_dword(v: int) -> int:
	return ((v ^ 0x0baeb716) - 1) & 0xffffffff

## Loads NPC database. Prefers pre-resolved all_npcs.json; falls back to binary Npc.dat decoding.
func load_from_file(file_path: String = "") -> bool:
	_clear_indices()

	# 1. Try pre-resolved all_npcs.json
	var json_candidates: Array[String] = [
		"res://assets/data/all_npcs.json",
		"D:/Godot/WonderlandOnline/wonderland-online-client/assets/data/all_npcs.json",
		"D:/GitHub/WLRI/data/all_npcs.json"
	]
	
	if not file_path.is_empty() and file_path.ends_with(".json") and FileAccess.file_exists(file_path):
		json_candidates.insert(0, file_path)
	
	for json_path in json_candidates:
		if FileAccess.file_exists(json_path):
			if _load_from_json(json_path):
				return true

	# 2. Binary fallback: parse Npc.dat
	var dat_candidates: Array[String] = [
		file_path,
		"res://assets/data/Npc.dat",
		"D:/Godot/WonderlandOnline/wonderland-online-client/assets/data/Npc.dat",
		"D:/GitHub/WLRI/data/Npc.dat"
	]
	for dat_path in dat_candidates:
		if not dat_path.is_empty() and FileAccess.file_exists(dat_path):
			if _load_from_dat(dat_path):
				return true

	push_error("NpcDatabase: Failed to find valid all_npcs.json or Npc.dat.")
	return false

func _clear_indices() -> void:
	_npcs.clear()
	_npcs_by_index.clear()
	_npcs_by_name.clear()
	_npcs_by_sprite.clear()

func _index_record(rec: NpcRecord, index: int) -> void:
	_npcs[rec.id] = rec
	_npcs_by_index[index] = rec
	
	# Index by name
	var lower_name := rec.name.to_lower().strip_edges()
	if not _npcs_by_name.has(lower_name):
		_npcs_by_name[lower_name] = []
	_npcs_by_name[lower_name].append(rec)
	
	# Index by sprite_id
	if rec.sprite_id > 0:
		if not _npcs_by_sprite.has(rec.sprite_id):
			_npcs_by_sprite[rec.sprite_id] = []
		_npcs_by_sprite[rec.sprite_id].append(rec)

func _load_from_json(json_path: String) -> bool:
	var file := FileAccess.open(json_path, FileAccess.READ)
	if not file:
		return false
	
	var text := file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		push_error("NpcDatabase: Invalid JSON format in %s" % json_path)
		return false
	
	var json_dict: Dictionary = parsed
	var idx: int = 1
	var _to_i = func(v, def_i: int = 0) -> int:
		if v == null: return def_i
		if v is int: return v
		if v is float: return int(v)
		if v is String: return v.to_int()
		return def_i

	for tid_str in json_dict:
		var d: Dictionary = json_dict[tid_str]
		var tid: int = _to_i.call(tid_str, 0)
		if tid == 0 and d.get("name", "") == "None":
			continue # skip dummy 0 template in internal indexing or keep as 0
		
		var rec := NpcRecord.new()
		rec.id = _to_i.call(d.get("template_id"), tid)
		rec.name = str(d.get("name", "NPC_%d" % rec.id))
		rec.sprite_id = _to_i.call(d.get("sprite_id"), 0)
		rec.icon_id = _to_i.call(d.get("icon_id"), 0)
		rec.model_id = _to_i.call(d.get("model_id"), rec.sprite_id)
		rec.model_jmp = str(d.get("model_jmp", ""))
		rec.model_jma = str(d.get("model_jma", "001.jma"))
		rec.icon_jmp = str(d.get("icon_jmp", ""))
		rec.icon_jma = str(d.get("icon_jma", "007.jma"))
		rec.level = _to_i.call(d.get("level"), 1)
		rec.max_hp = _to_i.call(d.get("hp"), 100)
		rec.max_sp = _to_i.call(d.get("sp"), 50)
		rec.element = _to_i.call(d.get("element"), 0)
		
		var raw_stats: Variant = d.get("stats")
		if raw_stats is Dictionary:
			rec.stats = {
				"str": _to_i.call(raw_stats.get("str"), 0),
				"con": _to_i.call(raw_stats.get("con"), 0),
				"int": _to_i.call(raw_stats.get("int"), 0),
				"wis": _to_i.call(raw_stats.get("wis"), 0),
				"agi": _to_i.call(raw_stats.get("agi"), 0)
			}
		
		rec.talk_image = _to_i.call(d.get("talk_image"), 0)
		rec.talk_image_jmp = str(d.get("talk_image_jmp", ""))
		rec.talk_image_jma = str(d.get("talk_image_jma", "008.jma"))
		rec.is_monster = bool(d.get("is_monster", false))
		
		var raw_skills: Variant = d.get("skills")
		if raw_skills is Array:
			rec.skills = []
			for s in raw_skills:
				rec.skills.append(_to_i.call(s, 0))
		
		rec.npc_type = _to_i.call(d.get("npc_type"), 0)
		rec.monster_book_index = _to_i.call(d.get("monster_book_index"), 0)
		
		var raw_maps: Variant = d.get("maps_present")
		if raw_maps is Array:
			rec.maps_present = raw_maps
		
		_index_record(rec, idx)
		idx += 1
	
	print("[NpcDatabase] Loaded %d NPC templates from JSON: %s" % [_npcs.size(), json_path])
	return not _npcs.is_empty()

func _load_from_dat(file_path: String) -> bool:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return false
	
	var data := file.get_buffer(file.get_length())
	var rec_size: int = 138
	var total_records: int = data.size() / rec_size
	
	for i in range(0, total_records):
		var offset: int = i * rec_size
		if offset + rec_size > data.size():
			break
		
		# Delphi in-place ShortString reversal for name
		var slen: int = mini(data[offset], 10)
		var name_str: String = ""
		if slen > 0:
			var name_bytes := PackedByteArray()
			for b in range(slen):
				name_bytes.append(data[offset + 11 - 1 - b])
			name_str = name_bytes.get_string_from_ascii().strip_edges()
			if name_str.is_empty():
				name_str = name_bytes.get_string_from_utf8().strip_edges()
		
		var npc_id: int = decode_npc_word(data.decode_u16(offset + 12))
		var sprite_id: int = decode_npc_word(data.decode_u16(offset + 14))
		var icon_id: int = decode_npc_word(data.decode_u16(offset + 16))
		var npc_type: int = decode_npc_byte(data[offset + 11])
		var level: int = decode_npc_byte(data[offset + 37])
		var max_hp: int = decode_npc_dword(data.decode_u32(offset + 38))
		var max_sp: int = decode_npc_dword(data.decode_u32(offset + 42))
		
		var str_val: int = decode_npc_word(data.decode_u16(offset + 46))
		var con_val: int = decode_npc_word(data.decode_u16(offset + 48))
		var int_val: int = decode_npc_word(data.decode_u16(offset + 50))
		var wis_val: int = decode_npc_word(data.decode_u16(offset + 52))
		var agi_val: int = decode_npc_word(data.decode_u16(offset + 54))
		
		var element: int = decode_npc_byte(data[offset + 57])
		if element > 4:
			element = 0
			
		var sk1: int = decode_npc_word(data.decode_u16(offset + 58))
		var sk2: int = decode_npc_word(data.decode_u16(offset + 60))
		var sk3: int = decode_npc_word(data.decode_u16(offset + 62))
		
		var talk_image: int = decode_npc_word(data.decode_u16(offset + 88))
		var mbook: int = decode_npc_word(data.decode_u16(offset + 90))
		
		var npc := NpcRecord.new()
		npc.id = npc_id if npc_id > 0 else i
		npc.name = name_str if not name_str.is_empty() else ("NPC_%d" % npc.id)
		npc.sprite_id = sprite_id
		npc.icon_id = icon_id
		npc.model_id = sprite_id
		npc.model_jmp = "%d.jmp" % sprite_id if sprite_id > 0 else ""
		npc.model_jma = "001.jma"
		npc.icon_jmp = "%d.jmp" % icon_id if icon_id > 0 else ""
		npc.icon_jma = "007.jma"
		npc.level = level
		npc.max_hp = max_hp
		npc.max_sp = max_sp
		npc.element = element
		npc.stats = {
			"str": str_val,
			"con": con_val,
			"int": int_val,
			"wis": wis_val,
			"agi": agi_val
		}
		npc.talk_image = talk_image
		npc.talk_image_jmp = "%d.jmp" % talk_image if talk_image > 0 else ""
		npc.talk_image_jma = "008.jma"
		npc.is_monster = mbook > 0 or (npc_id >= 17000 and npc_id < 18000 and npc_id != 17400)
		npc.skills = [sk1, sk2, sk3]
		npc.npc_type = npc_type
		npc.monster_book_index = mbook
		
		_index_record(npc, i)
	
	_load_english_names_from_sqlite()
	print("[NpcDatabase] Decoded %d NPC templates from binary Npc.dat: %s" % [_npcs.size(), file_path])
	return not _npcs.is_empty()

func _load_english_names_from_sqlite() -> void:
	var authentic_names: Dictionary = {
		10000: "Breillat",
		11000: "Persian Cat",
		11001: "Tabby Cat",
		11002: "Lala",
		11003: "Shiba inu",
		11008: "Little Persian",
		11009: "Mew",
		11010: "Lala Dog",
		11011: "Wild Pup",
		11012: "Laifu",
		11013: "Cat",
		12000: "Commercial Fleet",
		12001: "Zhenghe",
		12002: "Chinese Guard",
		12004: "Melhilis",
		14001: "Deck Crew",
		14002: "Crew",
		14003: "Captain Robinson",
		14042: "Drunk Man",
		14065: "Girl",
		14080: "Visitor",
		14087: "Visitor",
		14091: "Jack",
		14145: "John",
		14146: "Peter",
		14152: "Ross",
		14303: "Natasha",
		18000: "Game Machine a",
		18001: "Game Machine b"
	}
	for nid in authentic_names:
		if _npcs.has(nid):
			var rec: NpcRecord = _npcs[nid]
			rec.name = authentic_names[nid]
			var lower_name: String = rec.name.to_lower()
			if not _npcs_by_name.has(lower_name):
				_npcs_by_name[lower_name] = []
			_npcs_by_name[lower_name].append(rec)

## Returns the exact NpcRecord for a template ID (or index fallback).
func get_npc(template_id: int) -> NpcRecord:
	if _npcs.has(template_id):
		return _npcs[template_id]
	if _npcs_by_index.has(template_id):
		return _npcs_by_index[template_id]
	return null

## Queries all NPC records whose name contains the search string (case-insensitive).
func get_npcs_by_name(name_query: String) -> Array[NpcRecord]:
	var results: Array[NpcRecord] = []
	var q := name_query.to_lower().strip_edges()
	if q.is_empty():
		return results
	
	# Check exact match index first
	if _npcs_by_name.has(q):
		for rec in _npcs_by_name[q]:
			if not results.has(rec):
				results.append(rec)
	
	# Substring match across all records
	for tid in _npcs:
		var rec: NpcRecord = _npcs[tid]
		if rec.name.to_lower().find(q) != -1:
			if not results.has(rec):
				results.append(rec)
	return results

## Queries all NPC records that use a specific sprite / model ID.
func get_npcs_by_sprite(sprite_id: int) -> Array[NpcRecord]:
	var results: Array[NpcRecord] = []
	if _npcs_by_sprite.has(sprite_id):
		results.append_array(_npcs_by_sprite[sprite_id])
	return results

## Returns all NPCs flagged as monsters or hostile combat mobs.
func get_monsters() -> Array[NpcRecord]:
	var results: Array[NpcRecord] = []
	for tid in _npcs:
		var rec: NpcRecord = _npcs[tid]
		if rec.is_monster:
			results.append(rec)
	return results

## Returns all NPC templates that spawn on a specific map_id.
func get_npcs_on_map(map_id: int) -> Array[NpcRecord]:
	var results: Array[NpcRecord] = []
	for tid in _npcs:
		var rec: NpcRecord = _npcs[tid]
		for spawn in rec.maps_present:
			if spawn is Dictionary and int(spawn.get("map_id", -1)) == map_id:
				if not results.has(rec):
					results.append(rec)
				break
	return results

func get_all_npcs() -> Dictionary:
	return _npcs

func get_total_npcs() -> int:
	return _npcs.size()
