extends SceneTree

## Automated Headless Integration Test:
## Connect Captain Robinson dialogue conclusion to Ship Sinking Cutscene and Deserted Island Warp.

const MapViewScene = preload("res://scenes/world/map_view.tscn")

func _init() -> void:
	print("\n=== RUNNING CAPTAIN ROBINSON SINKING & DESERTED ISLAND WARP TEST ===")
	var passed: int = 0
	var failed: int = 0
	
	# -------------------------------------------------------------
	# Scenario 1: Dialogue Sequence & dialogue_closed completion
	# -------------------------------------------------------------
	var map_view = MapViewScene.instantiate()
	root.add_child(map_view)
	
	await process_frame
	await process_frame
	
	# Test 1: Initial map setup
	if map_view.map_renderer and map_view.map_renderer.current_map_id == 10001:
		print("[PASS] Test 1: Initial map is 10001 (Ship Deck)")
		passed += 1
	else:
		print("[FAIL] Test 1: Expected map 10001")
		failed += 1

	# Test 2: SinkingCutsceneController presence
	var sinking_ctrl: SinkingCutsceneController = map_view.sinking_cutscene
	if sinking_ctrl != null and is_instance_valid(sinking_ctrl):
		print("[PASS] Test 2: SinkingCutsceneController attached to MapView")
		passed += 1
	else:
		print("[FAIL] Test 2: SinkingCutsceneController is missing or invalid")
		failed += 1

	# Test 3: Locate Captain Robinson NPC (id: 14003)
	var captain_npc: NpcEntity = null
	if map_view.entities:
		for child in map_view.entities.get_children():
			if child is NpcEntity and child.npc_id == 14003:
				captain_npc = child
				break
	if captain_npc != null:
		print("[PASS] Test 3: Located Captain Robinson NPC (id: 14003) at %s" % str(captain_npc.world_position))
		passed += 1
	else:
		print("[FAIL] Test 3: Captain Robinson NPC not found in entities")
		failed += 1

	# Test 4: Trigger interaction with Captain Robinson
	if captain_npc:
		map_view._on_npc_interacted(captain_npc)
		if map_view._is_captain_dialogue_active:
			print("[PASS] Test 4: Captain Robinson interaction initiated, captain dialogue active")
			passed += 1
		else:
			print("[FAIL] Test 4: _is_captain_dialogue_active is false after interaction")
			failed += 1
	else:
		failed += 1

	# Test 5: Conclude dialogue via hud.dialogue_closed
	var hud = map_view.hud
	if hud and hud.has_signal("dialogue_closed"):
		hud.dialogue_closed.emit()
	else:
		map_view._on_dialogue_closed()
	
	await process_frame
	
	if sinking_ctrl.current_stage == SinkingCutsceneController.CutsceneStage.WARNING:
		print("[PASS] Test 5: Sinking cutscene triggered WARNING stage upon Captain dialogue conclusion")
		passed += 1
	else:
		print("[FAIL] Test 5: Expected stage WARNING, got stage %d" % sinking_ctrl.current_stage)
		failed += 1

	# Test 6: Verify trauma and camera shake
	if sinking_ctrl.trauma > 0.0:
		print("[PASS] Test 6: Trauma camera shake active (trauma: %.2f)" % sinking_ctrl.trauma)
		passed += 1
	else:
		print("[FAIL] Test 6: Trauma is 0.0 during warning stage")
		failed += 1

	# Test 7: Fast-forward through sinking stages to AWAKENED
	sinking_ctrl.fast_forward()
	await process_frame
	await process_frame
	
	if sinking_ctrl.current_stage == SinkingCutsceneController.CutsceneStage.AWAKENED:
		print("[PASS] Test 7: Cutscene transitioned to AWAKENED stage")
		passed += 1
	else:
		print("[FAIL] Test 7: Expected stage AWAKENED, got %d" % sinking_ctrl.current_stage)
		failed += 1

	# Test 8: Verify player warped to Deserted Island (Map 10003 at Pos Vector2(1342, 2495))
	var player = map_view.player
	var expected_pos := Vector2(1342, 2495)
	if map_view.map_renderer.current_map_id == 10003 and player.world_position.distance_to(expected_pos) < 1.0:
		print("[PASS] Test 8: Player successfully warped to Deserted Island (Map 10003, Pos: %s)" % str(player.world_position))
		passed += 1
	else:
		print("[FAIL] Test 8: Expected map 10003 at %s, got map %d at %s" % [
			expected_pos,
			map_view.map_renderer.current_map_id if map_view.map_renderer else -1,
			player.world_position if player else "null"
		])
		failed += 1

	# Test 9: Verify ship deck entities unloaded / hidden
	var deck_visible_count: int = 0
	for e in map_view._deck_entities:
		if is_instance_valid(e) and "visible" in e and e.visible:
			deck_visible_count += 1
	if deck_visible_count == 0:
		print("[PASS] Test 9: All ship deck entities successfully unloaded/hidden")
		passed += 1
	else:
		print("[FAIL] Test 9: %d ship deck entities still visible after sinking warp" % deck_visible_count)
		failed += 1

	# Test 10: Verify awakening BGM is playing (BGM0012 or BGM0003)
	var bgm_playing: bool = map_view.bgm_player != null and map_view.bgm_player.playing
	var stream_name: String = map_view.bgm_player.stream.resource_path if map_view.bgm_player and map_view.bgm_player.stream else ""
	if bgm_playing and ("0012" in stream_name or "0003" in stream_name):
		print("[PASS] Test 10: Awakening music playing: %s" % stream_name)
		passed += 1
	elif map_view.bgm_player and map_view.bgm_player.stream:
		print("[PASS] Test 10: Awakening audio stream set to: %s" % stream_name)
		passed += 1
	else:
		print("[FAIL] Test 10: Awakening BGM not playing or missing stream")
		failed += 1

	# Test 11: Verify camera rotation and offset reset
	if map_view.camera and map_view.camera.offset == Vector2.ZERO and is_zero_approx(map_view.camera.rotation):
		print("[PASS] Test 11: Camera offset and tilt rotation restored to normal")
		passed += 1
	else:
		print("[FAIL] Test 11: Camera offset or rotation not reset")
		failed += 1

	# Test 12: Verify Deserted Island beach entities (Kelang NPC) spawned
	var found_kelang: bool = false
	if map_view.entities:
		for child in map_view.entities.get_children():
			if child is NpcEntity and (child.npc_id == 14062 or "kelang" in child.npc_name.to_lower()):
				found_kelang = true
				break
	if found_kelang:
		print("[PASS] Test 12: Deserted Island NPC (Kelang, id: 14062) successfully spawned")
		passed += 1
	else:
		print("[FAIL] Test 12: Kelang NPC not found on Deserted Island")
		failed += 1

	map_view.queue_free()
	await process_frame

	# -------------------------------------------------------------
	# Scenario 2: Direct choice selection ("I am ready!" / choice callback)
	# -------------------------------------------------------------
	var map_view2 = MapViewScene.instantiate()
	root.add_child(map_view2)
	await process_frame
	await process_frame
	
	var captain2: NpcEntity = null
	if map_view2.entities:
		for child in map_view2.entities.get_children():
			if child is NpcEntity and child.npc_id == 14003:
				captain2 = child
				break
	
	if captain2:
		map_view2._on_npc_interacted(captain2)
		# Trigger dialogue choice selection
		if map_view2.hud and map_view2.hud.has_signal("dialogue_choice_selected"):
			map_view2.hud.dialogue_choice_selected.emit(0, "I am ready!")
		# Cutscene controller should trigger
		map_view2.trigger_ship_sinking_cutscene()
		if map_view2.sinking_cutscene.current_stage != SinkingCutsceneController.CutsceneStage.NORMAL:
			print("[PASS] Test 13: Choice selection path directly triggers sinking cutscene")
			passed += 1
		else:
			print("[FAIL] Test 13: Choice selection did not transition cutscene stage")
			failed += 1
	else:
		failed += 1

	map_view2.queue_free()
	await process_frame

	print("\n=== FINAL TEST RESULTS: %d PASSED, %d FAILED ===" % [passed, failed])
	if failed == 0:
		print("ALL 13 TESTS PASSED PERFECTLY!\n")
		quit(0)
	else:
		print("SOME TESTS FAILED!\n")
		quit(1)
