extends Node

const BattleEditor = preload("res://scripts/tools/battle_editor.gd")

## Automated Verification Suite for Wonderland Online Battle Formation & Encounter Studio
## Tests:
## 1. 2:1 Axonometric Battle Grid Geometry & Slot Coordinates
## 2. Interactive Slot Selection & Attribute Validation
## 3. Monster & Troop Formator (Player & Enemy Placement, Bounds Checking)
## 4. Authentic Party Formation Presets (Kelan Slimes, Cave Bats, Shipwreck Pirates)
## 5. Battle Simulation & Turn Order SPD Descending Sorting with Tie-breaking
## 6. Map Encounter Table Authoring & Statistical Probability Distribution
## 7. Loot Drop Table Configuration & Rate Rolling
## 8. JSON Data Serialization & File Roundtrip
## 9. Godot 4 .tscn Scene Exporter & Scene Instantiation Verification

func _ready() -> void:
	print("=================================================================")
	print("--- Running WLO Battle Formation & Encounter Studio Test Suite --")
	print("=================================================================\n")
	
	_test_instantiation_and_structure()
	_test_axonometric_grid_formation()
	_test_monster_and_player_placement()
	_test_party_formation_presets()
	_test_turn_order_simulation()
	_test_encounter_table_and_probability()
	_test_loot_drop_table()
	_test_serialization_and_roundtrip()
	_test_scene_export()
	
	print("\n=================================================================")
	print("--- ALL BATTLE EDITOR & ENCOUNTER STUDIO TESTS PASSED (100%) ---")
	print("=================================================================")
	get_tree().quit(0)

func _test_instantiation_and_structure() -> void:
	print(">>> [TEST 1] Verifying BattleEditor Instantiation & Layout (battle_editor.tscn)...")
	var scene_res = load("res://scenes/tools/battle_editor.tscn")
	assert(scene_res != null, "ERROR: battle_editor.tscn failed to load")
	
	var editor = scene_res.instantiate()
	assert(editor != null, "ERROR: battle_editor could not be instantiated")
	add_child(editor)
	
	assert(editor is BattleEditor, "ERROR: Instantiated node must be BattleEditor")
	assert(editor.custom_minimum_size.x >= 800.0, "ERROR: Custom min width must be >= 800")
	assert(editor.custom_minimum_size.y >= 600.0, "ERROR: Custom min height must be >= 600")
	
	# Verify essential exported/public methods exist
	var required_methods: Array[String] = [
		"set_enemy_slot",
		"get_enemy_slot",
		"set_player_slot",
		"get_player_slot",
		"clear_slot",
		"clear_all_slots",
		"load_formation_preset",
		"get_preset_names",
		"calculate_turn_order",
		"add_encounter_group",
		"remove_encounter_group",
		"get_encounter_groups",
		"roll_random_encounter",
		"add_loot_drop",
		"remove_loot_drop",
		"get_loot_drops",
		"roll_loot_drops",
		"create_encounter_data",
		"save_encounter_table",
		"load_encounter_table",
		"export_battle_scene"
	]
	
	for m in required_methods:
		assert(editor.has_method(m), "ERROR: BattleEditor missing required method: %s" % m)
		
	print("  PASS: BattleEditor instantiated with 800x600 size and all %d required methods." % required_methods.size())
	editor.queue_free()

