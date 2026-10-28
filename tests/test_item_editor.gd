extends Node

## Automated Headless Verification Suite for ItemEditor & Alchemy Studio
## Tests item creation, stat formatting, 5 presets, alchemy synthesis calculations,
## JSON persistence, recipe export, and visual scene binding.

const ItemEditorClass = preload("res://scripts/tools/item_editor.gd")

func _ready() -> void:
	print("=================================================================")
	print("--- Running Item, Equipment & Alchemy Studio Test Suite ---")
	print("=================================================================\n")

	_test_item_creation_and_attributes()
	_test_stat_formatting()
	_test_presets()
	_test_alchemy_synthesis_calculation()
	_test_json_export_and_import()
	_test_recipe_export()
	_test_scene_instantiation_and_ui()

	print("\n=================================================================")
	print("--- ALL ITEM & ALCHEMY STUDIO TESTS PASSED (100%) ---")
	print("=================================================================")
	if get_tree():
		get_tree().quit(0)

func _test_item_creation_and_attributes() -> void:
	print(">>> [TEST 1] Verifying Item Creation and Master Attributes...")
	var editor: ItemEditorClass = ItemEditorClass.new()
	assert(editor != null, "ERROR: ItemEditor instance could not be created")

	# Verify attributes exist and have correct types
	assert(editor.item_id is int, "item_id must be int")
	assert(editor.item_name is String, "item_name must be String")
	assert(editor.description is String, "description must be String")
	assert(editor.icon_id is int, "icon_id must be int")
	assert(editor.level_req is int, "level_req must be int")
	assert(editor.rank is int, "rank must be int")
	assert(editor.durability is int, "durability must be int")
	assert(editor.max_durability is int, "max_durability must be int")
	assert(editor.equip_slot is int, "equip_slot must be int")
	assert(editor.buy_price is int, "buy_price must be int")
	assert(editor.sell_price is int, "sell_price must be int")

	# Verify default initial state
	assert(editor.item_id > 0, "Default item_id must be positive")
	assert(not editor.item_name.is_empty(), "Default item_name must not be empty")
	assert(editor.durability > 0 and editor.durability <= editor.max_durability, "Durability must be valid")

	# Verify slot names helper
	assert(ItemEditorClass.get_equip_slot_name(ItemEditorClass.EquipSlot.WEAPON) == "Weapon", "Slot 3 must be Weapon")
	assert(ItemEditorClass.get_equip_slot_name(ItemEditorClass.EquipSlot.CLOTHES) == "Clothes", "Slot 2 must be Clothes")
	assert(ItemEditorClass.get_equip_slot_name(ItemEditorClass.EquipSlot.SHOES) == "Shoes", "Slot 5 must be Shoes")
	assert(ItemEditorClass.get_equip_slot_name(ItemEditorClass.EquipSlot.CONSUMABLE) == "Consumable", "Slot 7 must be Consumable")

	print("  PASS: Item master attributes and slot name resolutions verified.")
	editor.free()

func _test_stat_formatting() -> void:
	print(">>> [TEST 2] Verifying Stat Modifiers Builder and Formatting...")
	var editor: ItemEditorClass = ItemEditorClass.new()

	editor.atk = 25
	editor.def = 10
	editor.matk = 0
	editor.mdef = 5
	editor.spd = -4
	editor.hp_bonus = 100
	editor.sp_bonus = 0

	var stats: Array[Dictionary] = editor.get_formatted_stats()
	assert(stats.size() == 5, "Expected 5 non-zero stats, got %d" % stats.size())

	var stat_dict: Dictionary = {}
	for s in stats:
		assert(s.has("name") and s.has("delta") and s.has("text") and s.has("is_positive"), "Stat dict missing required keys")
		stat_dict[s["name"]] = s

	assert(stat_dict.has("ATK") and stat_dict["ATK"]["delta"] == 25, "ATK delta mismatch")
	assert(stat_dict["ATK"]["text"] == "ATK +25", "ATK text must be 'ATK +25', got: " + stat_dict["ATK"]["text"])
	assert(stat_dict["ATK"]["is_positive"] == true, "ATK +25 must be positive")

	assert(stat_dict.has("DEF") and stat_dict["DEF"]["delta"] == 10, "DEF delta mismatch")
	assert(stat_dict["DEF"]["text"] == "DEF +10", "DEF text must be 'DEF +10'")

	assert(stat_dict.has("MDEF") and stat_dict["MDEF"]["delta"] == 5, "MDEF delta mismatch")
	assert(stat_dict["MDEF"]["text"] == "MDEF +5", "MDEF text must be 'MDEF +5'")

	assert(stat_dict.has("SPD") and stat_dict["SPD"]["delta"] == -4, "SPD delta mismatch")
	assert(stat_dict["SPD"]["text"] == "SPD -4", "SPD text must be 'SPD -4', got: " + stat_dict["SPD"]["text"])
	assert(stat_dict["SPD"]["is_positive"] == false, "SPD -4 must not be positive")

	assert(stat_dict.has("HP") and stat_dict["HP"]["delta"] == 100, "HP bonus delta mismatch")
	assert(stat_dict["HP"]["text"] == "HP +100", "HP text must be 'HP +100'")

	print("  PASS: Formatted stats successfully validated across positive, negative, and zero values.")
	editor.free()

