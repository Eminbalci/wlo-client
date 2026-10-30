class_name ItemDatabase
extends RefCounted

## Decodes and caches authentic item records from itemDat.wpdat (4,818 items) and Item.dat (7,293 records).
## Applies bit-exact Delphi string reversal and numerical XOR decryption.

class ItemRecord:
	var id: int = 0
	var name: String = ""
	var icon_id: int = 0
	var large_icon_id: int = 0
	var item_type: int = 0
	var equip_pos: int = 0
	var level: int = 0
	var rank: int = 0
	var material_type: int = 0
	var material_name: String = ""
	var materials: Array[String] = []
	var authentic_materials: Array[String] = []
	var durability: int = 50
	var max_durability: int = 50
	var description: String = ""
	var buy_price: int = 0
	var sell_price: int = 0
	var status_types: Array[int] = []
	var status_values: Array[int] = []
	# Fields decoded from Item.dat exactly as aLogin.exe 0x3e7e40 decodes them (see docs/re/item_window_and_tooltip.md).
	var has_dat_record: bool = false # true once the Item.dat record was decoded
	var kind: int = 0 # rec+0x2F byte: sub-kind used by special cases (0x71/0x72/0x77/0x97...)
	var flags: int = 0 # rec+0x7B word: bit 0x02 = non-tradeable, bit 0x08 = "Can't craft"
	var set_id: int = 0 # rec+0x81 byte: equipment set id (5 equipped pieces with the same id = set bonus)
	var grid_w: int = 1 # rec+0x196 byte: bag footprint width in cells
	var grid_h: int = 1 # rec+0x197 byte: bag footprint height in cells
	var time_limit_hours: int = 0 # rec+0x1A5 word: time-limited item lifetime in hours
	var max_uses: int = 0 # rec+0x1A7 word: max uses (shown as "Uses: ")

	func get_material_name() -> String:
		if not materials.is_empty():
			return ", ".join(materials)
		if not material_name.is_empty():
			return material_name
		materials = ItemDatabase.resolve_materials(self)
		material_name = ", ".join(materials) if not materials.is_empty() else "Misc"
		return material_name

	func get_materials() -> Array[String]:
		if materials.is_empty():
			get_material_name()
		return materials

	func get_rank() -> int:
		# The real client prints rec+0x2D verbatim ("Rank: " at 0x2a2fd0); trust it whenever Item.dat was read.
		if has_dat_record:
			return rank
		if rank > 0:
			return rank
		if ItemDatabase.KNOWN_MATERIAL_RANKS.has(id):
			return ItemDatabase.KNOWN_MATERIAL_RANKS[id]
		if equip_pos > 0:
			return maxi(1, int(level / 2))
		return maxi(1, level)

	func is_equipment() -> bool:
		# aLogin 0x3e92a4: equip_pos 1..6 is wearable equipment.
		return equip_pos >= 1 and equip_pos <= 6

	func is_non_tradeable() -> bool:
		# aLogin 0x2a6cec: flags word & 2 => "<Non-tradeable>".
		return (flags & 2) != 0

	func get_type_name() -> String:
		return ItemDatabase.get_item_type_name(item_type)

	func get_equip_slot_name() -> String:
		# Slot names follow the real "Type: " strings of the item kinds that use each equip_pos
		# (Item.dat: pos1 = type 13 Head, 2 = 12 Body, 3 = types 1..11 weapons, 4 = 14 Hands,
		# 5 = 15 Shoes, 6 = 16 Special Eq). 7..10 are not equipment (0x3e92a4).
		match equip_pos:
			1: return "Head"
			2: return "Body"
			3: return "Weapon"
			4: return "Hands"
			5: return "Shoes"
			6: return "Special Eq"
			_: return "Item"

	func get_hp_restore() -> int:
		var total: int = 0
		for i in range(mini(status_types.size(), status_values.size())):
			if status_types[i] == 25 and status_values[i] > 100:
				total += (status_values[i] - 100)
		return total

	func get_sp_restore() -> int:
		var total: int = 0
		for i in range(mini(status_types.size(), status_values.size())):
			if status_types[i] == 26 and status_values[i] > 100:
				total += (status_values[i] - 100)
		return total

	func get_amity_restore() -> int:
		var total: int = 0
		for i in range(mini(status_types.size(), status_values.size())):
			if status_types[i] == 64 and status_values[i] > 100:
				total += (status_values[i] - 100)
		return total

	func get_formatted_stats() -> Array[Dictionary]:
		# Mirrors the stat lines of the real tooltip (aLogin 0x2a28a3..0x2a2c92): "<Name>: +N" where
		# N = value - 100; values 0 and 100 print nothing; code 250 is never printed.
		var stats: Array[Dictionary] = []
		for i in range(mini(status_types.size(), status_values.size())):
			var st: int = status_types[i]
			var raw_val: int = status_values[i]
			if st == 0 or st == 250 or raw_val == 0 or raw_val == 100:
				continue
			var delta: int = raw_val - 100
			stats.append({
				"name": ItemDatabase.get_status_name(st),
				"code": st,
				"delta": delta,
				"text": ItemDatabase.format_status_line(st, delta),
				"is_positive": delta >= 0
			})
		return stats

var _items: Dictionary = {} # int -> ItemRecord

## Hard-coded inventory facts recovered from aLogin.exe (docs/re/item_window_and_tooltip.md).
const STACK_LIMIT: int = 50 # 0x3f1c9a: stack count byte is clamped to 0x32
const BAG_SLOTS: int = 50 # bag loops run 1..0x32; grid ctor 0x10fa8c is called with 0x32
const BAG_COLUMNS: int = 5 # grid ctor: width byte = 5
const BAG_ROWS: int = 10 # grid ctor: max row index = 9 (rows 0..9)
const EQUIP_SLOT_COUNT: int = 6 # character equip array [char+0x64 + pos*4], pos 1..6

