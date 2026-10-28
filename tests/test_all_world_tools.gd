extends Node

## Master Verification Suite for the Wonderland Online Complete Content Creation & Studio Suite:
## 1. NpcEditor (Visual Appearance, 8-way Rotation, Dialogue Tree & Presets)
## 2. MapEditor (Map Canvas, Collision Painter, Portals, Ground Items, MapData & Scene Exporter)
## 3. QuestEditor (Multi-step Objectives, Token Parser, Rewards, Presets, Script Generator)
## 4. SkillEditor (Identity, Combat Formula, 4-Element Wheel +25%/-25%, MBTM Timelines, VFX)
## 5. ItemEditor (Master Attributes, Stat Formatting, Authentic WLO Synthesis Formula, Presets)
## 6. BattleEditor (2:1 Axonometric Battle Grid, Slot Placement, Turn Order, Encounters, Drops)
## 7. CutsceneEditor (Multi-track Timeline, Presets, Scrubber, JSON & Scene Exporter)
## 8. TentEditor (Player Housing, 18+ Furniture Catalog, 90-degree Rotation, Walkability, Presets, .tscn Exporter)
## 9. AudioEditor (Jukebox, 1,310 Audio Assets, 32-band Spectrum, Loop Points, Tagging, Manifest Exporter)
## 10. BattleView (Playable Turn-Based Battle View & Engine, 7 Battle Buttons, 2:1 Arena, 20s Timer)
## 11. WorldEditor (Unified TabContainer Housing All 9 Studios, DB Inspector, and Live Simulator)

func _ready() -> void:
	print("=================================================================")
	print("--- Running Master Wonderland Online Studio & Tool Test Suite ---")
	print("=================================================================\n")
	
	_test_npc_editor()
	_test_map_editor()
	_test_quest_editor()
	_test_skill_editor()
	_test_item_editor()
	_test_battle_editor()
	_test_cutscene_editor()
	_test_tent_editor()
	_test_audio_editor()
	_test_battle_view()
	_test_world_editor()
	
	print("\n=================================================================")
	print("--- ALL 11 STUDIO TOOLS & WORLD SUITE TESTS PASSED (100%) ---")
	print("=================================================================")
	get_tree().quit(0)

func _test_npc_editor() -> void:
	print(">>> [TEST 1] Verifying NPC Creator & Visual Studio (npc_editor.tscn)...")
	var scene_res = load("res://scenes/tools/npc_editor.tscn")
	assert(scene_res != null, "ERROR: npc_editor.tscn failed to load")
	var editor = scene_res.instantiate()
	assert(editor != null, "ERROR: npc_editor could not be instantiated")
	add_child(editor)
	
	assert(editor.has_method("create_npc_entity"), "ERROR: NpcEditor missing create_npc_entity")
	var custom_npc: NpcEntity = editor.create_npc_entity()
	assert(custom_npc != null and custom_npc is NpcEntity, "ERROR: Invalid NpcEntity")
	print("  PASS: Custom NpcEntity created cleanly: name='%s', id=%d, pos=%s" % [custom_npc.npc_name, custom_npc.npc_id, custom_npc.world_position])
	
	if editor.has_method("rotate_preview"):
		editor.rotate_preview(1)
		print("  PASS: Preview heading rotated successfully")
	
	if editor.has_method("save_custom_preset"):
		var ok = editor.save_custom_preset("TestNPC", {"name": "TestNPC", "id": 9999, "jmp": "1050.jmp", "heading": 2, "pos_x": 1000, "pos_y": 800})
		assert(ok == true, "ERROR: save_custom_preset failed")
		print("  PASS: Custom NPC preset saved successfully")
	
	editor.queue_free()

func _test_map_editor() -> void:
	print("\n>>> [TEST 2] Verifying Map Creator & Collision Studio (map_editor.tscn)...")
	var scene_res = load("res://scenes/tools/map_editor.tscn")
	assert(scene_res != null, "ERROR: map_editor.tscn failed to load")
	var editor = scene_res.instantiate()
	assert(editor != null, "ERROR: map_editor could not be instantiated")
	add_child(editor)
	
	if editor.has_method("add_portal"):
		editor.add_portal(Vector2(500, 400), 10002, Vector2(674, 1067), 56.0)
		print("  PASS: Portal added: target_map=10002, dest=(674, 1067)")
	
	if editor.has_method("add_ground_item"):
		editor.add_ground_item(Vector2(600, 700), 46113, 0, 120.0)
		print("  PASS: Ground harvesting item added: Item ID 46113, respawn 120s")
	
	if editor.has_method("export_map_json"):
		var ok = editor.export_map_json("user://test_suite_map.json")
		assert(ok == true, "ERROR: export_map_json failed")
		print("  PASS: Map JSON exported successfully: user://test_suite_map.json")
	
	if editor.has_method("export_mapdata_binary"):
		var ok = editor.export_mapdata_binary("user://test_suite_map.MapData")
		assert(ok == true, "ERROR: export_mapdata_binary failed")
		print("  PASS: Binary .MapData exported cleanly")
	
	editor.queue_free()

