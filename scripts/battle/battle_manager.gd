class_name BattleManager
extends Node

## Wonderland Online - Turn-Based Battle Manager.
## Logic coordinator governing authentic 4x2 Player vs 4x2 Enemy combat,
## turn countdown timing (20s), SPD-descending action queues, 4-element wheel (+25%/-25%),
## physical/magical damage formulas, capture/escape mechanics, and victory/defeat progression.

# --- Signals ---
signal battle_started
signal turn_started(turn: int)
signal turn_timer_tick(time_remaining: float)
signal turn_timer_expired
signal action_registered(is_enemy: bool, slot: int, action: Dictionary)
signal all_actions_ready
signal turn_order_calculated(order: Array[Dictionary])
signal round_execution_started(queue: Array[Dictionary])
signal action_executed(result: Dictionary)
signal actor_damaged(is_enemy: bool, slot: int, damage: int, is_critical: bool, current_hp: int)
signal actor_healed(is_enemy: bool, slot: int, amount: int, current_hp: int)
signal actor_defeated(is_enemy: bool, slot: int)
signal actor_escaped(is_enemy: bool, slot: int, success: bool)
signal actor_caught(is_enemy: bool, slot: int, success: bool, pet_data: Dictionary)
signal battle_won(rewards: Dictionary)
signal battle_lost
signal battle_escaped
signal battle_finished(result: Dictionary)
signal auto_battle_changed(enabled: bool)
signal combat_settings_updated(settings: Dictionary)

# --- Constants ---
const TOTAL_SLOTS: int = 8
const FRONT_ROW_COUNT: int = 4
const BACK_ROW_COUNT: int = 4
const TURN_TIME_LIMIT: float = 20.0 # Authentic WLO 20-second turn limit

enum Element {
	NONE = 0,
	EARTH = 1,
	WATER = 2,
	FIRE = 3,
	WIND = 4
}

const ELEMENT_NAMES: Array[String] = [
	"None",
	"Earth",
	"Water",
	"Fire",
	"Wind"
]

const ELEMENT_COLORS: Array[Color] = [
	Color(0.7, 0.7, 0.7, 1.0),       # None: Grey
	Color(0.85, 0.65, 0.25, 1.0),    # Earth: Ochre / Yellow
	Color(0.25, 0.65, 0.95, 1.0),    # Water: Cyan / Blue
	Color(0.95, 0.35, 0.25, 1.0),    # Fire: Crimson / Red
	Color(0.35, 0.95, 0.45, 1.0)     # Wind: Emerald / Green
]

enum BattleState {
	IDLE = 0,
	INPUT_WAIT = 1,
	ROUND_EXECUTION = 2,
	VICTORY = 3,
	DEFEAT = 4,
	ESCAPED = 5
}

enum ActionType {
	ATTACK = 0,
	DEFEND = 1,
	SKILL = 2,
	ITEM = 3,
	CATCH = 4,
	ESCAPE = 5,
	AUTO = 6
}

enum SkillMechanism {
	PHYSICAL = 0,
	MAGIC = 1,
	ASSIST = 2,
	STATUS = 3,
	SPECIAL = 4
}

enum TargetScope {
	SINGLE = 1,
	ROW = 2,
	COLUMN = 3,
	CROSS = 6,
	ALL = 8
}

# --- State Variables ---
var player_slots: Array[Dictionary] = []
var enemy_slots: Array[Dictionary] = []
var loot_table: Array[Dictionary] = []

var current_state: int = BattleState.IDLE
var current_turn: int = 0
var turn_timer: float = TURN_TIME_LIMIT
var timer_active: bool = false
var is_auto_battle: bool = false
var battle_speed_multiplier: float = 1.0
var pk_safety_lock: bool = true
var auto_flee_hp_threshold: int = 0

var queued_actions: Dictionary = {} # Keyed by actor key ("p_0", "e_1")
var round_results: Array[Dictionary] = []
var battle_log: Array[String] = []

var rewards: Dictionary = {
	"exp": 0,
	"gold": 0,
	"items": []
}

var last_round_execution: Array[Dictionary] = []
var deterministic_rolls: bool = false # When true, rng checks follow fixed thresholds for testing

# --- Lifecycle Methods ---

func _init() -> void:
	_init_slots()

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if timer_active and current_state == BattleState.INPUT_WAIT:
		turn_timer -= delta
		turn_timer_tick.emit(maxf(0.0, turn_timer))
		if turn_timer <= 0.0:
			turn_timer = 0.0
			timer_active = false
			turn_timer_expired.emit()
			_on_turn_timer_expired()

# --- Initialization & Slot Setup ---

func _init_slots() -> void:
	player_slots.clear()
	enemy_slots.clear()
	for i in range(TOTAL_SLOTS):
		player_slots.append({})
		enemy_slots.append({})

func initialize_battle(p_players: Array[Dictionary], p_enemies: Array[Dictionary], p_loot: Array[Dictionary] = []) -> void:
	_init_slots()
	queued_actions.clear()
	battle_log.clear()
	current_turn = 0
	current_state = BattleState.IDLE
	rewards = {"exp": 0, "gold": 0, "items": []}
	loot_table = p_loot.duplicate(true)

	for i in range(mini(p_players.size(), TOTAL_SLOTS)):
		if not p_players[i].is_empty():
			set_player_slot(i, p_players[i])

	for i in range(mini(p_enemies.size(), TOTAL_SLOTS)):
		if not p_enemies[i].is_empty():
			set_enemy_slot(i, p_enemies[i])