func _test_presets() -> void:
	print(">>> [TEST 3] Verifying 5 Built-in Presets...")
	var editor: ItemEditorClass = ItemEditorClass.new()

	# 1. Bronze Sword
	assert(editor.apply_preset("Bronze Sword") == true, "Failed to apply Bronze Sword")
	assert(editor.item_id == 23001, "Bronze Sword ID mismatch: %d" % editor.item_id)
	assert(editor.equip_slot == ItemEditorClass.EquipSlot.WEAPON, "Bronze Sword must be Weapon")
	assert(editor.rank == 3, "Bronze Sword rank must be 3")
	assert(editor.atk == 12, "Bronze Sword ATK must be 12")
	assert(editor.spd == -2, "Bronze Sword SPD must be -2")
	assert(editor.buy_price == 150, "Bronze Sword buy price must be 150")
	print("  PASS: Preset 'Bronze Sword' (ID 23001, Weapon, Rank 3, ATK +12, SPD -2, Buy 150g)")

	# 2. Iron Armor
	assert(editor.apply_preset("Iron Armor") == true, "Failed to apply Iron Armor")
	assert(editor.item_id == 21005, "Iron Armor ID mismatch: %d" % editor.item_id)
	assert(editor.equip_slot == ItemEditorClass.EquipSlot.CLOTHES, "Iron Armor must be Clothes")
	assert(editor.rank == 5, "Iron Armor rank must be 5")
	assert(editor.def == 18, "Iron Armor DEF must be 18")
	assert(editor.mdef == 4, "Iron Armor MDEF must be 4")
	assert(editor.buy_price == 300, "Iron Armor buy price must be 300")
	print("  PASS: Preset 'Iron Armor' (ID 21005, Clothes, Rank 5, DEF +18, MDEF +4, Buy 300g)")

	# 3. Feather Boots
	assert(editor.apply_preset("Feather Boots") == true, "Failed to apply Feather Boots")
	assert(editor.item_id == 24003, "Feather Boots ID mismatch: %d" % editor.item_id)
	assert(editor.equip_slot == ItemEditorClass.EquipSlot.SHOES, "Feather Boots must be Shoes")
	assert(editor.rank == 4, "Feather Boots rank must be 4")
	assert(editor.spd == 15, "Feather Boots SPD must be 15")
	assert(editor.def == 3, "Feather Boots DEF must be 3")
	assert(editor.buy_price == 200, "Feather Boots buy price must be 200")
	print("  PASS: Preset 'Feather Boots' (ID 24003, Shoes, Rank 4, SPD +15, DEF +3, Buy 200g)")

	# 4. Healing Grass
	assert(editor.apply_preset("Healing Grass") == true, "Failed to apply Healing Grass")
	assert(editor.item_id == 32001, "Healing Grass ID mismatch: %d" % editor.item_id)
	assert(editor.equip_slot == ItemEditorClass.EquipSlot.CONSUMABLE, "Healing Grass must be Consumable")
	assert(editor.rank == 1, "Healing Grass rank must be 1")
	assert(editor.hp_bonus == 50, "Healing Grass HP bonus must be 50")
	assert(editor.buy_price == 10, "Healing Grass buy price must be 10")
	print("  PASS: Preset 'Healing Grass' (ID 32001, Consumable, Rank 1, Heals 50 HP, Buy 10g)")

	# 5. Mana Potion
	assert(editor.apply_preset("Mana Potion") == true, "Failed to apply Mana Potion")
	assert(editor.item_id == 32002, "Mana Potion ID mismatch: %d" % editor.item_id)
	assert(editor.equip_slot == ItemEditorClass.EquipSlot.CONSUMABLE, "Mana Potion must be Consumable")
	assert(editor.rank == 2, "Mana Potion rank must be 2")
	assert(editor.sp_bonus == 60, "Mana Potion SP bonus must be 60")
	assert(editor.buy_price == 25, "Mana Potion buy price must be 25")
	print("  PASS: Preset 'Mana Potion' (ID 32002, Consumable, Rank 2, Heals 60 SP, Buy 25g)")

	editor.free()