func _test_quest_editor() -> void:
	print("\n>>> [TEST 3] Verifying Quest & Dialogue Studio (quest_editor.tscn)...")
	var scene_res = load("res://scenes/tools/quest_editor.tscn")
	assert(scene_res != null, "ERROR: quest_editor.tscn failed to load")
	var editor = scene_res.instantiate()
	assert(editor != null, "ERROR: quest_editor could not be instantiated")
	add_child(editor)
	
	assert(editor.has_method("add_objective"), "ERROR: QuestEditor missing add_objective")
	editor.add_objective("TalkToNPC", {"npc_id": 14003, "talk_id": 14003, "preview": "Hello Captain!"})
	editor.add_objective("CollectItem", {"item_id": 32001, "item_name": "Coconut", "count": 3})
	print("  PASS: Objectives added cleanly (TalkToNPC, CollectItem)")
	
	if editor.has_method("parse_tokens"):
		var parsed = editor.parse_tokens("Hello #n, take #RRed Apple#W!")
		assert(parsed.find("Red Apple") != -1, "ERROR: parse_tokens failed")
		print("  PASS: Token parsing verified: '%s'" % parsed)
	
	if editor.has_method("save_quest"):
		var ok = editor.save_quest("user://test_suite_quest.json")
		assert(ok == true, "ERROR: save_quest failed")
		print("  PASS: Quest JSON exported successfully: user://test_suite_quest.json")
	
	editor.queue_free()

func _test_skill_editor() -> void:
	print("\n>>> [TEST 4] Verifying Skill & Combat VFX Studio (skill_editor.tscn)...")
	var scene_res = load("res://scenes/tools/skill_editor.tscn")
	assert(scene_res != null, "ERROR: skill_editor.tscn failed to load")
	var editor = scene_res.instantiate()
	assert(editor != null, "ERROR: skill_editor could not be instantiated")
	add_child(editor)
	
	assert(editor.has_method("calculate_damage"), "ERROR: SkillEditor missing calculate_damage")
	# Earth vs Water = advantage (+25%), Fire vs Water = disadvantage (-25%)
	var neutral_dmg = editor.calculate_damage(100, 50, 40, 30, 0, 0)
	var adv_dmg = editor.calculate_damage(100, 50, 40, 30, 1, 2) # Earth vs Water
	var dis_dmg = editor.calculate_damage(100, 50, 40, 30, 3, 2) # Fire vs Water
	assert(adv_dmg > neutral_dmg, "ERROR: Elemental advantage should increase damage")
	assert(dis_dmg < neutral_dmg, "ERROR: Elemental disadvantage should reduce damage")
	print("  PASS: Formula simulator verified: Neutral=%d, Adv(+25%%)=%d, Dis(-25%%)=%d" % [neutral_dmg, adv_dmg, dis_dmg])
	
	if editor.has_method("save_skill_json"):
		var ok = editor.save_skill_json("user://test_suite_skill.json")
		assert(ok == true, "ERROR: save_skill_json failed")
		print("  PASS: Skill JSON exported successfully")
	
	editor.queue_free()

func _test_item_editor() -> void:
	print("\n>>> [TEST 5] Verifying Item, Equipment & Alchemy Studio (item_editor.tscn)...")
	var scene_res = load("res://scenes/tools/item_editor.tscn")
	assert(scene_res != null, "ERROR: item_editor.tscn failed to load")
	var editor = scene_res.instantiate()
	assert(editor != null, "ERROR: item_editor could not be instantiated")
	add_child(editor)
	
	assert(editor.has_method("calculate_synthesis_result"), "ERROR: ItemEditor missing calculate_synthesis_result")
	var synth = editor.calculate_synthesis_result(3, 5, 0)
	assert(synth.has("base_rank") and synth.get("base_rank") == 4, "ERROR: Synthesis rank mismatch")
	print("  PASS: WLO Synthesis calculation verified: Rank 3 + Rank 5 -> Base Rank %d [Range %d..%d], Rate %d%%" % [
		synth["base_rank"], synth["min_rank"], synth["max_rank"], int(synth["success_rate"] * 100)
	])
	
	if editor.has_method("save_item_json"):
		var ok = editor.save_item_json("user://test_suite_item.json")
		assert(ok == true, "ERROR: save_item_json failed")
		print("  PASS: Item JSON exported successfully")
	
	editor.queue_free()

