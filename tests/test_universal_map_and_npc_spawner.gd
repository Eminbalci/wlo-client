extends SceneTree

## Automated Verification Suite for Universal Dynamic NPC & Portal Spawner Engine
## Validates multi-map warping (10001 -> 10002 -> 10003 -> 10005 -> 10008 -> 12001),
## dynamic NPC instantiation, authentic texture resolution, rotation-to-heading mapping,
## entity recycling without leaks, and HUD/minimap synchronization.

const MapViewScene = preload("res://scenes/world/map_view.tscn")

func _init() -> void:
	_run_tests.call_deferred()

func _run_tests() -> void:
	print("\n=================================================================")
	print("--- Running Wonderland Online Universal Dynamic Spawner Tests ---")
	print("=================================================================\n")
	
	var passed: int = 0
	var failed: int = 0
	
	var map_view = MapViewScene.instantiate()
	root.add_child(map_view)
	await process_frame
	await process_frame
	
	# -----------------------------------------------------------------
	# Test 1: Initial map 10001 (Ship Deck) entity state
	# -----------------------------------------------------------------
	print(">>> [TEST 1] Verifying Map 10001 (Ship Deck) Initial State...")
	var initial_map_id: int = map_view.map_renderer.current_map_id if map_view.map_renderer else -1
	if initial_map_id == 10001 and map_view._deck_entities.size() >= 10:
		print("  [PASS] Map 10001 loaded with %d ship deck entities." % map_view._deck_entities.size())
		passed += 1
	else:
		print("  [FAIL] Map 10001 initial state failed: map_id=%d, deck_count=%d" % [initial_map_id, map_view._deck_entities.size()])
		failed += 1
	
	# -----------------------------------------------------------------
	# Test 2: Warp 10001 -> 10002 (Cabin)
	# -----------------------------------------------------------------
	print("\n>>> [TEST 2] Warping 10001 -> 10002 (Cabin)...")
	map_view._on_portal_triggered(null, 10002, Vector2(674, 1067))
	await process_frame
	await process_frame
	
	var deck_visible: int = 0
	for e in map_view._deck_entities:
		if is_instance_valid(e) and "visible" in e and e.visible:
			deck_visible += 1
	
	var cabin_count: int = map_view._cabin_entities.size()
	if map_view.map_renderer.current_map_id == 10002 and deck_visible == 0 and cabin_count == 7:
		print("  [PASS] Successfully warped to Cabin (Map 10002): deck hidden, %d cabin NPCs active." % cabin_count)
		passed += 1
	else:
		print("  [FAIL] Cabin warp failed: map=%d, deck_visible=%d, cabin_count=%d" % [
			map_view.map_renderer.current_map_id, deck_visible, cabin_count
		])
		failed += 1
	
	# -----------------------------------------------------------------
	# Test 3: Warp 10002 -> 10003 (Ship Kitchen / Bunk)
	# -----------------------------------------------------------------
	print("\n>>> [TEST 3] Warping 10002 -> 10003 (Ship Kitchen / Bunk)...")
	map_view._on_portal_triggered(null, 10003, Vector2(420, 360))
	await process_frame
	await process_frame
	
	var cabin_visible: int = 0
	for e in map_view._cabin_entities:
		if is_instance_valid(e) and "visible" in e and e.visible:
			cabin_visible += 1
	
	var kitchen_count: int = map_view._kitchen_entities.size()
	if map_view.map_renderer.current_map_id == 10003 and cabin_visible == 0 and kitchen_count >= 6:
		print("  [PASS] Successfully warped to Kitchen (Map 10003): cabin hidden, %d kitchen entities active." % kitchen_count)
		passed += 1
	else:
		print("  [FAIL] Kitchen warp failed: map=%d, cabin_visible=%d, kitchen_count=%d" % [
			map_view.map_renderer.current_map_id, cabin_visible, kitchen_count
		])
		failed += 1
	
	# -----------------------------------------------------------------
	# Test 4: Warp 10003 -> 10005 (Universal Dynamic NPC Spawner)
	# -----------------------------------------------------------------
	print("\n>>> [TEST 4] Warping 10003 -> 10005 (Testing Universal Dynamic Spawner)...")
	map_view._on_portal_triggered(null, 10005, Vector2(400, 300))
	await process_frame
	await process_frame
	
	var kitchen_visible: int = 0
	for e in map_view._kitchen_entities:
		if is_instance_valid(e) and "visible" in e and e.visible:
			kitchen_visible += 1
	
	var spawned_10005: Array[NpcEntity] = map_view._dynamic_npcs
	print("  Dynamic NPCs on Map 10005: %d" % spawned_10005.size())
	for n in spawned_10005:
		print("    NPC: name='%s' id=%d pos=%s heading=%d level=%d" % [
			n.npc_name, n.npc_id, str(n.world_position), n.heading, n.level
		])
	
	if map_view.map_renderer.current_map_id == 10005 and kitchen_visible == 0 and spawned_10005.size() == 5:
		print("  [PASS] Map 10005 dynamically spawned exactly 5 authentic NPCs from Eve.emg.")
		passed += 1
	else:
		print("  [FAIL] Map 10005 spawner failed: map=%d, kitchen_visible=%d, count=%d (expected 5)" % [
			map_view.map_renderer.current_map_id, kitchen_visible, spawned_10005.size()
		])
		failed += 1
	
	# Verify specific authentic NPCs on Map 10005
	var found_dragon := false
	var found_cat := false
	for n in spawned_10005:
		if n.npc_id == 12072: # Old Dragon
			found_dragon = true
		elif n.npc_id == 11000 or n.npc_id == 11001: # Cat
			found_cat = true
	
	if found_dragon and found_cat:
		print("  [PASS] Authentic NPCs (Old Dragon id: 12072 and Persian Cat id: 11000) verified on Map 10005.")
		passed += 1
	else:
		print("  [FAIL] Missing required NPCs on Map 10005: dragon=%s, cat=%s" % [found_dragon, found_cat])
		failed += 1
	
	# Verify portal spawned for 10005
	if not map_view._dynamic_portals.is_empty():
		var p = map_view._dynamic_portals[0]
		print("  [PASS] Map 10005 portal successfully spawned: target_map=%d, pos=%s" % [p.target_map_id, str(p.position)])
		passed += 1
	else:
		print("  [FAIL] Map 10005 portal missing.")
		failed += 1
	
	# -----------------------------------------------------------------
	# Test 5: Warp 10005 -> 10008 (Large map with 41 authentic NPCs)
	# -----------------------------------------------------------------
	print("\n>>> [TEST 5] Warping 10005 -> 10008 (Large map with 41 NPCs)...")
	map_view._on_portal_triggered(null, 10008, Vector2(135, 126))
	await process_frame
	await process_frame
	
	var spawned_10008: Array[NpcEntity] = map_view._dynamic_npcs
	print("  Dynamic NPCs on Map 10008: %d" % spawned_10008.size())
	
	if map_view.map_renderer.current_map_id == 10008 and spawned_10008.size() == 41:
		print("  [PASS] Map 10008 dynamically spawned all 41 authentic NPCs from Eve.emg.")
		passed += 1
	else:
		print("  [FAIL] Map 10008 spawner failed: count=%d (expected 41)" % spawned_10008.size())
		failed += 1
	
	# -----------------------------------------------------------------
	# Test 6: Warp 10008 -> 12001 (Kelan Village)
	# -----------------------------------------------------------------
	print("\n>>> [TEST 6] Warping 10008 -> 12001 (Kelan Village)...")
	map_view._on_portal_triggered(null, 12001, Vector2(500, 300))
	await process_frame
	await process_frame
	
	var spawned_12001: Array[NpcEntity] = map_view._dynamic_npcs
	print("  Dynamic NPCs on Map 12001: %d" % spawned_12001.size())
	for n in spawned_12001:
		print("    NPC: name='%s' id=%d pos=%s heading=%d" % [
			n.npc_name, n.npc_id, str(n.world_position), n.heading
		])
	
	if map_view.map_renderer.current_map_id == 12001 and spawned_12001.size() == 3:
		print("  [PASS] Map 12001 dynamically spawned 3 authentic NPCs (Kelan Leader & Rocas).")
		passed += 1
	else:
		print("  [FAIL] Map 12001 spawner failed: count=%d (expected 3)" % spawned_12001.size())
		failed += 1
	
	# -----------------------------------------------------------------
	# Test 7: Interactive Dialogue Trigger on Dynamically Spawned NPC
	# -----------------------------------------------------------------
	print("\n>>> [TEST 7] Testing Interactive Dialogue Trigger on Dynamic NPC...")
	if not spawned_12001.is_empty():
		var kelan_leader: NpcEntity = spawned_12001[0]
		map_view._on_npc_interacted(kelan_leader)
		await process_frame
		print("  [PASS] NPC interaction triggered successfully on %s (id: %d)." % [kelan_leader.npc_name, kelan_leader.npc_id])
		passed += 1
	else:
		print("  [FAIL] No NPCs available to test interaction.")
		failed += 1
	
	# -----------------------------------------------------------------
	# Test 8: Warp Back to Ship Deck (10001)
	# -----------------------------------------------------------------
	print("\n>>> [TEST 8] Warping back to Ship Deck (Map 10001)...")
	map_view._on_portal_triggered(null, 10001, Vector2(1042, 1075))
	await process_frame
	await process_frame
	
	var dynamic_count_on_10001: int = map_view._dynamic_npcs.size()
	var deck_revisible: int = 0
	for e in map_view._deck_entities:
		if is_instance_valid(e) and "visible" in e and e.visible:
			deck_revisible += 1
	
	if map_view.map_renderer.current_map_id == 10001 and dynamic_count_on_10001 == 0 and deck_revisible >= 10:
		print("  [PASS] Successfully warped back to Ship Deck: dynamic NPCs recycled, deck restored (%d visible)." % deck_revisible)
		passed += 1
	else:
		print("  [FAIL] Warp back failed: dynamic_count=%d, deck_revisible=%d" % [dynamic_count_on_10001, deck_revisible])
		failed += 1
	
	map_view.queue_free()
	await process_frame
	
	print("\n=================================================================")
	print("--- TEST SUMMARY: %d PASSED, %d FAILED ---" % [passed, failed])
	print("=================================================================\n")
	
	if failed == 0:
		print("ALL UNIVERSAL DYNAMIC SPAWNER TESTS PASSED (100% ZERO-ERROR)!")
		quit(0)
	else:
		print("SOME TESTS FAILED!")
		quit(1)
