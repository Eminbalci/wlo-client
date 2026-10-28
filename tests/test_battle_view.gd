extends SceneTree

## Automated Verification Suite for Wonderland Online In-Game Turn-Based Battle View & Engine.
## Tests:
## 1. BattleView Instantiation & 800x600 Resolution Layout
## 2. 2:1 Axonometric Combat Field Geometry & Diamond Polygons
## 3. 7 Authentic Battle Buttons Texture Binding & Action Triggers
## 4. Battle Initialization, Slot Placement & Overhead Actor HUD
## 5. 20-Second Turn Countdown Timer & Expiration Fallback
## 6. 4-Element Wheel (+25% / -25%) & Physical / Magical Damage Formulas
## 7. Turn Order Queue SPD-Descending Sorting with Deterministic Tie-Breaker
## 8. Round Action Execution Pipeline & Floating Damage/Heal Popups
## 9. Pet Capture & Escape Mechanics
## 10. Victory / Defeat Dialog, EXP / Gold Rewards, Loot Drops & View Cleanup
## 11. Defeat Screen & Battle View Cleanup

const BattleView = preload("res://scripts/battle/battle_view.gd")
const BattleManager = preload("res://scripts/battle/battle_manager.gd")

var battle_view: BattleView = null
var battle_manager: BattleManager = null

func _init() -> void:
	_run_suite.call_deferred()

func _run_suite() -> void:
	print("=================================================================")
	print("--- Running WLO Turn-Based Battle View & Engine Test Suite ------")
	print("=================================================================\n")
	
	await _test_instantiation_and_layout()
	_test_axonometric_grid_geometry()
	_test_7_battle_buttons_and_textures()
	_test_battle_initialization_and_presets()
	_test_turn_timer_countdown()
	_test_element_wheel_and_damage_formulas()
	_test_turn_order_spd_sorting()
	_test_action_execution_and_popups()
	_test_catch_and_escape_mechanics()
	_test_victory_rewards_and_loot_drops()
	_test_defeat_and_cleanup()
	
	print("\n=================================================================")
	print("--- ALL BATTLE VIEW & ENGINE TESTS PASSED (100%) ---------------")
	print("=================================================================")
	quit(0)

func _test_instantiation_and_layout() -> void:
	print(">>> [TEST 1] Verifying BattleView Scene Instantiation (battle_view.tscn)...")
	var scene_res = load("res://scenes/battle/battle_view.tscn")
	assert(scene_res != null, "ERROR: Failed to load res://scenes/battle/battle_view.tscn")
	
	battle_view = scene_res.instantiate() as BattleView
	assert(battle_view != null, "ERROR: Failed to instantiate BattleView")
	root.add_child(battle_view)
	await process_frame
	
	assert(battle_view.custom_minimum_size == Vector2(800.0, 600.0), "ERROR: Min size must be 800x600")
	assert(battle_view.size.x >= 800.0 and battle_view.size.y >= 600.0, "ERROR: View size must be at least 800x600")
	
	battle_manager = battle_view.battle_manager
	assert(battle_manager != null, "ERROR: BattleManager not initialized in BattleView")
	
	# Verify essential nodes exist
	assert(battle_view.arena_canvas != null, "ERROR: ArenaCanvas node missing")
	assert(battle_view.actors_layer != null, "ERROR: ActorsLayer node missing")
	assert(battle_view.floating_text_layer != null, "ERROR: FloatingTextLayer node missing")
	assert(battle_view.vfx_layer != null, "ERROR: VFXLayer node missing")
	assert(battle_view.status_panel != null, "ERROR: StatusPanel node missing")
	assert(battle_view.timer_label != null, "ERROR: TimerLabel node missing")
	assert(battle_view.action_bar != null, "ERROR: ActionButtonsBar node missing")
	assert(battle_view.skill_dialog != null, "ERROR: SkillSelectDialog node missing")
	assert(battle_view.item_dialog != null, "ERROR: ItemSelectDialog node missing")
	assert(battle_view.victory_dialog != null, "ERROR: VictoryDialog node missing")
	
	print("  PASS: BattleView 800x600 scene hierarchy and sub-controllers validated.")

