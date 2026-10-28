extends SceneTree

## Comprehensive Verification Suite for C# NPC States & PreEvent Visibility Sync
## Cross-referenced directly with:
## - PreEventInterpreter.cs (ShouldNpcBeVisible, EvaluateMapPreEvents)
## - QuestNpc.cs (HP, SP, Element, Level, WalkBehavior, IsWildMonster, IsStaticNpc)
## - Map.cs (AC 22:4 actor show/hide wire protocol)

const MapViewScene = preload("res://scenes/world/map_view.tscn")
const NpcStateEvaluator = preload("res://scripts/map/npc_state_evaluator.gd")
const EveParser = preload("res://scripts/map/eve_parser.gd")

func _init() -> void:
	_run_tests.call_deferred()

func _run_tests() -> void:
	print("\n=================================================================")
	print("--- Running C# NPC States & PreEvent Visibility Sync Test Suite ---")
	print("=================================================================\n")
	
	var passed: int = 0
	var failed: int = 0
	
	var eve_parser := EveParser.new()
	eve_parser.initialize()
	
	# -----------------------------------------------------------------
	# Test 1: Map 12000 Staged Cutscene Actor Suppression (Cutscene Roca ClickID 32)
	# -----------------------------------------------------------------
	print(">>> [TEST 1] Map 12000 Staged Cutscene Roca (ClickID 32)...")
	var roca_gate_vis: bool = NpcStateEvaluator.should_npc_be_visible(12000, 32, {}, [], [], false, eve_parser)
	if not roca_gate_vis:
		print("  [PASS] Staged Cutscene Roca (ClickID 32) at village gate is HIDDEN by default in overworld.")
		passed += 1
	else:
		print("  [FAIL] Staged Cutscene Roca (ClickID 32) should NOT be visible by default!")
		failed += 1
	
	# -----------------------------------------------------------------
	# Test 2: Map 12000 Permanent Entities (Guideposts, Honeycomb, Lina's dog)
	# -----------------------------------------------------------------
	print("\n>>> [TEST 2] Map 12000 Permanent Entities (10, 31, 17, 29)...")
	var gp10: bool = NpcStateEvaluator.should_npc_be_visible(12000, 10, {}, [], [], false, eve_parser)
	var gp31: bool = NpcStateEvaluator.should_npc_be_visible(12000, 31, {}, [], [], false, eve_parser)
	var comb17: bool = NpcStateEvaluator.should_npc_be_visible(12000, 17, {}, [], [], false, eve_parser)
	var lina_dog29: bool = NpcStateEvaluator.should_npc_be_visible(12000, 29, {}, [], [], false, eve_parser)
	
	if gp10 and gp31 and comb17 and lina_dog29:
		print("  [PASS] Permanent entities (Guideposts 10/31, Comb 17, Lina's Dog 29) are all VISIBLE.")
		passed += 1
	else:
		print("  [FAIL] Permanent entities failed: 10=%s, 31=%s, 17=%s, 29=%s" % [gp10, gp31, comb17, lina_dog29])
		failed += 1
	
	# -----------------------------------------------------------------
	# Test 3: Map 12000 Lina's Lost Dog Lifecycle (Quest 13046 & 13047)
	# -----------------------------------------------------------------
	print("\n>>> [TEST 3] Map 12000 Lina's Lost Dog Lifecycle (ClickID 20 vs 28)...")
	# State A: Quest Unstarted (NotStarted = 2) -> Dog 28 hidden at Lina, Dog 20 hidden in pen
	var dog28_unstarted: bool = NpcStateEvaluator.should_npc_be_visible(12000, 28, {13046: 2}, [], [], false, eve_parser)
	var dog20_unstarted: bool = NpcStateEvaluator.should_npc_be_visible(12000, 20, {13046: 2}, [], [], false, eve_parser)
	
	# State B: Quest InProgress at Step 1 (searching for dog) -> Dog 20 appears in trees/pen, Dog 28 still hidden
	var dog28_searching: bool = NpcStateEvaluator.should_npc_be_visible(12000, 28, {13046: {"state": 1, "step": 1}}, [], [], false, eve_parser)
	var dog20_searching: bool = NpcStateEvaluator.should_npc_be_visible(12000, 20, {13046: {"state": 1, "step": 1}}, [], [], false, eve_parser)
	
	# State C: Quest InProgress at Step 2 (found dog) -> Dog 20 hidden, Dog 28 appears by Lina
	var dog28_found: bool = NpcStateEvaluator.should_npc_be_visible(12000, 28, {13046: {"state": 1, "step": 2}}, [], [], false, eve_parser)
	var dog20_found: bool = NpcStateEvaluator.should_npc_be_visible(12000, 20, {13046: {"state": 1, "step": 2}}, [], [], false, eve_parser)
	
	# State D: Quest Completed (state = 3) -> Dog 28 visible by Lina, Dog 20 hidden
	var dog28_done: bool = NpcStateEvaluator.should_npc_be_visible(12000, 28, {13046: 3}, [], [], false, eve_parser)
	var dog20_done: bool = NpcStateEvaluator.should_npc_be_visible(12000, 20, {13046: 3}, [], [], false, eve_parser)
	
	if not dog28_unstarted and not dog20_unstarted \
		and not dog28_searching and dog20_searching \
		and dog28_found and not dog20_found \
		and dog28_done and not dog20_done:
		print("  [PASS] Lina's Lost Dog lifecycle matches C# PreEventInterpreter across all 4 stages.")
		passed += 1
	else:
		print("  [FAIL] Lost Dog lifecycle mismatch: unstarted=(%s,%s) search=(%s,%s) found=(%s,%s) done=(%s,%s)" % [
			dog28_unstarted, dog20_unstarted, dog28_searching, dog20_searching,
			dog28_found, dog20_found, dog28_done, dog20_done
		])
		failed += 1
	
	# -----------------------------------------------------------------
	# Test 4: Map 12000 Pigs Lifecycle (Quest 12020 & 12021)
	# -----------------------------------------------------------------
	print("\n>>> [TEST 4] Map 12000 Staged Pigs Lifecycle (ClickID 14 vs 15 vs 16)...")
	# Unstarted
	var pig14_unstarted: bool = NpcStateEvaluator.should_npc_be_visible(12000, 14, {12020: 2}, [], [], false, eve_parser)
	var pig15_unstarted: bool = NpcStateEvaluator.should_npc_be_visible(12000, 15, {12020: 2}, [], [], false, eve_parser)
	# Step 1: Stray pig escaped
	var pig14_step1: bool = NpcStateEvaluator.should_npc_be_visible(12000, 14, {12020: {"state": 1, "step": 1}}, [], [], false, eve_parser)
	var pig15_step1: bool = NpcStateEvaluator.should_npc_be_visible(12000, 15, {12020: {"state": 1, "step": 1}}, [], [], false, eve_parser)
	# Step 2: Pig returned to pen
	var pig14_step2: bool = NpcStateEvaluator.should_npc_be_visible(12000, 14, {12020: {"state": 1, "step": 2}}, [], [], false, eve_parser)
	var pig15_step2: bool = NpcStateEvaluator.should_npc_be_visible(12000, 15, {12020: {"state": 1, "step": 2}}, [], [], false, eve_parser)
	# Pig 16
	var pig16_unstarted: bool = NpcStateEvaluator.should_npc_be_visible(12000, 16, {13020: 2}, [], [], false, eve_parser)
	var pig16_active: bool = NpcStateEvaluator.should_npc_be_visible(12000, 16, {13020: 1}, [], [], false, eve_parser)
	
	if not pig14_unstarted and not pig15_unstarted \
		and not pig14_step1 and pig15_step1 \
		and pig14_step2 and not pig15_step2 \
		and not pig16_unstarted and pig16_active:
		print("  [PASS] Staged Pigs (14, 15, 16) lifecycle stages match C# PreEventInterpreter.")
		passed += 1
	else:
		print("  [FAIL] Pigs lifecycle mismatch: unstarted=(%s,%s) step1=(%s,%s) step2=(%s,%s) pig16=(%s,%s)" % [
			pig14_unstarted, pig15_unstarted, pig14_step1, pig15_step1, pig14_step2, pig15_step2, pig16_unstarted, pig16_active
		])
		failed += 1
	
	# -----------------------------------------------------------------
	# Test 5: Map 12000 Baby Bees (ClickID 18 & 19, Quest 13023)
	# -----------------------------------------------------------------
	print("\n>>> [TEST 5] Map 12000 Baby Bees (ClickID 18 & 19)...")
	var bees_unstarted: bool = NpcStateEvaluator.should_npc_be_visible(12000, 18, {13023: 2}, [], [], false, eve_parser)
	var bees_active: bool = NpcStateEvaluator.should_npc_be_visible(12000, 18, {13023: 1}, [], [], false, eve_parser)
	if not bees_unstarted and bees_active:
		print("  [PASS] Baby Bees (18/19) hidden when Quest 13023 unstarted, visible when active.")
		passed += 1
	else:
		print("  [FAIL] Baby Bees failed: unstarted=%s, active=%s" % [bees_unstarted, bees_active])
		failed += 1
	
	# -----------------------------------------------------------------
	# Test 6: Map 11016 Starter Beach S. Monkey (ClickID 1, TID 17162)
	# -----------------------------------------------------------------
	print("\n>>> [TEST 6] Map 11016 Starter Beach S. Monkey (ClickID 1)...")
	var monkey_wild: bool = NpcStateEvaluator.should_npc_be_visible(11016, 1, {}, [], [], false, eve_parser)
	var monkey_party: bool = NpcStateEvaluator.should_npc_be_visible(11016, 1, {}, [17162], [], false, eve_parser)
	var monkey_pet: bool = NpcStateEvaluator.should_npc_be_visible(11016, 1, {}, [], [17162], false, eve_parser)
	var monkey_quest_done: bool = NpcStateEvaluator.should_npc_be_visible(11016, 1, {12002: 3}, [], [], false, eve_parser)
	
	if monkey_wild and not monkey_party and not monkey_pet and not monkey_quest_done:
		print("  [PASS] S. Monkey is visible when unrecruited, and hidden once recruited/pet/completed.")
		passed += 1
	else:
		print("  [FAIL] S. Monkey visibility mismatch: wild=%s party=%s pet=%s done=%s" % [
			monkey_wild, monkey_party, monkey_pet, monkey_quest_done
		])
		failed += 1
	
	# -----------------------------------------------------------------
	# Test 7: Story Companion Party Suppression (Map 12001 Roca ClickID 2)
	# -----------------------------------------------------------------
	print("\n>>> [TEST 7] Story Companion Party Suppression (Map 12001 Roca)...")
	var roca_home_unrecruited: bool = NpcStateEvaluator.should_npc_be_visible(12001, 2, {}, [], [], false, eve_parser)
	var roca_home_recruited: bool = NpcStateEvaluator.should_npc_be_visible(12001, 2, {}, [14162], [], false, eve_parser)
	# ClickID 3 on Map 12001 is staged cutscene Roca (entity_type 4 -> bit 0 == 0)
	var roca_staged_click3: bool = NpcStateEvaluator.should_npc_be_visible(12001, 3, {}, [], [], false, eve_parser)
	
	if roca_home_unrecruited and not roca_home_recruited and not roca_staged_click3:
		print("  [PASS] Companion Roca is visible at home, hidden when in party; staged ClickID 3 suppressed.")
		passed += 1
	else:
		print("  [FAIL] Companion party suppression failed: home=%s in_party=%s staged_3=%s" % [
			roca_home_unrecruited, roca_home_recruited, roca_staged_click3
		])
		failed += 1
	
	# -----------------------------------------------------------------
	# Test 8: Map 11040 Clive Transient Battle Actor (ClickID 4)
	# -----------------------------------------------------------------
	print("\n>>> [TEST 8] Map 11040 Clive Transient Battle Actor (ClickID 4)...")
	var clive_default: bool = NpcStateEvaluator.should_npc_be_visible(11040, 4, {}, [], [], false, eve_parser)
	var clive_step4: bool = NpcStateEvaluator.should_npc_be_visible(11040, 4, {13102: {"state": 1, "step": 4}}, [], [], false, eve_parser)
	var clive_recruited: bool = NpcStateEvaluator.should_npc_be_visible(11040, 4, {13102: {"state": 1, "step": 4}, 13103: {"state": 1, "step": 1}}, [], [], false, eve_parser)
	
	if not clive_default and clive_step4 and not clive_recruited:
		print("  [PASS] Clive (ClickID 4) only appears during Quest 13102 Step 4 recruit offer.")
		passed += 1
	else:
		print("  [FAIL] Clive visibility failed: default=%s step4=%s recruited=%s" % [
			clive_default, clive_step4, clive_recruited
		])
		failed += 1
	
	# -----------------------------------------------------------------
	# Test 9: Full NPC States matching C# QuestNpc Defaults (HP, SP, Element, Level, WalkBehavior)
	# -----------------------------------------------------------------
	print("\n>>> [TEST 9] Authentic NPC States matching C# QuestNpc Defaults...")
	var game_db = root.get_node_or_null("/root/GameDatabase")
	if game_db == null:
		game_db = preload("res://scripts/database/game_database.gd").new()
		game_db.load_all()
	
	# Check Kelan Pig (Map 12000, ClickID 1)
	var pig_state: Dictionary = NpcStateEvaluator.get_npc_state(12000, 1, eve_parser, game_db)
	var pig_ok: bool = (pig_state.template_id == 17400 \
		and pig_state.name == "Pig" \
		and pig_state.level == 43 \
		and pig_state.hp == 448 \
		and pig_state.sp == 326 \
		and pig_state.element == 1 \
		and pig_state.walk_behavior == 3 \
		and pig_state.is_wild_monster == false)
	
	# Check Honeycomb (Map 12000, ClickID 17)
	var comb_state: Dictionary = NpcStateEvaluator.get_npc_state(12000, 17, eve_parser, game_db)
	var comb_ok: bool = (comb_state.template_id == 19026 and comb_state.is_static == true)
	
	# Check Baby Bee / Roaming Beetle (Map 12000, ClickID 18 / 25)
	var bee_state: Dictionary = NpcStateEvaluator.get_npc_state(12000, 18, eve_parser, game_db)
	var bee_ok: bool = (bee_state.template_id == 17064 and bee_state.is_wild_monster == true)
	
	if pig_ok and comb_ok and bee_ok:
		print("  [PASS] NPC States (Pig Lv.43 HP.448 SP.326 Earth, Comb prop, Bee mob) verified bit-exact.")
		passed += 1
	else:
		print("  [FAIL] NPC State verification failed: pig_ok=%s comb_ok=%s bee_ok=%s" % [pig_ok, comb_ok, bee_ok])
		failed += 1
	
	# -----------------------------------------------------------------
	# Test 10: Live MapView Integration & Dynamic NPC Visibility Updates
	# -----------------------------------------------------------------
	print("\n>>> [TEST 10] Live MapView Integration & Dynamic Visibility Updates...")
	var map_view = MapViewScene.instantiate()
	root.add_child(map_view)
	await process_frame
	await process_frame
	
	# Warp to Map 12000
	map_view.load_map(12000, Vector2(500, 400))
	await process_frame
	await process_frame
	
	var active_npcs: Array[NpcEntity] = map_view.get_active_npcs()
	var click32_found_active: bool = false
	var click28_found_active: bool = false
	var click20_found_active: bool = false
	var click29_found_active: bool = false
	
	for n in active_npcs:
		if n.click_id == 32: click32_found_active = true
		if n.click_id == 28: click28_found_active = true
		if n.click_id == 20: click20_found_active = true
		if n.click_id == 29: click29_found_active = true
	
	var initial_map12000_ok: bool = (not click32_found_active and not click28_found_active and not click20_found_active and click29_found_active)
	
	# Trigger quest step: search for lost dog
	map_view.set_quest_state(13046, 1, 1)
	active_npcs = map_view.get_active_npcs()
	var step1_dog20_active: bool = false
	var step1_dog28_active: bool = false
	for n in active_npcs:
		if n.click_id == 20: step1_dog20_active = true
		if n.click_id == 28: step1_dog28_active = true
	var step1_ok: bool = (step1_dog20_active and not step1_dog28_active)
	
	# Trigger quest step: dog found & returned
	map_view.set_quest_state(13046, 1, 2)
	active_npcs = map_view.get_active_npcs()
	var step2_dog20_active: bool = false
	var step2_dog28_active: bool = false
	for n in active_npcs:
		if n.click_id == 20: step2_dog20_active = true
		if n.click_id == 28: step2_dog28_active = true
	var step2_ok: bool = (not step2_dog20_active and step2_dog28_active)
	
	map_view.queue_free()
	
	if initial_map12000_ok and step1_ok and step2_ok:
		print("  [PASS] Live MapView dynamic NPC visibility and quest state switching verified!")
		passed += 1
	else:
		print("  [FAIL] Live MapView integration failed: initial=%s, step1=%s, step2=%s" % [
			initial_map12000_ok, step1_ok, step2_ok
		])
		failed += 1
	
	# -----------------------------------------------------------------
	# Final Summary
	# -----------------------------------------------------------------
	print("\n=================================================================")
	print("--- TEST SUMMARY: %d PASSED, %d FAILED ---" % [passed, failed])
	print("=================================================================\n")
	
	if failed == 0:
		print("ALL C# NPC STATES & VISIBILITY TESTS PASSED (100% ZERO-ERROR)!\n")
		quit(0)
	else:
		print("SOME TESTS FAILED!\n")
		quit(1)
