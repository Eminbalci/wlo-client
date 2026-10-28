class_name CombatEngine
extends BattleManager

## Wonderland Online - Turn-Based Combat Engine.
## Extended combat engine building upon BattleManager to provide:
## - Dynamic Initiative Timeline generation with participant stat cards & SPD sorting.
## - Detailed damage calculation with 4-element cycle advantage badges, critical hits, evasion, and defense mitigation.
## - Intelligent target candidate filtering for offensive vs assist/healing actions.
## - Round status effect tracking and tick processing.

# --- Extended Signals ---
signal initiative_timeline_updated(timeline: Array[Dictionary])
signal status_effect_applied(is_enemy: bool, slot: int, status: Dictionary)
signal status_effect_ticked(is_enemy: bool, slot: int, status: Dictionary, damage: int)

# --- Extended Enums ---
enum ElementRelation {
	NEUTRAL = 0,
	ADVANTAGE = 1,
	DISADVANTAGE = 2
}

# --- State ---
var status_effects: Dictionary = {} # Key: "p_0", "e_1" -> Array[Dictionary]

func _init() -> void:
	super._init()

## Returns a sorted initiative timeline for all living combatants.
## Sorted primarily by SPD descending, tie-breaking player first, then slot index.
func get_initiative_timeline(active_slot: int = -1, active_is_enemy: bool = false) -> Array[Dictionary]:
	var timeline: Array[Dictionary] = []
	
	# Collect living players
	for s in range(TOTAL_SLOTS):
		var p: Dictionary = player_slots[s]
		if not p.is_empty() and bool(p.get("is_alive", false)):
			var elem: int = int(p.get("element", Element.NONE))
			timeline.append({
				"id": int(p.get("id", 1)),
				"name": String(p.get("name", "Player %d" % s)),
				"level": int(p.get("level", 1)),
				"slot": s,
				"is_enemy": false,
				"spd": int(p.get("spd", 10)),
				"hp": int(p.get("hp", 100)),
				"max_hp": int(p.get("max_hp", 100)),
				"sp": int(p.get("sp", 50)),
				"max_sp": int(p.get("max_sp", 50)),
				"element": elem,
				"element_name": ELEMENT_NAMES[elem] if elem < ELEMENT_NAMES.size() else "None",
				"element_color": ELEMENT_COLORS[elem] if elem < ELEMENT_COLORS.size() else Color.GRAY,
				"is_boss": false,
				"is_defending": bool(p.get("is_defending", false)),
				"role_id": int(p.get("role_id", 0)),
				"is_active": (s == active_slot and not active_is_enemy)
			})
			
	# Collect living enemies
	for s in range(TOTAL_SLOTS):
		var e: Dictionary = enemy_slots[s]
		if not e.is_empty() and bool(e.get("is_alive", false)):
			var elem: int = int(e.get("element", Element.NONE))
			timeline.append({
				"id": int(e.get("id", 1000 + s)),
				"name": String(e.get("name", "Enemy %d" % s)),
				"level": int(e.get("level", 1)),
				"slot": s,
				"is_enemy": true,
				"spd": int(e.get("spd", 10)),
				"hp": int(e.get("hp", 100)),
				"max_hp": int(e.get("max_hp", 100)),
				"sp": int(e.get("sp", 50)),
				"max_sp": int(e.get("max_sp", 50)),
				"element": elem,
				"element_name": ELEMENT_NAMES[elem] if elem < ELEMENT_NAMES.size() else "None",
				"element_color": ELEMENT_COLORS[elem] if elem < ELEMENT_COLORS.size() else Color.GRAY,
				"is_boss": bool(e.get("is_boss", false)),
				"is_defending": bool(e.get("is_defending", false)),
				"role_id": int(e.get("role_id", 0)),
				"is_active": (s == active_slot and active_is_enemy)
			})
			
	# Sort by SPD descending, player-first tie-breaking, then slot index
	timeline.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var spd_a: int = int(a.get("spd", 10))
		var spd_b: int = int(b.get("spd", 10))
		if spd_a != spd_b:
			return spd_a > spd_b
		var e_a: bool = bool(a.get("is_enemy", false))
		var e_b: bool = bool(b.get("is_enemy", false))
		if e_a != e_b:
			return not e_a # Player first
		return int(a.get("slot", 0)) < int(b.get("slot", 0))
	)
	
	initiative_timeline_updated.emit(timeline)
	return timeline

