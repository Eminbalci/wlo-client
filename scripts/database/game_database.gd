extends Node

## Master game database coordinator for Wonderland Online.
## Centralizes access to Item, Scene, NPC, and Skill databases,
## as well as authentic playable character role definitions.

const ItemDatabase = preload("res://scripts/database/item_database.gd")
const SceneDatabase = preload("res://scripts/database/scene_database.gd")
const NpcDatabase = preload("res://scripts/database/npc_database.gd")
const SkillDatabase = preload("res://scripts/database/skill_database.gd")
const TalkDatabase = preload("res://scripts/database/talk_database.gd")

signal databases_loaded

## Authentic playable character role definitions (Role ID 1 to 14)
## Reverse-engineered from aLogin.exe (tables at 0x4a32c0 and 0x220b88) and WLO server databases.
const ROLES: Dictionary = {
	1: {
		"id": 1,
		"name": "Nina",
		"gender": "Female",
		"body_type": "Small Female",
		"element": "Fire",
		"body_archive": "003.jma",
		"body_jmp": "3000.jmp",
		"face_archive": "003f.jma",
		"face_jmp": "3600.jmp",
		"hair_archive": "003h.jma",
		"hair_jmp": "3100.jmp",
		"default_clothes_archive": "003e.jma",
		"default_clothes_jmp": "3300.jmp",
		"default_clothes_item_id": 21002, # Small Dress
		"default_shoes_archive": "003s.jma",
		"default_shoes_jmp": "3400.jmp",
		"default_shoes_item_id": 24002, # Baby Shoes
		"default_head_archive": "003c.jma",
		"default_head_jmp": "3203.jmp",
		"default_head_item_id": 22003, # Star Headdress
		"portrait_bmp": "menu/Skins/default/Btn_RolePic_1.bmp",
		"stunt_skill_id": 15039, # Wine Flame
		"str": 8, "con": 9, "int": 10, "wis": 9, "agi": 8
	},
	2: {
		"id": 2,
		"name": "Betty",
		"gender": "Female",
		"body_type": "Small Female",
		"element": "Wind",
		"body_archive": "003.jma",
		"body_jmp": "3000.jmp",
		"face_archive": "003f.jma",
		"face_jmp": "3601.jmp",
		"hair_archive": "003h.jma",
		"hair_jmp": "3101.jmp",
		"default_clothes_archive": "003e.jma",
		"default_clothes_jmp": "3301.jmp",
		"default_clothes_item_id": 21003, # Harness Pants
		"default_shoes_archive": "003s.jma",
		"default_shoes_jmp": "3401.jmp",
		"default_shoes_item_id": 24003, # Pink Shoes
		"default_head_archive": "003c.jma",
		"default_head_jmp": "3201.jmp",
		"default_head_item_id": 22001, # Feather Head
		"portrait_bmp": "menu/Skins/default/Btn_RolePic_2.bmp",
		"stunt_skill_id": 12036, # Leap
		"str": 10, "con": 10, "int": 6, "wis": 6, "agi": 18
	},
	3: {
		"id": 3,
		"name": "Rocco",
		"gender": "Male",
		"body_type": "Small Male",
		"element": "Earth",
		"body_archive": "002.jma",
		"body_jmp": "2000.jmp",
		"face_archive": "002f.jma",
		"face_jmp": "2600.jmp",
		"hair_archive": "002h.jma",
		"hair_jmp": "2100.jmp",
		"default_clothes_archive": "002e.jma",
		"default_clothes_jmp": "2300.jmp",
		"default_clothes_item_id": 21001, # Boy's Suit
		"default_shoes_archive": "002s.jma",
		"default_shoes_jmp": "2400.jmp",
		"default_shoes_item_id": 24001, # Moppet's Shoes
		"default_head_archive": "002c.jma",
		"default_head_jmp": "2200.jmp",
		"default_head_item_id": 22004, # Lovely Headdress
		"portrait_bmp": "menu/Skins/default/Btn_RolePic_3.bmp",
		"stunt_skill_id": 11075, # Summon Dogs Groups
		"str": 10, "con": 10, "int": 8, "wis": 8, "agi": 10
	},
	4: {
		"id": 4,
		"name": "Vanessa",
		"gender": "Female",
		"body_type": "Big Female",
		"element": "Water",
		"body_archive": "005.jma",
		"body_jmp": "5000.jmp",
		"face_archive": "005f.jma",
		"face_jmp": "5602.jmp",
		"hair_archive": "005h.jma",
		"hair_jmp": "5102.jmp",
		"default_clothes_archive": "005e.jma",
		"default_clothes_jmp": "5302.jmp",
		"default_clothes_item_id": 21008, # Uniform
		"default_shoes_archive": "005s.jma",
		"default_shoes_jmp": "5402.jmp",
		"default_shoes_item_id": 24008, # Student's Shoes
		"default_head_archive": "005c.jma",
		"default_head_jmp": "5200.jmp",
		"default_head_item_id": 22002,
		"portrait_bmp": "menu/Skins/default/Btn_RolePic_4.bmp",
		"stunt_skill_id": 15042,
		"str": 7, "con": 8, "int": 12, "wis": 12, "agi": 9
	},
	5: {
		"id": 5,
		"name": "Lique",
		"gender": "Female",
		"body_type": "Big Female",
		"element": "Wind",
		"body_archive": "005.jma",
		"body_jmp": "5000.jmp",
		"face_archive": "005f.jma",
		"face_jmp": "5601.jmp",
		"hair_archive": "005h.jma",
		"hair_jmp": "5101.jmp",
		"default_clothes_archive": "005e.jma",
		"default_clothes_jmp": "5301.jmp",
		"default_clothes_item_id": 21007, # Racing Suit
		"default_shoes_archive": "005s.jma",
		"default_shoes_jmp": "5401.jmp",
		"default_shoes_item_id": 24007, # Racing Shoes
		"default_head_archive": "",
		"default_head_jmp": "",
		"default_head_item_id": 0,
		"portrait_bmp": "menu/Skins/default/Btn_RolePic_5.bmp",
		"stunt_skill_id": 15041,
		"str": 11, "con": 9, "int": 7, "wis": 7, "agi": 14
	},
	6: {
		"id": 6,
		"name": "Daniel",
		"gender": "Male",
		"body_type": "Big Male",
		"element": "Fire",
		"body_archive": "004.jma",
		"body_jmp": "4000.jmp",
		"face_archive": "004f.jma",
		"face_jmp": "4601.jmp",
		"hair_archive": "004h.jma",
		"hair_jmp": "4101.jmp",
		"default_clothes_archive": "004e.jma",
		"default_clothes_jmp": "4300.jmp",
		"default_clothes_item_id": 21004, # Dust Coat
		"default_shoes_archive": "004s.jma",
		"default_shoes_jmp": "4400.jmp",
		"default_shoes_item_id": 24004, # Gentleman's Shoes
		"default_head_archive": "",
		"default_head_jmp": "",
		"default_head_item_id": 0,
		"portrait_bmp": "menu/Skins/default/Btn_RolePic_6.bmp",
		"stunt_skill_id": 15038, # Shoulder Throw
		"str": 14, "con": 12, "int": 6, "wis": 5, "agi": 11
	},
	7: {
		"id": 7,
		"name": "Sid",
		"gender": "Male",
		"body_type": "Big Male",
		"element": "Earth",
		"body_archive": "004.jma",
		"body_jmp": "4000.jmp",
		"face_archive": "004f.jma",
		"face_jmp": "4600.jmp",
		"hair_archive": "004h.jma",
		"hair_jmp": "4100.jmp",
		"default_clothes_archive": "004e.jma",
		"default_clothes_jmp": "4301.jmp",
		"default_clothes_item_id": 21005, # Jeans
		"default_shoes_archive": "004s.jma",
		"default_shoes_jmp": "4401.jmp",
		"default_shoes_item_id": 24005, # Leisure Shoes
		"default_head_archive": "",
		"default_head_jmp": "",
		"default_head_item_id": 0,
		"portrait_bmp": "menu/Skins/default/Btn_RolePic_7.bmp",
		"stunt_skill_id": 11076, # Combo x3 Attack
		"str": 13, "con": 11, "int": 6, "wis": 6, "agi": 12
	},
	8: {
		"id": 8,
		"name": "Jessica",
		"gender": "Female",
		"body_type": "Big Female",
		"element": "Water",
		"body_archive": "005.jma",
		"body_jmp": "5000.jmp",
		"face_archive": "005f.jma",
		"face_jmp": "5604.jmp",
		"hair_archive": "005h.jma",
		"hair_jmp": "5104.jmp",
		"default_clothes_archive": "005e.jma",
		"default_clothes_jmp": "5304.jmp",
		"default_clothes_item_id": 21010, # Violinists Suit
		"default_shoes_archive": "005s.jma",
		"default_shoes_jmp": "5404.jmp",
		"default_shoes_item_id": 24010, # High-Heeled Shoes
		"default_head_archive": "005c.jma",
		"default_head_jmp": "5200.jmp",
		"default_head_item_id": 22002, # Flower Headdress
		"portrait_bmp": "menu/Skins/default/Btn_RolePic_8.bmp",
		"stunt_skill_id": 15044,
		"str": 8, "con": 8, "int": 14, "wis": 13, "agi": 8
	},
	9: {
		"id": 9,
		"name": "Konnotsuroko",
		"gender": "Female",
		"body_type": "Big Female",
		"element": "Water",
		"body_archive": "005.jma",
		"body_jmp": "5000.jmp",
		"face_archive": "005f.jma",
		"face_jmp": "5605.jmp",
		"hair_archive": "005h.jma",
		"hair_jmp": "5105.jmp",
		"default_clothes_archive": "005e.jma",
		"default_clothes_jmp": "5305.jmp",
		"default_clothes_item_id": 21013, # Kimono
		"default_shoes_archive": "005s.jma",
		"default_shoes_jmp": "5405.jmp",
		"default_shoes_item_id": 24013, # Wooden Shoes
		"default_head_archive": "",
		"default_head_jmp": "",
		"default_head_item_id": 0,
		"portrait_bmp": "menu/Skins/default/Btn_RolePic_9.bmp",
		"stunt_skill_id": 15045,
		"str": 9, "con": 9, "int": 11, "wis": 11, "agi": 10
	},
	10: {
		"id": 10,
		"name": "Iris",
		"gender": "Female",
		"body_type": "Big Female",
		"element": "Water",
		"body_archive": "005.jma",
		"body_jmp": "5000.jmp",
		"face_archive": "005f.jma",
		"face_jmp": "5600.jmp",
		"hair_archive": "005h.jma",
		"hair_jmp": "5100.jmp",
		"default_clothes_archive": "005e.jma",
		"default_clothes_jmp": "5300.jmp",
		"default_clothes_item_id": 21006, # Sailor's Suit
		"default_shoes_archive": "005s.jma",
		"default_shoes_jmp": "5400.jmp",
		"default_shoes_item_id": 24006, # White Boots
		"default_head_archive": "005c.jma",
		"default_head_jmp": "5205.jmp",
		"default_head_item_id": 22005, # Sailor's Hat
		"portrait_bmp": "menu/Skins/default/Btn_RolePic_10.bmp",
		"stunt_skill_id": 12037,
		"str": 8, "con": 8, "int": 12, "wis": 12, "agi": 10
	},
	11: {
		"id": 11,
		"name": "Maria",
		"gender": "Female",
		"body_type": "Big Female",
		"element": "Water",
		"body_archive": "005.jma",
		"body_jmp": "5000.jmp",
		"face_archive": "005f.jma",
		"face_jmp": "5606.jmp",
		"hair_archive": "005h.jma",
		"hair_jmp": "5106.jmp",
		"default_clothes_archive": "005e.jma",
		"default_clothes_jmp": "5306.jmp",
		"default_clothes_item_id": 21011, # Nurse Clothes
		"default_shoes_archive": "005s.jma",
		"default_shoes_jmp": "5406.jmp",
		"default_shoes_item_id": 24011, # White Leather
		"default_head_archive": "005c.jma",
		"default_head_jmp": "5206.jmp",
		"default_head_item_id": 22006, # Nurse's Hat
		"portrait_bmp": "menu/Skins/default/Btn_RolePic_11.bmp",
		"stunt_skill_id": 11077, # Cure 2 Players
		"str": 7, "con": 8, "int": 13, "wis": 14, "agi": 8
	},
	12: {
		"id": 12,
		"name": "More",
		"gender": "Male",
		"body_type": "Big Male",
		"element": "Earth",
		"body_archive": "004.jma",
		"body_jmp": "4000.jmp",
		"face_archive": "004f.jma",
		"face_jmp": "4602.jmp",
		"hair_archive": "004h.jma",
		"hair_jmp": "4102.jmp",
		"default_clothes_archive": "004e.jma",
		"default_clothes_jmp": "4302.jmp",
		"default_clothes_item_id": 21012, # Bartender Uniform
		"default_shoes_archive": "004s.jma",
		"default_shoes_jmp": "4402.jmp",
		"default_shoes_item_id": 24012, # Great Pumps
		"default_head_archive": "",
		"default_head_jmp": "",
		"default_head_item_id": 0,
		"portrait_bmp": "menu/Skins/default/Btn_RolePic_12.bmp",
		"stunt_skill_id": 11183, # Deacon Attack
		"str": 12, "con": 11, "int": 8, "wis": 8, "agi": 10
	},
	13: {
		"id": 13,
		"name": "Kurogane",
		"gender": "Male",
		"body_type": "Big Male",
		"element": "Fire",
		"body_archive": "004.jma",
		"body_jmp": "4000.jmp",
		"face_archive": "004f.jma",
		"face_jmp": "4603.jmp",
		"hair_archive": "004h.jma",
		"hair_jmp": "4103.jmp",
		"default_clothes_archive": "004e.jma",
		"default_clothes_jmp": "4303.jmp",
		"default_clothes_item_id": 21014, # Craftsman's Clothes
		"default_shoes_archive": "004s.jma",
		"default_shoes_jmp": "4403.jmp",
		"default_shoes_item_id": 24014, # Craftsman Shoes
		"default_head_archive": "004c.jma",
		"default_head_jmp": "4209.jmp",
		"default_head_item_id": 22009, # Headscarf
		"portrait_bmp": "menu/Skins/default/Btn_RolePic_13.bmp",
		"stunt_skill_id": 11182, # Ghost Hammer
		"str": 15, "con": 13, "int": 5, "wis": 5, "agi": 9
	},
	14: {
		"id": 14,
		"name": "Karin",
		"gender": "Female",
		"body_type": "Big Female",
		"element": "Fire",
		"body_archive": "005.jma",
		"body_jmp": "5000.jmp",
		"face_archive": "005f.jma",
		"face_jmp": "5607.jmp",
		"hair_archive": "005h.jma",
		"hair_jmp": "5107.jmp",
		"default_clothes_archive": "005e.jma",
		"default_clothes_jmp": "5307.jmp",
		"default_clothes_item_id": 21015, # Uniform
		"default_shoes_archive": "005s.jma",
		"default_shoes_jmp": "5407.jmp",
		"default_shoes_item_id": 24015, # Leather Shoes
		"default_head_archive": "005c.jma",
		"default_head_jmp": "5208.jmp",
		"default_head_item_id": 22008, # Band
		"portrait_bmp": "menu/Skins/default/Btn_RolePic_14.bmp",
		"stunt_skill_id": 15040, # Palm
		"str": 11, "con": 10, "int": 7, "wis": 7, "agi": 13
	}
}