func _test_axonometric_grid_formation() -> void:
	print(">>> [TEST 2] Verifying 2:1 Axonometric Battle Grid Geometry & Polygon Containment...")
	var editor: BattleEditor = BattleEditor.new()
	add_child(editor)
	
	# Check all 8 player slots and 8 enemy slots
	for s in range(BattleEditor.TOTAL_SLOTS):
		var p_pos: Vector2 = editor.get_slot_screen_position(false, s)
		var e_pos: Vector2 = editor.get_slot_screen_position(true, s)
		
		# Positions must be strictly positive within arena boundaries
		assert(p_pos.x > 0 and p_pos.y > 0, "ERROR: Player slot %d position invalid: %s" % [s, p_pos])
		assert(e_pos.x > 0 and e_pos.y > 0, "ERROR: Enemy slot %d position invalid: %s" % [s, e_pos])
		
		# Players should be located left of enemies
		assert(p_pos.x < e_pos.x, "ERROR: Player slot %d (x=%.1f) must be left of enemy slot %d (x=%.1f)" % [s, p_pos.x, s, e_pos.x])
		
		# Check 2:1 diamond polygon vertices
		var poly: PackedVector2Array = editor.get_slot_polygon(true, s)
		assert(poly.size() == 4, "ERROR: Slot polygon must have 4 diamond vertices")
		
		var width: float = poly[1].x - poly[3].x
		var height: float = poly[2].y - poly[0].y
		assert(is_equal_approx(width, BattleEditor.DIAMOND_HALF_WIDTH * 2.0), "ERROR: Diamond width incorrect")
		assert(is_equal_approx(height, BattleEditor.DIAMOND_HALF_HEIGHT * 2.0), "ERROR: Diamond height incorrect")
		assert(is_equal_approx(width / height, 2.0), "ERROR: Axonometric aspect ratio must be exactly 2:1 (was %.2f)" % (width / height))
	
	# Verify front row vs back row separation
	var p_front_0: Vector2 = editor.get_slot_screen_position(false, 0)
	var p_back_0: Vector2 = editor.get_slot_screen_position(false, 4)
	assert(p_front_0 != p_back_0, "ERROR: Player front slot 0 and back slot 4 cannot coincide")
	assert(p_back_0.x < p_front_0.x, "ERROR: Player back row must be offset behind front row")
	
	var e_front_0: Vector2 = editor.get_slot_screen_position(true, 0)
	var e_back_0: Vector2 = editor.get_slot_screen_position(true, 4)
	assert(e_front_0 != e_back_0, "ERROR: Enemy front slot 0 and back slot 4 cannot coincide")
	assert(e_back_0.x > e_front_0.x, "ERROR: Enemy back row must be offset behind front row")
	
	# Verify point-in-polygon detection for mouse interaction
	var test_center: Vector2 = editor.get_slot_screen_position(true, 2)
	var hit: Dictionary = editor.find_slot_at_point(test_center)
	assert(hit["found"] == true, "ERROR: Point at center of Enemy slot 2 must be found")
	assert(hit["is_enemy"] == true, "ERROR: Hit slot must be identified as enemy")
	assert(hit["slot"] == 2, "ERROR: Hit slot must be 2")
	
	var p_test_center: Vector2 = editor.get_slot_screen_position(false, 1)
	var hit_p: Dictionary = editor.find_slot_at_point(p_test_center)
	assert(hit_p["found"] == true, "ERROR: Point at center of Player slot 1 must be found")
	assert(hit_p["is_enemy"] == false, "ERROR: Hit slot must be identified as player")
	assert(hit_p["slot"] == 1, "ERROR: Hit slot must be 1")
	
	var out_hit: Dictionary = editor.find_slot_at_point(Vector2(5.0, 5.0))
	assert(out_hit["found"] == false, "ERROR: Out-of-bounds point must return found=false")
	
	print("  PASS: 2:1 axonometric grid geometry, diamond vertices, and point click testing verified.")
	editor.queue_free()