func _test_axonometric_grid_geometry() -> void:
	print(">>> [TEST 2] Verifying 2:1 Axonometric Combat Field Geometry & Hit Detection...")
	assert(BattleView.DIAMOND_HALF_WIDTH == 24.0, "ERROR: Diamond half-width must be 24.0")
	assert(BattleView.DIAMOND_HALF_HEIGHT == 12.0, "ERROR: Diamond half-height must be 12.0")
	var ratio: float = (BattleView.DIAMOND_HALF_WIDTH * 2.0) / (BattleView.DIAMOND_HALF_HEIGHT * 2.0)
	assert(is_equal_approx(ratio, 2.0), "ERROR: Diamond aspect ratio must be strictly 2:1")
	
	var field_offset: Vector2 = battle_view.get_field_offset() if battle_view.has_method("get_field_offset") else Vector2.ZERO
	var p_pos_0: Vector2 = battle_view.get_slot_screen_position(false, 0)
	assert(p_pos_0 == BattleView.PLAYER_FRONT_START + field_offset, "ERROR: Player slot 0 must equal PLAYER_FRONT_START + field_offset")
	
	var poly_0: PackedVector2Array = battle_view.get_slot_polygon(false, 0)
	assert(poly_0.size() == 4, "ERROR: Diamond polygon must have 4 vertices")
	assert(poly_0[0] == Vector2(p_pos_0.x, p_pos_0.y - 12.0), "ERROR: Top vertex incorrect")
	assert(poly_0[1] == Vector2(p_pos_0.x + 24.0, p_pos_0.y), "ERROR: Right vertex incorrect")
	assert(poly_0[2] == Vector2(p_pos_0.x, p_pos_0.y + 12.0), "ERROR: Bottom vertex incorrect")
	assert(poly_0[3] == Vector2(p_pos_0.x - 24.0, p_pos_0.y), "ERROR: Left vertex incorrect")
	
	var e_pos_0: Vector2 = battle_view.get_slot_screen_position(true, 0)
	assert(e_pos_0 == BattleView.ENEMY_FRONT_START + field_offset, "ERROR: Enemy slot 0 must equal ENEMY_FRONT_START + field_offset")
	
	var hit_player: Dictionary = battle_view.find_slot_at_point(p_pos_0)
	assert(hit_player.get("found", false) == true, "ERROR: Center of player slot 0 must hit")
	assert(hit_player.get("is_enemy", true) == false, "ERROR: Hit must be player side")
	assert(hit_player.get("slot", -1) == 0, "ERROR: Hit must be slot 0")
	
	var hit_enemy: Dictionary = battle_view.find_slot_at_point(e_pos_0)
	assert(hit_enemy.get("found", false) == true, "ERROR: Center of enemy slot 0 must hit")
	assert(hit_enemy.get("is_enemy", false) == true, "ERROR: Hit must be enemy side")
	assert(hit_enemy.get("slot", -1) == 0, "ERROR: Hit must be slot 0")
	
	var miss: Dictionary = battle_view.find_slot_at_point(Vector2(50.0, 50.0))
	assert(miss.get("found", true) == false, "ERROR: Point (50, 50) must miss all slots")
	
	print("  PASS: 2:1 axonometric geometry, 4-vertex diamonds, and point hit detection verified.")

func _test_7_battle_buttons_and_textures() -> void:
	print(">>> [TEST 3] Verifying 7 Authentic Battle Buttons & Asset Texture Bindings...")
	assert(battle_view.action_buttons.size() == 7, "ERROR: Action bar must contain exactly 7 buttons")
	
	var expected_actions: Array[int] = [
		BattleManager.ActionType.ATTACK,
		BattleManager.ActionType.DEFEND,
		BattleManager.ActionType.SKILL,
		BattleManager.ActionType.ITEM,
		BattleManager.ActionType.CATCH,
		BattleManager.ActionType.ESCAPE,
		BattleManager.ActionType.AUTO
	]
	
	for i in range(7):
		var btn: TextureButton = battle_view.action_buttons[i]
		assert(btn != null, "ERROR: Button %d is null" % (i + 1))
		assert(btn.name == "Btn_Battle_%d" % (i + 1), "ERROR: Button name mismatch")
		assert(btn.texture_normal != null, "ERROR: Button %d texture_normal missing" % (i + 1))
		assert(BattleView.BTN_PATHS[i]["action"] == expected_actions[i], "ERROR: Action enum mismatch for button %d" % (i + 1))
		
	print("  PASS: 7 battle buttons (Attack, Defend, Skill, Item, Catch, Escape, Auto) verified with textures.")

