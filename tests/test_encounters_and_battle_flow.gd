extends SceneTree

## Random encounters and the world-to-battle flow: enemy parties come from the real monster
## templates of the map, walking triggers fights, and victory rewards reach the character.

const EncounterSystemScript = preload("res://scripts/map/encounter_system.gd")

var _count: int = 0
var _failures: int = 0


func _init() -> void:
	_run()


func _check(ok: bool, label: String) -> void:
	_count += 1
	if ok:
		print("  [PASS] ", label)
	else:
		_failures += 1
		print("  [FAIL] ", label)


func _run() -> void:
	print("--- Encounters and Battle Flow Suite ---")
	await process_frame
	await _test_party_building()
	await _test_walking_trigger()
	await _test_world_battle_flow()
	print("\n--- %d TESTS, %d FAILED ---" % [_count, _failures])
	quit(1 if _failures > 0 else 0)


func _test_party_building() -> void:
	print(">>> Enemy party building")
	var system: Node = EncounterSystemScript.new()
	root.add_child(system)
	system.rng.seed = 7
	_check(system.has_monsters(60000), "Map 60000 (North Island Overland) has monsters")
	_check(not system.has_monsters(10001), "Ship Deck has no monsters")
	var party: Array = system.build_enemy_party(60000, 3)
	_check(party.size() == 3, "Requested party size is respected")
	var names_clean := true
	var levels: Array[int] = []
	for actor in party:
		names_clean = names_clean and not str(actor["name"]).contains("  ") and not str(actor["name"]).is_empty()
		levels.append(int(actor["level"]))
		_check(int(actor["template_id"]) > 0 and int(actor["max_hp"]) > 0, "Actor %s is a real template with HP" % actor["name"])
	_check(names_clean, "Template double spaces are cleaned from monster names")
	_check(levels.max() - levels.min() <= 4, "Monsters in one party have similar levels")
	_check(system.build_enemy_party(10001).is_empty(), "No party is built for a map without monsters")
	var capped: Array = system.build_enemy_party(60000, 99)
	_check(capped.size() <= EncounterSystemScript.MAX_ENEMIES, "Party size is capped")
	system.queue_free()


func _test_walking_trigger() -> void:
	print(">>> Walking trigger")
	var system: Node = EncounterSystemScript.new()
	root.add_child(system)
	system.rng.seed = 11
	system.set_map(60000)
	system._cooldown = 0.0
	var triggered: Array = []
	system.encounter_triggered.connect(func(enemies: Array) -> void: triggered.append(enemies))
	var pos := Vector2(100, 100)
	system.update_player_position(pos)
	var steps := 0
	while triggered.is_empty() and steps < 2000:
		pos += Vector2(60, 0)
		system.update_player_position(pos)
		steps += 1
	_check(not triggered.is_empty(), "Walking eventually triggers an encounter (%d steps)" % steps)
	var first_count := triggered.size()
	for i in 60:
		pos += Vector2(60, 0)
		system.update_player_position(pos)
	_check(triggered.size() == first_count, "The cooldown prevents back-to-back fights")
	system._cooldown = 0.0
	system.update_player_position(pos + Vector2(5000, 0))
	_check(triggered.size() == first_count, "A warp-sized jump is not counted as walking")
	system.enabled = false
	for i in 400:
		pos += Vector2(60, 0)
		system.update_player_position(pos)
	_check(triggered.size() == first_count, "A disabled system never triggers")
	system.queue_free()


func _test_world_battle_flow() -> void:
	print(">>> World to battle flow")
	var game_db := root.get_node_or_null("GameDatabase")
	if game_db:
		game_db.active_character = {"name": "Daniel", "role_id": 6, "element": "Fire", "level": 3}
	var map_view: Node = (load("res://scenes/world/map_view.tscn") as PackedScene).instantiate()
	root.add_child(map_view)
	for i in 30:
		await process_frame
	var hud = map_view.hud
	var gold_before: int = hud.get_gold()
	var enemies: Array = map_view.ensure_encounter_system().build_enemy_party(60000, 2)
	map_view.start_battle(enemies)
	await process_frame
	_check(map_view.is_battle_active(), "Battle overlay opens over the world")
	var manager = map_view._battle_view.battle_manager
	_check(manager.get_living_participants(true).size() == 2, "Both enemies are in the battle")
	_check(manager.get_living_participants(false).size() == 1, "The player's character is in the battle")
	if DisplayServer.get_name() != "headless":
		_check(map_view._battle_view.map_backdrop.visible, "The world snapshot is used as the battle backdrop")
	_check(map_view.player.is_movement_locked, "The player cannot walk during the battle")
	map_view.start_battle(enemies)
	_check(map_view._battle_layer.get_child_count() == 1, "A second battle cannot open on top of the first")

	manager.rewards = {"exp": 40, "gold": 55, "items": []}
	map_view._battle_outcome = "victory"
	map_view._battle_view.view_closed.emit()
	await process_frame
	_check(not map_view.is_battle_active(), "Closing the battle removes the overlay")
	_check(not map_view.player.is_movement_locked, "Walking is possible again after the battle")
	_check(hud.get_gold() == gold_before + 55, "Victory gold is added to the character")
	_check(map_view.encounter_system._cooldown > 0.0, "A grace period starts after the battle")
	map_view.queue_free()