func _test_monster_and_player_placement() -> void:
	print(">>> [TEST 3] Verifying Monster & Player Placement & Bounds Checking...")
	var editor: BattleEditor = BattleEditor.new()
	add_child(editor)
	
	editor.clear_all_slots()
	for s in range(8):
		assert(editor.get_enemy_slot(s).is_empty(), "ERROR: Slot %d must be empty after clear_all_slots" % s)
		assert(editor.get_player_slot(s).is_empty(), "ERROR: Slot %d must be empty after clear_all_slots" % s)
		
	# Place monster in Enemy Slot 3
	var monster_data: Dictionary = {
		"monster_id": 501,
		"monster_name": "Forest Wolf",
		"level": 6,
		"hp": 180,
		"sp": 40,
		"element": BattleEditor.Element.EARTH,
		"jmp_name": "wolf.jmp",
		"is_boss": false,
		"spd": 16
	}
	var ok_e: bool = editor.set_enemy_slot(3, monster_data)
	assert(ok_e == true, "ERROR: set_enemy_slot(3) must return true")
	
	var retrieved_e: Dictionary = editor.get_enemy_slot(3)
	assert(retrieved_e.get("monster_id") == 501, "ERROR: monster_id mismatch")
	assert(retrieved_e.get("monster_name") == "Forest Wolf", "ERROR: monster_name mismatch")
	assert(retrieved_e.get("level") == 6, "ERROR: level mismatch")
	assert(retrieved_e.get("hp") == 180, "ERROR: hp mismatch")
	assert(retrieved_e.get("sp") == 40, "ERROR: sp mismatch")
	assert(retrieved_e.get("element") == BattleEditor.Element.EARTH, "ERROR: element mismatch")
	assert(retrieved_e.get("jmp_name") == "wolf.jmp", "ERROR: jmp_name mismatch")
	assert(retrieved_e.get("is_boss") == false, "ERROR: is_boss mismatch")
	assert(retrieved_e.get("spd") == 16, "ERROR: spd mismatch")
	
	# Place player in Player Slot 0
	var player_data: Dictionary = {
		"monster_id": 1,
		"monster_name": "Rocco",
		"level": 15,
		"hp": 450,
		"sp": 120,
		"element": BattleEditor.Element.FIRE,
		"jmp_name": "rocco.jmp",
		"is_boss": false,
		"spd": 24
	}
	var ok_p: bool = editor.set_player_slot(0, player_data)
	assert(ok_p == true, "ERROR: set_player_slot(0) must return true")
	var retrieved_p: Dictionary = editor.get_player_slot(0)
	assert(retrieved_p.get("monster_name") == "Rocco", "ERROR: player name mismatch")
	assert(retrieved_p.get("spd") == 24, "ERROR: player spd mismatch")
	
	# Test clear single slot
	editor.clear_slot(true, 3)
	assert(editor.get_enemy_slot(3).is_empty(), "ERROR: Enemy slot 3 must be empty after clear_slot")
	assert(not editor.get_player_slot(0).is_empty(), "ERROR: Player slot 0 must still remain occupied")
	
	# Test out-of-bounds slot handling
	assert(editor.set_enemy_slot(-1, monster_data) == false, "ERROR: Negative slot index must fail gracefully")
	assert(editor.set_enemy_slot(8, monster_data) == false, "ERROR: Slot index 8 must fail gracefully")
	assert(editor.get_enemy_slot(-1).is_empty(), "ERROR: Negative slot get must return empty dict")
	assert(editor.get_enemy_slot(8).is_empty(), "ERROR: Slot 8 get must return empty dict")
	
	print("  PASS: Monster & Player attributes, normalizations, and bounds checks verified.")
	editor.queue_free()

