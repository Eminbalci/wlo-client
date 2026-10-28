class_name TestFightWindowAndCombatSettings
extends SceneTree

const FightWindowScript = preload("res://scripts/ui/hud/fight_window.gd")
const BattleManagerScript = preload("res://scripts/battle/battle_manager.gd")
const BattleViewScript = preload("res://scripts/battle/battle_view.gd")

const TEST_SETTINGS_PATH: String = "user://system_settings.json"

func _init() -> void:
	print("\n=================================================================")
	print("--- RUNNING FIGHT WINDOW & COMBAT SETTINGS TEST SUITE ---")
	print("=================================================================\n")

	_test_1_window_geometry_and_hierarchy()
	_test_2_interactive_controls_and_signals()
	_test_3_json_persistence_and_merging()
	_test_4_battle_manager_forwarding_and_sync()
	_test_5_pk_safety_lock_behavior()
	_test_6_auto_flee_threshold_behavior()
	_test_7_battle_view_speed_integration()
	_test_8_window_open_close_toggling()

	print("\n=================================================================")
	print("--- ALL 8 FIGHT WINDOW & COMBAT SETTINGS TESTS PASSED (100%) ---")
	print("=================================================================\n")
	quit(0)

func _test_1_window_geometry_and_hierarchy() -> void:
	print(">>> [TEST 1] Verifying Fight Window geometry and node hierarchy...")
	var win: FightWindow = FightWindowScript.new()
	root.add_child(win)

	assert(win.size.x == 153.0 and win.size.y == 115.0, "Window dimensions must be 153x115")
	assert(win.custom_minimum_size == Vector2(153.0, 115.0), "Custom minimum size must be 153x115")

	var backing: Panel = win.get_node_or_null("BackingPanel") as Panel
	assert(backing != null, "BackingPanel must exist")
	assert(backing.size == Vector2(153.0, 115.0), "BackingPanel size must be 153x115")

	var bg: TextureRect = win.get_node_or_null("Background") as TextureRect
	assert(bg != null, "Background TextureRect must exist")
	assert(bg.size == Vector2(153.0, 115.0), "Background TextureRect must match 153x115")

	var close_btn: Button = win.get_node_or_null("CloseButton") as Button
	assert(close_btn != null, "CloseButton must exist")
	assert(close_btn.position == Vector2(123.0, 8.0), "CloseButton must be positioned at (123, 8)")
	assert(close_btn.size == Vector2(18.0, 18.0), "CloseButton size must be 18x18")

	var title: Label = win.get_node_or_null("TitleLabel") as Label
	assert(title != null, "TitleLabel must exist")
	assert(title.text == "Combat Settings", "TitleLabel text must be 'Combat Settings'")

	var auto_check: CheckBox = win.get_node_or_null("AutoBattleCheck") as CheckBox
	assert(auto_check != null, "AutoBattleCheck must exist")

	var pk_check: CheckBox = win.get_node_or_null("PKSafetyCheck") as CheckBox
	assert(pk_check != null, "PKSafetyCheck must exist")

	var speed_opt: OptionButton = win.get_node_or_null("SpeedOption") as OptionButton
	assert(speed_opt != null, "SpeedOption must exist")
	assert(speed_opt.item_count == 3, "SpeedOption must have 3 items (1.0x, 1.5x, 2.0x)")

	var flee_spin: SpinBox = win.get_node_or_null("AutoFleeSpinBox") as SpinBox
	assert(flee_spin != null, "AutoFleeSpinBox must exist")
	assert(flee_spin.max_value == 30.0, "AutoFleeSpinBox max value must be 30%")

	win.queue_free()
	print("  [PASS] Fight Window geometry and hierarchy verified.")

