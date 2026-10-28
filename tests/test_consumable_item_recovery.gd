extends SceneTree

## Automated Test Suite: Consumable Item Recovery & Status Effects
## Verifies ItemRecord recovery calculations, status types 25 (HP) and 26 (SP),
## CharacterStatusController HP/SP restoration, inventory item use, and visual feedback.

const ItemDatabaseClass = preload("res://scripts/database/item_database.gd")
const HUDInventoryClass = preload("res://scripts/ui/hud/hud_inventory.gd")
const HUDCharacterStatusClass = preload("res://scripts/ui/hud/hud_character_status.gd")
const ItemTooltipClass = preload("res://scripts/ui/item_tooltip.gd")

var _passed: int = 0
var _failed: int = 0

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("  [PASS] %s" % msg)
	else:
		_failed += 1
		print("  [FAIL] %s" % msg)

func assert_eq(a: Variant, b: Variant, msg: String) -> void:
	if a == b:
		_passed += 1
		print("  [PASS] %s: %s == %s" % [msg, str(a), str(b)])
	else:
		_failed += 1
		print("  [FAIL] %s: expected %s, got %s" % [msg, str(b), str(a)])

func _init() -> void:
	print("\n=================================================================")
	print("STARTING TEST SUITE: Consumable Item Recovery & Status Effects")
	print("=================================================================\n")

	test_item_database_consumable_records()
	test_character_status_restoration()
	test_inventory_consumable_use()
	test_item_tooltip_consumable_stats()

	print("\n=================================================================")
	print("RESULTS: %d PASSED, %d FAILED" % [_passed, _failed])
	print("=================================================================\n")

	if _failed > 0:
		quit(1)
	else:
		quit(0)

func test_item_database_consumable_records() -> void:
	print("--- 1. Testing ItemDatabase Consumable Recovery Fields ---")
	var db = ItemDatabaseClass.new()
	db.load_from_wpdat("res://assets/data/itemDat.wpdat")
	db.load_from_file("res://assets/data/Item.dat")

	# Bread (ID 32011): StatusTypes [25, 0], Values [150, 100] -> +50 HP
	var bread = db.get_item(32011)
	assert_true(bread != null, "Bread record exists in database")
	assert_eq(bread.get_hp_restore(), 50, "Bread restores exactly 50 HP")
	assert_eq(bread.get_sp_restore(), 0, "Bread does not restore SP")

	# Rice Wine (ID 32002): StatusTypes [26, 0], Values [250, 100] -> +150 SP
	var wine = db.get_item(32002)
	assert_true(wine != null, "Rice Wine record exists in database")
	assert_eq(wine.get_hp_restore(), 0, "Rice Wine does not restore HP")
	assert_eq(wine.get_sp_restore(), 150, "Rice Wine restores exactly 150 SP")

	# Multi Bread (ID 32013): StatusTypes [25, 26], Values [240, 160] -> +140 HP, +60 SP
	var multi = db.get_item(32013)
	assert_true(multi != null, "Multi Bread record exists in database")
	assert_eq(multi.get_hp_restore(), 140, "Multi Bread restores 140 HP")
	assert_eq(multi.get_sp_restore(), 60, "Multi Bread restores 60 SP")

	# Formatted stats in tooltip
	var b_stats = bread.get_formatted_stats()
	assert_eq(b_stats.size(), 1, "Bread has 1 formatted stat")
	assert_eq(b_stats[0]["name"], "HP", "Stat name is 'HP'")
	assert_eq(b_stats[0]["text"], "HP +50", "Stat text is 'HP +50'")

	var w_stats = wine.get_formatted_stats()
	assert_eq(w_stats.size(), 1, "Rice Wine has 1 formatted stat")
	assert_eq(w_stats[0]["name"], "SP", "Stat name is 'SP'")
	assert_eq(w_stats[0]["text"], "SP +150", "Stat text is 'SP +150'")

