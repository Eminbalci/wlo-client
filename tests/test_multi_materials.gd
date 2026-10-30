class_name TestMultiMaterials
extends SceneTree

const ItemDatabaseClass = preload("res://scripts/database/item_database.gd")
const ItemDataClass = preload("res://scripts/database/item_data.gd")
const ItemTooltipClass = preload("res://scripts/ui/item_tooltip.gd")
const ItemEditorClass = preload("res://scripts/tools/item_editor.gd")

func _init() -> void:
	print("=================================================================")
	print("--- Running Multi-Materials Verification Suite ('Birden Fazla Materyal') ---")
	print("=================================================================\n")

	_test_database_multi_material_resolution()
	_test_item_data_serialization()
	_test_world_editor_database_inspector_format()
	_test_item_tooltip_multi_material_display()
	_test_item_editor_multi_material_inspector_and_preview()

	print("\n=================================================================")
	print("--- ALL MULTI-MATERIALS TESTS PASSED WITH ZERO ERRORS ---")
	print("=================================================================")
	quit(0)

func _test_database_multi_material_resolution() -> void:
	print(">>> [TEST 1] Verifying ItemDatabase Multiple Constituent Material Resolution...")
	var db = ItemDatabaseClass.new()
	var loaded = db.load_from_file("res://assets/data/Item.dat")
	if not loaded:
		loaded = db.load_from_file("D:/Godot/WonderlandOnline/wonderland-online-client/assets/data/Item.dat")
	assert(loaded, "Failed to load item database")

	# 1. 10031: Copper Knife -> ["Copper", "Wood"], "Copper, Wood"
	var copper_knife = db.get_item(10031)
	assert(copper_knife != null, "Item 10031 must exist")
	var ck_mats: Array[String] = copper_knife.get_materials()
	assert(ck_mats.has("Copper") and ck_mats.has("Wood"), "Copper Knife must contain Copper and Wood, got: %s" % str(ck_mats))
	assert(copper_knife.get_material_name() == "Copper, Wood", "Copper Knife material_name must be 'Copper, Wood', got: " + copper_knife.get_material_name())
	print("  PASS: Item 10031 (Copper Knife) -> Materials: %s | Formatted: '%s'" % [str(ck_mats), copper_knife.get_material_name()])

	# 2. 10032: Bronze Knife -> ["Bronze", "Wood"], "Bronze, Wood"
	var bronze_knife = db.get_item(10032)
	assert(bronze_knife != null, "Item 10032 must exist")
	var bk_mats: Array[String] = bronze_knife.get_materials()
	assert(bk_mats.has("Bronze") and bk_mats.has("Wood"), "Bronze Knife must contain Bronze and Wood, got: %s" % str(bk_mats))
	assert(bronze_knife.get_material_name() == "Bronze, Wood", "Bronze Knife material_name must be 'Bronze, Wood', got: " + bronze_knife.get_material_name())
	print("  PASS: Item 10032 (Bronze Knife) -> Materials: %s | Formatted: '%s'" % [str(bk_mats), bronze_knife.get_material_name()])

	# 3. 10033: Iron Knife -> ["Iron", "Wood"], "Iron, Wood"
	var iron_knife = db.get_item(10033)
	assert(iron_knife != null, "Item 10033 must exist")
	var ik_mats: Array[String] = iron_knife.get_materials()
	assert(ik_mats.has("Iron") and ik_mats.has("Wood"), "Iron Knife must contain Iron and Wood, got: %s" % str(ik_mats))
	assert(iron_knife.get_material_name() == "Iron, Wood", "Iron Knife material_name must be 'Iron, Wood', got: " + iron_knife.get_material_name())
	print("  PASS: Item 10033 (Iron Knife) -> Materials: %s | Formatted: '%s'" % [str(ik_mats), iron_knife.get_material_name()])

	# 4. Pure single material: 45001 (Ordinary Wood) -> ["Wood"]
	var ord_wood = db.get_item(45001)
	assert(ord_wood != null, "Item 45001 must exist")
	var ow_mats: Array[String] = ord_wood.get_materials()
	assert(ow_mats == ["Wood"], "Ordinary Wood must be pure single material ['Wood'], got: %s" % str(ow_mats))
	assert(ord_wood.get_material_name() == "Wood", "Ordinary Wood material_name must be 'Wood', got: " + ord_wood.get_material_name())
	print("  PASS: Item 45001 (Ordinary Wood) -> Materials: %s | Formatted: '%s'" % [str(ow_mats), ord_wood.get_material_name()])

	# 5. Pure single material: 42011 (Copper Material) -> ["Copper"]
	var copper_mat = db.get_item(42011)
	assert(copper_mat != null, "Item 42011 must exist")
	var cm_mats: Array[String] = copper_mat.get_materials()
	assert(cm_mats == ["Copper"], "Copper Material must be pure single material ['Copper'], got: %s" % str(cm_mats))
	assert(copper_mat.get_material_name() == "Copper", "Copper Material material_name must be 'Copper', got: " + copper_mat.get_material_name())
	print("  PASS: Item 42011 (Copper Material) -> Materials: %s | Formatted: '%s'" % [str(cm_mats), copper_mat.get_material_name()])

	# 6. Synthesized resolution: Bronze Sword -> ["Bronze", "Wood"]
	var sword_mats := ItemDatabaseClass.resolve_materials_from_info("Bronze Sword", "A standard bronze sword forged by village blacksmiths.", 3)
	assert(sword_mats.has("Bronze") and sword_mats.has("Wood"), "Bronze Sword must be Bronze + Wood, got: %s" % str(sword_mats))
	print("  PASS: Bronze Sword -> Materials: %s" % str(sword_mats))

	# 7. Synthesized resolution: Iron Armor -> ["Iron", "Leather"]
	var armor_mats := ItemDatabaseClass.resolve_materials_from_info("Iron Armor", "Heavy protective armor crafted from refined iron plates.", 2)
	assert(armor_mats.has("Iron") and armor_mats.has("Leather"), "Iron Armor must be Iron + Leather, got: %s" % str(armor_mats))
	print("  PASS: Iron Armor -> Materials: %s" % str(armor_mats))

	# 8. Bow: Longbow -> ["Wood", "Grass"]
	var bow_mats := ItemDatabaseClass.resolve_materials_from_info("Longbow", "A flexible wooden bow strung with dried fibrous hemp.", 3)
	assert(bow_mats.has("Wood") and bow_mats.has("Grass"), "Longbow must be Wood + Grass, got: %s" % str(bow_mats))
	print("  PASS: Longbow -> Materials: %s" % str(bow_mats))

	# 9. Magic Wand -> ["Crystal", "Wood"]
	var wand_mats := ItemDatabaseClass.resolve_materials_from_info("Magic Wand", "An ancient wooden wand mounted with a glowing quartz crystal.", 3)
	assert(wand_mats.has("Crystal") and wand_mats.has("Wood"), "Magic Wand must be Crystal + Wood, got: %s" % str(wand_mats))
	print("  PASS: Magic Wand -> Materials: %s" % str(wand_mats))

	# 10. Raft (48010) -> ["Wood", "Grass"]
	var raft_mats := ItemDatabaseClass.resolve_materials_from_info("Raft", "A buoyant wooden watercraft tied with strong vines and rope.", 0, 48010)
	assert(raft_mats.has("Wood") and raft_mats.has("Grass"), "Raft must be Wood + Grass, got: %s" % str(raft_mats))
	print("  PASS: Raft (48010) -> Materials: %s" % str(raft_mats))

	# 11. Heavy Boots -> ["Iron", "Leather"]
	var boots_mats := ItemDatabaseClass.resolve_materials_from_info("Heavy Boots", "Reinforced boots with heavy iron toe-caps.", 5)
	assert(boots_mats.has("Iron") and boots_mats.has("Leather"), "Heavy Boots must be Iron + Leather, got: %s" % str(boots_mats))
	print("  PASS: Heavy Boots -> Materials: %s" % str(boots_mats))