## Status code -> label, from the switch at aLogin 0x2a28c0 (strings at 0x2a4a20..0x2a4abc).
const STATUS_NAMES: Dictionary = {
	25: "Hp", 26: "Sp", 36: "EXP", 64: "Amity", 100: "Shoot RES",
	207: "MaxHp", 208: "MaxSp", 210: "ATK", 211: "DEF", 214: "SPD", 215: "MATK", 216: "MDEF",
}

## Item.dat type byte (rec+0x0F) -> "Type: " text, from aLogin 0x49f674 (jump table 0x49f695).
## Codes 0, 17..20, 22..24 and > 25 all fall to "Prop".
const ITEM_TYPE_NAMES: Dictionary = {
	1: "Saber", 2: "Sword", 3: "Halberd", 4: "Bow", 5: "Wand", 6: "Claw", 7: "Knuckle",
	8: "Axe", 9: "Club", 10: "Exotic", 11: "Hammer", 12: "Body", 13: "Head", 14: "Hands",
	15: "Shoes", 16: "Special Eq", 21: "Quest Item", 25: "Spec Prop",
}

## Tooltip colours (RGB565 in the client): every line 0xFFE0, the durability word 0xFFE0 or 0xF800.
const TOOLTIP_TEXT_COLOR := Color(1.0, 1.0, 0.0, 1.0)
const TOOLTIP_WARN_COLOR := Color(1.0, 0.0, 0.0, 1.0)

static func get_status_name(code: int) -> String:
	return STATUS_NAMES.get(code, "")

static func get_item_type_name(type_code: int) -> String:
	return ITEM_TYPE_NAMES.get(type_code, "Prop")

static func format_status_line(code: int, delta: int) -> String:
	var label := get_status_name(code)
	var head := (label + ": ") if not label.is_empty() else ""
	return head + ("+%d" % delta if delta >= 0 else "%d" % delta)

## Durability word for the tooltip "State:" line, from aLogin 0x2a44dc (wear byte 0..250).
## Returns [text, is_warning]. Some item ids print "Usable" instead of "Good" for wear 1..149
## (id lists behind 0x3f1e74/0x3f1e78, not decoded); those are reported as "Good" here.
static func durability_state(wear: int) -> Array:
	if wear >= 250:
		return ["Broken", true]
	if wear >= 200:
		return ["Wearing", true]
	if wear >= 150:
		return ["Used", false]
	return ["Good", false]

## Builds the tooltip lines in the order of aLogin 0x2a2058. `inst` carries per-instance data:
## forge (int), wear (0..250), used (int), socket_name, model_name, content_name,
## time_left_hours, non_tradeable (bool), compound (bool: hover inside the compound window).
static func build_tooltip_lines(rec: ItemRecord, inst: Dictionary = {}) -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	if rec == null:
		return lines
	var color := TOOLTIP_TEXT_COLOR
	var forge: int = int(inst.get("forge", 0))
	var suffix := ""
	if forge > 0 and rec.equip_pos >= 1 and rec.equip_pos <= 5:
		suffix = "+%d" % forge
	lines.append({"text": "[ %s%s ]" % [rec.name, suffix], "color": color})
	if rec.is_non_tradeable() or bool(inst.get("non_tradeable", false)):
		lines.append({"text": "<Non-tradeable>", "color": color})
	# 0x3ec1f8: kind 0x97 potions restoring Hp/Sp show "left/total" instead of stat lines.
	var potion_mode: int = 0
	if rec.kind == 0x97 and not rec.status_types.is_empty():
		if rec.status_types[0] == 25:
			potion_mode = 1
		elif rec.status_types[0] == 26:
			potion_mode = 2
	if potion_mode == 0:
		for st in rec.get_formatted_stats():
			lines.append({"text": str(st["text"]) + " ", "color": color, "stat": true})
	lines.append({"text": "Type: " + rec.get_type_name(), "color": color})
	lines.append({"text": "Rank: %d" % rec.get_rank(), "color": color})
	if rec.level > 0:
		if rec.kind == 0x72:
			lines.append({"text": "LV Req: %dBelow " % mini(rec.level, 199), "color": color})
		else:
			lines.append({"text": "LV Req: %d" % rec.level, "color": color})
	if potion_mode != 0:
		var total: int = rec.status_values[0] - 100
		var used: int = int(inst.get("used", 0))
		lines.append({"text": "%d/%d" % [total - used, total], "color": color})
	if rec.time_limit_hours > 0 and ((rec.equip_pos >= 1 and rec.equip_pos <= 7) or rec.equip_pos == 9):
		var hours: int = int(inst.get("time_left_hours", rec.time_limit_hours))
		var days: int = int(hours / 24)
		var rem: int = hours % 24
		var t := ""
		if days > 0:
			t += "%dday" % days
		if rem > 0:
			t += "%d hr " % rem
		if days <= 0 and rem <= 0:
			t = "1 hour "
		lines.append({"text": "Time: " + t, "color": color})
	if rec.max_uses > 0:
		var wear_u: int = int(inst.get("wear", 0))
		lines.append({"text": "Uses: %d " % int(float(250 - wear_u) * float(rec.max_uses) / 250.0), "color": color})
	var content := str(inst.get("content_name", ""))
	if not content.is_empty():
		lines.append({"text": "Content:" + content, "color": color})
	if rec.is_equipment() and rec.max_uses <= 0:
		var state := durability_state(int(inst.get("wear", 0)))
		lines.append({"text": "State: " + str(state[0]), "color": color, "state_word": state[0],
			"state_color": TOOLTIP_WARN_COLOR if state[1] else TOOLTIP_TEXT_COLOR})
	var socket := str(inst.get("socket_name", ""))
	if not socket.is_empty() and rec.is_equipment():
		lines.append({"text": "Socket: " + socket, "color": color})
	var model := str(inst.get("model_name", ""))
	if not model.is_empty():
		lines.append({"text": "Model: " + model, "color": color})
	if not bool(inst.get("compound", false)) and not rec.description.is_empty():
		lines.append({"text": rec.description, "color": color})
	return lines