## Computes element relationship between user and target.
func get_element_relation(user_elem: int, target_elem: int) -> Dictionary:
	var mult: float = get_element_multiplier(user_elem, target_elem)
	var rel: int = ElementRelation.NEUTRAL
	var badge: String = ""
	
	if mult > 1.0:
		rel = ElementRelation.ADVANTAGE
		var u_name: String = ELEMENT_NAMES[user_elem] if user_elem < ELEMENT_NAMES.size() else "None"
		var t_name: String = ELEMENT_NAMES[target_elem] if target_elem < ELEMENT_NAMES.size() else "None"
		badge = "+25%% [%s > %s]" % [u_name, t_name]
	elif mult < 1.0:
		rel = ElementRelation.DISADVANTAGE
		var u_name: String = ELEMENT_NAMES[user_elem] if user_elem < ELEMENT_NAMES.size() else "None"
		var t_name: String = ELEMENT_NAMES[target_elem] if target_elem < ELEMENT_NAMES.size() else "None"
		badge = "-25%% [%s < %s]" % [u_name, t_name]
		
	return {
		"multiplier": mult,
		"relation": rel,
		"badge_text": badge
	}

## Calculates evasion probability based on target agility vs attacker agility.
func calculate_evasion_rate(attacker_spd: int, target_spd: int) -> float:
	if target_spd <= attacker_spd:
		return 0.0
	var diff: float = float(target_spd - attacker_spd)
	return clampf(diff * 0.015, 0.0, 0.25) # Max 25% evasion

## Detailed combat strike calculation with damage, crit, evasion, defense, and badges.
func calculate_detailed_attack(attacker: Dictionary, target: Dictionary, action: Dictionary) -> Dictionary:
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
		if int(skill.get("element", 0)) != 0:
			action_elem = int(skill.get("element", 0))
	elif action_type == ActionType.ATTACK:
		base_dmg = 25.0
		mult1 = 1.0
		mult2 = 0.0
		
	var target_elem: int = int(target.get("element", Element.NONE))
	var elem_info: Dictionary = get_element_relation(action_elem, target_elem)
	var elem_mult: float = float(elem_info.get("multiplier", 1.0))
	
	# Evasion Check
	var atk_spd: int = int(attacker.get("spd", 10))
	var tgt_spd: int = int(target.get("spd", 10))
	var eva_rate: float = calculate_evasion_rate(atk_spd, tgt_spd)
	var is_miss: bool = false
	if not deterministic_rolls and eva_rate > 0.0:
		is_miss = randf() < eva_rate
		
	if is_miss:
		return {
			"damage": 0,
			"is_miss": true,
			"is_critical": false,
			"is_guarded": false,
			"element_multiplier": elem_mult,
			"element_relation": int(elem_info.get("relation", 0)),
			"badge_text": "MISS"
		}
		
	# Offensive Stat vs Defensive Stat
	var atk_stat: float = float(attacker.get("matk", 10)) if is_magic else float(attacker.get("atk", 10))
	var def_stat: float = float(target.get("mdef", 5)) if is_magic else float(target.get("def", 5))
	
	var raw_dmg: float = base_dmg + (atk_stat * mult1) - (def_stat * 0.6) + (atk_stat * mult2)
	raw_dmg = maxf(1.0, raw_dmg)
	
	# Apply Element Multiplier
	var scaled_dmg: float = raw_dmg * elem_mult
	
	# Guard Mitigation
	var is_guarded: bool = bool(target.get("is_defending", false))
	if is_guarded:
		scaled_dmg *= 0.5
		
	# Critical Strike Check (10% base chance)
	var crit_chance: float = 0.10
	var is_crit: bool = false
	if not is_guarded:
		if deterministic_rolls:
			is_crit = false
		else:
			is_crit = randf() < crit_chance
			
	if is_crit:
		scaled_dmg *= 1.5
		
	var final_damage: int = maxi(1, int(round(scaled_dmg)))
	
	return {
		"damage": final_damage,
		"is_miss": false,
		"is_critical": is_crit,
		"is_guarded": is_guarded,
		"element_multiplier": elem_mult,
		"element_relation": int(elem_info.get("relation", 0)),
		"badge_text": String(elem_info.get("badge_text", ""))
	}

