extends SceneTree

## Headless tests for RepairWindow (Form_Repair, 0x1ac9f0): geometry, durability restore from the
## item dict / ItemDatabase record, battle guard, "Broken" ids, cost placeholder.

const RepairScene = preload("res://scenes/ui/repair/repair_window.tscn")

var _fail: int = 0
var _count: int = 0


func _init() -> void:
	for n in ["ArchiveLoader:res://scripts/core/archive_loader.gd", "GameDatabase:res://scripts/database/game_database.gd"]:
		var parts: PackedStringArray = n.split(":", true, 1)
		if not root.has_node(parts[0]):
			var node: Node = load(parts[1]).new()
			node.name = parts[0]
			root.add_child(node)
	_run()
	print("--- %d checks, %d failed ---" % [_count, _fail])
	quit(1 if _fail > 0 else 0)


func _check(cond: bool, name: String, detail: String = "") -> void:
	_count += 1
	if cond:
		print("  [PASS] " + name)
	else:
		_fail += 1
		printerr("  [FAIL] %s %s" % [name, detail])


func _run() -> void:
	var inv := HUDInventory.new()
	inv.inventory_data.resize(45)
	for i in range(45):
		inv.inventory_data[i] = {}
	inv.current_gold = 100
	inv.set_inventory_data_item(0, {"id": 11001, "count": 1, "name": "Sword", "equip_slot": "weapon", "durability": 10, "max_durability": 50})
	inv.set_inventory_data_item(1, {"id": 32011, "count": 3, "name": "Bread", "equip_slot": ""})
	inv.set_inventory_data_item(2, {"id": 11098, "count": 1, "name": "Broken Sword", "equip_slot": "weapon", "durability": 0, "max_durability": 50})
	inv.set_inventory_data_item(3, {"id": 11001, "count": 1, "name": "Sword", "equip_slot": "weapon", "durability": 50, "max_durability": 50})
	inv.set_inventory_data_item(4, {"id": 11001, "count": 1, "name": "Sword", "equip_slot": "weapon"})

	var w: RepairWindow = RepairScene.instantiate()
	root.add_child(w)
	_check(w.size == Vector2(171, 183) and w.background.texture != null, "171x183 Form_Repair skin")
	_check(w.background.texture.get_image().get_pixel(0, 0).a == 0.0, "chroma key removed")
	_check(w.item_slot.position == Vector2(70, 71) and w.item_slot.size == Vector2(32, 32), "SelectUitem (70,71) 32x32")
	_check(w.btn_ok.position == Vector2(37, 142) and w.btn_ok.size == Vector2(39, 20), "Btn_OK_2 (37,142) 39x20")
	_check(w.btn_cancel.position == Vector2(93, 142) and w.btn_ok.texture_normal != null, "Btn_Cancel_3 (93,142)")
	var msgs: Array = []
	w.message.connect(func(t: String) -> void: msgs.append(t))
	w.open_repair(inv)
	_check(not w.repair_selected(), "OK with empty cell does nothing")
	_check(w.select_inventory_slot(0) and w.item_slot.item.get("name") == "Sword", "item copied into the cell")
	w.in_battle = true
	_check(not w.repair_selected() and msgs.has("Can't fix in battle"), "battle guard")
	w.in_battle = false
	var repaired: Array = []
	w.item_repaired.connect(func(i: int, it: Dictionary, c: int) -> void: repaired.append([i, it, c]))
	_check(w.repair_selected(), "repair")
	_check(int(inv.inventory_data[0]["durability"]) == 50, "durability restored to max")
	_check(msgs.has("Sword Repaired") and repaired.size() == 1, "message + signal")
	w.select_inventory_slot(1)
	_check(not w.repair_selected(), "consumable refused")
	w.select_inventory_slot(2)
	_check(not w.repair_selected() and int(inv.inventory_data[2]["durability"]) == 0, "Broken Sword (11098) silently refused")
	w.select_inventory_slot(3)
	_check(not w.repair_selected() and msgs.has("Doesn't need repairs"), "full durability")
	# durability from the ItemDatabase record when the dict has none
	var rec: Variant = SkinWindowKit.item_record(11001)
	var dur: Vector2i = w.get_durability(inv.inventory_data[4])
	if rec != null:
		_check(dur == Vector2i(rec.durability, rec.max_durability), "durability falls back to the ItemDatabase record", str(dur))
	else:
		_check(dur.y == 0, "no record -> 0")
	# cost placeholder
	w.cost_per_point = 5
	inv.set_inventory_data_item(0, {"id": 11001, "count": 1, "name": "Sword", "equip_slot": "weapon", "durability": 30, "max_durability": 50})
	w.select_inventory_slot(0)
	_check(w.get_repair_cost(inv.inventory_data[0]) == 100, "cost = missing points x cost_per_point")
	_check(w.repair_selected() and inv.current_gold == 0, "gold charged")
	inv.set_inventory_data_item(0, {"id": 11001, "count": 1, "name": "Sword", "equip_slot": "weapon", "durability": 49, "max_durability": 50})
	w.select_inventory_slot(0)
	_check(not w.repair_selected() and msgs.has("Not enough Gold"), "not enough gold")
	w.close_window()
	_check(not w.visible and w.selected_bag_index == -1, "cancel/close clears")
	w.queue_free()
