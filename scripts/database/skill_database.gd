class_name SkillDatabase
extends RefCounted

## Decodes and caches the 148-byte skill binary records from Skill.dat
## and battle motion timeline indices from SkillData.MBTM.
##
## Record layout (148 bytes, 953 records):
## - Offset 0: Name length (L <= 20)
## - Offset 1..20: Reversed Name characters (right-aligned, rec[21-L..20])
## - Offset 21: Skill Category / Source (byte)
## - Offset 22..23: Skill ID (uint16, decrypted: ((w ^ 0x6ea0) - 4) & 0xffff)
## - Offset 24..25: SP Cost (uint16, decrypted: ((w ^ 0x6ea0) - 4) & 0xffff)
## - Offset 26: Element (byte: 0=None, 1=Earth, 2=Water, 3=Fire, 4=Wind)
## - Offset 27..28: Skill Mechanism / Subtype (uint16)
## - Offset 29: Action Type / Skill Type (byte)
## - Offset 30: Skill Rank / Tier (byte)
## - Offset 31: Target Scope (byte: 1=Single, 2=Row, 3/4=Column, 6/7=Cross, 8=All)
## - Offset 32..39: Damage Multiplier 1 (float64 IEEE 754)
## - Offset 40..47: Damage Multiplier 2 (float64 IEEE 754)
## - Offset 49..50: Base Damage (uint16, decrypted: ((w ^ 0x6ea0) - 4) & 0xffff)
## - Offset 66: Description length (D <= 30)
## - Offset 67..96: Reversed Description characters (right-aligned, rec[97-D..96])
## - Offset 100..101: Animation ID (uint16, decrypted: ((w ^ 0x6ea0) - 4) & 0xffff)

enum Element {
	NONE = 0,
	EARTH = 1,
	WATER = 2,
	FIRE = 3,
	WIND = 4
}

enum SkillType {
	PHYSICAL = 0,
	MAGIC = 1,
	ASSIST = 2,
	STATUS = 3,
	SPECIAL = 4
}

enum TargetScope {
	SINGLE = 0,
	ROW = 1,
	COLUMN = 2,
	CROSS = 3,
	ALL = 4
}

class SkillRecord extends RefCounted:
	var id: int = 0
	var name: String = ""
	var description: String = ""
	var element: Element = Element.NONE
	var element_name: String = "None"
	var skill_type: SkillType = SkillType.PHYSICAL
	var skill_type_name: String = "Physical"
	var sp_cost: int = 0
	var base_damage: int = 0
	var target_scope: TargetScope = TargetScope.SINGLE
	var target_scope_name: String = "Single"
	var animation_id: int = 0
	var damage_rate_1: float = 0.0
	var damage_rate_2: float = 0.0
	var rank: int = 1
	var category: int = 0
	
	var damage_multiplier_1: float:
		get:
			return damage_rate_1
		set(val):
			damage_rate_1 = val
			
	var damage_multiplier_2: float:
		get:
			return damage_rate_2
		set(val):
			damage_rate_2 = val
	
	func to_dict() -> Dictionary:
		return {
			"id": id,
			"name": name,
			"description": description,
			"element": element,
			"element_name": element_name,
			"skill_type": skill_type,
			"skill_type_name": skill_type_name,
			"sp_cost": sp_cost,
			"base_damage": base_damage,
			"target_scope": target_scope,
			"target_scope_name": target_scope_name,
			"animation_id": animation_id,
			"damage_rate_1": damage_rate_1,
			"damage_rate_2": damage_rate_2,
			"damage_multiplier_1": damage_rate_1,
			"damage_multiplier_2": damage_rate_2,
			"rank": rank,
			"category": category
		}

const RECORD_SIZE: int = 148

## Authentic starter stunt skills for the 14 playable roles (Role ID 1..14)
## Derived from Delphi binary table and role definitions.
const STARTER_SKILLS: Dictionary = {
	1: 15039, # Nina: Wine Flame (Fire)
	2: 12036, # Betty: Leap (Wind)
	3: 11075, # Rocco: Summon Dogs Groups (Earth)
	4: 15042, # Vanessa: Recover Normal (Water)
	5: 15041, # Lique: Love Wish (Wind)
	6: 15038, # Daniel: Overarm Stumble (Fire)
	7: 11076, # Sid: Combo x3 Attack (Earth)
	8: 15044, # Jessica: Hagendis Attack (Water)
	9: 15045, # Konnotsuroko: Hagendis Beating (Water)
	10: 11078, # Iris: Bomber Attack (Water) [Alias 12037]
	11: 11077, # Maria: Cure 2 Players (Water)
	12: 11183, # More: Deacon Attack (Earth)
	13: 11182, # Kurogane: Ghost Hammer (Fire)
	14: 15040, # Karin: Palm (Fire)
}