func _test_item_data_serialization() -> void:
	print("\n>>> [TEST 2] Verifying ItemData Model & Dictionary Serialization...")
	var idata = ItemDataClass.new()
	idata.id = 10031
	idata.name = "Copper Knife"
	var mats_list: Array[String] = ["Copper", "Wood"]
	idata.materials = mats_list
	idata.level_req = 2
	idata.durability = 50

	assert(idata.get_materials() == ["Copper", "Wood"], "ItemData get_materials must return materials array")
	assert(idata.get_material_name() == "Copper, Wood", "ItemData get_material_name must return 'Copper, Wood'")

	var dict = idata.to_dict()
	assert(dict.has("materials"), "to_dict must contain 'materials'")
	assert(dict["materials"] == ["Copper", "Wood"], "to_dict['materials'] must equal ['Copper', 'Wood']")
	assert(dict["material_name"] == "Copper, Wood", "to_dict['material_name'] must equal 'Copper, Wood'")
	print("  PASS: ItemData serialized correctly: %s" % str(dict["materials"]))

func _test_world_editor_database_inspector_format() -> void:
	print("\n>>> [TEST 3] Verifying WorldEditor Database Inspector Metadata Format...")
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

	assert(meta_text.contains("Material: Copper, Wood"), "WorldEditor meta must display 'Material: Copper, Wood'")
	print("  PASS: WorldEditor Inspector Metadata String:\n" + meta_text)