func test_character_status_restoration() -> void:
	print("\n--- 2. Testing HUDCharacterStatus restore_hp & restore_sp ---")
	var ctrl = HUDCharacterStatusClass.new()
	ctrl.current_hp = 100
	ctrl.current_max_hp = 300
	ctrl.current_sp = 40
	ctrl.current_max_sp = 200

	# Partial restoration
	var res_hp1 = ctrl.restore_hp(50)
	assert_eq(res_hp1, 50, "Restored 50 HP")
	assert_eq(ctrl.current_hp, 150, "Current HP is now 150")

	# Over-cap restoration
	var res_hp2 = ctrl.restore_hp(250)
	assert_eq(res_hp2, 150, "Restored only 150 HP up to cap")
	assert_eq(ctrl.current_hp, 300, "Current HP capped at 300")

	# Zero restoration when full
	var res_hp3 = ctrl.restore_hp(50)
	assert_eq(res_hp3, 0, "Restored 0 HP when already at max")
	assert_eq(ctrl.current_hp, 300, "Current HP remains 300")

	# SP restoration
	var res_sp1 = ctrl.restore_sp(60)
	assert_eq(res_sp1, 60, "Restored 60 SP")
	assert_eq(ctrl.current_sp, 100, "Current SP is now 100")

	var res_sp2 = ctrl.restore_sp(200)
	assert_eq(res_sp2, 100, "Restored 100 SP up to cap")
	assert_eq(ctrl.current_sp, 200, "Current SP capped at 200")

func test_inventory_consumable_use() -> void:
	print("\n--- 3. Testing Inventory Consumable Item Consumption ---")
	var mock_hud = Control.new()
	root.add_child(mock_hud)

	var inv = HUDInventoryClass.new()
	var char_ctrl = HUDCharacterStatusClass.new()
	char_ctrl.current_hp = 80
	char_ctrl.current_max_hp = 200
	char_ctrl.current_sp = 50
	char_ctrl.current_max_sp = 200

	inv.character_status_ctrl = char_ctrl
	mock_hud.set("character_status_ctrl", char_ctrl)
	mock_hud.set("inventory_ctrl", inv)

	var inv_grid = Control.new()
	mock_hud.add_child(inv_grid)
	inv.setup(mock_hud, {"inventory_grid": inv_grid})
	char_ctrl.setup(mock_hud, {})

	# Set up consumable items in inventory
	# Slot 0: Bread (ID 32011, count 3, +50 HP)
	var bread_rec = inv.create_item_record(32011, 1011, 3, "Bread", "Restores 50 HP")
	inv.set_inventory_data_item(0, bread_rec)

	# Slot 1: Rice Wine (ID 32002, count 1, +150 SP)
	var wine_rec = inv.create_item_record(32002, 1292, 1, "Rice Wine", "Restores 150 SP")
	inv.set_inventory_data_item(1, wine_rec)

	assert_eq(bread_rec.get("hp_restore"), 50, "Bread record has hp_restore=50")
	assert_eq(wine_rec.get("sp_restore"), 150, "Rice Wine record has sp_restore=150")

	# Use Bread (count 3 -> 2, HP 80 -> 130)
	inv.use_or_equip_inventory_item(0)
	assert_eq(char_ctrl.current_hp, 130, "Player HP restored from 80 to 130")
	var slot0_after = inv.inventory_data[0]
	assert_eq(slot0_after.get("count"), 2, "Bread stack decremented to 2")

	# Use Rice Wine (count 1 -> empty, SP 50 -> 200)
	inv.use_or_equip_inventory_item(1)
	assert_eq(char_ctrl.current_sp, 200, "Player SP restored from 50 to 200 (capped)")
	var slot1_after = inv.inventory_data[1]
	assert_true(slot1_after.is_empty(), "Slot 1 cleared after single item used")

	mock_hud.queue_free()

func test_item_tooltip_consumable_stats() -> void:
	print("\n--- 4. Testing ItemTooltip Display For Consumables ---")
	var tip = ItemTooltipClass.new()
	root.add_child(tip)

	var item_sample = {
		"id": 32013,
		"name": "Multi Bread",
		"description": "It's made from various grains",
		"equip_pos": 8,
		"hp_restore": 140,
		"sp_restore": 60
	}

	tip.display_item(item_sample)
	assert_eq(tip._title_label.text, "Multi Bread", "Tooltip title displays 'Multi Bread'")
	assert_eq(tip._stats_container.get_child_count(), 2, "Tooltip displays 2 recovery stats")

	var stat1: Label = tip._stats_container.get_child(0) as Label
	var stat2: Label = tip._stats_container.get_child(1) as Label
	assert_eq(stat1.text, "HP +140", "First stat is 'HP +140'")
	assert_eq(stat2.text, "SP +60", "Second stat is 'SP +60'")

	tip.queue_free()