const KNOWN_MATERIAL_RANKS: Dictionary = {
	# Wood materials (45001..45020)
	45005: 1, # Wood / Log
	45001: 2, # Ordinary Wood
	45002: 3, # Oak wood
	45003: 4, # Lauan Wood
	45004: 5, # Cypress Wood
	45010: 6, # Fine Wood
	45011: 7, # Delicate Wood
	45012: 8, # Fine Log

	# Copper & Bronze materials (42008..42013)
	42008: 1, # Copper Ore
	42009: 2, # Copper Sand
	42010: 3, # Copper Block
	42011: 4, # Copper Material
	42012: 5, # Bronze Material
	42013: 6, # Copper Plate

	# Iron & Steel materials (42014..42023)
	42014: 1, # Iron Ore
	42015: 2, # Iron Sand
	42016: 3, # Iron Block
	42017: 4, # Iron Fillet
	42018: 5, # Iron Material
	42019: 6, # Steel
	42020: 7, # Pure Iron Ore
	42021: 8, # Pure Iron Sand
	42022: 9, # Pure Iron Block
	42023: 10, # Pure Iron Fillet

	# Gold materials (42001..42004)
	42001: 1, # Gold Ore
	42002: 2, # Gold Sand
	42003: 3, # Gold Block
	42004: 4, # Bullion

	# Silver materials (42005..42007)
	42005: 1, # Silvery Ore
	42006: 2, # Silvery Sand
	42007: 3, # Silvery Block

	# Tin & Lead (42024..42028)
	42024: 1, # Tin Ore
	42025: 2, # Tin Sand
	42026: 1, # Lead Ore
	42027: 2, # Lead Sand
	42028: 3, # Lead Block

	# Titanium, Platinum, Aluminum (42029..42037)
	42029: 1, # Titanium Ore
	42030: 2, # Titanium Sand
	42031: 3, # Titanium Block
	42032: 1, # Platinum Ore
	42033: 2, # Platinum Sand
	42034: 3, # Platinum Block
	42035: 1, # Aluminum Ore
	42036: 2, # Aluminum Sand
	42037: 3, # Aluminum Block

	# Coal & Clay
	43001: 1, # Coal
	44001: 1, # Clay
	44002: 2, # White Clay
	44003: 3, # Red Clay
	44004: 4, # Black Clay
	44005: 5, # Yellow Clay
	44006: 6, # Blue Clay
	44007: 7, # Gray Clay
}

const MATERIAL_TYPES: Dictionary = {
	"Misc": 0,
	"Wood": 1,
	"Iron": 2,
	"Copper": 3,
	"Bronze": 4,
	"Steel": 5,
	"Gold": 6,
	"Silver": 7,
	"Titanium": 8,
	"Platinum": 9,
	"Aluminum": 10,
	"Diamond": 11,
	"Crystal": 12,
	"Jade": 13,
	"Stone": 14,
	"Clay": 15,
	"Leather": 16,
	"Fur": 17,
	"Feather": 18,
	"Grass": 19,
	"Cloth": 20,
	"Bone": 21,
	"Shellfish": 22,
	"Fish": 23,
	"Meat": 24,
	"Grain": 25,
	"Herb": 26,
	"Flower": 27,
	"Water": 28,
	"Magic": 29,
	"Lead": 30,
	"Tin": 31,
	"Mercury": 32,
	"Glass": 33,
	"Ruby": 34,
	"Sapphire": 35,
	"Emerald": 36,
	"Opal": 37,
	"Coral": 38,
	"Pearl": 39,
	"Amber": 40,
	"Obsidian": 41,
	"Flint": 42,
	"Coal": 43,
	"Oil": 44,
	"Rubber": 45,
	"Paper": 46,
	"Plastic": 47,
	"Wool": 48,
	"Silk": 49,
	"Cotton": 50,
	"Linen": 51,
	"Bamboo": 52,
	"Vine": 53,
	"Straw": 54,
	"Fruit": 55,
	"Vegetable": 56,
	"Seed": 57,
	"Leaf": 58,
	"Mushroom": 59,
	"Poison": 60,
	"Gem": 61,
	"Metal": 62,
	"Mineral": 63,
	"Wheat": 64,
	"Egg": 65,
	"Bean": 66,
	"Milk": 67,
	"Medicine": 68,
	"Hematite": 69,
	"Silicon": 70,
	"Sulfur": 71,
	"Salt": 72,
	"Carapace": 73,
	"Nest": 74,
	"Innards": 75,
	"Feces": 76,
	"Secrets": 77,
	"Alcohol": 78,
	"Nylon": 79,
	"Crude": 80,
	"Fuel": 81,
	"WolfMeat": 82,
	"Pet Potential": 83,
	"Pet Equipment": 84,
	"Stat Potential": 85,
	"Pet Weapon": 86,
}