var data_directory: String = "res://assets/data"

var items = ItemDatabase.new()
var scenes = SceneDatabase.new()
var npcs = NpcDatabase.new()
var skills = SkillDatabase.new()
var talks = TalkDatabase.new()

var is_loaded: bool = false
var active_character: Dictionary = {}

func _init() -> void:
	if not DirAccess.dir_exists_absolute(data_directory) and DirAccess.dir_exists_absolute("D:/GitHub/WLRI/data"):
		data_directory = "D:/GitHub/WLRI/data"

func _ready() -> void:
	load_all()

func load_all() -> void:
	var item_ok: bool = items.load_from_file(data_directory + "/Item.dat")
	var scene_ok: bool = scenes.load_from_file(data_directory + "/SceneData.dat")
	var npc_ok: bool = npcs.load_from_file(data_directory + "/Npc.dat")
	var skill_ok: bool = skills.load_from_file(data_directory + "/Skill.dat")
	var talk_ok: bool = talks.load_from_file(data_directory + "/Talk.dat", data_directory + "/Npc.dat", data_directory + "/Eve.emg")
	
	var mbtm_path: String = data_directory + "/SkillData.MBTM"
	if FileAccess.file_exists(mbtm_path):
		skills.load_mbtm_from_file(mbtm_path)
	
	is_loaded = item_ok and scene_ok and talk_ok
	databases_loaded.emit()
	print("[GameDatabase] Initialized: %d items, %d scenes, %d NPCs, %d skills (%d MBTM anims), %d talks, %d roles" % [
		items.get_all_items().size(),
		scenes.get_all_scenes().size(),
		npcs.get_all_npcs().size(),
		skills.get_all_skills().size(),
		skills.get_mbtm_count(),
		talks.get_count(),
		ROLES.size()
	])