func set_player_slot(slot: int, data: Dictionary) -> bool:
	if slot < 0 or slot >= TOTAL_SLOTS:
		push_warning("BattleManager: Player slot %d out of range [0..%d]" % [slot, TOTAL_SLOTS - 1])
		return false
	if data.is_empty():
		player_slots[slot] = {}
		return true

	var sanitized: Dictionary = _sanitize_actor_data(data, false, slot)
	player_slots[slot] = sanitized
	return true

func set_enemy_slot(slot: int, data: Dictionary) -> bool:
	if slot < 0 or slot >= TOTAL_SLOTS:
		push_warning("BattleManager: Enemy slot %d out of range [0..%d]" % [slot, TOTAL_SLOTS - 1])
		return false
	if data.is_empty():
		enemy_slots[slot] = {}
		return true

	var sanitized: Dictionary = _sanitize_actor_data(data, true, slot)
	enemy_slots[slot] = sanitized
	return true

func get_participant(is_enemy: bool, slot: int) -> Dictionary:
	if slot < 0 or slot >= TOTAL_SLOTS:
		return {}
	return (enemy_slots if is_enemy else player_slots)[slot]

func get_living_participants(is_enemy: bool) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var pool: Array[Dictionary] = enemy_slots if is_enemy else player_slots
	for slot in range(TOTAL_SLOTS):
		var p: Dictionary = pool[slot]
		if not p.is_empty() and bool(p.get("is_alive", false)):
			result.append(p)
	return result

func _sanitize_actor_data(raw: Dictionary, is_enemy: bool, slot: int) -> Dictionary:
	var actor: Dictionary = raw.duplicate(true)
	actor["is_enemy"] = is_enemy
	actor["slot"] = slot
	actor["row"] = "Front" if slot < FRONT_ROW_COUNT else "Back"
	
	actor["id"] = int(actor.get("id", actor.get("monster_id", slot + (100 if is_enemy else 1))))
	actor["name"] = String(actor.get("name", actor.get("monster_name", "Enemy %d" % slot if is_enemy else "Player %d" % slot)))
	actor["level"] = clampi(int(actor.get("level", 1)), 1, 200)
	
	var max_hp: int = maxi(1, int(actor.get("max_hp", actor.get("hp", 100))))
	actor["max_hp"] = max_hp
	actor["hp"] = clampi(int(actor.get("hp", max_hp)), 1, max_hp)
	
	var max_sp: int = maxi(0, int(actor.get("max_sp", actor.get("sp", 50))))
	actor["max_sp"] = max_sp
	actor["sp"] = clampi(int(actor.get("sp", max_sp)), 0, max_sp)
	
	actor["atk"] = maxi(1, int(actor.get("atk", actor.get("level", 1) * 3 + 12)))
	actor["matk"] = maxi(1, int(actor.get("matk", actor.get("level", 1) * 2 + 10)))
	actor["def"] = maxi(0, int(actor.get("def", actor.get("level", 1) * 2 + 6)))
	actor["mdef"] = maxi(0, int(actor.get("mdef", actor.get("level", 1) * 2 + 6)))
	actor["spd"] = maxi(1, int(actor.get("spd", 10)))
	actor["element"] = clampi(int(actor.get("element", Element.NONE)), 0, 4)
	
	actor["is_boss"] = bool(actor.get("is_boss", false))
	actor["is_alive"] = true
	actor["is_defending"] = false
	actor["jmp_name"] = String(actor.get("jmp_name", "monster.jmp" if is_enemy else "role.jmp"))
	actor["role_id"] = int(actor.get("role_id", 0))
	
	# Skills loadout
	if not actor.has("skills") or not (actor["skills"] is Array):
		actor["skills"] = _get_default_skills(actor)
	
	# Consumable items
	if not actor.has("items") or not (actor["items"] is Array):
		actor["items"] = []
		
	return actor

func _get_default_skills(actor: Dictionary) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	# Basic Attack (Skill ID 10001)
	list.append({
		"id": 10001,
		"name": "Normal Attack",
		"sp_cost": 0,
		"element": Element.NONE,
		"skill_type": SkillMechanism.PHYSICAL,
		"base_damage": 25,
		"multiplier_1": 1.0,
		"multiplier_2": 0.0,
		"target_scope": TargetScope.SINGLE
	})
	
	# Elemental Strike for actors with an element
	var elem: int = int(actor.get("element", Element.NONE))
	if elem != Element.NONE:
		var skill_names: Dictionary = {
			Element.EARTH: "Rock Spike",
			Element.WATER: "Ice Lance",
			Element.FIRE: "Flame Strike",
			Element.WIND: "Gale Slash"
		}
		list.append({
			"id": 20000 + elem,
			"name": skill_names.get(elem, "Elemental Strike"),
			"sp_cost": 15,
			"element": elem,
			"skill_type": SkillMechanism.MAGIC if elem in [Element.WATER, Element.FIRE] else SkillMechanism.PHYSICAL,
			"base_damage": 55,
			"multiplier_1": 1.25,
			"multiplier_2": 0.0,
			"target_scope": TargetScope.SINGLE
		})
	return list

# --- Turn Progression & Timing ---

func start_battle() -> void:
	current_turn = 0
	current_state = BattleState.IDLE
	battle_started.emit()
	start_turn()

func start_turn() -> void:
	current_turn += 1
	current_state = BattleState.INPUT_WAIT
	turn_timer = TURN_TIME_LIMIT
	timer_active = true
	queued_actions.clear()
	
	# Reset round defensive stances
	for slot in range(TOTAL_SLOTS):
		if not player_slots[slot].is_empty():
			player_slots[slot]["is_defending"] = false
		if not enemy_slots[slot].is_empty():
			enemy_slots[slot]["is_defending"] = false
			
	turn_started.emit(current_turn)
	
	# If auto-battle is enabled, populate player actions automatically
	if is_auto_battle:
		auto_assign_player_actions()