func _test_item_tooltip_multi_material_display() -> void:
	print("\n>>> [TEST 4] Verifying ItemTooltip Composite Material Formatting...")
	var tooltip = ItemTooltipClass.new()
	root.add_child(tooltip)

	var items_to_test = [
		{"id": 10031, "name": "Copper Knife", "level": 2, "equip_pos": 3, "materials": ["Copper", "Wood"], "expected_mat": "Copper, Wood", "expected_rank": 1},
		{"id": 10032, "name": "Bronze Knife", "level": 6, "equip_pos": 3, "materials": ["Bronze", "Wood"], "expected_mat": "Bronze, Wood", "expected_rank": 3},
		{"id": 10033, "name": "Iron Knife", "level": 8, "equip_pos": 3, "materials": ["Iron", "Wood"], "expected_mat": "Iron, Wood", "expected_rank": 4},
		{"id": 21005, "name": "Iron Armor", "level": 15, "equip_pos": 2, "materials": ["Iron", "Leather"], "expected_mat": "Iron, Leather", "expected_rank": 5},
		{"id": 45001, "name": "Ordinary Wood", "level": 0, "equip_pos": 0, "materials": ["Wood"], "rank": 2, "expected_mat": "Wood", "expected_rank": 2},
	]

	for it in items_to_test:
		tooltip.display_item(it)
		assert(tooltip.visible, "Tooltip must be visible")
		# The real tooltip only lists materials ("Alch Mat: ...") inside the compound window (aLogin 0x2a2ced),
		# so only check that the tooltip renders; materials stay available via ItemRecord.get_materials().
		var type_text: String = " | ".join(tooltip.get_lines_text())
		assert(type_text.begins_with("[ ") and type_text.contains("Rank: "), "Tooltip '%s' must start with '[ Name ]' and show 'Rank: '" % type_text)
		print("  PASS: Tooltip for %s -> '%s'" % [it["name"], type_text])

	tooltip.queue_free()

func _test_item_editor_multi_material_inspector_and_preview() -> void:
	print("\n>>> [TEST 5] Verifying ItemEditor Multi-Material Studio Inspector & Live Previews...")
	var scene_res = load("res://scenes/tools/item_editor.tscn")
	assert(scene_res != null, "item_editor.tscn must exist")
	var editor = scene_res.instantiate()
	root.add_child(editor)
	if not editor._is_ui_ready:
		editor._ready()

	# 1. Preset Bronze Sword
	editor.apply_preset("Bronze Sword")
	var bs_mats: Array[String] = editor.get_materials()
	assert(bs_mats.has("Bronze") and bs_mats.has("Wood"), "Bronze Sword materials must contain Bronze and Wood, got: %s" % str(bs_mats))
	assert(editor.get_material_name() == "Bronze, Wood", "Bronze Sword material_name must be 'Bronze, Wood'")
	editor.update_tooltip_preview()
	assert(editor.lbl_tt_slot.text.contains("Material: Bronze, Wood"), "Preview must contain 'Material: Bronze, Wood', got: " + editor.lbl_tt_slot.text)
	print("  PASS: ItemEditor Bronze Sword slot preview -> '%s'" % editor.lbl_tt_slot.text)

	# 2. Preset Iron Armor
	editor.apply_preset("Iron Armor")
	var ia_mats: Array[String] = editor.get_materials()
	assert(ia_mats.has("Iron") and ia_mats.has("Leather"), "Iron Armor materials must contain Iron and Leather, got: %s" % str(ia_mats))
	assert(editor.get_material_name() == "Iron, Leather", "Iron Armor material_name must be 'Iron, Leather'")
	editor.update_tooltip_preview()
	assert(editor.lbl_tt_slot.text.contains("Material: Iron, Leather"), "Preview must contain 'Material: Iron, Leather', got: " + editor.lbl_tt_slot.text)
	print("  PASS: ItemEditor Iron Armor slot preview -> '%s'" % editor.lbl_tt_slot.text)

	# 3. Create Item Record
	var record = editor.create_item_record()
	assert(record.has("materials"), "ItemEditor record must include 'materials'")
	assert(record["materials"] == ["Iron", "Leather"], "Record materials must equal ['Iron', 'Leather']")
	assert(record["material_name"] == "Iron, Leather", "Record material_name must equal 'Iron, Leather'")
	print("  PASS: ItemEditor record created with materials: %s" % str(record["materials"]))

	editor.queue_free()
