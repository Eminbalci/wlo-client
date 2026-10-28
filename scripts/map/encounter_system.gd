class_name EncounterSystem
extends Node

## Random encounters on maps that have monsters.
##
## The player accumulates walked distance; every STEP_DISTANCE there is a CHANCE of a fight. The
## enemy party is built from the real monster templates (Npc.dat, `is_monster` with the map in
## `maps_present`), so each map only produces the monsters that live there.

signal encounter_triggered(enemies: Array)

const STEP_DISTANCE: float = 110.0
const ENCOUNTER_CHANCE: float = 0.12
const COOLDOWN_SECONDS: float = 8.0
const MAX_ENEMIES: int = 4
## Npc.dat type of field monsters (other flagged templates are pets and townsfolk).
const HOSTILE_NPC_TYPE: int = 7
## Battle slots are filled front row first (slots 0..3), then back row.
const ENEMY_SLOT_ORDER: Array[int] = [0, 1, 4, 2, 5, 3, 6, 7]

var enabled: bool = true
var map_id: int = 0
var rng := RandomNumberGenerator.new()

var _walked: float = 0.0
var _last_position: Vector2 = Vector2.INF
var _cooldown: float = 0.0
var _monster_cache: Dictionary = {} # map_id -> Array of NpcRecord


func _ready() -> void:
	rng.randomize()


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown = maxf(0.0, _cooldown - delta)


## Call when the map changes: resets the distance counter and starts a short grace period.
func set_map(new_map_id: int) -> void:
	map_id = new_map_id
	_walked = 0.0
	_last_position = Vector2.INF
	_cooldown = COOLDOWN_SECONDS * 0.5


## Starts the post-battle grace period so a fight cannot immediately follow another.
func start_cooldown() -> void:
	_cooldown = COOLDOWN_SECONDS
	_walked = 0.0


func has_monsters(for_map_id: int) -> bool:
	return not _monsters_on_map(for_map_id).is_empty()


## Feed the player's world position every time it changes. `blocked` (dialogue, cutscene, battle)
## pauses the counter. Returns true when an encounter was triggered.
func update_player_position(world_position: Vector2, blocked: bool = false) -> bool:
	if _last_position == Vector2.INF:
		_last_position = world_position
		return false
	var step: float = world_position.distance_to(_last_position)
	_last_position = world_position
	if not enabled or blocked or _cooldown > 0.0 or step <= 0.0 or step > 400.0:
		return false # large jumps are warps, not walking
	_walked += step
	if _walked < STEP_DISTANCE:
		return false
	_walked = 0.0
	if rng.randf() > ENCOUNTER_CHANCE:
		return false
	var enemies := build_enemy_party(map_id)
	if enemies.is_empty():
		return false
	start_cooldown()
	encounter_triggered.emit(enemies)
	return true


## Builds 1..MAX_ENEMIES battle actors from monsters living on `for_map_id`. Monsters of a
## similar level appear together (a random monster picks the group's level band).
func build_enemy_party(for_map_id: int, forced_count: int = 0) -> Array:
	var pool: Array = _monsters_on_map(for_map_id)
	if pool.is_empty():
		return []
	var lead = pool[rng.randi_range(0, pool.size() - 1)]
	var band: Array = []
	for rec in pool:
		if absi(int(rec.level) - int(lead.level)) <= 2:
			band.append(rec)
	var count: int = forced_count if forced_count > 0 else rng.randi_range(1, MAX_ENEMIES)
	count = clampi(count, 1, MAX_ENEMIES)
	var party: Array = []
	for i in count:
		var rec = lead if i == 0 else band[rng.randi_range(0, band.size() - 1)]
		party.append(monster_to_actor(rec, ENEMY_SLOT_ORDER[i]))
	return party


## Converts an Npc.dat monster template into a BattleManager enemy actor.
func monster_to_actor(rec, slot: int = 0) -> Dictionary:
	var level: int = maxi(1, int(rec.level))
	var stats: Dictionary = rec.stats
	var max_hp: int = maxi(1, int(rec.max_hp))
	var max_sp: int = maxi(0, int(rec.max_sp))
	return {
		"slot": slot,
		"id": int(rec.template_id),
		"template_id": int(rec.template_id),
		"name": " ".join(str(rec.name).split(" ", false)), # templates carry double spaces
		"level": level,
		"hp": max_hp,
		"max_hp": max_hp,
		"sp": max_sp,
		"max_sp": max_sp,
		"atk": 8 + level * 3 + int(stats.get("str", 0)) * 2,
		"matk": 6 + level * 2 + int(stats.get("int", 0)) * 2,
		"def": 4 + level * 2 + int(stats.get("con", 0)),
		"mdef": 4 + level * 2 + int(stats.get("wis", 0)),
		"spd": 4 + level + int(stats.get("agi", 0)),
		"element": clampi(int(rec.element), 0, 4),
	}


func _monsters_on_map(for_map_id: int) -> Array:
	if _monster_cache.has(for_map_id):
		return _monster_cache[for_map_id]
	var found: Array = []
	var game_db := get_node_or_null("/root/GameDatabase")
	if game_db == null and Engine.get_main_loop() is SceneTree:
		game_db = (Engine.get_main_loop() as SceneTree).root.get_node_or_null("GameDatabase")
	if game_db != null and "npcs" in game_db:
		for rec in game_db.npcs.get_monsters():
			for spawn in rec.maps_present:
				if spawn is Dictionary and int(spawn.get("map_id", -1)) == for_map_id and int(rec.level) <= 60 and int(rec.npc_type) == HOSTILE_NPC_TYPE:
					found.append(rec)
					break
	_monster_cache[for_map_id] = found
	return found