func _on_turn_timer_expired() -> void:
	# Default any uncommitted player to Defend or Basic Attack
	for slot in range(TOTAL_SLOTS):
		var p: Dictionary = player_slots[slot]
		if not p.is_empty() and bool(p.get("is_alive", false)):
			var key: String = "p_%d" % slot
			if not queued_actions.has(key):
				register_player_action(slot, {
					"type": ActionType.DEFEND,
					"slot": slot,
					"is_enemy": false,
					"target_slot": slot,
					"target_is_enemy": false
				})
	check_and_trigger_execution()

func set_auto_battle(enabled: bool) -> void:
	if is_auto_battle != enabled:
		is_auto_battle = enabled
		auto_battle_changed.emit(is_auto_battle)
		combat_settings_updated.emit(get_combat_settings())
		if is_auto_battle and current_state == BattleState.INPUT_WAIT:
			auto_assign_player_actions()

func set_pk_safety_lock(enabled: bool) -> void:
	pk_safety_lock = enabled
	combat_settings_updated.emit(get_combat_settings())

func set_battle_speed(speed: float) -> void:
	battle_speed_multiplier = maxf(speed, 0.1)
	combat_settings_updated.emit(get_combat_settings())

func set_auto_flee_hp_threshold(val: int) -> void:
	auto_flee_hp_threshold = clampi(val, 0, 100)
	combat_settings_updated.emit(get_combat_settings())

func get_combat_settings() -> Dictionary:
	return {
		"auto_battle": is_auto_battle,
		"pk_safety_lock": pk_safety_lock,
		"battle_speed": battle_speed_multiplier,
		"auto_flee_threshold": auto_flee_hp_threshold
	}

func apply_combat_settings(settings: Dictionary) -> void:
	if settings.has("auto_battle"):
		var ab: bool = bool(settings["auto_battle"])
		if is_auto_battle != ab:
			is_auto_battle = ab
			auto_battle_changed.emit(is_auto_battle)
	if settings.has("pk_safety_lock"):
		pk_safety_lock = bool(settings["pk_safety_lock"])
	if settings.has("battle_speed"):
		battle_speed_multiplier = maxf(float(settings["battle_speed"]), 0.1)
	if settings.has("auto_flee_threshold"):
		auto_flee_hp_threshold = clampi(int(settings["auto_flee_threshold"]), 0, 100)
	combat_settings_updated.emit(get_combat_settings())

func auto_assign_player_actions() -> void:
	var enemies: Array[Dictionary] = get_living_participants(true)
	if enemies.is_empty():
		return
		
	# Select lowest HP enemy as target
	var target_enemy: Dictionary = enemies[0]
	for e in enemies:
		if int(e.get("hp", 0)) < int(target_enemy.get("hp", 0)):
			target_enemy = e

	for slot in range(TOTAL_SLOTS):
		var p: Dictionary = player_slots[slot]
		if not p.is_empty() and bool(p.get("is_alive", false)):
			var key: String = "p_%d" % slot
			if not queued_actions.has(key):
				# Check auto-flee HP threshold
				if auto_flee_hp_threshold > 0:
					var cur_hp: int = int(p.get("hp", 0))
					var max_hp: int = int(p.get("max_hp", 1))
					if max_hp <= 0:
						max_hp = 1
					var hp_pct: float = (float(cur_hp) / float(max_hp)) * 100.0
					if hp_pct <= float(auto_flee_hp_threshold):
						register_player_action(slot, {
							"type": ActionType.ESCAPE,
							"slot": slot,
							"is_enemy": false
						})
						continue

				# Prefer elemental skill if SP allows, else Normal Attack
				var chosen_skill: Dictionary = {}
				var skills: Array = p.get("skills", [])
				for s in skills:
					if int(s.get("sp_cost", 0)) <= int(p.get("sp", 0)) and int(s.get("sp_cost", 0)) > 0:
						chosen_skill = s
						break
				
				if not chosen_skill.is_empty():
					register_player_action(slot, {
						"type": ActionType.SKILL,
						"slot": slot,
						"is_enemy": false,
						"skill": chosen_skill,
						"target_slot": int(target_enemy.get("slot", 0)),
						"target_is_enemy": true
					})
				else:
					register_player_action(slot, {
						"type": ActionType.ATTACK,
						"slot": slot,
						"is_enemy": false,
						"target_slot": int(target_enemy.get("slot", 0)),
						"target_is_enemy": true
					})

# --- Action Registration ---

func register_player_action(slot: int, action: Dictionary) -> bool:
	if slot < 0 or slot >= TOTAL_SLOTS:
		return false
	var actor: Dictionary = player_slots[slot]
	if actor.is_empty() or not bool(actor.get("is_alive", false)):
		return false

	# PK Safety Lock check: prevent targeting friendly allies with attacks
	if pk_safety_lock:
		var act_type: int = int(action.get("type", -1))
		var tgt_is_enemy: bool = bool(action.get("target_is_enemy", true))
		if not tgt_is_enemy and (act_type == ActionType.ATTACK or act_type == ActionType.SKILL):
			var sk: Dictionary = action.get("skill", {})
			var mechanism: int = int(sk.get("mechanism", -1))
			if act_type == ActionType.ATTACK or (sk.is_empty() or mechanism != SkillMechanism.ASSIST):
				_log("PK Safety Lock: Action blocked on friendly target.")
				return false
		
	var sanitized_action: Dictionary = action.duplicate(true)
	sanitized_action["is_enemy"] = false
	sanitized_action["slot"] = slot
	sanitized_action["user_name"] = actor.get("name", "Player")
	
	var key: String = "p_%d" % slot
	queued_actions[key] = sanitized_action
	action_registered.emit(false, slot, sanitized_action)
	
	check_and_trigger_execution()
	return true