## Authentic 70-category Material Taxonomy reverse-engineered from Delphi binary Main.exe/aLogin.exe subroutine FUN_0049f998.
## Encoded in Item.dat records at offsets 0x88, 0x8A, 0x8C, 0x8E, 0x90 (up to 5 constituent materials per item).
const WLO_AUTHENTIC_MATERIALS: Dictionary = {
	1: "Flower",
	2: "Grass",
	3: "Leaf",
	4: "Wood",
	5: "Rice",
	6: "Wheat",
	7: "Veggie",
	8: "Fruit",
	9: "Meat",
	10: "Egg",
	11: "Bean",
	12: "Milk",
	13: "Seafood",
	14: "Medicine",
	15: "Gold",
	16: "Silver",
	17: "Copper",
	18: "Iron",
	19: "Hematite",
	20: "Tin",
	21: "Lead",
	22: "Aluminum",
	23: "Silicon",
	24: "Sulfur",
	25: "Salt",
	26: "Coal",
	27: "Steel",
	28: "Jade",
	29: "Gem",
	30: "Diamond",
	31: "Crystal",
	32: "Mercury",
	33: "Silver",
	34: "Stone",
	35: "Magnet",
	36: "Mercury",
	37: "Titanium",
	42: "Clay",
	43: "Red Clay",
	44: "Clay",
	45: "Black Clay",
	46: "White Clay",
	47: "Grey Clay",
	48: "Dry Clay",
	49: "Fur",
	50: "Feather",
	51: "Carapace",
	52: "Bone",
	53: "Nest",
	54: "Innards",
	55: "Feces",
	56: "Secrets",
	57: "Alcohol",
	58: "Nylon",
	59: "Crude",
	60: "Oil",
	61: "Fuel",
	62: "Seed",
	63: "WolfMeat",
	64: "Plastic",
	65: "Misc",
	66: "Crystal",
	67: "Magic",
	68: "Poison",
	69: "Fur",
	71: "Chemical",
	72: "Pet Potential",
	73: "Pet Equipment",
	74: "Stat Potential",
	75: "Pet Weapon",
	101: "Water",
	102: "Poison",
}

static var _compound_recipes: Dictionary = {} # int -> Array[int]
static var _compound_loaded: bool = false

static func _ensure_compound_loaded() -> void:
	if _compound_loaded:
		return
	_compound_loaded = true
	var candidate_paths := [
		"res://assets/data/Compound2.Dat",
		"res://assets/data/Compound2.dat",
		"D:/Godot/WonderlandOnline/wonderland-online-client/assets/data/Compound2.Dat",
		"D:/GitHub/Wonderland-Private-Server/Data/Compound2.dat",
	]
	var file_path := ""
	for p in candidate_paths:
		if FileAccess.file_exists(p):
			file_path = p
			break
	if file_path.is_empty():
		return
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return
	var data := file.get_buffer(file.get_length())
	var rec_size: int = 65
	var total: int = data.size() / rec_size
	for i in range(1, total):
		var offset: int = i * rec_size
		var res_id: int = ((data.decode_u16(offset) ^ 0xFBBC) - 3) & 0xFFFF
		if res_id == 0 or res_id == 60003:
			continue
		var mat_ids: Array[int] = []
		for m in range(5):
			var m_off: int = offset + 11 + m * 3
			var mat_id: int = ((data.decode_u16(m_off) ^ 0xFBBC) - 3) & 0xFFFF
			var amt: int = ((data[m_off + 2] ^ 0xD3) - 3) & 0xFF
			if mat_id > 0 and amt > 0 and mat_id != 60003:
				mat_ids.append(mat_id)
		if not mat_ids.is_empty():
			_compound_recipes[res_id] = mat_ids

static func _has_word(text: String, word: String) -> bool:
	if text == word:
		return true
	if text.begins_with(word + " ") or text.ends_with(" " + word) or text.contains(" " + word + " ") or text.contains(" " + word + ".") or text.contains(" " + word + ",") or text.contains(" " + word + "/"):
		return true
	return false

static func _resolve_material_from_id(id: int) -> String:
	if (id >= 45001 and id <= 45025) or id == 45005 or id == 45007 or id == 37138:
		return "Wood"
	if id >= 42008 and id <= 42011:
		return "Copper"
	if id >= 42012 and id <= 42013:
		return "Bronze"
	if (id >= 42014 and id <= 42018) or (id >= 42020 and id <= 42023):
		return "Iron"
	if id == 42019:
		return "Steel"
	if id >= 42001 and id <= 42004:
		return "Gold"
	if id >= 42005 and id <= 42007:
		return "Silver"
	if id >= 44001 and id <= 44007:
		return "Clay"
	if id >= 43001 and id <= 43005:
		return "Coal"
	if id == 37132 or (id >= 41001 and id <= 41030):
		return "Grass"
	if id == 37089:
		return "Water"
	return "Misc"

static func resolve_materials(item: ItemRecord) -> Array[String]:
	if not item:
		return ["Misc"]
	if not item.authentic_materials.is_empty():
		var mats: Array[String] = item.authentic_materials.duplicate()
		if item.name.to_lower().contains("bronze") and mats.has("Copper"):
			var idx: int = mats.find("Copper")
			mats[idx] = "Bronze"
		item.materials = mats
		item.material_name = item.get_material_name()
		item.material_type = resolve_material_type(item.materials[0] if not item.materials.is_empty() else "Misc")
		return item.materials
	if not item.materials.is_empty():
		return item.materials
	var resolved := resolve_materials_from_info(item.name, item.description, item.equip_pos, item.id)
	item.materials = resolved
	item.material_name = item.get_material_name()
	item.material_type = resolve_material_type(item.materials[0] if not item.materials.is_empty() else "Misc")
	return item.materials

