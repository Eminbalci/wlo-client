extends SceneTree

const BattleViewScene = preload("res://scenes/battle/battle_view.tscn")
const BattleManager = preload("res://scripts/battle/battle_manager.gd")
const BattleView = preload("res://scripts/battle/battle_view.gd")

func _init() -> void:
	_run_all_tests()

func _run_all_tests() -> void:
	print("\n=================================================================")
	print("--- Running Battle Round Timer & Backdrop Parity Test Suite ---")
	print("=================================================================\n")

	await _test_environment_backdrop_resolution()
	await _test_countdown_timer_parity()
	await _test_pet_command_radial_ring_step()
	await _test_camera_attack_zoom()

	print("\n=================================================================")
	print("--- ALL BATTLE ROUND TIMER & BACKDROP PARITY TESTS PASSED ---")
	print("=================================================================\n")
	quit(0)

func _test_environment_backdrop_resolution() -> void:
	print(">>> [TEST 1] Verifying Dynamic Environment Backdrop Resolution & Tinting...")
	
	# 1. Environment lookup from map ID and name
	assert(BattleView.resolve_environment_for_map(10002, "North Island Forest") == "forest", "ERROR: Forest map must resolve to forest")
	assert(BattleView.resolve_environment_for_map(10001, "Kelan Beach") == "beach", "ERROR: Beach map must resolve to beach")
	assert(BattleView.resolve_environment_for_map(10003, "Kelan Underground Cave") == "cave", "ERROR: Cave map must resolve to cave")
	assert(BattleView.resolve_environment_for_map(10000, "Ocean Star Deck") == "deck", "ERROR: Deck map must resolve to deck")

	var view: BattleView = BattleViewScene.instantiate()
	root.add_child(view)
	await process_frame

	# 2. Testing Forest Environment
	view.set_environment("forest")
	assert(view.current_environment == "forest", "ERROR: Current environment should be forest")
	assert(view.map_backdrop.visible == true, "ERROR: Backdrop must be visible")
	assert(view.map_backdrop.texture != null, "ERROR: Forest backdrop texture must be assigned")
	var bg_rect := view.get_node("ArenaBackground") as ColorRect
	assert(bg_rect.color == Color(0.18, 0.38, 0.12, 1.0), "ERROR: Forest ground base must be grass green")

	# 3. Testing Beach Environment
	view.set_environment("beach")
	assert(view.current_environment == "beach", "ERROR: Current environment should be beach")
	assert(view.map_backdrop.texture != null, "ERROR: Beach backdrop texture must be assigned")
	assert(bg_rect.color == Color(0.82, 0.76, 0.58, 1.0), "ERROR: Beach ground base must be sand tan")

	# 4. Testing Cave Environment
	view.set_environment("cave")
	assert(view.current_environment == "cave", "ERROR: Current environment should be cave")
	assert(view.map_backdrop.texture != null, "ERROR: Cave backdrop texture must be assigned")
	assert(bg_rect.color == Color(0.24, 0.22, 0.26, 1.0), "ERROR: Cave ground base must be stone slate")

	# 5. Testing Deck Environment
	view.set_environment("deck")
	assert(view.current_environment == "deck", "ERROR: Current environment should be deck")
	assert(view.map_backdrop.texture != null, "ERROR: Deck backdrop texture must be assigned")
	assert(bg_rect.color == Color(0.44, 0.30, 0.18, 1.0), "ERROR: Deck ground base must be wood plank brown")

	view.queue_free()
	await process_frame
	print("  PASS: Dynamic environment backdrops and arena ground colors verified.")

func _test_countdown_timer_parity() -> void:
	print(">>> [TEST 2] Verifying Centered 20s/30s Digital Cyan Countdown Timer...")
	var view: BattleView = BattleViewScene.instantiate()
	root.add_child(view)
	await process_frame

	assert(view.countdown_label != null, "ERROR: CountdownLabel must exist")
	assert(view.countdown_label.name == "CountdownLabel", "ERROR: Countdown label name mismatch")

	# Check font styling & default color
	var font_color: Color = view.countdown_label.get_theme_color("font_color")
	assert(font_color == Color(0.25, 0.92, 1.0, 1.0), "ERROR: Default countdown color must be authentic digital cyan")

	# Test timer updates
	view.battle_manager.start_battle()
	assert(view.countdown_label.visible == true, "ERROR: Countdown label must be visible during INPUT_WAIT")
	assert(view.countdown_label.text == "20", "ERROR: Initial countdown must show 20")

	# Tick down to 10s
	view._on_bm_timer_tick(10.0)
	assert(view.countdown_label.text == "10", "ERROR: Countdown label must read 10")
	assert(view.countdown_label.get_theme_color("font_color") == Color(0.25, 0.92, 1.0, 1.0), "ERROR: Font color should remain cyan > 5s")

	# Tick down to warning threshold <= 5s
	view._on_bm_timer_tick(4.2)
	assert(view.countdown_label.text == "5", "ERROR: Countdown label must read 5 (ceilf)")
	assert(view.countdown_label.get_theme_color("font_color") == Color(1.0, 0.25, 0.25, 1.0), "ERROR: Font color must turn warning red when <= 5s")

	# Configurable timer limit (e.g. 30s)
	view.battle_manager.set_turn_time_limit(30.0)
	assert(view.battle_manager.turn_time_limit == 30.0, "ERROR: Turn time limit should be 30s")
	view.battle_manager.start_turn()
	assert(view.countdown_label.text == "30", "ERROR: Countdown should reset to 30 on turn start")

	# Hides on round execution
	view._on_bm_round_execution_started([])
	assert(view.countdown_label.visible == false, "ERROR: Countdown label must hide during round execution")

	view.queue_free()
	await process_frame
	print("  PASS: Centered digital cyan countdown, tick updates, warning colors, and configurable limits verified.")