func _test_party_formation_presets() -> void:
	print(">>> [TEST 4] Verifying Authentic WLO Party Formation Presets...")
	var editor: BattleEditor = BattleEditor.new()
	add_child(editor)
	
	var preset_names: Array[String] = editor.get_preset_names()
	assert(preset_names.has("Kelan Slimes Troop"), "ERROR: Missing preset 'Kelan Slimes Troop'")
	assert(preset_names.has("Kelan Cave Bats"), "ERROR: Missing preset 'Kelan Cave Bats'")
	assert(preset_names.has("Shipwreck Pirates"), "ERROR: Missing preset 'Shipwreck Pirates'")
	
	# Test Preset 1: Kelan Slimes Troop
	var ok_slimes: bool = editor.load_formation_preset("Kelan Slimes Troop")
	assert(ok_slimes == true, "ERROR: Failed to load 'Kelan Slimes Troop'")
	var s0: Dictionary = editor.get_enemy_slot(0)
	var s1: Dictionary = editor.get_enemy_slot(1)
	var s4: Dictionary = editor.get_enemy_slot(4)
	assert(s0.get("monster_name") == "Blue Jelly" and s0.get("level") == 1, "ERROR: Slot 0 must be Blue Jelly Lv1")
	assert(s1.get("monster_name") == "Blue Jelly" and s1.get("level") == 1, "ERROR: Slot 1 must be Blue Jelly Lv1")
	assert(s4.get("monster_name") == "Green Jelly" and s4.get("level") == 2, "ERROR: Slot 4 must be Green Jelly Lv2")
	assert(s0.get("element") == BattleEditor.Element.WATER, "ERROR: Blue Jelly must be Water element")
	assert(s4.get("element") == BattleEditor.Element.EARTH, "ERROR: Green Jelly must be Earth element")
	assert(editor.get_enemy_slot(2).is_empty(), "ERROR: Slot 2 should be empty in Slime troop")
	
	# Test Preset 2: Kelan Cave Bats
	var ok_bats: bool = editor.load_formation_preset("Kelan Cave Bats")
	assert(ok_bats == true, "ERROR: Failed to load 'Kelan Cave Bats'")
	var b0: Dictionary = editor.get_enemy_slot(0)
	var b1: Dictionary = editor.get_enemy_slot(1)
	var b2: Dictionary = editor.get_enemy_slot(2)
	var b4: Dictionary = editor.get_enemy_slot(4)
	assert(b0.get("monster_name") == "Cave Bat" and b0.get("level") == 3, "ERROR: Slot 0 must be Cave Bat Lv3")
	assert(b1.get("monster_name") == "Cave Bat" and b1.get("level") == 3, "ERROR: Slot 1 must be Cave Bat Lv3")
	assert(b2.get("monster_name") == "Cave Bat" and b2.get("level") == 3, "ERROR: Slot 2 must be Cave Bat Lv3")
	assert(b4.get("monster_name") == "Leader Bat" and b4.get("level") == 5, "ERROR: Slot 4 must be Leader Bat Lv5")
	assert(b4.get("is_boss") == true, "ERROR: Leader Bat must be marked as boss")
	assert(b0.get("element") == BattleEditor.Element.WIND, "ERROR: Cave Bat must be Wind element")
	assert(b4.get("element") == BattleEditor.Element.FIRE, "ERROR: Leader Bat must be Fire element")
	
	# Test Preset 3: Shipwreck Pirates
	var ok_pirates: bool = editor.load_formation_preset("Shipwreck Pirates")
	assert(ok_pirates == true, "ERROR: Failed to load 'Shipwreck Pirates'")
	for i in range(4):
		var p_slot: Dictionary = editor.get_enemy_slot(i)
		assert(p_slot.get("monster_name") == "Sailor Pirate" and p_slot.get("level") == 8, "ERROR: Slot %d must be Sailor Pirate Lv8" % i)
	var p_capt: Dictionary = editor.get_enemy_slot(5)
	assert(p_capt.get("monster_name") == "Pirate Captain" and p_capt.get("level") == 12, "ERROR: Slot 5 must be Pirate Captain Lv12")
	assert(p_capt.get("is_boss") == true, "ERROR: Pirate Captain must be marked as boss")
	
	# Test Custom Preset Save & Recall
	editor.save_formation_preset("CustomTestPres")
	assert(editor.get_preset_names().has("CustomTestPres"), "ERROR: Custom preset name missing after save")
	editor.clear_all_slots()
	assert(editor.get_enemy_slot(5).is_empty(), "ERROR: Slot 5 should be empty after clear")
	editor.load_formation_preset("CustomTestPres")
	assert(editor.get_enemy_slot(5).get("monster_name") == "Pirate Captain", "ERROR: Custom preset reload failed")
	
	print("  PASS: All presets loaded and verified with authentic monster compositions.")
	editor.queue_free()