static var _instance: SkillDatabase = null

var _skills: Dictionary = {} # int -> SkillRecord
var _mbtm_entries: Dictionary = {} # int -> Dictionary: {"offset": int, "length": int}
var _mbtm_path: String = ""

func _init() -> void:
	if _instance == null:
		_instance = self

static func get_instance() -> SkillDatabase:
	return _instance

static func decode_byte(b: int) -> int:
	return ((b ^ 0xfd) - 4) & 0xff

static func decode_word(w: int) -> int:
	return ((w ^ 0x6ea0) - 4) & 0xffff

static func decode_dword(d: int) -> int:
	return ((d ^ 0x0bdedebf) - 4) & 0xffffffff

static func clean_string(bytes: PackedByteArray) -> String:
	var nul_idx := bytes.find(0)
	if nul_idx != -1:
		bytes = bytes.slice(0, nul_idx)
	var filtered := PackedByteArray()
	for b in bytes:
		if (b >= 32 and b <= 126) or b > 127:
			filtered.append(b)
	if filtered.is_empty():
		return ""
	var s := filtered.get_string_from_ascii()
	if s.is_empty():
		s = filtered.get_string_from_utf8()
	return s.strip_edges()

static func get_element_name(elem: Element) -> String:
	match elem:
		Element.NONE:
			return "None"
		Element.EARTH:
			return "Earth"
		Element.WATER:
			return "Water"
		Element.FIRE:
			return "Fire"
		Element.WIND:
			return "Wind"
		_:
			return "None"

static func get_skill_type_name(st: SkillType) -> String:
	match st:
		SkillType.PHYSICAL:
			return "Physical"
		SkillType.MAGIC:
			return "Magic"
		SkillType.ASSIST:
			return "Assist"
		SkillType.STATUS:
			return "Status"
		SkillType.SPECIAL:
			return "Special"
		_:
			return "Physical"

static func get_target_scope_name(scope: TargetScope) -> String:
	match scope:
		TargetScope.SINGLE:
			return "Single"
		TargetScope.ROW:
			return "Row"
		TargetScope.COLUMN:
			return "Column"
		TargetScope.CROSS:
			return "Cross"
		TargetScope.ALL:
			return "All"
		_:
			return "Single"

static func map_target_scope(val: int) -> TargetScope:
	match val:
		1:
			return TargetScope.SINGLE
		2:
			return TargetScope.ROW
		3, 4:
			return TargetScope.COLUMN
		6, 7:
			return TargetScope.CROSS
		8:
			return TargetScope.ALL
		_:
			return TargetScope.SINGLE

static func map_skill_type(action_type: int, mechanism: int) -> SkillType:
	match action_type:
		1:
			return SkillType.PHYSICAL
		2:
			return SkillType.MAGIC
		4, 7, 14, 19:
			return SkillType.ASSIST
		3, 5, 11, 15, 17:
			return SkillType.STATUS
		10, 12, 13:
			return SkillType.SPECIAL
		_:
			if mechanism == 1:
				return SkillType.PHYSICAL
			elif mechanism == 2 or mechanism == 3:
				return SkillType.MAGIC
			elif mechanism == 4:
				return SkillType.SPECIAL
			return SkillType.PHYSICAL

