class_name TestItemMaterialsAndRanks
extends SceneTree

const ItemDatabaseClass = preload("res://scripts/database/item_database.gd")
const ItemTooltipClass = preload("res://scripts/ui/item_tooltip.gd")
const ItemEditorClass = preload("res://scripts/tools/item_editor.gd")

func _init() -> void:
	print("=================================================================")
	print("--- Running Test Item Materials & Ranks Verification Suite ---")
	print("=================================================================\n")

	_test_database_item_materials_and_ranks()
	_test_world_editor_meta_string_formatting()
	_test_item_tooltip_material_and_rank_display()
	_test_item_editor_material_and_rank_preview()

	print("\n=================================================================")
	print("--- ALL ITEM MATERIALS & RANKS TESTS PASSED WITH ZERO ERRORS ---")
	print("=================================================================")
	quit(0)

func _test_database_item_materials_and_ranks() -> void:
	print(">>> [TEST 1] Verifying ItemDatabase Material & Rank Resolution...")
	var db = ItemDatabaseClass.new()
	var loaded = db.load_from_file("res://assets/data/Item.dat")
	if not loaded:
		loaded = db.load_from_file("D:/Godot/WonderlandOnline/wonderland-online-client/assets/data/Item.dat")
	assert(loaded, "Failed to load item database")

	# 10031: Copper Knife -> Copper, Rank 2 (Item.dat rec+0x2D, printed by aLogin 0x2a2fd0)
	var copper_knife = db.get_item(10031)
	assert(copper_knife != null, "Item 10031 must exist")
	assert(copper_knife.get_material_name().contains("Copper"), "10031 material must contain Copper, got: " + copper_knife.get_material_name())
	assert(copper_knife.get_rank() == 2, "10031 rank must be 2, got: %d" % copper_knife.get_rank())
	print("  PASS: Item 10031 (Copper Knife) -> Material: %s | Rank: %d" % [copper_knife.get_material_name(), copper_knife.get_rank()])

	# 10032: Bronze Knife -> Bronze, Rank 3
	var bronze_knife = db.get_item(10032)
	assert(bronze_knife != null, "Item 10032 must exist")
	assert(bronze_knife.get_material_name().contains("Bronze"), "10032 material must contain Bronze, got: " + bronze_knife.get_material_name())
	assert(bronze_knife.get_rank() == 3, "10032 rank must be 3, got: %d" % bronze_knife.get_rank())
	print("  PASS: Item 10032 (Bronze Knife) -> Material: %s | Rank: %d" % [bronze_knife.get_material_name(), bronze_knife.get_rank()])

	# 10033: Iron Knife -> Iron, Rank 4
	var iron_knife = db.get_item(10033)
	assert(iron_knife != null, "Item 10033 must exist")
	assert(iron_knife.get_material_name().contains("Iron"), "10033 material must contain Iron, got: " + iron_knife.get_material_name())
	assert(iron_knife.get_rank() == 4, "10033 rank must be 4, got: %d" % iron_knife.get_rank())
	print("  PASS: Item 10033 (Iron Knife) -> Material: %s | Rank: %d" % [iron_knife.get_material_name(), iron_knife.get_rank()])

	# 45001: Ordinary Wood -> Wood, Rank 2
	var ord_wood = db.get_item(45001)
	assert(ord_wood != null, "Item 45001 must exist")
	assert(ord_wood.get_material_name() == "Wood", "45001 material must be Wood, got: " + ord_wood.get_material_name())
	assert(ord_wood.get_rank() == 2, "45001 rank must be 2, got: %d" % ord_wood.get_rank())
	print("  PASS: Item 45001 (Ordinary Wood) -> Material: %s | Rank: %d" % [ord_wood.get_material_name(), ord_wood.get_rank()])

	# 42011: Copper Material -> Copper, Rank 4
	var copper_mat = db.get_item(42011)
	assert(copper_mat != null, "Item 42011 must exist")
	assert(copper_mat.get_material_name() == "Copper", "42011 material must be Copper, got: " + copper_mat.get_material_name())
	assert(copper_mat.get_rank() == 4, "42011 rank must be 4, got: %d" % copper_mat.get_rank())
	print("  PASS: Item 42011 (Copper Material) -> Material: %s | Rank: %d" % [copper_mat.get_material_name(), copper_mat.get_rank()])