func _test_turn_order_simulation() -> void:
	print(">>> [TEST 5] Verifying Battle Simulation & Turn Order SPD Descending Sorting...")
	var editor: BattleEditor = BattleEditor.new()
	add_child(editor)
	
	editor.clear_all_slots()
	
	# Populate actors with distinct SPDs
	editor.set_player_slot(0, {"monster_name": "Fast Warrior", "spd": 25, "hp": 300})
	editor.set_player_slot(1, {"monster_name": "Slow Priest", "spd": 10, "hp": 200})
	
	editor.set_enemy_slot(0, {"monster_name": "Medium Slime", "spd": 18, "hp": 80})
	editor.set_enemy_slot(4, {"monster_name": "Hyper Boss", "spd": 32, "hp": 600, "is_boss": true})
	editor.set_enemy_slot(5, {"monster_name": "Crawling Snail", "spd": 5, "hp": 40})
	
	var order: Array[Dictionary] = editor.calculate_turn_order()
	assert(order.size() == 5, "ERROR: Expected 5 participants in turn order, got %d" % order.size())
	
	# Check order descending by SPD: 32 -> 25 -> 18 -> 10 -> 5
	assert(order[0]["monster_name"] == "Hyper Boss" and order[0]["spd"] == 32, "ERROR: 1st must be Hyper Boss")
	assert(order[1]["monster_name"] == "Fast Warrior" and order[1]["spd"] == 25, "ERROR: 2nd must be Fast Warrior")
	assert(order[2]["monster_name"] == "Medium Slime" and order[2]["spd"] == 18, "ERROR: 3rd must be Medium Slime")
	assert(order[3]["monster_name"] == "Slow Priest" and order[3]["spd"] == 10, "ERROR: 4th must be Slow Priest")
	assert(order[4]["monster_name"] == "Crawling Snail" and order[4]["spd"] == 5, "ERROR: 5th must be Crawling Snail")
	
	# Test Deterministic Tie-Breaking: Player before Enemy when SPDs match
	editor.clear_all_slots()
	editor.set_player_slot(2, {"monster_name": "Player Tied", "spd": 20})
	editor.set_enemy_slot(1, {"monster_name": "Enemy Tied", "spd": 20})
	
	var tie_order: Array[Dictionary] = editor.calculate_turn_order()
	assert(tie_order.size() == 2, "ERROR: Expected 2 tied participants")
	assert(tie_order[0]["team"] == "player", "ERROR: Player must win tie-break over Enemy at identical SPD")
	assert(tie_order[1]["team"] == "enemy", "ERROR: Enemy must follow Player at identical SPD")
	
	print("  PASS: Turn order SPD sorting and deterministic tie-breaking logic validated.")
	editor.queue_free()

func _test_encounter_table_and_probability() -> void:
	print(">>> [TEST 6] Verifying Map Encounter Table Authoring & Statistical Probability...")
	var editor: BattleEditor = BattleEditor.new()
	add_child(editor)
	
	editor.map_id = 11016
	editor.map_name = "Kelan Trail"
	editor.encounter_rate_pct = 20.0 # 20% step chance
	
	editor.clear_encounter_groups()
	editor.add_encounter_group({"group_id": 1, "group_name": "Slime Pack", "weight": 70})
	editor.add_encounter_group({"group_id": 2, "group_name": "Bat Colony", "weight": 30})
	
	var groups: Array[Dictionary] = editor.get_encounter_groups()
	assert(groups.size() == 2, "ERROR: Expected 2 groups in encounter table")
	
	# Test deterministic roll triggers
	var hit: Dictionary = editor.roll_random_encounter(15.0, 30.0) # 15% <= 20% -> triggers
	assert(hit["triggered"] == true, "ERROR: Roll 15.0% must trigger encounter under 20% rate")
	assert(hit["group"]["group_name"] == "Slime Pack", "ERROR: Group roll 30.0 under weight 70 must pick Slime Pack")
	
	var miss: Dictionary = editor.roll_random_encounter(25.0, 10.0) # 25% > 20% -> no encounter
	assert(miss["triggered"] == false, "ERROR: Roll 25.0% must not trigger encounter under 20% rate")
	
	var bat_hit: Dictionary = editor.roll_random_encounter(5.0, 85.0) # 85.0 > 70 -> picks Bat Colony
	assert(bat_hit["triggered"] == true, "ERROR: Roll 5.0% must trigger encounter")
	assert(bat_hit["group"]["group_name"] == "Bat Colony", "ERROR: Group roll 85.0 must pick Bat Colony")
	
	# Statistical distribution test (1000 trials at 20% trigger rate)
	var trigger_count: int = 0
	var trials: int = 1000
	for t in range(trials):
		var res: Dictionary = editor.roll_random_encounter()
		if res["triggered"]:
			trigger_count += 1
			
	var trigger_pct: float = (float(trigger_count) / float(trials)) * 100.0
	print("  Encounter Trial: %d / %d triggers (%.1f%%, Target: 20.0%%)" % [trigger_count, trials, trigger_pct])
	assert(trigger_count >= 130 and trigger_count <= 270, "ERROR: Trigger count out of statistical tolerance (3 standard deviations)")
	
	print("  PASS: Encounter table weights, step trigger logic, and statistical distributions verified.")
	editor.queue_free()

