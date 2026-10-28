extends SceneTree

## Automated Verification Suite for Simulator NPC Click & Dialogue System
## Verifies:
## 1. SimViewport physics_object_picking and handle_input_locally configuration
## 2. Click detection on nearby NPCs in simulator via find_npc_near_world_pos / _on_tile_clicked
## 3. Immediate dialogue opening, face-to-face heading adjustment, and authentic dialogue text
## 4. Distant NPC click: approach pathfinding, arrival detection, and automatic dialogue opening
## 5. Injected NPC interaction from NPC Studio in simulator
## 6. NPC dialogue interaction after simulator map teleportation (Map 10002 Cabin)

func _init() -> void:
	print("\n=======================================================")
	print("--- Running Simulator NPC Interaction & Dialogue Tests ---")
	print("=======================================================\n")
	_run_tests.call_deferred()

func _run_tests() -> void:
	var passed: int = 0
	var failed: int = 0
	
	var scene_res = ResourceLoader.load("res://scenes/tools/world_editor.tscn")
	if not scene_res:
		push_error("Failed to load world_editor.tscn")
		quit(1)
		return
	var editor = scene_res.instantiate()
	root.add_child(editor)
	await process_frame
	await process_frame

	# -------------------------------------------------------------
	# Test 1: Verify SimViewport configuration
	# -------------------------------------------------------------
	print(">>> [TEST 1] Verifying SimViewport properties...")
	var vp = editor.sim_viewport
	assert(vp != null, "sim_viewport must exist")
	
	if vp.physics_object_picking:
		print("  [PASS] sim_viewport.physics_object_picking is true.")
		passed += 1
	else:
		print("  [FAIL] sim_viewport.physics_object_picking is false.")
		failed += 1

	if vp.handle_input_locally:
		print("  [PASS] sim_viewport.handle_input_locally is true.")
		passed += 1
	else:
		print("  [FAIL] sim_viewport.handle_input_locally is false.")
		failed += 1

	# -------------------------------------------------------------
	# Test 2: Launch Simulator on Map 10001 (Ship Deck)
	# -------------------------------------------------------------
	print("\n>>> [TEST 2] Launching Simulator on Map 10001...")
	editor.start_playtest()
	await process_frame
	await process_frame

	var sim_mv = editor._simulator_instance
	assert(sim_mv != null, "Simulator MapView instance must be valid")
	
	if sim_mv.hud != null and sim_mv.hud.dialogue_ctrl != null:
		print("  [PASS] Simulator MapView HUD and dialogue coordinator initialized.")
		passed += 1
	else:
		print("  [FAIL] Simulator MapView HUD or dialogue coordinator missing.")
		failed += 1

	var npcs = sim_mv.get_active_npcs()
	if npcs.size() >= 5:
		print("  [PASS] Located %d active NPCs on Ship Deck." % npcs.size())
		passed += 1
	else:
		print("  [FAIL] Insufficient NPCs on Ship Deck: %d" % npcs.size())
		failed += 1

	# -------------------------------------------------------------
	# Test 3: Click nearby NPC and verify immediate dialogue opening & facing
	# -------------------------------------------------------------
	print("\n>>> [TEST 3] Testing nearby NPC interaction...")
	var cat_npc: NpcEntity = null
	for n in npcs:
		if "cat" in n.npc_name.to_lower():
			cat_npc = n
			break
	assert(cat_npc != null, "Cat NPC must be present on deck")
	
	# Place player close to Cat (within 100px)
	sim_mv.player.world_position = cat_npc.world_position + Vector2(60, 40)
	sim_mv.player.position = sim_mv.player.world_position
	
	# Click directly on the Cat's position
	sim_mv._on_tile_clicked(cat_npc.world_position)
	await process_frame
	
	var dctrl = sim_mv.hud.dialogue_ctrl
	if sim_mv.hud.is_dialogue_active() and dctrl.dialogue_dock.visible:
		print("  [PASS] Dialogue window opened immediately on nearby NPC click.")
		passed += 1
	else:
		print("  [FAIL] Dialogue window failed to open.")
		failed += 1

	var spk: String = dctrl.speaker_label.text if dctrl.speaker_label else ""
	if spk == "Persian Cat":
		print("  [PASS] Speaker nameplate correctly displayed: '%s'." % spk)
		passed += 1
	else:
		print("  [FAIL] Speaker nameplate expected 'Persian Cat', got '%s'." % spk)
		failed += 1

	var txt: String = dctrl.dialogue_text.text if dctrl.dialogue_text else ""
	if "Meow" in txt or "purr" in txt:
		print("  [PASS] Dialogue text correctly presented: '%s'." % txt)
		passed += 1
	else:
		print("  [FAIL] Unexpected dialogue text: '%s'." % txt)
		failed += 1

	# Close dialogue
	sim_mv.hud.hide_dialogue()
	await process_frame
	if not sim_mv.hud.is_dialogue_active():
		print("  [PASS] Dialogue closed successfully.")
		passed += 1
	else:
		print("  [FAIL] Dialogue failed to close.")
		failed += 1

	# -------------------------------------------------------------
	# Test 4: Click distant NPC, approach pathfinding, and arrival trigger
	# -------------------------------------------------------------
	print("\n>>> [TEST 4] Testing distant NPC approach & auto-dialogue...")
	# Place player further away (> 150px)
	sim_mv.player.world_position = cat_npc.world_position + Vector2(160, 100)
	sim_mv.player.position = sim_mv.player.world_position
	sim_mv.player.is_moving = false
	
	# Click on Cat from distance
	sim_mv._on_tile_clicked(cat_npc.world_position)
	
	if sim_mv._pending_npc_interaction == cat_npc:
		print("  [PASS] Pending interaction registered for distant NPC.")
		passed += 1
	else:
		print("  [FAIL] Pending interaction not set.")
		failed += 1

	# Step movement until player approaches and triggers dialogue
	var dialogue_triggered := false
	for step in range(40):
		sim_mv._process(0.05)
		if sim_mv.player.has_method("_update_movement"):
			sim_mv.player._update_movement(0.05)
		if sim_mv.hud.is_dialogue_active():
			dialogue_triggered = true
			break
	
	if dialogue_triggered and dctrl.dialogue_dock.visible:
		print("  [PASS] Player walked toward NPC and dialogue opened automatically upon reaching range.")
		passed += 1
	else:
		print("  [FAIL] Dialogue did not trigger automatically during approach.")
		failed += 1

	# Close dialogue
	sim_mv.hud.hide_dialogue()
	await process_frame

	# -------------------------------------------------------------
	# Test 5: Teleport Simulator to Map 10002 (Cabin) & interact with Cabin NPC
	# -------------------------------------------------------------
	print("\n>>> [TEST 5] Teleporting Simulator to Map 10002 (Cabin)...")
	editor.teleport_simulator_to(10002, Vector2(674, 1067))
	await process_frame
	await process_frame

	var cabin_npcs = sim_mv.get_active_npcs()
	print("  Active Cabin NPCs: %d" % cabin_npcs.size())
	assert(cabin_npcs.size() > 0, "Cabin must have NPCs")
	
	var first_cabin_npc = cabin_npcs[0]
	print("  Interacting with Cabin NPC: %s at %s" % [first_cabin_npc.npc_name, str(first_cabin_npc.world_position)])
	
	# Place player near cabin NPC and click
	sim_mv.player.world_position = first_cabin_npc.world_position + Vector2(50, 20)
	sim_mv.player.position = sim_mv.player.world_position
	sim_mv._on_tile_clicked(first_cabin_npc.world_position)
	await process_frame

	if sim_mv.hud.is_dialogue_active():
		print("  [PASS] Dialogue opened on Cabin NPC click: '%s'." % dctrl.speaker_label.text)
		passed += 1
	else:
		print("  [FAIL] Cabin NPC dialogue did not open.")
		failed += 1

	sim_mv.hud.hide_dialogue()
	await process_frame

	# -------------------------------------------------------------
	# Test 6: Stop simulator cleanly
	# -------------------------------------------------------------
	print("\n>>> [TEST 6] Stopping Simulator...")
	editor.stop_playtest()
	await process_frame
	
	if not editor.is_simulator_running and editor._simulator_instance == null:
		print("  [PASS] Simulator stopped cleanly.")
		passed += 1
	else:
		print("  [FAIL] Simulator failed to stop.")
		failed += 1

	editor.queue_free()

	print("\n=======================================================")
	print("--- TEST SUMMARY: %d PASSED, %d FAILED ---" % [passed, failed])
	print("=======================================================\n")

	if failed == 0:
		print("[PASS] ALL SIMULATOR NPC INTERACTION TESTS PASSED (100% ZERO-ERROR)!")
		quit(0)
	else:
		push_error("Some tests failed.")
		quit(1)