static func resolve_material_name(item: ItemRecord) -> String:
	if not item:
		return "Misc"
	return item.get_material_name()

static func resolve_material_type(mat_name: String) -> int:
	return MATERIAL_TYPES.get(mat_name, 0)

static func resolve_material_name_from_dict(item_data: Dictionary) -> String:
	var n: String = str(item_data.get("name", ""))
	var d: String = str(item_data.get("description", ""))
	var p: int = int(item_data.get("equip_pos", 0))
	var id: int = int(item_data.get("id", 0))
	return resolve_material_name_from_info(n, d, p, id)

static func resolve_material_name_from_info(name_str: String, desc_str: String, equip_pos: int, item_id: int = 0) -> String:
	var mats := resolve_materials_from_info(name_str, desc_str, equip_pos, item_id)
	return ", ".join(mats) if not mats.is_empty() else "Misc"

static func resolve_materials_from_info(name_str: String, desc_str: String, equip_pos: int, item_id: int = 0) -> Array[String]:
	_ensure_compound_loaded()

	var text := (name_str + " " + desc_str).to_lower()
	var mats: Array[String] = []

	var is_raft := _has_word(text, "raft") or name_str.to_lower().strip_edges().begins_with("raft") or name_str.to_lower().contains(" raft")
	var is_bow := (_has_word(text, "bow") or name_str.to_lower().ends_with("bow") or name_str.to_lower().contains(" bow")) and not text.contains("bowl") and not text.contains("elbow")
	var is_wand_staff := _has_word(text, "wand") or _has_word(text, "staff") or _has_word(text, "rod") or name_str.to_lower().contains("wand") or name_str.to_lower().contains("staff")
	var is_bladed := text.contains("knife") or text.contains("dagger") or text.contains("sword") or text.contains("blade") or text.contains("rapier") or text.contains("saber") or text.contains("katana") or text.contains("falchion") or text.contains("scimitar") or text.contains("broadsword") or text.contains("claymore") or text.contains("cutlass") or text.contains("machete")
	var is_armor := equip_pos == 2 or text.contains("armor") or text.contains("mail") or text.contains("plate") or text.contains("cuirass") or text.contains("breastplate")
	var is_boots := equip_pos == 5 or text.contains("boots") or text.contains("shoes") or text.contains("greaves")

	var is_pure_material := equip_pos == 0 and not is_raft and not is_bladed and not is_armor and not is_boots and not is_bow and not is_wand_staff
	if KNOWN_MATERIAL_RANKS.has(item_id) or text.contains("material") or text.contains("ore") or text.contains("sand") or text.contains("block") or text.contains("bullion") or text.contains("fillet"):
		is_pure_material = true

	# Check authentic Compound2.Dat formula if item_id is provided and not a pure raw material base
	if not is_pure_material and item_id > 0 and _compound_recipes.has(item_id):
		var ing_ids: Array = _compound_recipes[item_id]
		for ing in ing_ids:
			var m_name := _resolve_material_from_id(int(ing))
			if not m_name.is_empty() and m_name != "Misc" and not mats.has(m_name):
				mats.append(m_name)

	# 1. Scanning constituent materials from name & description
	# Metals
	if text.contains("copper") and not mats.has("Copper"):
		mats.append("Copper")
	if text.contains("bronze") and not mats.has("Bronze"):
		mats.append("Bronze")
	if text.contains("steel") and not mats.has("Steel"):
		mats.append("Steel")
	if text.contains("iron") and not mats.has("Iron"):
		mats.append("Iron")
	if text.contains("titanium") and not mats.has("Titanium"):
		mats.append("Titanium")
	if text.contains("platinum") and not mats.has("Platinum"):
		mats.append("Platinum")
	if (text.contains("aluminum") or text.contains("aluminium")) and not mats.has("Aluminum"):
		mats.append("Aluminum")
	if text.contains("gold") and not mats.has("Gold"):
		mats.append("Gold")
	if (text.contains("silver") or text.contains("silvery")) and not mats.has("Silver"):
		mats.append("Silver")
	if _has_word(text, "lead") and not mats.has("Lead"):
		mats.append("Lead")
	if _has_word(text, "tin") and not mats.has("Tin"):
		mats.append("Tin")
	if text.contains("mercury") and not mats.has("Mercury"):
		mats.append("Mercury")

	# Minerals & Gems
	if text.contains("diamond") and not mats.has("Diamond"):
		mats.append("Diamond")
	if (text.contains("crystal") or text.contains("quartz")) and not mats.has("Crystal"):
		mats.append("Crystal")
	if (text.contains("jade") or text.contains("amethyst")) and not mats.has("Jade"):
		mats.append("Jade")
	if text.contains("ruby") and not mats.has("Ruby"):
		mats.append("Ruby")
	if text.contains("sapphire") and not mats.has("Sapphire"):
		mats.append("Sapphire")
	if text.contains("emerald") and not mats.has("Emerald"):
		mats.append("Emerald")
	if text.contains("opal") and not mats.has("Opal"):
		mats.append("Opal")
	if text.contains("stone") or text.contains("granite") or text.contains("marble") or text.contains("flint") or _has_word(text, "ore") or text.contains("rock"):
		if not mats.has("Stone"):
			mats.append("Stone")
	if text.contains("clay") or text.contains("ceramic") or text.contains("porcelain") or text.contains("pottery") or text.contains("tile"):
		if not mats.has("Clay"):
			mats.append("Clay")
	if text.contains("coal") and not mats.has("Coal"):
		mats.append("Coal")

	# Wood & Flora
	if text.contains("wood") or _has_word(text, "log") or text.contains("timber") or text.contains("oak") or _has_word(text, "pine") or text.contains("lauan") or text.contains("cypress"):
		if not mats.has("Wood"):
			mats.append("Wood")
	if text.contains("bamboo") and not mats.has("Bamboo"):
		mats.append("Bamboo")
	if text.contains("grass") or text.contains("hemp") or text.contains("straw") or text.contains("reed") or text.contains("vine") or text.contains("flax"):
		if not mats.has("Grass"):
			mats.append("Grass")
	if text.contains("feather") or text.contains("plume") or text.contains("down"):
		if not mats.has("Feather"):
			mats.append("Feather")
	if text.contains("fur") or text.contains("pelt"):
		if not mats.has("Fur"):
			mats.append("Fur")
	if text.contains("leather") or text.contains("hide"):
		if not mats.has("Leather"):
			mats.append("Leather")
	if text.contains("cloth") or text.contains("cotton") or text.contains("silk") or text.contains("linen") or text.contains("wool") or text.contains("fabric") or text.contains("thread") or text.contains("yarn"):
		if not mats.has("Cloth"):
			mats.append("Cloth")
	if text.contains("bone") or text.contains("horn") or text.contains("ivory") or text.contains("fang") or text.contains("tooth") or text.contains("skull"):
		if not mats.has("Bone"):
			mats.append("Bone")
	if text.contains("shellfish") or text.contains("shell") or text.contains("coral") or text.contains("clam") or text.contains("pearl") or text.contains("conch"):
		if not mats.has("Shellfish"):
			mats.append("Shellfish")
	if text.contains("fish") or text.contains("eel") or text.contains("salmon") or text.contains("trout") or text.contains("carp") or text.contains("tuna"):
		if not mats.has("Fish"):
			mats.append("Fish")
	if text.contains("meat") or text.contains("pork") or text.contains("beef") or text.contains("chicken") or text.contains("mutton") or text.contains("steak"):
		if not mats.has("Meat"):
			mats.append("Meat")
	if text.contains("grain") or text.contains("rice") or text.contains("wheat") or text.contains("barley") or text.contains("corn") or text.contains("flour") or text.contains("bread"):
		if not mats.has("Grain"):
			mats.append("Grain")
	if text.contains("herb") or text.contains("ginseng") or text.contains("mint") or text.contains("root") or text.contains("herbal"):
		if not mats.has("Herb"):
			mats.append("Herb")
	if text.contains("flower") or text.contains("rose") or text.contains("lily") or text.contains("petal") or text.contains("blossom"):
		if not mats.has("Flower"):
			mats.append("Flower")
	if _has_word(text, "water") or text.contains("dew") or text.contains("spring") or text.contains("juice"):
		if not mats.has("Water"):
			mats.append("Water")
	if text.contains("glass") and not mats.has("Glass"):
		mats.append("Glass")
	if text.contains("rubber") and not mats.has("Rubber"):
		mats.append("Rubber")
	if text.contains("paper") and not mats.has("Paper"):
		mats.append("Paper")
	if text.contains("plastic") and not mats.has("Plastic"):
		mats.append("Plastic")

	# Pure materials in WLODB (e.g. Ordinary Wood -> Wood, Copper Material -> Copper, Wolf Fur -> Fur)
	if is_pure_material and not mats.is_empty():
		return [mats[0]]

	# Special items (Raft, Bows, Wands/Staves)
	if is_raft:
		if not mats.has("Wood"):
			mats.append("Wood")
		if not mats.has("Grass"):
			mats.append("Grass")

	if is_bow:
		if not mats.has("Wood") and not mats.has("Bamboo"):
			mats.append("Wood")
		if not mats.has("Grass"):
			mats.append("Grass")

	if is_wand_staff:
		if not mats.has("Crystal") and not mats.has("Jade") and not mats.has("Ruby") and not mats.has("Diamond"):
			mats.insert(0, "Crystal")
		if not mats.has("Wood"):
			mats.append("Wood")
	elif text.contains("magic") and not mats.has("Magic"):
		mats.append("Magic")

	# Equipment complementary crafting components (WLODB / authentic WLO alchemy bases)
	if is_bladed or (equip_pos == 3 and not is_bow and not is_wand_staff):
		var has_metal := false
		for m in ["Copper", "Bronze", "Iron", "Steel", "Gold", "Silver", "Titanium", "Platinum", "Aluminum", "Lead", "Tin"]:
			if mats.has(m):
				has_metal = true
				break
		if has_metal and not mats.has("Wood"):
			mats.append("Wood")

	if is_armor:
		var has_metal := false
		for m in ["Copper", "Bronze", "Iron", "Steel", "Gold", "Silver", "Titanium", "Platinum", "Aluminum"]:
			if mats.has(m):
				has_metal = true
				break
		if has_metal and not mats.has("Leather") and not mats.has("Cloth"):
			mats.append("Leather")

	if is_boots:
		var has_metal := false
		for m in ["Copper", "Bronze", "Iron", "Steel", "Gold", "Silver", "Titanium", "Platinum", "Aluminum"]:
			if mats.has(m):
				has_metal = true
				break
		if has_metal and not mats.has("Leather"):
			mats.append("Leather")
		elif text.contains("heavy") and not mats.has("Iron") and not mats.has("Steel"):
			if not mats.has("Iron"):
				mats.insert(0, "Iron")
			if not mats.has("Leather"):
				mats.append("Leather")
		elif mats.has("Feather") and not mats.has("Leather"):
			mats.append("Leather")

	# Fallback if empty
	if mats.is_empty():
		match equip_pos:
			3: mats = ["Iron", "Wood"]
			1, 2: mats = ["Cloth"]
			4, 5: mats = ["Leather"]
			6: mats = ["Silver"]
			_: mats = ["Misc"]

	return mats

	# Fallback if empty
	if mats.is_empty():
		match equip_pos:
			3: mats = ["Iron", "Wood"]
			1, 2: mats = ["Cloth"]
			4, 5: mats = ["Leather"]
			6: mats = ["Silver"]
			_: mats = ["Misc"]

	return mats