func _test_2_interactive_controls_and_signals() -> void:
	print(">>> [TEST 2] Verifying interactive controls, getters, setters, and signals...")
	var win: FightWindow = FightWindowScript.new()
	root.add_child(win)

	var auto_toggled_val: Array = []
	win.auto_battle_toggled.connect(func(enabled: bool) -> void:
		auto_toggled_val.append(enabled)
	)

	var pk_toggled_val: Array = []
	win.pk_safety_toggled.connect(func(enabled: bool) -> void:
		pk_toggled_val.append(enabled)
	)

	var speed_changed_val: Array = []
	win.battle_speed_changed.connect(func(spd: float) -> void:
		speed_changed_val.append(spd)
	)

	var flee_changed_val: Array = []
	win.auto_flee_threshold_changed.connect(func(val: int) -> void:
		flee_changed_val.append(val)
	)

	# Test Auto-Battle toggle
	win.set_auto_battle(true, false)
	assert(win.is_auto_battle() == true, "Auto-battle must be true")
	assert(win.auto_battle_check.button_pressed == true, "AutoBattleCheck button_pressed must be true")
	assert(auto_toggled_val.size() == 1 and auto_toggled_val[0] == true, "auto_battle_toggled signal emitted")

	win.set_auto_battle(false, false)
	assert(win.is_auto_battle() == false, "Auto-battle must be false")
	assert(win.auto_battle_check.button_pressed == false, "AutoBattleCheck button_pressed must be false")
	assert(auto_toggled_val.size() == 2 and auto_toggled_val[1] == false, "auto_battle_toggled emitted false")

	# Test PK Safety Lock toggle
	win.set_pk_safety_lock(false, false)
	assert(win.is_pk_safety_locked() == false, "PK safety lock must be false")
	assert(win.pk_safety_check.button_pressed == false, "PKSafetyCheck button_pressed must be false")
	assert(pk_toggled_val.size() == 1 and pk_toggled_val[0] == false, "pk_safety_toggled signal emitted")

	win.set_pk_safety_lock(true, false)
	assert(win.is_pk_safety_locked() == true, "PK safety lock must be true")

	# Test Battle Speed
	win.set_battle_speed(1.5, false)
	assert(is_equal_approx(win.get_battle_speed(), 1.5), "Battle speed must be 1.5")
	assert(win.speed_option.selected == 1, "Speed option index must be 1 (1.5x)")
	assert(speed_changed_val.size() == 1 and is_equal_approx(speed_changed_val[0], 1.5), "battle_speed_changed emitted")

	win.set_battle_speed(2.0, false)
	assert(win.speed_option.selected == 2, "Speed option index must be 2 (2.0x)")

	# Test Auto-Flee threshold
	win.set_auto_flee_threshold(20, false)
	assert(win.get_auto_flee_threshold() == 20, "Auto-flee threshold must be 20")
	assert(int(win.auto_flee_spinbox.value) == 20, "AutoFleeSpinBox value must be 20")
	assert(flee_changed_val.size() == 1 and flee_changed_val[0] == 20, "auto_flee_threshold_changed emitted")

	win.queue_free()
	print("  [PASS] Interactive controls, getters, setters, and signals verified.")

func _test_3_json_persistence_and_merging() -> void:
	print(">>> [TEST 3] Verifying JSON persistence and merging in user://system_settings.json...")
	
	# Pre-populate settings file with dummy system settings (audio & video)
	var initial_system_data := {
		"bgm_volume": 75,
		"bgm_muted": false,
		"sfx_volume": 60,
		"sfx_muted": true,
		"fullscreen": true
	}
	var f := FileAccess.open(TEST_SETTINGS_PATH, FileAccess.WRITE)
	assert(f != null, "Must open settings file for write")
	f.store_string(JSON.stringify(initial_system_data, "\t"))
	f.close()

	var win: FightWindow = FightWindowScript.new()
	root.add_child(win)

	# Configure combat settings and save
	win.set_auto_battle(true, false)
	win.set_pk_safety_lock(false, false)
	win.set_battle_speed(2.0, false)
	win.set_auto_flee_threshold(15, false)
	win.save_settings()

	# Read settings back from file directly
	var rf := FileAccess.open(TEST_SETTINGS_PATH, FileAccess.READ)
	assert(rf != null, "Must open settings file for read")
	var content := rf.get_as_text()
	rf.close()

	var parsed = JSON.parse_string(content)
	assert(parsed is Dictionary, "Parsed JSON must be Dictionary")
	var dict: Dictionary = parsed as Dictionary

	# Verify non-combat keys were preserved
	assert(int(dict.get("bgm_volume", 0)) == 75, "bgm_volume preserved")
	assert(bool(dict.get("sfx_muted", false)) == true, "sfx_muted preserved")
	assert(bool(dict.get("fullscreen", false)) == true, "fullscreen preserved")

	# Verify combat dictionary contents
	assert(dict.has("combat"), "'combat' key must be present in settings JSON")
	var combat_dict: Dictionary = dict["combat"]
	assert(bool(combat_dict.get("auto_battle", false)) == true, "Persisted auto_battle must be true")
	assert(bool(combat_dict.get("pk_safety_lock", true)) == false, "Persisted pk_safety_lock must be false")
	assert(is_equal_approx(float(combat_dict.get("battle_speed", 1.0)), 2.0), "Persisted battle_speed must be 2.0")
	assert(int(combat_dict.get("auto_flee_threshold", 0)) == 15, "Persisted auto_flee_threshold must be 15")

	# Create a fresh window and verify load_settings()
	var win2: FightWindow = FightWindowScript.new()
	root.add_child(win2)
	win2.load_settings()

	assert(win2.is_auto_battle() == true, "Loaded auto_battle must be true")
	assert(win2.is_pk_safety_locked() == false, "Loaded pk_safety_lock must be false")
	assert(is_equal_approx(win2.get_battle_speed(), 2.0), "Loaded battle_speed must be 2.0")
	assert(win2.get_auto_flee_threshold() == 15, "Loaded auto_flee_threshold must be 15")

	win.queue_free()
	win2.queue_free()
	print("  [PASS] JSON persistence and key merging verified.")