func generate_enemy_ai_actions() -> void:
	var living_players: Array[Dictionary] = get_living_participants(false)
	if living_players.is_empty():
		return
		
	for slot in range(TOTAL_SLOTS):
		var enemy: Dictionary = enemy_slots[slot]
		if enemy.is_empty() or not bool(enemy.get("is_alive", false)):
			continue
			
		var key: String = "e_%d" % slot
		if queued_actions.has(key):
			continue
			
		# AI Target Selection: Random living player or Front-row bias
		var target_player: Dictionary = living_players[randi() % living_players.size()]
		# Bosses favor lowest HP player
		if bool(enemy.get("is_boss", false)):
			for lp in living_players:
				if int(lp.get("hp", 0)) < int(target_player.get("hp", 0)):
					target_player = lp
					
		# 35% chance to use elemental skill if available and SP sufficient
		var skills: Array = enemy.get("skills", [])
		var chosen_skill: Dictionary = {}
		if skills.size() > 1 and (randf() < 0.35 or deterministic_rolls):
			var candidate: Dictionary = skills[1]
			if int(candidate.get("sp_cost", 0)) <= int(enemy.get("sp", 0)):
				chosen_skill = candidate
				
		if not chosen_skill.is_empty():
			queued_actions[key] = {
				"type": ActionType.SKILL,
				"is_enemy": true,
				"slot": slot,
				"user_name": enemy.get("name", "Enemy"),
				"skill": chosen_skill,
				"target_slot": int(target_player.get("slot", 0)),
				"target_is_enemy": false
			}
		else:
			queued_actions[key] = {
				"type": ActionType.ATTACK,
				"is_enemy": true,
				"slot": slot,
				"user_name": enemy.get("name", "Enemy"),
				"target_slot": int(target_player.get("slot", 0)),
				"target_is_enemy": false
			}
		action_registered.emit(true, slot, queued_actions[key])

func are_all_player_actions_ready() -> bool:
	for slot in range(TOTAL_SLOTS):
		var p: Dictionary = player_slots[slot]
		if not p.is_empty() and bool(p.get("is_alive", false)):
			var key: String = "p_%d" % slot
			if not queued_actions.has(key):
				return false
	return true

func check_and_trigger_execution() -> void:
	if are_all_player_actions_ready():
		timer_active = false
		generate_enemy_ai_actions()
		all_actions_ready.emit()
		execute_round()

# --- Turn Order & SPD Sorting ---

func calculate_turn_order() -> Array[Dictionary]:
	var order: Array[Dictionary] = []
	
	for key in queued_actions.keys():
		var action: Dictionary = queued_actions[key]
		var is_enemy: bool = bool(action.get("is_enemy", false))
		var slot: int = int(action.get("slot", 0))
		var actor: Dictionary = get_participant(is_enemy, slot)
		if actor.is_empty() or not bool(actor.get("is_alive", false)):
			continue
			
		var entry: Dictionary = {
			"action": action,
			"is_enemy": is_enemy,
			"slot": slot,
			"spd": int(actor.get("spd", 10)),
			"name": String(actor.get("name", "")),
			"level": int(actor.get("level", 1))
		}
		order.append(entry)
		
	# Sort descending by SPD:
	# Primary: spd descending
	# Tie-breaker 1: player precedes enemy
	# Tie-breaker 2: lower slot index precedes higher slot index
	order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var spd_a: int = int(a.get("spd", 10))
		var spd_b: int = int(b.get("spd", 10))
		if spd_a != spd_b:
			return spd_a > spd_b
		var is_e_a: bool = bool(a.get("is_enemy", false))
		var is_e_b: bool = bool(b.get("is_enemy", false))
		if is_e_a != is_e_b:
			return not is_e_a # Player first
		return int(a.get("slot", 0)) < int(b.get("slot", 0))
	)
	
	turn_order_calculated.emit(order)
	return order

# --- Round Execution Pipeline ---

func execute_round() -> Array[Dictionary]:
	current_state = BattleState.ROUND_EXECUTION
	var order: Array[Dictionary] = calculate_turn_order()
	round_execution_started.emit(order)
	last_round_execution.clear()
	
	for entry in order:
		var action: Dictionary = entry.get("action", {})
		var is_enemy: bool = bool(entry.get("is_enemy", false))
		var slot: int = int(entry.get("slot", 0))
		
		# Verify actor is still alive
		var actor: Dictionary = get_participant(is_enemy, slot)
		if actor.is_empty() or not bool(actor.get("is_alive", false)):
			continue
			
		# Check if battle is already concluded
		var check_state: String = check_battle_end_conditions()
		if check_state != "none":
			break
			
		# Resolve action
		var res: Dictionary = execute_single_action(action)
		last_round_execution.append(res)
		action_executed.emit(res)
		
		# Re-verify end conditions after each hit
		check_state = check_battle_end_conditions()
		if check_state != "none":
			_handle_battle_end(check_state)
			return last_round_execution
			
	# Round complete, check victory/defeat or start next turn
	var end_state: String = check_battle_end_conditions()
	if end_state != "none":
		_handle_battle_end(end_state)
	else:
		start_turn()
		
	return last_round_execution