static func decode_byte(v: int) -> int:
	return ((v ^ 0x9a) - 9) & 0xff

static func decode_word(v: int) -> int:
	return ((v ^ 0xefc3) - 9) & 0xffff

static func decode_dword(v: int) -> int:
	return ((v ^ 0x0b80f4b4) - 9) & 0xffffffff

## Loads 47-byte pre-indexed item records from itemDat.wpdat
func load_from_wpdat(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		return false
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return false
	
	var data := file.get_buffer(file.get_length())
	var rec_size: int = 47
	var total_records: int = data.size() / rec_size
	
	for i in range(total_records):
		var offset: int = i * rec_size
		var name_len: int = data[offset]
		var raw_name: PackedByteArray = data.slice(offset + 1, offset + 1 + mini(name_len, 20))
		var nul_idx := raw_name.find(0)
		if nul_idx != -1:
			raw_name = raw_name.slice(0, nul_idx)
		
		var name_str := raw_name.get_string_from_ascii().strip_edges()
		if name_str.is_empty():
			name_str = raw_name.get_string_from_utf8().strip_edges()
		
		var item_type: int = data[offset + 21]
		var item_id: int = data.decode_u16(offset + 22)
		var icon_num: int = data.decode_u16(offset + 24)
		var large_icon: int = data.decode_u16(offset + 26)
		var equip_pos: int = data.decode_u16(offset + 28)
		var level: int = data.decode_u16(offset + 30)
		var rank: int = data[offset + 32]
		var st1: int = data.decode_u16(offset + 35)
		var st2: int = data.decode_u16(offset + 37)
		var su1: int = data.decode_s32(offset + 39)
		var su2: int = data.decode_s32(offset + 43)
		
		if item_id == 0:
			continue
		
		var item: ItemRecord = _items.get(item_id, null)
		if not item:
			item = ItemRecord.new()
			item.id = item_id
			_items[item_id] = item
		
		item.name = name_str if not name_str.is_empty() else ("Item_%d" % item_id)
		item.icon_id = icon_num
		item.large_icon_id = large_icon
		item.item_type = item_type
		item.equip_pos = equip_pos
		item.level = level
		item.rank = rank
		item.status_types = [st1, st2]
		item.status_values = [su1, su2]
		item.materials = resolve_materials(item)
		item.material_name = item.get_material_name()
		item.material_type = resolve_material_type(item.materials[0] if not item.materials.is_empty() else item.material_name)
		item.rank = item.get_rank()
	
	return not _items.is_empty()

## Decodes the 451-byte binary records from Item.dat (augmenting names/descriptions/stats)
func load_from_file(file_path: String) -> bool:
	# First, attempt to load itemDat.wpdat if located in same folder or fallback paths
	var dir := file_path.get_base_dir()
	var wpdat_path := dir + "/itemDat.wpdat"
	if FileAccess.file_exists(wpdat_path):
		load_from_wpdat(wpdat_path)
	elif FileAccess.file_exists("res://assets/data/itemDat.wpdat"):
		load_from_wpdat("res://assets/data/itemDat.wpdat")
	elif FileAccess.file_exists("D:/Godot/WonderlandOnline/wonderland-online-client/assets/data/itemDat.wpdat"):
		load_from_wpdat("D:/Godot/WonderlandOnline/wonderland-online-client/assets/data/itemDat.wpdat")
	elif FileAccess.file_exists("D:/GitHub/Wonderland-Private-Server/Data/itemDat.wpdat"):
		load_from_wpdat("D:/GitHub/Wonderland-Private-Server/Data/itemDat.wpdat")
	
	if not FileAccess.file_exists(file_path):
		return not _items.is_empty()
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return not _items.is_empty()
	
	var data := file.get_buffer(file.get_length())
	var rec_size: int = 451
	var total_records: int = data.size() / rec_size
	
	for i in range(1, total_records):
		var offset: int = i * rec_size
		if offset + rec_size > data.size():
			break
		
		var rec: PackedByteArray = data.slice(offset, offset + rec_size)
		
		# Decrypt unique Item ID at offset 0x10
		var raw_id: int = rec.decode_u16(0x10)
		var item_id: int = decode_word(raw_id)
		if item_id == 0 or item_id == 60003: # 60003 is encrypted 0
			continue
		
		# Decrypt authentic fields matching PhoenixData.dll & Delphi layouts:
		# 0x0F: Item Type (1 byte, decode_byte)
		# 0x10: Item ID (uint16, decode_word)
		# 0x12: Small Icon ID (uint16, decode_word)
		# 0x14: Large Icon ID (uint16, decode_word)
		# 0x2E: Equip Position / Wear slot (1 byte, decode_byte)
		var raw_type: int = rec[0x0f]
		var item_type: int = decode_byte(raw_type)
		var raw_icon: int = rec.decode_u16(0x12)
		var icon_id: int = decode_word(raw_icon)
		var raw_large: int = rec.decode_u16(0x14)
		var large_icon: int = decode_word(raw_large)
		var raw_equip: int = rec[0x2e]
		var equip_pos: int = decode_byte(raw_equip)
		
		# Decrypt authentic constituent materials at offsets 0x88, 0x8A, 0x8C, 0x8E, 0x90
		var auth_mats: Array[String] = []
		for m_off in [0x88, 0x8a, 0x8c, 0x8e, 0x90]:
			var raw_mid: int = rec.decode_u16(m_off)
			var mid: int = decode_word(raw_mid)
			if mid > 0 and WLO_AUTHENTIC_MATERIALS.has(mid):
				var m_name: String = WLO_AUTHENTIC_MATERIALS[mid]
				if not auth_mats.has(m_name):
					auth_mats.append(m_name)
		
		# 1. Reverse Name string: characters stored in rec[15 - name_len .. 14] in reverse order
		var name_len: int = rec[0]
		var name_str := ""
		if name_len > 0 and name_len <= 14:
			var n_bytes := rec.slice(15 - name_len, 15)
			var rev_bytes := PackedByteArray()
			rev_bytes.resize(name_len)
			for b in range(name_len):
				rev_bytes[b] = n_bytes[name_len - 1 - b]
			var nul_idx := rev_bytes.find(0)
			if nul_idx != -1:
				rev_bytes = rev_bytes.slice(0, nul_idx)
			name_str = rev_bytes.get_string_from_ascii().strip_edges()
			if name_str.is_empty():
				name_str = rev_bytes.get_string_from_utf8().strip_edges()
		
		# 2. Reverse Description: characters stored in rec[0x191 - desc_len .. 0x190] in reverse order
		var desc_len: int = rec[0x92]
		var desc_str := ""
		if desc_len > 0 and desc_len <= 200:
			var d_bytes := rec.slice(0x191 - desc_len, 0x191)
			var rev_desc := PackedByteArray()
			rev_desc.resize(desc_len)
			for b in range(desc_len):
				rev_desc[b] = d_bytes[desc_len - 1 - b]
			var nul_idx := rev_desc.find(0)
			if nul_idx != -1:
				rev_desc = rev_desc.slice(0, nul_idx)
			desc_str = rev_desc.get_string_from_ascii().strip_edges()
			if desc_str.is_empty():
				desc_str = rev_desc.get_string_from_utf8().strip_edges()
		
		var item: ItemRecord = _items.get(item_id, null)
		if not item:
			item = ItemRecord.new()
			item.id = item_id
			item.name = name_str if not name_str.is_empty() else ("Item_%d" % item_id)
			item.icon_id = icon_id
			item.large_icon_id = large_icon
			item.item_type = item_type
			item.equip_pos = equip_pos
			_items[item_id] = item
		else:
			if not name_str.is_empty() and (item.name.begins_with("Item_") or item.name.is_empty()):
				item.name = name_str
			if item.icon_id == 0 and icon_id != 0:
				item.icon_id = icon_id
			if item.large_icon_id == 0 and large_icon != 0:
				item.large_icon_id = large_icon
			if item.equip_pos == 0 and equip_pos != 0:
				item.equip_pos = equip_pos
			if item.item_type == 0 and item_type != 0:
				item.item_type = item_type
		
		if not desc_str.is_empty():
			item.description = desc_str
		_apply_dat_fields(item, rec)
		if not auth_mats.is_empty():
			item.authentic_materials = auth_mats
	
	for it: ItemRecord in _items.values():
		it.materials = resolve_materials(it)
		it.material_name = it.get_material_name()
		it.material_type = resolve_material_type(it.materials[0] if not it.materials.is_empty() else it.material_name)
		it.rank = it.get_rank()
	
	return not _items.is_empty()

## Copies the Item.dat fields the real client reads (offsets are record-relative; aLogin adds 4).
static func _apply_dat_fields(item: ItemRecord, rec: PackedByteArray) -> void:
	item.has_dat_record = true
	item.item_type = decode_byte(rec[0x0f])
	item.equip_pos = decode_byte(rec[0x2e])
	item.rank = decode_byte(rec[0x2d])
	item.kind = decode_byte(rec[0x2f])
	item.level = decode_byte(rec[0x71])
	item.buy_price = decode_dword(rec.decode_u32(0x72))
	item.sell_price = decode_dword(rec.decode_u32(0x76))
	item.flags = decode_word(rec.decode_u16(0x7b))
	item.set_id = decode_byte(rec[0x81])
	item.grid_w = maxi(1, decode_byte(rec[0x196]))
	item.grid_h = maxi(1, decode_byte(rec[0x197]))
	item.time_limit_hours = decode_word(rec.decode_u16(0x1a5))
	item.max_uses = decode_word(rec.decode_u16(0x1a7))
	var types: Array[int] = [decode_word(rec.decode_u16(0x1e)), decode_word(rec.decode_u16(0x20))]
	var values: Array[int] = [decode_dword(rec.decode_u32(0x24)), decode_dword(rec.decode_u32(0x28))]
	item.status_types = types
	item.status_values = values

func get_item(item_id: int) -> ItemRecord:
	var item: ItemRecord = _items.get(item_id)
	if item:
		if item.materials.is_empty():
			item.materials = resolve_materials(item)
			item.material_name = item.get_material_name()
			item.material_type = resolve_material_type(item.materials[0] if not item.materials.is_empty() else item.material_name)
		if item.rank == 0:
			item.rank = item.get_rank()
	return item

func get_all_items() -> Dictionary:
	return _items