func _test_4_battle_manager_forwarding_and_sync() -> void:
	print(">>> [TEST 4] Verifying bidirectional forwarding with BattleManager...")
	var bm: BattleManager = BattleManagerScript.new()
	root.add_child(bm)

	var win: FightWindow = FightWindowScript.new()
	root.add_child(win)

	win.set_battle_manager(bm)

	# 1. Forwarding from FightWindow to BattleManager
	win.set_auto_battle(true, false)
	assert(bm.is_auto_battle == true, "BattleManager is_auto_battle updated to true")

	win.set_pk_safety_lock(false, false)
	assert(bm.pk_safety_lock == false, "BattleManager pk_safety_lock updated to false")

	win.set_battle_speed(1.5, false)
	assert(is_equal_approx(bm.battle_speed_multiplier, 1.5), "BattleManager battle_speed_multiplier updated to 1.5")

	win.set_auto_flee_threshold(25, false)
	assert(bm.auto_flee_hp_threshold == 25, "BattleManager auto_flee_hp_threshold updated to 25")

	# 2. Reverse synchronization from BattleManager to FightWindow
	bm.set_auto_battle(false)
	assert(win.is_auto_battle() == false, "FightWindow auto_battle synced to false from BattleManager")
	assert(win.auto_battle_check.button_pressed == false, "AutoBattleCheck UI reflects false")

	bm.set_auto_battle(true)
	assert(win.is_auto_battle() == true, "FightWindow auto_battle synced to true from BattleManager")
	assert(win.auto_battle_check.button_pressed == true, "AutoBattleCheck UI reflects true")

	win.queue_free()
	bm.queue_free()
	print("  [PASS] Bidirectional forwarding with BattleManager verified.")

func _test_5_pk_safety_lock_behavior() -> void:
	print(">>> [TEST 5] Verifying PK Safety Lock combat protection in BattleManager...")
	var bm: BattleManager = BattleManagerScript.new()
	root.add_child(bm)

	# Set up 2 player allies (slot 0: Player 1, slot 1: Ally 2)
	bm.set_player_slot(0, {
		"name": "Hero",
		"hp": 200, "max_hp": 200, "sp": 100, "max_sp": 100, "spd": 30,
		"element": 1, "is_alive": true
	})
	bm.set_player_slot(1, {
		"name": "Cleric",
		"hp": 150, "max_hp": 150, "sp": 80, "max_sp": 80, "spd": 25,
		"element": 2, "is_alive": true
	})

	# Test 1: PK Safety Lock is ON (default true)
	bm.set_pk_safety_lock(true)
	var friendly_attack: Dictionary = {
		"type": BattleManager.ActionType.ATTACK,
		"slot": 0,
		"is_enemy": false,
		"target_slot": 1,
		"target_is_enemy": false
	}
	var res1: bool = bm.register_player_action(0, friendly_attack)
	assert(res1 == false, "Attacking friendly ally must be BLOCKED when PK safety lock is ON")

	# Test 2: Friendly support / heal skill is allowed even when PK lock is ON
	var friendly_heal: Dictionary = {
		"type": BattleManager.ActionType.SKILL,
		"slot": 0,
		"is_enemy": false,
		"target_slot": 1,
		"target_is_enemy": false,
		"skill": {
			"id": 101,
			"name": "Healing Water",
			"sp_cost": 20,
			"mechanism": BattleManager.SkillMechanism.ASSIST
		}
	}
	var res_heal: bool = bm.register_player_action(0, friendly_heal)
	assert(res_heal == true, "Support / Assist skill on ally must be ALLOWED when PK safety lock is ON")

	# Test 3: PK Safety Lock is OFF (player explicitly consents to PK)
	bm.queued_actions.clear()
	bm.set_pk_safety_lock(false)
	var res2: bool = bm.register_player_action(0, friendly_attack)
	assert(res2 == true, "Attacking friendly ally must be ALLOWED when PK safety lock is OFF")

	bm.queue_free()
	print("  [PASS] PK Safety Lock combat protection verified.")