## Returns authentic dialogue record by Talk ID
func get_talk(talk_id: int) -> Dictionary:
	if talks:
		return talks.get_talk(talk_id)
	return {}

## Returns SkillRecord for skill_id
func get_skill(skill_id: int) -> SkillDatabase.SkillRecord:
	return skills.get_skill(skill_id)

## Returns starter stunt skill for role_id (1..14)
func get_starter_stunt_for_role(role_id: int) -> SkillDatabase.SkillRecord:
	return skills.get_starter_skill_for_role(role_id)

## Returns starter skill loadout for role_id (1..14)
func get_starter_skills_for_role(role_id: int) -> Array[SkillDatabase.SkillRecord]:
	return skills.get_starter_skills_for_role(role_id)

## Returns the authentic role definition dictionary for role_id (1..14), or Role 2 (Betty) by default
func get_role(role_id: int) -> Dictionary:
	if ROLES.has(role_id):
		return ROLES[role_id].duplicate()
	return ROLES[2].duplicate()

## Returns all authentic role definitions
func get_all_roles() -> Dictionary:
	return ROLES.duplicate()

## Returns the character name for role_id
func get_role_name(role_id: int) -> String:
	if ROLES.has(role_id):
		return str(ROLES[role_id].get("name", "Betty"))
	return "Betty"