func execute_single_action(action: Dictionary) -> Dictionary:
	var action_type: int = int(action.get("type", ActionType.ATTACK))
	var is_enemy: bool = bool(action.get("is_enemy", false))
	var slot: int = int(action.get("slot", 0))
	var actor: Dictionary = get_participant(is_enemy, slot)
	
	var result: Dictionary = {
		"action_type": action_type,
		"user_is_enemy": is_enemy,
		"user_slot": slot,
		"user_name": String(actor.get("name", "Actor")),
		"success": true,
		"damage": 0,
		"heal": 0,
		"is_critical": false,
		"is_guarded": false,
		"element_mult": 1.0,
		"target_defeated": false,
		"target_slot": int(action.get("target_slot", -1)),
		"target_is_enemy": bool(action.get("target_is_enemy", not is_enemy)),
		"message": ""
	}
	
	match action_type:
		ActionType.DEFEND:
			actor["is_defending"] = true
			result["message"] = "%s braces into a defensive stance!" % actor.get("name", "Actor")
			_log(result["message"])
			
		ActionType.ATTACK:
			_resolve_attack_action(actor, action, result)
			
		ActionType.SKILL:
			_resolve_skill_action(actor, action, result)
			
		ActionType.ITEM:
			_resolve_item_action(actor, action, result)
			
		ActionType.CATCH:
			_resolve_catch_action(actor, action, result)
			
		ActionType.ESCAPE:
			_resolve_escape_action(actor, action, result)
			
		_:
			result["success"] = false
			result["message"] = "%s passes their turn." % actor.get("name", "Actor")
			
	return result

func _resolve_attack_action(actor: Dictionary, action: Dictionary, result: Dictionary) -> void:
	var target_is_enemy: bool = bool(action.get("target_is_enemy", not bool(actor.get("is_enemy", false))))
	var target_slot: int = int(action.get("target_slot", 0))
	var target: Dictionary = get_participant(target_is_enemy, target_slot)
	
	# Retarget if target is dead
	if target.is_empty() or not bool(target.get("is_alive", false)):
		var living: Array[Dictionary] = get_living_participants(target_is_enemy)
		if living.is_empty():
			result["success"] = false
			return
		target = living[0]
		target_slot = int(target.get("slot", 0))
		result["target_slot"] = target_slot
		action["target_slot"] = target_slot
		
	var dmg_data: Dictionary = calculate_damage(actor, target, action)
	var final_damage: int = int(dmg_data.get("damage", 1))
	var is_crit: bool = bool(dmg_data.get("is_critical", false))
	var is_guard: bool = bool(dmg_data.get("is_guarded", false))
	var elem_mult: float = float(dmg_data.get("element_multiplier", 1.0))
	
	result["damage"] = final_damage
	result["is_critical"] = is_crit
	result["is_guarded"] = is_guard
	result["element_mult"] = elem_mult
	result["target_name"] = String(target.get("name", "Target"))
	result["animation_id"] = int(action.get("animation_id", 60022))
	
	# Apply damage
	var new_hp: int = maxi(0, int(target.get("hp", 0)) - final_damage)
	target["hp"] = new_hp
	actor_damaged.emit(target_is_enemy, target_slot, final_damage, is_crit, new_hp)
	
	if new_hp <= 0:
		target["is_alive"] = false
		result["target_defeated"] = true
		actor_defeated.emit(target_is_enemy, target_slot)
		result["message"] = "%s attacked %s for %d damage! %s was defeated!" % [
			actor.get("name"), target.get("name"), final_damage, target.get("name")
		]
	else:
		result["message"] = "%s attacked %s for %d damage!%s%s" % [
			actor.get("name"), target.get("name"), final_damage,
			" (CRITICAL!)" if is_crit else "",
			" (GUARDED!)" if is_guard else ""
		]
	_log(result["message"])