func _test_6_auto_flee_threshold_behavior() -> void:
	print(">>> [TEST 6] Verifying Auto-Flee HP threshold auto-escape assignment...")
	
	# Case A: Player has 15% HP, threshold is 20% -> Auto-flee triggered!
	var bm_a: BattleManager = BattleManagerScript.new()
	root.add_child(bm_a)

	var reg_a: Array[Dictionary] = []
	bm_a.action_registered.connect(func(is_enemy: bool, slot: int, action: Dictionary) -> void:
		if not is_enemy and slot == 0:
			reg_a.append(action)
	)

	bm_a.set_enemy_slot(0, {
		"name": "Wild Boar",
		"hp": 100, "max_hp": 100, "sp": 0, "max_sp": 0, "spd": 15,
		"element": 1, "is_alive": true
	})
	bm_a.set_player_slot(0, {
		"name": "Injured Hero",
		"hp": 15, "max_hp": 100, "sp": 50, "max_sp": 50, "spd": 25,
		"element": 3, "is_alive": true
	})
	bm_a.set_auto_flee_hp_threshold(20)
	bm_a.auto_assign_player_actions()

	assert(reg_a.size() > 0, "Action for slot 0 must be registered in Case A")
	assert(int(reg_a[0].get("type", -1)) == BattleManager.ActionType.ESCAPE, "Action must be ESCAPE when HP% <= threshold")
	bm_a.queue_free()

	# Case B: Player has 50% HP, threshold is 20% -> Normal attack/skill triggered!
	var bm_b: BattleManager = BattleManagerScript.new()
	root.add_child(bm_b)

	var reg_b: Array[Dictionary] = []
	bm_b.action_registered.connect(func(is_enemy: bool, slot: int, action: Dictionary) -> void:
		if not is_enemy and slot == 0:
			reg_b.append(action)
	)

	bm_b.set_enemy_slot(0, {
		"name": "Wild Boar",
		"hp": 100, "max_hp": 100, "sp": 0, "max_sp": 0, "spd": 15,
		"element": 1, "is_alive": true
	})
	bm_b.set_player_slot(0, {
		"name": "Healthy Hero",
		"hp": 50, "max_hp": 100, "sp": 50, "max_sp": 50, "spd": 25,
		"element": 3, "is_alive": true
	})
	bm_b.set_auto_flee_hp_threshold(20)
	bm_b.auto_assign_player_actions()

	assert(reg_b.size() > 0, "Action for healthy slot 0 must be registered in Case B")
	assert(int(reg_b[0].get("type", -1)) != BattleManager.ActionType.ESCAPE, "Healthy character must NOT flee")
	assert(int(reg_b[0].get("type", -1)) in [BattleManager.ActionType.ATTACK, BattleManager.ActionType.SKILL], "Action must be ATTACK or SKILL")
	bm_b.queue_free()

	print("  [PASS] Auto-Flee HP threshold auto-escape assignment verified.")

func _test_7_battle_view_speed_integration() -> void:
	print(">>> [TEST 7] Verifying BattleView battle speed multiplier integration...")
	var bv: BattleView = BattleViewScript.new()
	var bm: BattleManager = BattleManagerScript.new()
	bv.battle_manager = bm

	assert(is_equal_approx(bv.battle_speed_multiplier, 1.0), "Initial BattleView speed must be 1.0")

	bv.set_battle_speed(1.5)
	assert(is_equal_approx(bv.battle_speed_multiplier, 1.5), "BattleView speed updated to 1.5")
	assert(is_equal_approx(bm.battle_speed_multiplier, 1.5), "Propagated to BattleManager speed 1.5")

	bv.set_battle_speed(2.0)
	assert(is_equal_approx(bv.battle_speed_multiplier, 2.0), "BattleView speed updated to 2.0")
	assert(is_equal_approx(bm.battle_speed_multiplier, 2.0), "Propagated to BattleManager speed 2.0")

	bm.queue_free()
	bv.queue_free()
	print("  [PASS] BattleView battle speed multiplier integration verified.")

func _test_8_window_open_close_toggling() -> void:
	print(">>> [TEST 8] Verifying window open, close, toggle, and close button actions...")
	var win: FightWindow = FightWindowScript.new()
	root.add_child(win)

	win.visible = false
	var closed_emitted: Array = [false]
	win.window_closed.connect(func() -> void:
		closed_emitted[0] = true
	)

	win.open_window()
	assert(win.visible == true, "open_window() must set visible to true")

	win.close_window()
	assert(win.visible == false, "close_window() must set visible to false")
	assert(closed_emitted[0] == true, "window_closed signal emitted")

	win.toggle_window()
	assert(win.visible == true, "toggle_window() on closed window must set visible to true")

	closed_emitted[0] = false
	win.toggle_window()
	assert(win.visible == false, "toggle_window() on open window must set visible to false")
	assert(closed_emitted[0] == true, "toggle_window() on open window emits window_closed")

	# Test close button trigger
	win.visible = true
	closed_emitted[0] = false
	win.close_button.pressed.emit()
	assert(win.visible == false, "Clicking close button must close window")
	assert(closed_emitted[0] == true, "Clicking close button must emit window_closed")

	win.queue_free()
	print("  [PASS] Window open, close, toggle, and close button actions verified.")