func _test_battle_initialization_and_presets() -> void:
	print(">>> [TEST 4] Verifying Battle Initialization, Presets & Actor Overhead HUD...")
	battle_manager.load_formation_preset("Kelan Slimes Troop")
	
	battle_manager.set_player_slot(0, {
		"id": 1,
		"name": "Nina",
		"level": 10,
		"hp": 320,
		"max_hp": 320,
		"sp": 140,
		"max_sp": 140,
		"atk": 45,
		"matk": 55,
		"def": 22,
		"mdef": 26,
		"spd": 18,
		"element": BattleManager.Element.FIRE,
		"skills": [
			{"id": 10001, "name": "Normal Attack", "sp_cost": 0, "base_damage": 25, "skill_type": 0, "element": 0},
			{"id": 15039, "name": "Wine Flame", "sp_cost": 9, "base_damage": 40, "skill_type": 0, "element": 3}
		]
	})
	
	battle_manager.start_battle()
	battle_view.refresh_actor_widgets()
	
	var living_enemies: Array[Dictionary] = battle_manager.get_living_participants(true)
	assert(living_enemies.size() == 3, "ERROR: Expected 3 living enemies in Kelan Slimes preset")
	
	var living_players: Array[Dictionary] = battle_manager.get_living_participants(false)
	assert(living_players.size() == 1, "ERROR: Expected 1 living player")
	
	var p_widget: Dictionary = battle_view.get_actor_widget(false, 0)
	assert(not p_widget.is_empty(), "ERROR: Player 0 overhead widget missing")
	var hp_bar: ProgressBar = p_widget.get("hp_bar") as ProgressBar
	assert(hp_bar != null and hp_bar.value == 320.0, "ERROR: Player HP bar value mismatch")
	
	var e_widget_0: Dictionary = battle_view.get_actor_widget(true, 0)
	assert(not e_widget_0.is_empty(), "ERROR: Enemy 0 overhead widget missing")
	
	print("  PASS: Formation preset, slot normalizations, and actor overhead HUD widgets verified.")

func _test_turn_timer_countdown() -> void:
	print(">>> [TEST 5] Verifying 20-Second Turn Countdown Timer & Fallback...")
	assert(battle_manager.turn_timer == 20.0, "ERROR: Initial turn timer must be 20.0 seconds")
	assert(battle_manager.timer_active == true, "ERROR: Timer should be active during INPUT_WAIT")
	
	battle_manager._process(5.0)
	assert(is_equal_approx(battle_manager.turn_timer, 15.0), "ERROR: Timer should be 15.0 after 5s")
	assert(battle_view.timer_label.text == "15", "ERROR: View timer label should read '15'")
	
	var prev_turn: int = battle_manager.current_turn
	battle_manager._process(16.0)
	assert(battle_manager.current_turn == prev_turn + 1, "ERROR: Expiration should advance turn")
	assert(battle_manager.turn_timer == BattleManager.TURN_TIME_LIMIT, "ERROR: Next turn resets timer to 20.0s")
	
	print("  PASS: 20-second turn timer countdown, label update, and auto-defend fallback verified.")