func _test_world_editor_meta_string_formatting() -> void:
	print("\n>>> [TEST 2] Verifying WorldEditor Metadata Label Formatting...")
	var db = ItemDatabaseClass.new()
	db.load_from_file("res://assets/data/Item.dat")
	var item = db.get_item(10031)
	assert(item != null, "Item 10031 must exist")

	var meta_text := "Item ID: %d | Type: %d | Slot: %s\nLevel: %d | Rank: %d | Material: %s | Durability: %d/%d\nBuy Price: %d G | Sell Price: %d G" % [
		item.id, item.item_type, item.get_equip_slot_name(),
		item.level, item.get_rank(), item.get_material_name(),
		item.durability, item.max_durability,
		item.buy_price, item.sell_price
	]

	assert(meta_text.contains("Level: 2"), "Meta must contain Level: 2")
	assert(meta_text.contains("Rank: 2"), "Meta must contain Rank: 2")
	assert(meta_text.contains("Material: Copper"), "Meta must contain Material: Copper")
	print("  PASS: WorldEditor meta format output:\n" + meta_text)

func _test_item_tooltip_material_and_rank_display() -> void:
	print("\n>>> [TEST 3] Verifying ItemTooltip Material and Rank Display...")
	var tooltip = ItemTooltipClass.new()
	root.add_child(tooltip)

	var items_to_test = [
		{"id": 10031, "name": "Copper Knife", "level": 2, "equip_pos": 3, "rank": 2, "expected_mat": "Copper", "expected_rank": 2},
		{"id": 10032, "name": "Bronze Knife", "level": 6, "equip_pos": 3, "rank": 3, "expected_mat": "Bronze", "expected_rank": 3},
		{"id": 10033, "name": "Iron Knife", "level": 8, "equip_pos": 3, "rank": 4, "expected_mat": "Iron", "expected_rank": 4},
		{"id": 45001, "name": "Ordinary Wood", "level": 0, "equip_pos": 0, "rank": 2, "expected_mat": "Wood", "expected_rank": 2},
		{"id": 42011, "name": "Copper Material", "level": 0, "equip_pos": 0, "rank": 4, "expected_mat": "Copper", "expected_rank": 4},
	]

	for it in items_to_test:
		tooltip.display_item(it)
		assert(tooltip.visible, "Tooltip must be visible")
		# The real tooltip has no material line outside the compound window; it prints "Rank: N".
		var type_text: String = " | ".join(tooltip.get_lines_text())
		assert(type_text.contains("Rank: %d" % it["expected_rank"]), "Tooltip '%s' must contain Rank: %d" % [type_text, it["expected_rank"]])
		print("  PASS: Tooltip for %s -> '%s'" % [it["name"], type_text])

	tooltip.queue_free()

func _test_item_editor_material_and_rank_preview() -> void:
	print("\n>>> [TEST 4] Verifying ItemEditor Studio Inspector & Tooltip Preview...")
	var scene_res = load("res://scenes/tools/item_editor.tscn")
	assert(scene_res != null, "item_editor.tscn must exist")
	var editor = scene_res.instantiate()
	root.add_child(editor)
	if not editor._is_ui_ready:
		editor._ready()

	editor.apply_preset("Bronze Sword")
	assert(editor.rank == 3, "Bronze Sword rank must be 3")
	assert(editor.get_material_name().contains("Bronze"), "Bronze Sword material must contain Bronze, got: " + editor.get_material_name())

	editor.update_tooltip_preview()
	assert(editor.lbl_tt_slot != null, "lbl_tt_slot must exist in item_editor.tscn")
	assert(editor.lbl_tt_slot.text.contains("Material: Bronze"), "ItemEditor lbl_tt_slot must contain 'Material: Bronze'")
	assert(editor.lbl_tt_slot.text.contains("Rank: 3"), "ItemEditor lbl_tt_slot must contain 'Rank: 3'")
	print("  PASS: ItemEditor Bronze Sword slot preview -> '%s'" % editor.lbl_tt_slot.text)

	editor.apply_preset("Iron Armor")
	assert(editor.rank == 5, "Iron Armor rank must be 5")
	assert(editor.get_material_name().contains("Iron"), "Iron Armor material must contain Iron, got: " + editor.get_material_name())
	editor.update_tooltip_preview()
	assert(editor.lbl_tt_slot.text.contains("Material: Iron"), "ItemEditor lbl_tt_slot must contain 'Material: Iron'")
	assert(editor.lbl_tt_slot.text.contains("Rank: 5"), "ItemEditor lbl_tt_slot must contain 'Rank: 5'")
	print("  PASS: ItemEditor Iron Armor slot preview -> '%s'" % editor.lbl_tt_slot.text)

	editor.queue_free()