func _resolve_skill_action(actor: Dictionary, action: Dictionary, result: Dictionary) -> void:
	var skill: Dictionary = action.get("skill", {})
	if skill.is_empty():
		_resolve_attack_action(actor, action, result)
		return
		
	var sp_cost: int = int(skill.get("sp_cost", 0))
	if int(actor.get("sp", 0)) < sp_cost:
		# Insufficient SP fallback to attack
		result["message"] = "%s lacks SP for %s and performs normal attack!" % [actor.get("name"), skill.get("name")]
		_resolve_attack_action(actor, action, result)
		return
		
	# Deduct SP
	actor["sp"] = maxi(0, int(actor.get("sp", 0)) - sp_cost)
	result["skill"] = skill
	result["skill_name"] = String(skill.get("name", "Skill"))
	result["animation_id"] = int(skill.get("animation_id", 0))
	
	var is_heal: bool = int(skill.get("skill_type", 0)) == SkillMechanism.ASSIST and int(skill.get("base_damage", 0)) < 0
	var target_is_enemy: bool = bool(action.get("target_is_enemy", not bool(actor.get("is_enemy", false))))
	if is_heal:
		# Heals target friendly actors
		target_is_enemy = bool(actor.get("is_enemy", false))
		
	var target_slot: int = int(action.get("target_slot", 0))
	var target: Dictionary = get_participant(target_is_enemy, target_slot)
	
	if target.is_empty() or not bool(target.get("is_alive", false)):
		var living: Array[Dictionary] = get_living_participants(target_is_enemy)
		if living.is_empty():
			result["success"] = false
			return
		target = living[0]
		target_slot = int(target.get("slot", 0))
		result["target_slot"] = target_slot
		action["target_slot"] = target_slot
		
	result["target_name"] = String(target.get("name", "Target"))
	
	if is_heal:
		# Healing Formula
		var heal_base: int = absi(int(skill.get("base_damage", -50)))
		var matk_bonus: int = int(float(actor.get("matk", 10)) * 0.6)
		var heal_amount: int = heal_base + matk_bonus
		var current_hp: int = int(target.get("hp", 0))
		var max_hp: int = int(target.get("max_hp", 100))
		var new_hp: int = mini(max_hp, current_hp + heal_amount)
		target["hp"] = new_hp
		var actual_heal: int = new_hp - current_hp
		
		result["heal"] = actual_heal
		actor_healed.emit(target_is_enemy, target_slot, actual_heal, new_hp)
		result["message"] = "%s cast %s on %s, healing %d HP!" % [
			actor.get("name"), skill.get("name"), target.get("name"), actual_heal
		]
	else:
		# Offensive Skill Formula
		var dmg_data: Dictionary = calculate_damage(actor, target, action)
		var final_damage: int = int(dmg_data.get("damage", 1))
		var is_crit: bool = bool(dmg_data.get("is_critical", false))
		var is_guard: bool = bool(dmg_data.get("is_guarded", false))
		var elem_mult: float = float(dmg_data.get("element_multiplier", 1.0))
		
		result["damage"] = final_damage
		result["is_critical"] = is_crit
		result["is_guarded"] = is_guard
		result["element_mult"] = elem_mult
		
		var new_hp: int = maxi(0, int(target.get("hp", 0)) - final_damage)
		target["hp"] = new_hp
		actor_damaged.emit(target_is_enemy, target_slot, final_damage, is_crit, new_hp)
		
		if new_hp <= 0:
			target["is_alive"] = false
			result["target_defeated"] = true
			actor_defeated.emit(target_is_enemy, target_slot)
			result["message"] = "%s unleashed %s on %s for %d damage! %s was defeated!" % [
				actor.get("name"), skill.get("name"), target.get("name"), final_damage, target.get("name")
			]
		else:
			result["message"] = "%s unleashed %s on %s for %d damage!%s" % [
				actor.get("name"), skill.get("name"), target.get("name"), final_damage,
				" (CRITICAL!)" if is_crit else ""
			]
	_log(result["message"])

func _resolve_item_action(actor: Dictionary, action: Dictionary, result: Dictionary) -> void:
	var item: Dictionary = action.get("item", {
		"id": 1001,
		"name": "Healing Herb",
		"heal_hp": 80,
		"heal_sp": 0
	})
	var target_is_enemy: bool = bool(action.get("target_is_enemy", bool(actor.get("is_enemy", false))))
	var target_slot: int = int(action.get("target_slot", actor.get("slot", 0)))
	var target: Dictionary = get_participant(target_is_enemy, target_slot)
	
	if target.is_empty() or not bool(target.get("is_alive", false)):
		result["success"] = false
		return
		
	var hp_gain: int = int(item.get("heal_hp", 0))
	var sp_gain: int = int(item.get("heal_sp", 0))
	
	if hp_gain > 0:
		var cur_hp: int = int(target.get("hp", 0))
		var max_hp: int = int(target.get("max_hp", 100))
		target["hp"] = mini(max_hp, cur_hp + hp_gain)
		actor_healed.emit(target_is_enemy, target_slot, hp_gain, int(target["hp"]))
		
	if sp_gain > 0:
		var cur_sp: int = int(target.get("sp", 0))
		var max_sp: int = int(target.get("max_sp", 50))
		target["sp"] = mini(max_sp, cur_sp + sp_gain)
		
	result["heal"] = hp_gain
	result["message"] = "%s used %s on %s (+%d HP, +%d SP)!" % [
		actor.get("name"), item.get("name"), target.get("name"), hp_gain, sp_gain
	]
	_log(result["message"])

func _resolve_catch_action(actor: Dictionary, action: Dictionary, result: Dictionary) -> void:
	var target_slot: int = int(action.get("target_slot", 0))
	var target: Dictionary = get_participant(true, target_slot)
	
	if target.is_empty() or not bool(target.get("is_alive", false)):
		result["success"] = false
		result["message"] = "Invalid target for capture!"
		_log(result["message"])
		return
		
	if bool(target.get("is_boss", false)):
		result["success"] = false
		result["message"] = "%s cannot be captured! Boss immune." % target.get("name")
		actor_caught.emit(true, target_slot, false, {})
		_log(result["message"])
		return
		
	var catch_chance: float = calculate_catch_rate(actor, target)
	var roll: float = 0.0 if deterministic_rolls else randf()
	var success: bool = roll < catch_chance
	
	result["success"] = success
	if success:
		target["is_alive"] = false
		target["captured"] = true
		actor_defeated.emit(true, target_slot)
		actor_caught.emit(true, target_slot, true, target)
		result["message"] = "SUCCESS! %s captured %s as a loyal pet!" % [actor.get("name"), target.get("name")]
	else:
		actor_caught.emit(true, target_slot, false, {})
		result["message"] = "%s attempted to capture %s, but it broke free!" % [actor.get("name"), target.get("name")]
	_log(result["message"])

func _resolve_escape_action(actor: Dictionary, _action: Dictionary, result: Dictionary) -> void:
	var living_enemies: Array[Dictionary] = get_living_participants(true)
	var avg_spd: float = 10.0
	if not living_enemies.is_empty():
		var total_spd: int = 0
		for e in living_enemies:
			total_spd += int(e.get("spd", 10))
		avg_spd = float(total_spd) / float(living_enemies.size())
		
	var escape_chance: float = calculate_escape_rate(int(actor.get("spd", 10)), int(round(avg_spd)))
	var roll: float = 0.0 if deterministic_rolls else randf()
	var success: bool = roll < escape_chance
	
	result["success"] = success
	actor_escaped.emit(bool(actor.get("is_enemy", false)), int(actor.get("slot", 0)), success)
	
	if success:
		result["message"] = "%s fled from the battle!" % actor.get("name")
		_log(result["message"])
		_handle_battle_end("escaped")
	else:
		result["message"] = "%s attempted to flee, but failed to escape!" % actor.get("name")
		_log(result["message"])