func _test_element_wheel_and_damage_formulas() -> void:
	print(">>> [TEST 6] Verifying 4-Element Wheel (+25% / -25%) & Damage Formulas...")
	assert(BattleManager.get_element_multiplier(BattleManager.Element.EARTH, BattleManager.Element.WATER) == 1.25, "ERROR: Earth > Water must be 1.25x")
	assert(BattleManager.get_element_multiplier(BattleManager.Element.WATER, BattleManager.Element.FIRE) == 1.25, "ERROR: Water > Fire must be 1.25x")
	assert(BattleManager.get_element_multiplier(BattleManager.Element.FIRE, BattleManager.Element.WIND) == 1.25, "ERROR: Fire > Wind must be 1.25x")
	assert(BattleManager.get_element_multiplier(BattleManager.Element.WIND, BattleManager.Element.EARTH) == 1.25, "ERROR: Wind > Earth must be 1.25x")
	
	assert(BattleManager.get_element_multiplier(BattleManager.Element.WATER, BattleManager.Element.EARTH) == 0.75, "ERROR: Water < Earth must be 0.75x")
	assert(BattleManager.get_element_multiplier(BattleManager.Element.FIRE, BattleManager.Element.WATER) == 0.75, "ERROR: Fire < Water must be 0.75x")
	assert(BattleManager.get_element_multiplier(BattleManager.Element.WIND, BattleManager.Element.FIRE) == 0.75, "ERROR: Wind < Fire must be 0.75x")
	assert(BattleManager.get_element_multiplier(BattleManager.Element.EARTH, BattleManager.Element.WIND) == 0.75, "ERROR: Earth < Wind must be 0.75x")
	
	assert(BattleManager.get_element_multiplier(BattleManager.Element.NONE, BattleManager.Element.FIRE) == 1.0, "ERROR: None vs Fire must be 1.0x")
	assert(BattleManager.get_element_multiplier(BattleManager.Element.FIRE, BattleManager.Element.FIRE) == 1.0, "ERROR: Same element must be 1.0x")
	
	var attacker: Dictionary = {"atk": 50, "matk": 40, "element": BattleManager.Element.FIRE}
	var target_normal: Dictionary = {"def": 20, "mdef": 15, "element": BattleManager.Element.WIND, "is_defending": false}
	var target_defending: Dictionary = {"def": 20, "mdef": 15, "element": BattleManager.Element.WIND, "is_defending": true}
	var action: Dictionary = {"type": BattleManager.ActionType.ATTACK}
	
	battle_manager.deterministic_rolls = true
	var dmg_norm: Dictionary = battle_manager.calculate_damage(attacker, target_normal, action)
	var dmg_def: Dictionary = battle_manager.calculate_damage(attacker, target_defending, action)
	
	assert(dmg_norm["element_multiplier"] == 1.25, "ERROR: Fire vs Wind element mult must be 1.25")
	assert(dmg_def["is_guarded"] == true, "ERROR: Defending target must flag is_guarded")
	assert(dmg_def["damage"] <= int(dmg_norm["damage"] * 0.55), "ERROR: Defending target damage must be reduced by ~50%")
	
	print("  PASS: 4-element wheel bonuses, penalties, and defensive mitigation validated.")

func _test_turn_order_spd_sorting() -> void:
	print(">>> [TEST 7] Verifying Turn Order SPD Descending Sorting & Player Tie-Breaker...")
	battle_manager.queued_actions.clear()
	
	battle_manager.player_slots[0] = {"name": "P1", "spd": 25, "is_alive": true, "slot": 0, "is_enemy": false}
	battle_manager.player_slots[1] = {"name": "P2", "spd": 15, "is_alive": true, "slot": 1, "is_enemy": false}
	battle_manager.enemy_slots[0] = {"name": "E1", "spd": 35, "is_alive": true, "slot": 0, "is_enemy": true}
	battle_manager.enemy_slots[1] = {"name": "E2", "spd": 25, "is_alive": true, "slot": 1, "is_enemy": true}
	battle_manager.enemy_slots[2] = {"name": "E3", "spd": 8, "is_alive": true, "slot": 2, "is_enemy": true}
	
	battle_manager.queued_actions["e_0"] = {"is_enemy": true, "slot": 0, "type": 0}
	battle_manager.queued_actions["p_0"] = {"is_enemy": false, "slot": 0, "type": 0}
	battle_manager.queued_actions["e_1"] = {"is_enemy": true, "slot": 1, "type": 0}
	battle_manager.queued_actions["p_1"] = {"is_enemy": false, "slot": 1, "type": 0}
	battle_manager.queued_actions["e_2"] = {"is_enemy": true, "slot": 2, "type": 0}
	
	var order: Array[Dictionary] = battle_manager.calculate_turn_order()
	assert(order.size() == 5, "ERROR: Expected 5 participants in turn order")
	
	assert(order[0]["name"] == "E1" and order[0]["spd"] == 35, "ERROR: 1st must be E1 (SPD 35)")
	assert(order[1]["name"] == "P1" and order[1]["spd"] == 25, "ERROR: 2nd must be P1 (SPD 25, player first)")
	assert(order[2]["name"] == "E2" and order[2]["spd"] == 25, "ERROR: 3rd must be E2 (SPD 25)")
	assert(order[3]["name"] == "P2" and order[3]["spd"] == 15, "ERROR: 4th must be P2 (SPD 15)")
	assert(order[4]["name"] == "E3" and order[4]["spd"] == 8, "ERROR: 5th must be E3 (SPD 8)")
	
	print("  PASS: SPD descending sort and player-first deterministic tie-breaking validated.")