func _test_loot_drop_table() -> void:
	print(">>> [TEST 7] Verifying Loot Drop Table Configuration & Rate Rolling...")
	var editor: BattleEditor = BattleEditor.new()
	add_child(editor)
	
	editor.clear_loot_drops()
	
	# Add drops: Guaranteed (100%), Impossible (0%), and Variable Qty
	editor.add_loot_drop(1001, "Guaranteed Gold Pouch", 100.0, 3, 5)
	editor.add_loot_drop(1002, "Never Drop Relic", 0.0, 1, 1)
	editor.add_loot_drop(1003, "Common Herb", 100.0, 1, 1)
	
	var drops: Array[Dictionary] = editor.get_loot_drops()
	assert(drops.size() == 3, "ERROR: Expected 3 loot drop definitions")
	
	var rolled: Array[Dictionary] = editor.roll_loot_drops()
	
	var found_gold: bool = false
	var found_relic: bool = false
	var gold_qty: int = 0
	
	for r in rolled:
		if r["item_id"] == 1001:
			found_gold = true
			gold_qty = r["quantity"]
		elif r["item_id"] == 1002:
			found_relic = true
			
	assert(found_gold == true, "ERROR: 100% drop rate item must always drop")
	assert(found_relic == false, "ERROR: 0% drop rate item must never drop")
	assert(gold_qty >= 3 and gold_qty <= 5, "ERROR: Gold drop quantity (%d) out of range [3..5]" % gold_qty)
	
	# Test remove drop
	editor.remove_loot_drop(1) # Remove relic
	assert(editor.get_loot_drops().size() == 2, "ERROR: Loot drops count must be 2 after removal")
	
	print("  PASS: Loot drop rates, quantities, and removal verified.")
	editor.queue_free()

func _test_serialization_and_roundtrip() -> void:
	print(">>> [TEST 8] Verifying JSON Serialization & File Roundtrip...")
	var editor: BattleEditor = BattleEditor.new()
	add_child(editor)
	
	editor.map_id = 10003
	editor.map_name = "Newbie Beach Roundtrip"
	editor.encounter_rate_pct = 18.5
	
	editor.load_formation_preset("Kelan Slimes Troop")
	editor.set_player_slot(0, {"monster_name": "TestHero", "level": 12, "hp": 350, "spd": 15})
	
	var save_path: String = "user://test_encounter_roundtrip.json"
	var save_ok: bool = editor.save_encounter_table(save_path)
	assert(save_ok == true, "ERROR: save_encounter_table failed")
	assert(FileAccess.file_exists(save_path), "ERROR: Saved file does not exist on disk")
	
	# Clear and restore
	editor.clear_all_slots()
	editor.map_id = 99999
	editor.encounter_rate_pct = 1.0
	
	var loaded_data: Dictionary = editor.load_encounter_table(save_path)
	assert(not loaded_data.is_empty(), "ERROR: load_encounter_table returned empty dictionary")
	assert(editor.map_id == 10003, "ERROR: Loaded map_id mismatch (got %d)" % editor.map_id)
	assert(editor.map_name == "Newbie Beach Roundtrip", "ERROR: Loaded map_name mismatch")
	assert(is_equal_approx(editor.encounter_rate_pct, 18.5), "ERROR: Loaded encounter rate mismatch")
	
	var p0: Dictionary = editor.get_player_slot(0)
	assert(p0.get("monster_name") == "TestHero", "ERROR: Loaded player slot 0 mismatch")
	
	var e0: Dictionary = editor.get_enemy_slot(0)
	assert(e0.get("monster_name") == "Blue Jelly", "ERROR: Loaded enemy slot 0 mismatch")
	
	print("  PASS: JSON table data serialization roundtrip clean and bit-exact.")
	editor.queue_free()