# --- Combat Formulas & Calculation ---

static func get_element_multiplier(user_elem: int, target_elem: int) -> float:
	if user_elem == 0 or target_elem == 0 or user_elem == target_elem:
		return 1.0
	# Authentic 4-element wheel: Earth(1) -> Water(2) -> Fire(3) -> Wind(4) -> Earth(1)
	if (user_elem == Element.EARTH and target_elem == Element.WATER) or \
	   (user_elem == Element.WATER and target_elem == Element.FIRE) or \
	   (user_elem == Element.FIRE and target_elem == Element.WIND) or \
	   (user_elem == Element.WIND and target_elem == Element.EARTH):
		return 1.25 # +25% bonus
	if (user_elem == Element.WATER and target_elem == Element.EARTH) or \
	   (user_elem == Element.FIRE and target_elem == Element.WATER) or \
	   (user_elem == Element.WIND and target_elem == Element.FIRE) or \
	   (user_elem == Element.EARTH and target_elem == Element.WIND):
		return 0.75 # -25% penalty
	return 1.0

func calculate_damage(attacker: Dictionary, target: Dictionary, action: Dictionary) -> Dictionary:
	var action_type: int = int(action.get("type", ActionType.ATTACK))
	var skill: Dictionary = action.get("skill", {})
	
	var is_magic: bool = false
	var base_dmg: float = 0.0
	var mult1: float = 1.0
	var mult2: float = 0.0
	var action_elem: int = int(attacker.get("element", Element.NONE))
	
	if action_type == ActionType.SKILL and not skill.is_empty():
		is_magic = int(skill.get("skill_type", 0)) == SkillMechanism.MAGIC
		base_dmg = float(skill.get("base_damage", 30))
		mult1 = float(skill.get("multiplier_1", 1.0))
		mult2 = float(skill.get("multiplier_2", 0.0))
		if int(skill.get("element", Element.NONE)) != Element.NONE:
			action_elem = int(skill.get("element", Element.NONE))
	else:
		# Normal Attack: physical, base damage = 20
		base_dmg = 20.0
		mult1 = 1.0
		mult2 = 0.0
		
	var atk_stat: float = float(attacker.get("matk", 10)) if is_magic else float(attacker.get("atk", 10))
	var def_stat: float = float(target.get("mdef", 5)) if is_magic else float(target.get("def", 5))
	var target_elem: int = int(target.get("element", Element.NONE))
	
	var elem_mult: float = get_element_multiplier(action_elem, target_elem)
	
	# Damage formula: Base + (ATK * mult1) - (DEF * 0.6) + (ATK * mult2)
	var raw: float = base_dmg + (atk_stat * mult1) - (def_stat * 0.6) + (atk_stat * mult2)
	if raw < 1.0:
		raw = 1.0
		
	# Critical strike calculation: 10% base chance
	var crit_roll: float = 0.05 if deterministic_rolls else randf()
	var is_crit: bool = (crit_roll < 0.10)
	var crit_mult: float = 1.5 if is_crit else 1.0
	
	var calculated: float = raw * elem_mult * crit_mult
	
	# Guard mitigation: 50% damage reduction
	var is_guarded: bool = bool(target.get("is_defending", false))
	if is_guarded:
		calculated *= 0.5
		
	var final_damage: int = maxi(1, int(round(calculated)))
	
	return {
		"damage": final_damage,
		"is_critical": is_crit,
		"is_guarded": is_guarded,
		"element_multiplier": elem_mult,
		"raw_damage": raw
	}

func calculate_catch_rate(attacker: Dictionary, target: Dictionary) -> float:
	var hp_pct: float = float(target.get("hp", 1)) / float(maxi(1, int(target.get("max_hp", 1))))
	var level_diff: int = int(attacker.get("level", 1)) - int(target.get("level", 1))
	# Base 70% minus HP% scaling, plus level difference bonus
	var rate: float = 0.70 - (hp_pct * 0.45) + (float(level_diff) * 0.03)
	return clampf(rate, 0.10, 0.95)

func calculate_escape_rate(player_spd: int, enemy_avg_spd: int) -> float:
	var diff: int = player_spd - enemy_avg_spd
	var rate: float = 0.60 + (float(diff) * 0.03)
	return clampf(rate, 0.20, 0.95)

# --- Battle End & Reward Resolution ---

func check_battle_end_conditions() -> String:
	var living_enemies: Array[Dictionary] = get_living_participants(true)
	if living_enemies.is_empty():
		return "victory"
		
	var living_players: Array[Dictionary] = get_living_participants(false)
	if living_players.is_empty():
		return "defeat"
		
	return "none"

func _handle_battle_end(outcome: String) -> void:
	timer_active = false
	match outcome:
		"victory":
			current_state = BattleState.VICTORY
			calculate_rewards()
			battle_won.emit(rewards)
			battle_finished.emit({"outcome": "victory", "rewards": rewards})
			_log("VICTORY! All enemies defeated!")
		"defeat":
			current_state = BattleState.DEFEAT
			battle_lost.emit()
			battle_finished.emit({"outcome": "defeat", "rewards": {}})
			_log("DEFEAT! Your party has fallen in battle...")
		"escaped":
			current_state = BattleState.ESCAPED
			battle_escaped.emit()
			battle_finished.emit({"outcome": "escaped", "rewards": {}})
			_log("Successfully escaped from battle.")

