class_name ItemData
extends RefCounted

## Represents a parsed and decrypted item record from Item.dat.

var id: int = 0
var name: String = ""
var description: String = ""
var icon_id: int = 0
var item_type: int = 0
var buy_price: int = 0
var sell_price: int = 0
var level_req: int = 0
var durability: int = 0
var attributes: Dictionary = {}
var rank: int = 0
var material_type: int = 0
var material_name: String = ""
var materials: Array[String] = []

func get_rank() -> int:
	if rank > 0:
		return rank
	return maxi(1, int(level_req / 2)) if level_req > 0 else 1

func get_material_name() -> String:
	if not materials.is_empty():
		return ", ".join(materials)
	if not material_name.is_empty():
		return material_name
	return "Misc"

func get_materials() -> Array[String]:
	return materials

func set_materials(new_mats: Array) -> void:
	materials.clear()
	for m in new_mats:
		materials.append(str(m))

func is_valid() -> bool:
	return id > 0 and not name.is_empty()

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"icon_id": icon_id,
		"item_type": item_type,
		"buy_price": buy_price,
		"sell_price": sell_price,
		"level_req": level_req,
		"durability": durability,
		"attributes": attributes,
		"rank": get_rank(),
		"materials": materials,
		"material_name": get_material_name(),
		"material_type": material_type
	}

func _to_string() -> String:
	return "ItemData(id=%d, name='%s', icon=%d, type=%d, rank=%d, mat='%s')" % [id, name, icon_id, item_type, get_rank(), get_material_name()]