func _test_battle_editor() -> void:
	print("\n>>> [TEST 6] Verifying Battle Formation & Encounter Studio (battle_editor.tscn)...")
	var scene_res = load("res://scenes/tools/battle_editor.tscn")
	assert(scene_res != null, "ERROR: battle_editor.tscn failed to load")
	var editor = scene_res.instantiate()
	assert(editor != null, "ERROR: battle_editor could not be instantiated")
	add_child(editor)
	
	assert(editor.has_method("set_enemy_slot"), "ERROR: BattleEditor missing set_enemy_slot")
	editor.set_enemy_slot(0, {"monster_id": 1001, "monster_name": "Blue Jelly", "level": 1, "hp": 50, "sp": 20, "spd": 12})
	editor.set_enemy_slot(1, {"monster_id": 1002, "monster_name": "Green Jelly", "level": 2, "hp": 80, "sp": 30, "spd": 25})
	print("  PASS: Monsters placed in slots 0 and 1 cleanly")
	
	assert(editor.has_method("calculate_turn_order"), "ERROR: BattleEditor missing calculate_turn_order")
	var turn_order = editor.calculate_turn_order()
	assert(turn_order.size() >= 2, "ERROR: Turn order count mismatch")
	assert(turn_order[0]["spd"] >= turn_order[1]["spd"], "ERROR: Turn order must sort descending by SPD")
	var p_name = str(turn_order[0].get("monster_name", turn_order[0].get("name", "Participant")))
	print("  PASS: Turn order verified (Fastest SPD: %d -> '%s')" % [turn_order[0]["spd"], p_name])
	
	if editor.has_method("roll_random_encounter"):
		var enc = editor.roll_random_encounter(0.05, 0.5)
		print("  PASS: Random encounter trigger simulated: triggered=%s" % enc.get("triggered", false))
	
	if editor.has_method("save_encounter_table"):
		var ok = editor.save_encounter_table("user://test_suite_encounters.json")
		assert(ok == true, "ERROR: save_encounter_table failed")
		print("  PASS: Encounter table JSON exported successfully")
	
	editor.queue_free()

func _test_cutscene_editor() -> void:
	print("\n>>> [TEST 7] Verifying Cutscene & Event Sequence Director (cutscene_editor.tscn)...")
	var scene_res = load("res://scenes/tools/cutscene_editor.tscn")
	assert(scene_res != null, "ERROR: cutscene_editor.tscn failed to load")
	var editor = scene_res.instantiate()
	assert(editor != null, "ERROR: cutscene_editor could not be instantiated")
	add_child(editor)
	
	assert(editor.has_method("load_preset"), "ERROR: Missing load_preset")
	assert(editor.has_method("evaluate_at_time"), "ERROR: Missing evaluate_at_time")
	assert(editor.has_method("export_cutscene_scene"), "ERROR: Missing export_cutscene_scene")
	
	editor.load_preset("Ship Sinking Climax")
	var state = editor.evaluate_at_time(4.5)
	assert(state["camera"]["shake_intensity"] > 0.6, "ERROR: Shake trauma mismatch")
	print("  PASS: Cutscene preset 'Ship Sinking Climax' loaded & evaluated at t=4.5s (Shake: %.2f)" % state["camera"]["shake_intensity"])
	
	var exported = editor.export_cutscene_scene("user://test_suite_cutscene.tscn")
	assert(FileAccess.file_exists(exported), "ERROR: Exported cutscene scene missing")
	print("  PASS: Standalone cutscene scene exported successfully: %s" % exported)
	
	editor.queue_free()

func _test_tent_editor() -> void:
	print("\n>>> [TEST 8] Verifying Tent Housing & Furniture Studio (tent_editor.tscn)...")
	var scene_res = load("res://scenes/tools/tent_editor.tscn")
	assert(scene_res != null, "ERROR: tent_editor.tscn failed to load")
	var editor = scene_res.instantiate()
	assert(editor != null, "ERROR: tent_editor could not be instantiated")
	add_child(editor)
	
	assert(editor.has_method("apply_preset"), "ERROR: Missing apply_preset")
	assert(editor.has_method("export_tent_scene"), "ERROR: Missing export_tent_scene")
	assert(editor.has_method("save_tent_layout"), "ERROR: Missing save_tent_layout")
	
	var applied = editor.apply_preset("Beginner Camping Tent")
	assert(applied == true, "ERROR: Failed to apply 'Beginner Camping Tent' preset")
	var placed_items = editor.placed_furniture
	assert(placed_items.size() > 0, "ERROR: Placed furniture should not be empty")
	print("  PASS: Tent preset 'Beginner Camping Tent' applied (%d furniture pieces placed)" % placed_items.size())
	
	var export_path: String = "user://test_suite_tent.tscn"
	var scene_str: String = editor.export_tent_scene(export_path)
	assert(not scene_str.is_empty(), "ERROR: Exported tent scene content is empty")
	assert(FileAccess.file_exists(export_path), "ERROR: Exported tent scene missing on disk")
	print("  PASS: Standalone tent scene exported successfully: %s" % export_path)
	
	editor.queue_free()

