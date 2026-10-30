extends SceneTree

## Headless tests for WarehouseWindow (Form_itemBank_1, 0x1f8850): geometry, deposit/withdraw with
## multi-select, messages, stacking, and persistence to a user:// JSON file.

const WarehouseScene = preload("res://scenes/ui/warehouse/warehouse_window.tscn")
const SAVE: String = "user://test_warehouse.json"

var _fail: int = 0
var _count: int = 0


func _init() -> void:
	for n in ["ArchiveLoader:res://scripts/core/archive_loader.gd", "GameDatabase:res://scripts/database/game_database.gd"]:
		var parts: PackedStringArray = n.split(":", true, 1)
		if not root.has_node(parts[0]):
			var node: Node = load(parts[1]).new()
			node.name = parts[0]
			root.add_child(node)
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	_run()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	print("--- %d checks, %d failed ---" % [_count, _fail])
	quit(1 if _fail > 0 else 0)


func _check(cond: bool, name: String, detail: String = "") -> void:
	_count += 1
	if cond:
		print("  [PASS] " + name)
	else:
		_fail += 1
		printerr("  [FAIL] %s %s" % [name, detail])


func _inv() -> HUDInventory:
	var inv := HUDInventory.new()
	inv.inventory_data.resize(45)
	for i in range(45):
		inv.inventory_data[i] = {}
	inv.set_inventory_data_item(0, {"id": 32011, "icon_id": 1011, "count": 10, "name": "Bread", "equip_slot": ""})
	inv.set_inventory_data_item(1, {"id": 32002, "icon_id": 1292, "count": 5, "name": "Rice Wine", "equip_slot": ""})
	inv.set_inventory_data_item(2, {"id": 11001, "count": 1, "name": "Sword", "equip_slot": "weapon", "durability": 12, "max_durability": 50})
	return inv


func _run() -> void:
	var inv := _inv()
	var w: WarehouseWindow = WarehouseScene.instantiate()
	root.add_child(w)
	_check(w.size == Vector2(416, 481) and w.background.texture != null, "416x481 Form_itemBank_1 skin")
	_check(w.background.texture.get_image().get_pixel(0, 0).a == 0.0, "chroma key removed")
	_check(w.bank_slots.size() == 50 and w.bag_slots.size() == 50, "two 50-cell grids")
	_check(w.bank_slots[0].position == Vector2(20, 83) and w.bank_slots[49].position == Vector2(156, 389), "bank grid (20+34c, 83+34r)")
	_check(w.bag_slots[0].position == Vector2(224, 83), "bag grid origin (224,83)")
	_check(w.btn_withdraw.position == Vector2(200, 200) and w.btn_deposit.position == Vector2(199, 247), "arrows R(200,200) L(199,247)")
	_check(w.btn_close.position == Vector2(179, 437) and w.close_button.position == Vector2(365, 25), "Btn_Close_1 and close sphere")
	_check(not w.restrain_panel.visible, "panel_restrainBank_1 hidden")
	w.setup(inv, SAVE)
	w.open_warehouse()
	var msgs: Array = []
	w.message.connect(func(t: String) -> void: msgs.append(t))
	w.deposit_selected()
	_check(msgs.has("Select item on right side"), "deposit with nothing selected")
	w.withdraw_selected()
	_check(msgs.has("Select item on left side"), "withdraw with nothing selected")
	w.toggle_bag_selection(0)
	w.toggle_bag_selection(2)
	_check(w.bag_slots[0].selected and w.bag_slots[2].selected, "multi-select in bag")
	var moved := w.deposit_selected()
	_check(moved.size() == 2, "two items stored")
	_check(inv.inventory_data[0].is_empty() and inv.inventory_data[2].is_empty(), "removed from bag")
	_check(w.bank_slots[0].item.get("name") == "Bread" and w.bank_slots[1].item.get("name") == "Sword", "shown in bank grid")
	_check(FileAccess.file_exists(SAVE), "saved to user://")
	# stacking: deposit more bread
	inv.set_inventory_data_item(5, {"id": 32011, "icon_id": 1011, "count": 3, "name": "Bread", "equip_slot": ""})
	w.deposit_bag_slot(5)
	_check(int(w.stored[0]["count"]) == 13, "consumables stack in the bank", str(w.stored[0]))
	# persistence: a new window reads the file
	var w2: WarehouseWindow = WarehouseScene.instantiate()
	root.add_child(w2)
	w2.setup(_inv(), SAVE)
	_check(w2.get_stored_items().size() == 2, "reloaded 2 stacks")
	_check(typeof(w2.stored[1]["durability"]) == TYPE_INT and int(w2.stored[1]["durability"]) == 12, "durability survives JSON as int")
	# withdraw the sword back
	_check(w.withdraw_bank_slot(1), "withdraw sword")
	var found := false
	for it in inv.inventory_data:
		if it is Dictionary and int(it.get("id", 0)) == 11001:
			found = true
	_check(found and w.stored[1].is_empty(), "sword back in bag")
	w.close_window()
	_check(not w.visible, "closed")
	w.queue_free()
	w2.queue_free()