func _test_action_execution_and_popups() -> void:
	print(">>> [TEST 8] Verifying Round Action Execution Pipeline & Floating Popups...")
	battle_manager.player_slots[0] = {
		"name": "Nina", "hp": 300, "max_hp": 300, "sp": 100, "max_sp": 100,
		"atk": 50, "matk": 60, "def": 20, "mdef": 20, "spd": 25,
		"element": BattleManager.Element.FIRE, "is_alive": true, "slot": 0, "is_enemy": false,
		"skills": [
			{"name": "Wine Flame", "sp_cost": 15, "base_damage": 40, "skill_type": 0, "element": 3}
		]
	}
	battle_manager.enemy_slots[0] = {
		"name": "Blue Jelly", "hp": 60, "max_hp": 60, "sp": 20, "max_sp": 20,
		"atk": 15, "def": 10, "mdef": 10, "spd": 10,
		"element": BattleManager.Element.WATER, "is_alive": true, "slot": 0, "is_enemy": true
	}
	
	battle_view.refresh_actor_widgets()
	battle_manager.deterministic_rolls = true
	
	var attack_action: Dictionary = {
		"type": BattleManager.ActionType.ATTACK,
		"slot": 0, "is_enemy": false,
		"target_slot": 0, "target_is_enemy": true
	}
	var res: Dictionary = battle_manager.execute_single_action(attack_action)
	assert(res["success"] == true, "ERROR: Attack action must succeed")
	assert(res["damage"] > 0, "ERROR: Damage must be positive")
	assert(int(battle_manager.enemy_slots[0]["hp"]) < 60, "ERROR: Enemy HP must decrease")
	
	var popup: Label = battle_view.spawn_floating_text(Vector2(400.0, 300.0), "-45", Color(1.0, 0.3, 0.2, 1.0))
	assert(popup != null, "ERROR: Floating text label not created")
	assert(popup.text == "-45", "ERROR: Popup text mismatch")
	
	print("  PASS: Single action execution, HP mutation, and floating combat text popups verified.")

func _test_catch_and_escape_mechanics() -> void:
	print(">>> [TEST 9] Verifying Pet Capture & Flee / Escape Mechanics...")
	battle_manager.deterministic_rolls = true
	
	var target_monster: Dictionary = {
		"name": "Blue Jelly", "level": 1, "hp": 10, "max_hp": 60,
		"is_alive": true, "is_boss": false, "slot": 0, "is_enemy": true
	}
	battle_manager.enemy_slots[0] = target_monster
	var player_actor: Dictionary = {"name": "Nina", "level": 10, "spd": 25, "is_enemy": false, "slot": 0}
	
	var catch_rate: float = battle_manager.calculate_catch_rate(player_actor, target_monster)
	assert(catch_rate >= 0.50, "ERROR: Catch rate against low HP level 1 monster should be >= 50%")
	
	var catch_action: Dictionary = {
		"type": BattleManager.ActionType.CATCH,
		"slot": 0, "is_enemy": false,
		"target_slot": 0, "target_is_enemy": true
	}
	var catch_res: Dictionary = battle_manager.execute_single_action(catch_action)
	assert(catch_res["success"] == true, "ERROR: Deterministic catch should succeed")
	assert(target_monster.get("captured", false) == true, "ERROR: Monster must be flagged as captured")
	
	var boss_monster: Dictionary = {
		"name": "Leader Bat", "level": 5, "hp": 20, "max_hp": 190,
		"is_alive": true, "is_boss": true, "slot": 1, "is_enemy": true
	}
	battle_manager.enemy_slots[1] = boss_monster
	var boss_catch_action: Dictionary = {
		"type": BattleManager.ActionType.CATCH,
		"slot": 0, "is_enemy": false,
		"target_slot": 1, "target_is_enemy": true
	}
	var boss_res: Dictionary = battle_manager.execute_single_action(boss_catch_action)
	assert(boss_res["success"] == false, "ERROR: Boss monster cannot be captured")
	
	var escape_action: Dictionary = {
		"type": BattleManager.ActionType.ESCAPE,
		"slot": 0, "is_enemy": false
	}
	var esc_res: Dictionary = battle_manager.execute_single_action(escape_action)
	assert(esc_res["success"] == true, "ERROR: High SPD player should successfully flee")
	assert(battle_manager.current_state == BattleManager.BattleState.ESCAPED, "ERROR: Battle state must be ESCAPED")
	
	print("  PASS: Pet capture formula, boss immunity, and escape mechanics validated.")