func _test_alchemy_synthesis_calculation() -> void:
	print(">>> [TEST 4] Verifying WLO Alchemy & Synthesis Calculation...")
	var editor: ItemEditorClass = ItemEditorClass.new()

	# Case 1: Mat A rank 3, Mat B rank 5, Catalyst 0
	# base_rank = int((3 + 5) / 2.0) + 0 = 4
	# min_rank = maxi(1, 4 - 1) = 3
	# max_rank = 4 + 2 = 6
	var res1: Dictionary = editor.calculate_synthesis_result(3, 5, 0)
	assert(res1["base_rank"] == 4, "Expected base_rank 4, got %d" % res1["base_rank"])
	assert(res1["min_rank"] == 3, "Expected min_rank 3, got %d" % res1["min_rank"])
	assert(res1["max_rank"] == 6, "Expected max_rank 6, got %d" % res1["max_rank"])
	assert(res1["success_rate"] >= 0.15 and res1["success_rate"] <= 0.95, "Success rate out of bounds")
	print("  PASS: Synthesis Case 1 (Rank 3 + 5, Cat 0) -> Base %d, Range [%d..%d], Rate %d%%" % [
		res1["base_rank"], res1["min_rank"], res1["max_rank"], res1["success_percentage"]
	])

	# Case 2: Mat A rank 3, Mat B rank 5, Catalyst 1 (Alchemy Book I)
	# base_rank = int((3 + 5) / 2.0) + 1 = 5
	# min_rank = maxi(1, 5 - 1) = 4
	# max_rank = 5 + 2 = 7
	var res2: Dictionary = editor.calculate_synthesis_result(3, 5, 1)
	assert(res2["base_rank"] == 5, "Expected base_rank 5, got %d" % res2["base_rank"])
	assert(res2["min_rank"] == 4, "Expected min_rank 4, got %d" % res2["min_rank"])
	assert(res2["max_rank"] == 7, "Expected max_rank 7, got %d" % res2["max_rank"])
	print("  PASS: Synthesis Case 2 (Rank 3 + 5, Cat 1) -> Base %d, Range [%d..%d], Rate %d%%" % [
		res2["base_rank"], res2["min_rank"], res2["max_rank"], res2["success_percentage"]
	])

	# Case 3: Mat A rank 1, Mat B rank 1, Catalyst 0
	# base_rank = int((1 + 1) / 2.0) + 0 = 1
	# min_rank = maxi(1, 1 - 1) = 1 (clamped by maxi(1, ...))
	# max_rank = 1 + 2 = 3
	var res3: Dictionary = editor.calculate_synthesis_result(1, 1, 0)
	assert(res3["base_rank"] == 1, "Expected base_rank 1, got %d" % res3["base_rank"])
	assert(res3["min_rank"] == 1, "Expected min_rank 1, got %d" % res3["min_rank"])
	assert(res3["max_rank"] == 3, "Expected max_rank 3, got %d" % res3["max_rank"])
	print("  PASS: Synthesis Case 3 (Rank 1 + 1, Cat 0) -> Base %d, Range [%d..%d], Rate %d%%" % [
		res3["base_rank"], res3["min_rank"], res3["max_rank"], res3["success_percentage"]
	])

	editor.free()