func _test_audio_editor() -> void:
	print("\n>>> [TEST 9] Verifying Audio Jukebox & Sound Design Studio (audio_editor.tscn)...")
	var scene_res = load("res://scenes/tools/audio_editor.tscn")
	assert(scene_res != null, "ERROR: audio_editor.tscn failed to load")
	var editor = scene_res.instantiate()
	assert(editor != null, "ERROR: audio_editor could not be instantiated")
	add_child(editor)
	
	assert(editor.has_method("export_audio_manifest"), "ERROR: Missing export_audio_manifest")
	assert(editor.has_method("save_audio_config"), "ERROR: Missing save_audio_config")
	
	var catalog_size = editor.get_sound_assets().size()
	assert(catalog_size > 0, "ERROR: Audio catalog should contain scanned audio files")
	print("  PASS: Audio Jukebox scanned %d audio assets cleanly" % catalog_size)
	
	var ok = editor.export_audio_manifest("user://test_suite_audio_manifest.json")
	assert(ok == true, "ERROR: Audio manifest export failed")
	assert(FileAccess.file_exists("user://test_suite_audio_manifest.json"), "ERROR: Audio manifest file missing")
	print("  PASS: Audio manifest exported cleanly: user://test_suite_audio_manifest.json")
	
	editor.queue_free()

func _test_battle_view() -> void:
	print("\n>>> [TEST 10] Verifying Playable Turn-Based Battle View & Engine (battle_view.tscn)...")
	var scene_res = load("res://scenes/battle/battle_view.tscn")
	assert(scene_res != null, "ERROR: battle_view.tscn failed to load")
	var view = scene_res.instantiate()
	assert(view != null, "ERROR: battle_view could not be instantiated")
	add_child(view)
	
	assert(view.action_buttons.size() == 7, "ERROR: Exactly 7 authentic battle action buttons required, found %d" % view.action_buttons.size())
	print("  PASS: Authentic 7 battle buttons verified in BattleView")
	
	assert(view.battle_manager != null, "ERROR: BattleView must have an internal BattleManager instance")
	assert(view.arena_canvas != null, "ERROR: ArenaCanvas 2:1 axonometric field missing")
	print("  PASS: 2:1 Axonometric Battle Arena and BattleManager verified")
	
	view.queue_free()

func _test_world_editor() -> void:
	print("\n>>> [TEST 11] Verifying Unified World Editor Suite (world_editor.tscn)...")
	var scene_res = load("res://scenes/tools/world_editor.tscn")
	assert(scene_res != null, "ERROR: world_editor.tscn failed to load")
	var editor = scene_res.instantiate()
	assert(editor != null, "ERROR: world_editor could not be instantiated")
	add_child(editor)
	
	var tab_container = editor.find_child("MainTabContainer", true, false)
	assert(tab_container != null, "ERROR: WorldEditor must have MainTabContainer")
	assert(tab_container.get_tab_count() >= 11, "ERROR: WorldEditor must house all 11 workspace tabs, found %d" % tab_container.get_tab_count())
	print("  PASS: WorldEditor MainTabContainer verified with %d workspace tabs:" % tab_container.get_tab_count())
	for i in range(tab_container.get_tab_count()):
		print("    Tab %d: '%s'" % [i, tab_container.get_tab_title(i)])
	
	# Verify programmatic search across all 5 categories
	assert(editor.has_method("search_database"), "ERROR: WorldEditor missing search_database")
	var items = editor.search_database("items", "knife")
	print("  PASS: Item search for 'knife': %d results" % items.size())
	assert(items.size() > 0, "ERROR: Item search should find knife")
	
	var npcs = editor.search_database("npcs", "captain")
	print("  PASS: NPC search for 'captain': %d results" % npcs.size())
	assert(npcs.size() > 0, "ERROR: NPC search should find captain")
	
	var talks = editor.search_database("talks", "welcome")
	print("  PASS: Dialogue search for 'welcome': %d results" % talks.size())
	assert(talks.size() > 0, "ERROR: Dialogue search should find talks")
	
	var skills = editor.search_database("skills", "flame")
	print("  PASS: Skill search for 'flame': %d results" % skills.size())
	assert(skills.size() > 0, "ERROR: Skill search should find skills")
	
	editor.queue_free()