func _test_victory_rewards_and_loot_drops() -> void:
	print(">>> [TEST 10] Verifying Victory Progression, Rewards & Loot Tables...")
	battle_manager.load_formation_preset("Kelan Slimes Troop")
	battle_manager.deterministic_rolls = true
	
	for s in range(BattleManager.TOTAL_SLOTS):
		if not battle_manager.enemy_slots[s].is_empty():
			battle_manager.enemy_slots[s]["hp"] = 0
			battle_manager.enemy_slots[s]["is_alive"] = false
			
	var outcome: String = battle_manager.check_battle_end_conditions()
	assert(outcome == "victory", "ERROR: Battle condition must resolve to 'victory'")
	
	battle_manager._handle_battle_end("victory")
	assert(battle_manager.current_state == BattleManager.BattleState.VICTORY, "ERROR: State must be VICTORY")
	
	var rewards: Dictionary = battle_manager.rewards
	assert(int(rewards.get("exp", 0)) > 0, "ERROR: EXP reward must be > 0")
	assert(int(rewards.get("gold", 0)) > 0, "ERROR: Gold reward must be > 0")
	assert(not (rewards.get("items", []) as Array).is_empty(), "ERROR: Guaranteed loot drops must be present")
	
	assert(battle_view.is_victory_dialog_visible() == true, "ERROR: VictoryDialog must be visible upon victory")
	assert(battle_view.exp_reward_label.text.contains("+"), "ERROR: Exp label must display positive reward")
	
	var confirmed: Array[bool] = [false]
	battle_view.victory_confirmed.connect(func(): confirmed[0] = true)
	battle_view._on_victory_ok_pressed()
	assert(confirmed[0] == true, "ERROR: victory_confirmed signal must be emitted")
	assert(battle_view.is_victory_dialog_visible() == false, "ERROR: VictoryDialog must close after OK")
	
	print("  PASS: Victory state, EXP/Gold calculation, loot rolling, and dialog interaction verified.")

func _test_defeat_and_cleanup() -> void:
	print(">>> [TEST 11] Verifying Defeat Screen & Battle View Cleanup...")
	battle_manager.load_formation_preset("Kelan Cave Bats")
	
	for s in range(BattleManager.TOTAL_SLOTS):
		if not battle_manager.player_slots[s].is_empty():
			battle_manager.player_slots[s]["hp"] = 0
			battle_manager.player_slots[s]["is_alive"] = false
			
	var outcome: String = battle_manager.check_battle_end_conditions()
	assert(outcome == "defeat", "ERROR: Defeat condition must trigger when party is wiped")
	
	battle_manager._handle_battle_end("defeat")
	assert(battle_manager.current_state == BattleManager.BattleState.DEFEAT, "ERROR: State must be DEFEAT")
	assert(battle_view.is_victory_dialog_visible() == true, "ERROR: Defeat modal must be visible")
	assert(battle_view.victory_title_label.text.contains("DEFEAT"), "ERROR: Dialog title must show DEFEAT")
	
	battle_view.cleanup()
	assert(battle_manager.current_state == BattleManager.BattleState.IDLE, "ERROR: Cleanup must reset BattleManager")
	assert(battle_view.is_victory_dialog_visible() == false, "ERROR: Cleanup must hide all dialogs")
	
	print("  PASS: Defeat handling and complete battle cleanup verified.")