## Returns an array of candidate target slots based on action type and skill mechanism.
func get_valid_targets(is_enemy_caster: bool, action_type: int, skill_data: Dictionary = {}) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var target_enemies: bool = true
	
	if action_type == ActionType.ATTACK or action_type == ActionType.CATCH:
		target_enemies = true
	elif action_type == ActionType.ITEM:
		target_enemies = false
	elif action_type == ActionType.SKILL and not skill_data.is_empty():
		var mechanism: int = int(skill_data.get("skill_type", 0))
		var base_dmg: int = int(skill_data.get("base_damage", 0))
		if mechanism == SkillMechanism.ASSIST and base_dmg < 0:
			target_enemies = false
		else:
			target_enemies = true
			
	var target_is_enemy: bool = target_enemies if not is_enemy_caster else not target_enemies
	var pool: Array[Dictionary] = enemy_slots if target_is_enemy else player_slots
	
	for s in range(TOTAL_SLOTS):
		var p: Dictionary = pool[s]
		if not p.is_empty() and bool(p.get("is_alive", false)):
			candidates.append({
				"slot": s,
				"is_enemy": target_is_enemy,
				"name": String(p.get("name", "Actor")),
				"hp": int(p.get("hp", 0)),
				"max_hp": int(p.get("max_hp", 1)),
				"element": int(p.get("element", 0)),
				"is_boss": bool(p.get("is_boss", false))
			})
			
	return candidates

## Applies a status effect (e.g. "poison", "stun", "shield", "atk_buff") to an actor.
func apply_status_effect(is_enemy: bool, slot: int, status_name: String, duration_turns: int, potency: int = 0) -> bool:
	var actor: Dictionary = get_participant(is_enemy, slot)
	if actor.is_empty() or not bool(actor.get("is_alive", false)):
		return false
		
	var key: String = "%s_%d" % ["e" if is_enemy else "p", slot]
	if not status_effects.has(key):
		status_effects[key] = []
		
	var effect_data: Dictionary = {
		"name": status_name,
		"duration": duration_turns,
		"potency": potency,
		"is_enemy": is_enemy,
		"slot": slot
	}
	
	(status_effects[key] as Array).append(effect_data)
	status_effect_applied.emit(is_enemy, slot, effect_data)
	return true

## Processes active status effect ticks at round end.
func process_round_end_statuses() -> Array[Dictionary]:
	var ticked_events: Array[Dictionary] = []
	
	for key in status_effects.keys():
		var list: Array = status_effects[key]
		var remaining: Array[Dictionary] = []
		
		for eff in list:
			var e: Dictionary = eff as Dictionary
			var is_enemy: bool = bool(e.get("is_enemy", false))
			var slot: int = int(e.get("slot", 0))
			var actor: Dictionary = get_participant(is_enemy, slot)
			if actor.is_empty() or not bool(actor.get("is_alive", false)):
				continue
				
			var s_name: String = String(e.get("name", ""))
			var potency: int = int(e.get("potency", 0))
			
			if s_name == "poison":
				var dmg: int = maxi(1, potency)
				var cur_hp: int = int(actor.get("hp", 1))
				actor["hp"] = maxi(0, cur_hp - dmg)
				if int(actor["hp"]) == 0:
					actor["is_alive"] = false
					actor_defeated.emit(is_enemy, slot)
				actor_damaged.emit(is_enemy, slot, dmg, false, int(actor["hp"]))
				status_effect_ticked.emit(is_enemy, slot, e, dmg)
				ticked_events.append({"key": key, "name": s_name, "damage": dmg})
				
			var dur: int = int(e.get("duration", 1)) - 1
			if dur > 0:
				e["duration"] = dur
				remaining.append(e)
				
		status_effects[key] = remaining
		
	return ticked_events