func _test_pet_command_radial_ring_step() -> void:
	print(">>> [TEST 3] Verifying 2-Phase Player to Pet Radial Ring Step...")
	var view: BattleView = BattleViewScene.instantiate()
	root.add_child(view)
	await process_frame

	var bm: BattleManager = view.battle_manager
	var party: Array[Dictionary] = [
		{
			"id": 1,
			"name": "Daniel",
			"level": 15,
			"hp": 400,
			"max_hp": 400,
			"sp": 150,
			"max_sp": 150,
			"spd": 25,
			"element": 0
		},
		{
			"id": 8090,
			"name": "Roca",
			"level": 14,
			"hp": 350,
			"max_hp": 350,
			"sp": 120,
			"max_sp": 120,
			"spd": 20,
			"element": 1
		}
	]
	var enemies: Array[Dictionary] = [
		{
			"id": 1001,
			"name": "Forest Mush",
			"level": 5,
			"hp": 50,
			"max_hp": 50,
			"sp": 20,
			"max_sp": 20,
			"spd": 10,
			"element": 0
		}
	]
	bm.initialize_battle(party, enemies)
	bm.start_battle()

	# Phase 1: Player (Slot 0)
	assert(view.current_player_slot == 0, "ERROR: Turn must start on player Slot 0")
	assert(view.action_bar.visible == true, "ERROR: Action ring must be visible")
	var player_feet: Vector2 = view.get_slot_screen_position(false, 0)
	var attack_btn: TextureButton = view.action_buttons[0] # Attack button
	var attack_offset: Vector2 = BattleView.RING_OFFSET[BattleManager.ActionType.ATTACK]
	assert(attack_btn.position == player_feet + attack_offset - Vector2(14.0, 14.0), "ERROR: Attack button must be placed around player's feet")
	
	# Verify player action button permissions (Catch and Item enabled)
	var catch_btn: TextureButton = view.action_buttons[4] # Catch
	var item_btn: TextureButton = view.action_buttons[3]  # Item
	assert(catch_btn.disabled == false, "ERROR: Catch button must be enabled for player")
	assert(item_btn.disabled == false, "ERROR: Item button must be enabled for player")

	# Player commits attack against enemy 0
	view.pending_action_type = BattleManager.ActionType.ATTACK
	view.selected_target_is_enemy = true
	view.selected_target_slot = 0
	view._commit_pending_action()

	# Phase 2: Ring automatically sequences to Pet (Slot 1)
	assert(view.current_player_slot == 1, "ERROR: Ring must sequence to Pet Slot 1")
	assert(view.action_bar.visible == true, "ERROR: Ring must remain visible for pet command phase")
	var pet_feet: Vector2 = view.get_slot_screen_position(false, 1)
	assert(attack_btn.position == pet_feet + attack_offset - Vector2(14.0, 14.0), "ERROR: Attack button must be placed around pet's feet")

	# Verify pet action button permissions (Catch and Item disabled for pet)
	assert(catch_btn.disabled == true, "ERROR: Catch button must be disabled for pet")
	assert(item_btn.disabled == true, "ERROR: Item button must be disabled for pet")

	# Pet commits attack against enemy 0
	view.pending_action_type = BattleManager.ActionType.ATTACK
	view.selected_target_is_enemy = true
	view.selected_target_slot = 0
	view._commit_pending_action()

	# After both player and pet commit, ring hides and execution begins
	assert(view.action_bar.visible == false, "ERROR: Action bar must hide after all party actions committed")
	assert(bm.are_all_player_actions_ready() == true, "ERROR: All party actions should be ready")

	view.queue_free()
	await process_frame
	print("  PASS: 2-phase player to pet command radial ring handoff and permission gating verified.")

func _test_camera_attack_zoom() -> void:
	print(">>> [TEST 4] Verifying Dynamic Combat Camera Attack Zoom...")
	var view: BattleView = BattleViewScene.instantiate()
	root.add_child(view)
	await process_frame

	var target_pos := Vector2(200.0, 300.0)
	assert(view.actors_layer != null, "ERROR: actors_layer must exist")
	view.play_camera_attack_zoom(target_pos)
	assert(view.actors_layer.pivot_offset == target_pos, "ERROR: actors_layer pivot_offset must target attack impact point")

	view.queue_free()
	await process_frame
	print("  PASS: Dynamic combat camera attack zoom verified.")