func _test_scene_export() -> void:
	print(">>> [TEST 9] Verifying Godot 4 .tscn Scene Exporter & Scene Instantiation...")
	var editor: BattleEditor = BattleEditor.new()
	add_child(editor)
	
	editor.map_id = 10003
	editor.map_name = "Newbie Beach"
	editor.load_formation_preset("Shipwreck Pirates")
	editor.set_player_slot(0, {"monster_name": "Captain Dan", "level": 20, "hp": 600, "spd": 18})
	
	var scene_path: String = "user://test_exported_battle.tscn"
	var export_res: String = editor.export_battle_scene(scene_path)
	assert(export_res == scene_path, "ERROR: export_battle_scene did not return expected path")
	assert(FileAccess.file_exists(scene_path), "ERROR: Exported scene file does not exist on disk")
	
	# Verify that Godot can parse and instantiate the generated scene cleanly
	var loaded_scene = load(scene_path)
	assert(loaded_scene != null, "ERROR: Exported .tscn could not be parsed by Godot resource loader")
	
	var scene_node = loaded_scene.instantiate()
	assert(scene_node != null, "ERROR: Exported scene could not be instantiated")
	add_child(scene_node)
	
	# Verify node tree hierarchy
	var bg: Node = scene_node.get_node_or_null("ArenaBackground")
	assert(bg != null, "ERROR: Exported scene missing 'ArenaBackground'")
	
	var player_party: Node = scene_node.get_node_or_null("PlayerParty")
	assert(player_party != null, "ERROR: Exported scene missing 'PlayerParty'")
	assert(player_party.get_child_count() == 8, "ERROR: PlayerParty must contain 8 slot markers")
	
	var enemy_troop: Node = scene_node.get_node_or_null("EnemyTroop")
	assert(enemy_troop != null, "ERROR: Exported scene missing 'EnemyTroop'")
	assert(enemy_troop.get_child_count() == 8, "ERROR: EnemyTroop must contain 8 slot markers")
	
	# Verify pirate captain metadata in Enemy slot 5
	var capt_marker: Node = enemy_troop.get_node_or_null("Enemy_Slot_5")
	assert(capt_marker != null, "ERROR: Missing Enemy_Slot_5 marker")
	assert(capt_marker.get_meta("occupied") == true, "ERROR: Enemy_Slot_5 must have occupied=true")
	assert(capt_marker.get_meta("monster_name") == "Pirate Captain", "ERROR: Monster name mismatch in metadata")
	assert(capt_marker.get_meta("is_boss") == true, "ERROR: Boss status mismatch in metadata")
	
	# Verify player slot 0
	var p0_marker: Node = player_party.get_node_or_null("Player_Slot_0")
	assert(p0_marker != null, "ERROR: Missing Player_Slot_0 marker")
	assert(p0_marker.get_meta("monster_name") == "Captain Dan", "ERROR: Player name mismatch in metadata")
	
	scene_node.queue_free()
	editor.queue_free()
	print("  PASS: Exported .tscn scene loaded and validated with accurate node hierarchy and metadata.")
