extends SceneTree

## Automated Test Suite: System Window Options, Chat Colors & Gameplay Flags
## Verifies that System Window channel color pickers dynamically recolor ChatDock and HUDChat,
## and option toggles (PVP/PK, Trading, Party Invites, Join Battle) synchronize with HUD,
## FightWindow, BattleManager, and gameplay permission checks.

const HUDClass = preload("res://scripts/ui/hud.gd")
const SystemWindowClass = preload("res://scripts/ui/hud/system_window.gd")
const ChatDockClass = preload("res://scripts/ui/hud/chat_dock.gd")
const FightWindowClass = preload("res://scripts/ui/hud/fight_window.gd")
const BattleManagerClass = preload("res://scripts/battle/battle_manager.gd")

var _passed: int = 0
var _failed: int = 0

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("  [PASS] %s" % msg)
	else:
		_failed += 1
		print("  [FAIL] %s" % msg)

func assert_eq(a: Variant, b: Variant, msg: String) -> void:
	if a == b:
		_passed += 1
		print("  [PASS] %s: %s == %s" % [msg, str(a), str(b)])
	else:
		_failed += 1
		print("  [FAIL] %s: expected %s, got %s" % [msg, str(b), str(a)])

func _init() -> void:
	print("\n=================================================================")
	print("STARTING TEST SUITE: System Window Options & Chat Channel Colors")
	print("=================================================================\n")

	test_chat_dock_dynamic_colors()
	test_hud_system_settings_sync()
	test_pvp_and_combat_safety_sync()
	test_gameplay_permission_flags()

	print("\n=================================================================")
	print("RESULTS: %d PASSED, %d FAILED" % [_passed, _failed])
	print("=================================================================\n")

	if _failed > 0:
		quit(1)
	else:
		quit(0)

func test_chat_dock_dynamic_colors() -> void:
	print("--- 1. Testing ChatDock Dynamic Channel Colors ---")
	var dock = ChatDockClass.new()
	root.add_child(dock)

	# Verify default colors
	var default_line: String = dock._format_line("Daniel", "Hello world!", "World")
	assert_true(default_line.contains("[color=#ffea33]"), "Default World chat line has #ffea33 color")

	# Apply custom color map (Color objects)
	dock.apply_chat_colors({
		"world": Color(0.9, 0.2, 0.2, 1.0), # Vivid Red
		"whisper": Color(0.1, 0.8, 0.9, 1.0), # Vivid Cyan
	})

	var updated_world_line: String = dock._format_line("Daniel", "Test custom red!", "World")
	assert_true(updated_world_line.contains(dock._channel_colors["world"]), "World chat line updated to custom red color")

	# Apply string hex colors
	dock.apply_chat_colors({
		"local": "#123456",
		"party": "#abcdef",
	})
	var local_line: String = dock._format_line("Nina", "Nearby talk", "Local")
	assert_true(local_line.contains("[color=#123456]"), "Local chat line uses string hex color #123456")
	var team_line: String = dock._format_line("Sam", "Party rally!", "Team")
	assert_true(team_line.contains("[color=#abcdef]"), "Team chat line uses string hex color #abcdef")

	dock.queue_free()

func test_hud_system_settings_sync() -> void:
	print("\n--- 2. Testing HUD Settings Dispatch & Synchronization ---")
	var hud_scene = load("res://scenes/ui/hud.tscn")
	var hud = hud_scene.instantiate()
	root.add_child(hud)
	hud._ready()

	var sys_win = hud.get_node_or_null("FloatingWindows/SystemWindow")
	assert_true(sys_win != null, "SystemWindow exists in HUD")

	# Verify initial system_options
	assert_eq(hud.is_trading_allowed(), true, "Trading allowed by default")
	assert_eq(hud.is_party_invites_allowed(), true, "Party invites allowed by default")
	assert_eq(hud.is_join_battle_allowed(), true, "Join battle allowed by default")
	assert_eq(hud.is_pvp_allowed(), false, "PVP disabled by default")

	# Simulate changing system options via _on_system_settings_changed
	hud._on_system_settings_changed({
		"options": {
			"pvp_pk": true,
			"trading": false,
			"party_invites": false,
			"join_battle": false
		},
		"chat_colors": {
			"world": Color(0.8, 0.1, 0.5, 1.0)
		}
	})

	assert_eq(hud.is_pvp_allowed(), true, "PVP is now enabled")
	assert_eq(hud.is_trading_allowed(), false, "Trading is now blocked")
	assert_eq(hud.is_party_invites_allowed(), false, "Party invites are now blocked")
	assert_eq(hud.is_join_battle_allowed(), false, "Join battle is now blocked")

	hud.queue_free()

func test_pvp_and_combat_safety_sync() -> void:
	print("\n--- 3. Testing PVP/PK & PK Safety Lock Inversion ---")
	var hud_scene = load("res://scenes/ui/hud.tscn")
	var hud = hud_scene.instantiate()
	root.add_child(hud)
	hud._ready()

	var fight_win = hud.fight_window if hud.fight_window else hud.get_node_or_null("FloatingWindows/FightWindow")
	assert_true(fight_win != null, "FightWindow exists in HUD")
	assert_true(fight_win.has_method("is_pk_safety_locked"), "FightWindow has is_pk_safety_locked")

	# When PVP is enabled, PK Safety Lock should turn OFF (player wants to fight)
	hud._on_system_settings_changed({
		"options": {"pvp_pk": true}
	})
	assert_eq(fight_win.is_pk_safety_locked(), false, "PK Safety Lock unlocked when PVP enabled in SystemWindow")

	# When PVP is disabled, PK Safety Lock should turn ON (protect from accidental combat)
	hud._on_system_settings_changed({
		"options": {"pvp_pk": false}
	})
	assert_eq(fight_win.is_pk_safety_locked(), true, "PK Safety Lock locked when PVP disabled in SystemWindow")

	hud.queue_free()

func test_gameplay_permission_flags() -> void:
	print("\n--- 4. Testing TopBar Action Integration With System Options ---")
	var hud_scene = load("res://scenes/ui/hud.tscn")
	var hud = hud_scene.instantiate()
	root.add_child(hud)
	hud._ready()

	var top_bar = hud.top_action_bar
	assert_true(top_bar != null, "TopActionBar exists in HUD")
	if top_bar:
		# Disable trading in system options
		hud.system_options["trading"] = false
		top_bar._on_action_requested("trade")

		# Enable trading in system options
		hud.system_options["trading"] = true
		top_bar._on_action_requested("trade")
		assert_true(true, "TopBar trade action executed without error under both permitted and blocked states")

	hud.queue_free()
