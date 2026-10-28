extends SceneTree

## Automated Verification Suite for Live Playtest & Simulator Map Teleportation
## Tests:
## 1. opt_sim_map population & connection
## 2. Dynamic map selection updating target map and default spawn coordinates
## 3. Starting playtest with non-default map (10002 Cabin, 10005 Kelan Trail, 12001 Kelan Village)
## 4. Real-time in-simulator teleportation via opt_sim_map and btn_sim_teleport
## 5. NPC and portal synchronization on teleported maps
## 6. Returning to Ship Deck (10001)

func _init() -> void:
	print("\n=======================================================")
	print("--- Running World Editor Simulator Teleport Tests ---")
	print("=======================================================\n")
	_run_tests.call_deferred()

func _run_tests() -> void:
	var passed: int = 0
	var failed: int = 0
	print("[TestSimTeleport] Starting test execution...")
	var scene_res = ResourceLoader.load("res://scenes/tools/world_editor.tscn")
	if not scene_res:
		push_error("Failed to load world_editor.tscn")
		quit(1)
		return
	var editor = scene_res.instantiate()
	if not editor:
		push_error("Failed to instantiate world_editor")
		quit(1)
		return
	root.add_child(editor)
	await process_frame
	await process_frame
	print("[TestSimTeleport] WorldEditor instantiated.")
	
	# -------------------------------------------------------------
	# Test 1: Verify opt_sim_map is populated with all maps
	# -------------------------------------------------------------
	print(">>> [TEST 1] Verifying opt_sim_map dropdown population...")
	var opt_sim_map: OptionButton = editor.opt_sim_map
	assert(opt_sim_map != null, "opt_sim_map must exist")
	print("  opt_sim_map item count: %d" % opt_sim_map.item_count)
	if opt_sim_map.item_count >= 50:
		print("  [PASS] opt_sim_map populated with %d maps." % opt_sim_map.item_count)
		passed += 1
	else:
		print("  [FAIL] opt_sim_map item count too low: %d" % opt_sim_map.item_count)
		failed += 1
	
	# Verify BtnSimTeleport exists
	var btn_teleport: Button = editor.btn_sim_teleport
	if btn_teleport != null:
		print("  [PASS] btn_sim_teleport button node found.")
		passed += 1
	else:
		print("  [FAIL] btn_sim_teleport not found.")
		failed += 1
	
	# -------------------------------------------------------------
	# Test 2: Select map 10002 (Cabin) in opt_sim_map before launching
	# -------------------------------------------------------------
	print("\n>>> [TEST 2] Selecting Map 10002 (Cabin) in opt_sim_map...")
	var cabin_idx := -1
	for i in range(opt_sim_map.item_count):
		if opt_sim_map.get_item_id(i) == 10002:
			cabin_idx = i
			break
	
	assert(cabin_idx >= 0, "Map 10002 must be in opt_sim_map")
	opt_sim_map.selected = cabin_idx
	editor._on_sim_map_selected(cabin_idx)
	await process_frame
	
	print("  active_map_id: %d, spin_sim_x: %d, spin_sim_y: %d" % [
		editor.active_map_id, int(editor.spin_sim_x.value), int(editor.spin_sim_y.value)
	])
	if editor.active_map_id == 10002 and int(editor.spin_sim_x.value) == 674 and int(editor.spin_sim_y.value) == 1067:
		print("  [PASS] Active map synced to 10002 and default spawn coordinates set to (674, 1067).")
		passed += 1
	else:
		print("  [FAIL] Spawn coordinates or active map did not sync properly.")
		failed += 1
	
	# -------------------------------------------------------------
	# Test 3: Launch simulator on Map 10002 and verify MapView loads 10002
	# -------------------------------------------------------------
	print("\n>>> [TEST 3] Launching simulator on Map 10002...")
	editor.start_playtest()
	await process_frame
	await process_frame
	
	var sim_mv = editor._simulator_instance
	assert(sim_mv != null, "Simulator instance must be valid")
	var sim_renderer = sim_mv.map_renderer
	var sim_player = sim_mv.player
	
	print("  sim_renderer current_map_id: %d" % sim_renderer.current_map_id)
	print("  sim_player position: %s" % str(sim_player.world_position if ("world_position" in sim_player) else sim_player.position))
	print("  cabin entities active: %d" % sim_mv._cabin_entities.size())
	
	if sim_renderer.current_map_id == 10002 and sim_mv._cabin_entities.size() >= 5:
		print("  [PASS] Simulator correctly loaded Map 10002 with cabin entities active (NOT stuck on Map 10001).")
		passed += 1
	else:
		print("  [FAIL] Simulator failed to load Map 10002.")
		failed += 1
	
	# -------------------------------------------------------------
	# Test 4: Real-time Teleport from 10002 to 10005 (Kelan Trail) while simulator runs
	# -------------------------------------------------------------
	print("\n>>> [TEST 4] Real-time Teleport to Map 10005 (Kelan Trail)...")
	var trail_idx := -1
	for i in range(opt_sim_map.item_count):
		if opt_sim_map.get_item_id(i) == 10005:
			trail_idx = i
			break
	
	assert(trail_idx >= 0, "Map 10005 must be in opt_sim_map")
	opt_sim_map.selected = trail_idx
	editor._on_sim_map_selected(trail_idx)
	await process_frame
	await process_frame
	
	print("  sim_renderer current_map_id: %d" % sim_renderer.current_map_id)
	print("  sim_mv dynamic NPCs count: %d" % sim_mv._dynamic_npcs.size())
	
	if sim_renderer.current_map_id == 10005 and sim_mv._dynamic_npcs.size() == 5:
		print("  [PASS] Real-time teleport to Map 10005 succeeded: 5 authentic NPCs spawned.")
		passed += 1
	else:
		print("  [FAIL] Real-time teleport to Map 10005 failed: current_map=%d, dynamic_npcs=%d" % [
			sim_renderer.current_map_id, sim_mv._dynamic_npcs.size()
		])
		failed += 1
	
	# -------------------------------------------------------------
	# Test 5: Teleport using btn_sim_teleport with custom coordinates to Map 12001
	# -------------------------------------------------------------
	print("\n>>> [TEST 5] Teleporting with custom coordinates using btn_sim_teleport to Map 12001...")
	var kelan_idx := -1
	for i in range(opt_sim_map.item_count):
		if opt_sim_map.get_item_id(i) == 12001:
			kelan_idx = i
			break
	
	assert(kelan_idx >= 0, "Map 12001 must be in opt_sim_map")
	opt_sim_map.selected = kelan_idx
	editor.active_map_id = 12001
	editor.spin_sim_x.value = 523.0
	editor.spin_sim_y.value = 334.0
	
	editor._on_btn_sim_teleport_pressed()
	await process_frame
	await process_frame
	
	var p_pos: Vector2 = sim_player.world_position if ("world_position" in sim_player) else sim_player.position
	print("  sim_renderer current_map_id: %d" % sim_renderer.current_map_id)
	print("  player position: %s" % str(p_pos))
	print("  sim_mv dynamic NPCs count: %d" % sim_mv._dynamic_npcs.size())
	
	if sim_renderer.current_map_id == 12001 and sim_mv._dynamic_npcs.size() == 3 and p_pos == Vector2(523, 334):
		print("  [PASS] Custom coordinate teleport to Map 12001 succeeded: player at (523, 334) with 3 NPCs.")
		passed += 1
	else:
		print("  [FAIL] Custom teleport to Map 12001 failed.")
		failed += 1
	
	# -------------------------------------------------------------
	# Test 6: Teleport back to Map 10001 (Ship Deck) and verify deck restoration
	# -------------------------------------------------------------
	print("\n>>> [TEST 6] Teleporting back to Ship Deck (Map 10001)...")
	var deck_idx := -1
	for i in range(opt_sim_map.item_count):
		if opt_sim_map.get_item_id(i) == 10001:
			deck_idx = i
			break
	
	opt_sim_map.selected = deck_idx
	editor._on_sim_map_selected(deck_idx)
	await process_frame
	await process_frame
	
	var deck_visible: int = 0
	for e in sim_mv._deck_entities:
		if is_instance_valid(e) and "visible" in e and e.visible:
			deck_visible += 1
	
	print("  sim_renderer current_map_id: %d" % sim_renderer.current_map_id)
	print("  deck entities visible: %d" % deck_visible)
	
	if sim_renderer.current_map_id == 10001 and deck_visible >= 10:
		print("  [PASS] Successfully returned to Ship Deck (10001): deck entities restored.")
		passed += 1
	else:
		print("  [FAIL] Return to Ship Deck failed: map=%d, deck_visible=%d" % [
			sim_renderer.current_map_id, deck_visible
		])
		failed += 1
	
	# Stop playtest cleanly
	editor.stop_playtest()
	await process_frame
	assert(not editor.is_simulator_running, "Simulator must be stopped")
	print("  [PASS] Simulator stopped cleanly.")
	passed += 1
	
	print("\n=======================================================")
	print("--- TEST SUMMARY: %d PASSED, %d FAILED ---" % [passed, failed])
	print("=======================================================\n")
	
	if failed == 0:
		print("[TestSimTeleport] ALL SIMULATOR TELEPORT TESTS PASSED (100% ZERO-ERROR)!")
		quit(0)
	else:
		push_error("[TestSimTeleport] Some tests failed!")
		quit(1)