func _test_json_export_and_import() -> void:
	print(">>> [TEST 5] Verifying Item Record Creation, JSON Export & Import...")
	var editor: ItemEditorClass = ItemEditorClass.new()
	editor.apply_preset("Iron Armor")

	var record: Dictionary = editor.create_item_record()
	assert(record["item_id"] == 21005, "Record item_id mismatch")
	assert(record["item_name"] == "Iron Armor", "Record item_name mismatch")
	assert(record["equip_slot_name"] == "Clothes", "Record slot name mismatch")
	assert(record["stats"]["def"] == 18, "Record stats def mismatch")
	assert(record["stats"]["mdef"] == 4, "Record stats mdef mismatch")

	var test_path: String = "user://test_iron_armor.json"
	var save_ok: bool = editor.save_item_json(test_path)
	assert(save_ok == true, "save_item_json failed")
	assert(FileAccess.file_exists(test_path), "Exported file does not exist on disk")

	# Modify editor values and restore by loading
	editor.reset_to_blank()
	assert(editor.item_id != 21005, "Editor should have been reset")

	var loaded_dict: Dictionary = editor.load_item_json(test_path)
	assert(not loaded_dict.is_empty(), "load_item_json returned empty dict")
	assert(editor.item_id == 21005, "Loaded item_id mismatch: %d" % editor.item_id)
	assert(editor.item_name == "Iron Armor", "Loaded item_name mismatch: " + editor.item_name)
	assert(editor.def == 18, "Loaded DEF mismatch: %d" % editor.def)
	assert(editor.mdef == 4, "Loaded MDEF mismatch: %d" % editor.mdef)
	assert(editor.equip_slot == ItemEditorClass.EquipSlot.CLOTHES, "Loaded equip_slot mismatch")

	print("  PASS: Item JSON exported, validated on disk, and restored accurately.")
	editor.free()

func _test_recipe_export() -> void:
	print(">>> [TEST 6] Verifying Recipe JSON Export...")
	var editor: ItemEditorClass = ItemEditorClass.new()
	editor.apply_preset("Bronze Sword")
	editor.alchemy_recipe_name = "Bronze Sword Forging"
	editor.alchemy_mat_a_id = 23001
	editor.alchemy_mat_a_rank = 3
	editor.alchemy_mat_b_id = 21005
	editor.alchemy_mat_b_rank = 5
	editor.alchemy_catalyst_tier = 1

	var recipe_path: String = "user://test_recipe_bronze_sword.json"
	var export_ok: bool = editor.export_recipe_json(recipe_path)
	assert(export_ok == true, "export_recipe_json failed")
	assert(FileAccess.file_exists(recipe_path), "Recipe file does not exist on disk")

	var f := FileAccess.open(recipe_path, FileAccess.READ)
	assert(f != null, "Failed to read exported recipe file")
	var text := f.get_as_text()
	f.close()

	var json := JSON.new()
	assert(json.parse(text) == OK, "Recipe JSON parsing failed")
	var data: Dictionary = json.data
	assert(data["recipe_name"] == "Bronze Sword Forging", "Recipe name mismatch")
	assert(data["material_a"]["rank"] == 3, "Material A rank mismatch")
	assert(data["material_b"]["rank"] == 5, "Material B rank mismatch")
	assert(data["catalyst_tier"] == 1, "Catalyst tier mismatch")
	assert(data["synthesis_result"]["base_rank"] == 5, "Synthesis base rank mismatch")

	print("  PASS: Recipe JSON successfully exported with full material & synthesis payload.")
	editor.free()

func _test_scene_instantiation_and_ui() -> void:
	print(">>> [TEST 7] Verifying Scene Instantiation & UI Signal Flow (item_editor.tscn)...")
	var scene_res = load("res://scenes/tools/item_editor.tscn")
	assert(scene_res != null, "ERROR: Failed to load res://scenes/tools/item_editor.tscn")

	var editor = scene_res.instantiate()
	assert(editor != null, "ERROR: Failed to instantiate item_editor.tscn")
	add_child(editor)

	# Verify UI Nodes bound
	assert(editor.spin_item_id != null, "spin_item_id missing")
	assert(editor.edit_item_name != null, "edit_item_name missing")
	assert(editor.spin_icon_id != null, "spin_icon_id missing")
	assert(editor.rect_icon_preview != null, "rect_icon_preview missing")
	assert(editor.spin_atk != null, "spin_atk missing")
	assert(editor.opt_presets != null, "opt_presets missing")
	assert(editor.panel_tooltip != null, "panel_tooltip missing")

	# Test preset selection via UI
	editor.apply_preset("Feather Boots")
	assert(editor.edit_item_name.text == "Feather Boots", "UI name did not update to Feather Boots")
	assert(editor.spin_spd.value == 15.0, "UI SPD did not update to 15")

	# Test Icon preview update
	editor.update_icon_preview()
	assert(editor.rect_icon_preview.texture != null, "Icon preview texture must not be null")
	print("  PASS: Icon preview generated and attached successfully: %s" % editor.rect_icon_preview.texture)

	# Test Tooltip preview update
	editor.update_tooltip_preview()
	assert(editor.lbl_tt_title.text == "Feather Boots", "Tooltip title did not sync")

	editor.queue_free()
	print("  PASS: Scene instantiated and all UI bindings confirmed.")