func calculate_rewards() -> Dictionary:
	var total_exp: int = 0
	var total_gold: int = 0
	
	for slot in range(TOTAL_SLOTS):
		var enemy: Dictionary = enemy_slots[slot]
		if not enemy.is_empty():
			var lvl: int = int(enemy.get("level", 1))
			var is_boss: bool = bool(enemy.get("is_boss", false))
			total_exp += lvl * 20 + (100 if is_boss else 0)
			total_gold += lvl * 12 + (60 if is_boss else 0)
			
	var dropped_items: Array[Dictionary] = roll_loot_drops()
	rewards = {
		"exp": total_exp,
		"gold": total_gold,
		"items": dropped_items
	}
	return rewards

func roll_loot_drops() -> Array[Dictionary]:
	var drops: Array[Dictionary] = []
	for item in loot_table:
		var rate: float = float(item.get("drop_rate_pct", 100.0))
		var roll: float = 0.0 if deterministic_rolls else randf() * 100.0
		if roll <= rate:
			var min_q: int = int(item.get("min_qty", 1))
			var max_q: int = int(item.get("max_qty", 1))
			var qty: int = min_q if min_q == max_q else randi_range(min_q, max_q)
			var drop_copy: Dictionary = item.duplicate(true)
			drop_copy["quantity"] = qty
			drops.append(drop_copy)
	return drops

# --- Formation Presets ---

func load_formation_preset(preset_name: String) -> bool:
	match preset_name:
		"Kelan Slimes Troop":
			_init_slots()
			set_enemy_slot(0, {
				"id": 101, "name": "Blue Jelly", "level": 1, "hp": 45, "max_hp": 45,
				"sp": 15, "max_sp": 15, "spd": 8, "element": Element.WATER,
				"atk": 16, "def": 8, "jmp_name": "slime_blue.jmp"
			})
			set_enemy_slot(1, {
				"id": 101, "name": "Blue Jelly", "level": 1, "hp": 45, "max_hp": 45,
				"sp": 15, "max_sp": 15, "spd": 8, "element": Element.WATER,
				"atk": 16, "def": 8, "jmp_name": "slime_blue.jmp"
			})
			set_enemy_slot(4, {
				"id": 102, "name": "Green Jelly", "level": 2, "hp": 70, "max_hp": 70,
				"sp": 25, "max_sp": 25, "spd": 6, "element": Element.EARTH,
				"atk": 22, "def": 12, "jmp_name": "slime_green.jmp"
			})
			loot_table = [
				{"item_id": 2001, "item_name": "Jelly Essence", "drop_rate_pct": 100.0, "min_qty": 1, "max_qty": 2},
				{"item_id": 2002, "item_name": "Water Bead", "drop_rate_pct": 50.0, "min_qty": 1, "max_qty": 1}
			]
			return true
			
		"Kelan Cave Bats":
			_init_slots()
			for s in [0, 1, 2]:
				set_enemy_slot(s, {
					"id": 105, "name": "Cave Bat", "level": 3, "hp": 95, "max_hp": 95,
					"sp": 30, "max_sp": 30, "spd": 14, "element": Element.WIND,
					"atk": 25, "def": 10, "jmp_name": "cave_bat.jmp"
				})
			set_enemy_slot(4, {
				"id": 106, "name": "Leader Bat", "level": 5, "hp": 190, "max_hp": 190,
				"sp": 60, "max_sp": 60, "spd": 18, "element": Element.FIRE, "is_boss": true,
				"atk": 42, "def": 18, "jmp_name": "leader_bat.jmp"
			})
			loot_table = [
				{"item_id": 2010, "item_name": "Bat Wing", "drop_rate_pct": 100.0, "min_qty": 2, "max_qty": 3},
				{"item_id": 2011, "item_name": "Cave Fruit", "drop_rate_pct": 75.0, "min_qty": 1, "max_qty": 2}
			]
			return true
			
		"Shipwreck Pirates":
			_init_slots()
			for s in range(4):
				set_enemy_slot(s, {
					"id": 110, "name": "Sailor Pirate", "level": 8, "hp": 240, "max_hp": 240,
					"sp": 80, "max_sp": 80, "spd": 12, "element": Element.WATER,
					"atk": 48, "def": 24, "jmp_name": "pirate_sailor.jmp"
				})
			set_enemy_slot(5, {
				"id": 115, "name": "Pirate Captain", "level": 12, "hp": 850, "max_hp": 850,
				"sp": 250, "max_sp": 250, "spd": 22, "element": Element.FIRE, "is_boss": true,
				"atk": 85, "def": 45, "jmp_name": "pirate_captain.jmp"
			})
			loot_table = [
				{"item_id": 2020, "item_name": "Pirate Coin", "drop_rate_pct": 100.0, "min_qty": 5, "max_qty": 10},
				{"item_id": 2021, "item_name": "Rum Bottle", "drop_rate_pct": 80.0, "min_qty": 1, "max_qty": 2}
			]
			return true
			
		_:
			push_warning("Unknown formation preset: " + preset_name)
			return false

func _log(msg: String) -> void:
	battle_log.append(msg)

func reset() -> void:
	_init_slots()
	queued_actions.clear()
	round_results.clear()
	battle_log.clear()
	current_state = BattleState.IDLE
	current_turn = 0
	turn_timer = TURN_TIME_LIMIT
	timer_active = false
	is_auto_battle = false
	rewards = {"exp": 0, "gold": 0, "items": []}