## Loads and decodes Skill.dat
func load_from_file(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		push_error("Skill.dat not found: %s" % file_path)
		return false
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return false
	
	var data := file.get_buffer(file.get_length())
	var total_records: int = data.size() / RECORD_SIZE
	_skills.clear()
	
	# Record 0 is header / sentinel, start from 1
	for i in range(1, total_records):
		var offset: int = i * RECORD_SIZE
		if offset + RECORD_SIZE > data.size():
			break
		
		var raw_id: int = data.decode_u16(offset + 22)
		var skill_id: int = decode_word(raw_id)
		if skill_id == 0:
			continue
		
		# Name at offset 0 (length L), characters stored right-aligned reversed ending at offset 20
		var name_len: int = data[offset]
		var name: String = ""
		if name_len > 0 and name_len <= 20:
			var name_bytes := PackedByteArray()
			name_bytes.resize(name_len)
			for b in range(name_len):
				name_bytes[b] = data[offset + 20 - b]
			name = clean_string(name_bytes)
		if name.is_empty():
			name = "Skill_%d" % skill_id
		
		# Category (offset 21)
		var category: int = decode_byte(data[offset + 21])
		
		# SP Cost (offset 24, uint16)
		var sp_cost: int = decode_word(data.decode_u16(offset + 24))
		
		# Element (offset 26, byte: 0=None, 1=Earth, 2=Water, 3=Fire, 4=Wind)
		var raw_elem: int = decode_byte(data[offset + 26])
		var element: Element = Element.NONE
		if raw_elem >= 1 and raw_elem <= 4:
			element = raw_elem as Element
		elif category >= 1 and category <= 4:
			element = category as Element
		
		# Mechanism (offset 27, uint16)
		var mechanism: int = decode_word(data.decode_u16(offset + 27))
		
		# Action / Skill Type (offset 29, byte)
		var action_type: int = decode_byte(data[offset + 29])
		var skill_type: SkillType = map_skill_type(action_type, mechanism)
		
		# Rank / Tier (offset 30, byte)
		var rank: int = decode_byte(data[offset + 30])
		
		# Target Scope (offset 31, byte)
		var raw_target: int = decode_byte(data[offset + 31])
		var target_scope: TargetScope = map_target_scope(raw_target)
		
		# Damage multipliers (offset 32 and 40, float64 IEEE 754)
		var dmg_rate_1: float = data.decode_double(offset + 32)
		var dmg_rate_2: float = data.decode_double(offset + 40)
		
		# Base Damage (offset 49, uint16)
		var base_damage: int = decode_word(data.decode_u16(offset + 49))
		
		# Description at offset 66 (length D <= 30), characters stored right-aligned reversed ending at offset 96
		var desc_len: int = data[offset + 66]
		var desc: String = ""
		if desc_len > 0 and desc_len <= 30:
			var desc_bytes := PackedByteArray()
			desc_bytes.resize(desc_len)
			for b in range(desc_len):
				desc_bytes[b] = data[offset + 96 - b]
			desc = clean_string(desc_bytes)
		
		# Animation ID (offset 100, uint16)
		var animation_id: int = decode_word(data.decode_u16(offset + 100))
		
		var record := SkillRecord.new()
		record.id = skill_id
		record.name = name
		record.description = desc
		record.element = element
		record.element_name = get_element_name(element)
		record.skill_type = skill_type
		record.skill_type_name = get_skill_type_name(skill_type)
		record.sp_cost = sp_cost
		record.base_damage = base_damage
		record.target_scope = target_scope
		record.target_scope_name = get_target_scope_name(target_scope)
		record.animation_id = animation_id
		record.damage_rate_1 = dmg_rate_1
		record.damage_rate_2 = dmg_rate_2
		record.rank = rank
		record.category = category
		
		_skills[skill_id] = record
	
	# Alias for Iris stunt (12037 -> 11078 Bomber Attack)
	if _skills.has(11078) and not _skills.has(12037):
		var iris_alias := SkillRecord.new()
		var real_stunt: SkillRecord = _skills[11078]
		iris_alias.id = 12037
		iris_alias.name = real_stunt.name
		iris_alias.description = real_stunt.description
		iris_alias.element = Element.WATER
		iris_alias.element_name = "Water"
		iris_alias.skill_type = real_stunt.skill_type
		iris_alias.skill_type_name = real_stunt.skill_type_name
		iris_alias.sp_cost = real_stunt.sp_cost
		iris_alias.base_damage = real_stunt.base_damage
		iris_alias.target_scope = real_stunt.target_scope
		iris_alias.target_scope_name = real_stunt.target_scope_name
		iris_alias.animation_id = real_stunt.animation_id
		iris_alias.damage_rate_1 = real_stunt.damage_rate_1
		iris_alias.damage_rate_2 = real_stunt.damage_rate_2
		iris_alias.rank = real_stunt.rank
		iris_alias.category = real_stunt.category
		_skills[12037] = iris_alias
	
	return true

## Loads and parses the index table of SkillData.MBTM (10 bytes per entry at end of file)
func load_mbtm_from_file(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		return false
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return false
	
	var total_size: int = file.get_length()
	if total_size < 12:
		return false
	
	# Read record count from last 2 bytes
	file.seek(total_size - 2)
	var count: int = file.get_16()
	if count <= 0 or (total_size - 2 - count * 10) < 0:
		return false
	
	var index_offset: int = total_size - 2 - count * 10
	file.seek(index_offset)
	var index_buffer := file.get_buffer(count * 10)
	
	_mbtm_entries.clear()
	_mbtm_path = file_path
	
	for i in range(count):
		var base_off: int = i * 10
		var skill_id: int = index_buffer.decode_u16(base_off)
		var entry_off: int = index_buffer.decode_u32(base_off + 2)
		var entry_len: int = index_buffer.decode_u32(base_off + 6)
		_mbtm_entries[skill_id] = {
			"offset": entry_off,
			"length": entry_len
		}
	
	return true

## Returns whether MBTM animation data is available for skill_id
func has_mbtm_entry(skill_id: int) -> bool:
	return _mbtm_entries.has(skill_id)

## Returns MBTM entry dictionary {"offset": int, "length": int}
func get_mbtm_entry(skill_id: int) -> Dictionary:
	return _mbtm_entries.get(skill_id, {})

## Returns the raw MBTM animation timeline byte payload for skill_id
func get_mbtm_payload(skill_id: int) -> PackedByteArray:
	if not _mbtm_entries.has(skill_id) or _mbtm_path.is_empty():
		return PackedByteArray()
	
	var entry: Dictionary = _mbtm_entries[skill_id]
	var file := FileAccess.open(_mbtm_path, FileAccess.READ)
	if not file:
		return PackedByteArray()
	
	file.seek(entry["offset"])
	return file.get_buffer(entry["length"])

## Returns total number of animation entries in MBTM
func get_mbtm_count() -> int:
	return _mbtm_entries.size()

## Returns a skill by ID, or null if not found
func get_skill(id: int) -> SkillRecord:
	return _skills.get(id)

## Returns whether a skill exists
func has_skill(id: int) -> bool:
	return _skills.has(id)

## Returns the dictionary of all loaded skills (ID -> SkillRecord)
func get_all_skills() -> Dictionary:
	return _skills

## Returns all skills matching the specified element
func get_skills_by_element(elem: Element) -> Array[SkillRecord]:
	var result: Array[SkillRecord] = []
	for skill in _skills.values():
		if skill.element == elem:
			result.append(skill)
	return result

## Returns all skills matching the specified skill type
func get_skills_by_type(st: SkillType) -> Array[SkillRecord]:
	var result: Array[SkillRecord] = []
	for skill in _skills.values():
		if skill.skill_type == st:
			result.append(skill)
	return result

## Returns all skills matching the specified target scope
func get_skills_by_target_scope(scope: TargetScope) -> Array[SkillRecord]:
	var result: Array[SkillRecord] = []
	for skill in _skills.values():
		if skill.target_scope == scope:
			result.append(skill)
	return result

## Returns the authentic starter stunt skill ID for role_id (1..14)
func get_starter_stunt_id(role_id: int) -> int:
	return STARTER_SKILLS.get(role_id, 12036)

## Returns the authentic starter stunt skill record for role_id (1..14)
func get_starter_skill_for_role(role_id: int) -> SkillRecord:
	var stunt_id: int = get_starter_stunt_id(role_id)
	return get_skill(stunt_id)

## Returns the full starter skill loadout for role_id (1..14)
## (Basic Hand Attack 10001 + Character Stunt Skill)
func get_starter_skills_for_role(role_id: int) -> Array[SkillRecord]:
	var list: Array[SkillRecord] = []
	var basic_atk: SkillRecord = get_skill(10001)
	if basic_atk:
		list.append(basic_atk)
	var stunt: SkillRecord = get_starter_skill_for_role(role_id)
	if stunt and stunt != basic_atk:
		list.append(stunt)
	return list

## Returns map of role_id -> stunt SkillRecord
func get_role_stunts() -> Dictionary:
	var map: Dictionary = {}
	for role_id in STARTER_SKILLS.keys():
		map[role_id] = get_starter_skill_for_role(role_id)
	return map
