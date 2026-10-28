class_name NpcStateEvaluator
extends RefCounted

## Evaluates authentic NPC visibility, lifecycle stages, and state attributes
## ported directly from Wonderland Private Server (C# wlo.pserver.core):
## - PreEventInterpreter.cs (ShouldNpcBeVisible, EvaluateMapPreEvents)
## - QuestNpc.cs (HP, SP, Element, Level, WalkBehavior, IsWildMonster, IsStaticNpc)
## - Map.cs (Wire protocol AC 22:4 actor visibility and state defaults)
##
## Supports per-map cutscene actor suppression (e.g. Map 12000 Staged Roca ClickID 32),
## quest-driven visibility stages (lost dogs, pigs, bees, monkeys), and full Eve.emg
## Category 9 PreEvent bytecode evaluation.

const IsometricMath = preload("res://scripts/map/isometric_math.gd")

const QUEST_IN_PROGRESS: int = 1
const QUEST_NOT_STARTED: int = 2
const QUEST_COMPLETED: int = 3

## Determines whether an NPC should be visible on a given map according to authentic C# server rules
static func should_npc_be_visible(
	map_id: int,
	click_id: int,
	quest_states: Dictionary = {},
	party_companions: Array = [],
	player_pets: Array = [],
	is_broken: bool = false,
	eve_parser = null
) -> bool:
	# 1. Defeated / broken wild monsters are concealed
	if is_broken:
		return false
	
	# 2. Resolve NPC definition from eve_parser or fallback
	var npc_def = null
	if eve_parser != null and eve_parser.has_method("get_npc_by_id"):
		npc_def = eve_parser.get_npc_by_id(map_id, click_id)
	
	# 3. Check if this map entity is a companion already recruited in the player's active party
	if npc_def != null and npc_def.npc_id > 0 and party_companions.has(npc_def.npc_id):
		return false
	
	# 4. Map 12000 (Kelan Village) - Authentic lifecycle visibility rules
	if map_id == 12000:
		# Permanent scenery props: guideposts (10, 31) and honeycomb (17) are always visible initially
		if click_id == 17 or click_id == 10 or click_id == 31:
			return true
		
		# Staged Cutscene Roca at village gate (ClickID 32):
		# Ephemeral cutscene actor dynamically spawned during Event 45/49 (Quest 13098 step 3)
		# and hidden immediately when dialogue finishes. Never visible by default in normal overworld!
		if click_id == 32:
			return false
		
		# Lina's permanent Shiba Inu (ClickID 29, X=624, Y=1259): sitting by her side, ALWAYS visible.
		if click_id == 29:
			return true
		
		# Lina's lost dog that went missing (ClickID 28, X=592, Y=1192, Event 35, PreEvents #5 & #6):
		# Hidden while Quest 13046 is NotStarted (2) OR InProgress at Step 1 (still missing in hogpen).
		# Appears next to Lina only when Quest 13046 is found (Step >= 2) or Completed (3) or flag 13047 is set.
		if click_id == 28:
			var q13046_st: int = get_player_quest_state(quest_states, 13046)
			var q13046_step: int = get_player_quest_step(quest_states, 13046)
			var q13047_done: bool = (get_player_quest_state(quest_states, 13047) == 1 or int(quest_states.get(13047, 0)) == 1)
			if q13046_st == QUEST_NOT_STARTED or (q13046_st == QUEST_IN_PROGRESS and q13046_step < 2 and not q13047_done):
				return false
			return true
		
		# Lost Shiba Inu in trees/hogpen (ClickID 20):
		# Only visible when Quest 13046 is InProgress at Step 1 (searching for dog)
		if click_id == 20:
			var q13046_st: int = get_player_quest_state(quest_states, 13046)
			var q13046_step: int = get_player_quest_step(quest_states, 13046)
			var q13047_done: bool = (get_player_quest_state(quest_states, 13047) == 1 or int(quest_states.get(13047, 0)) == 1)
			if q13046_st == QUEST_IN_PROGRESS and q13046_step < 2 and not q13047_done:
				return true
			return false
		
		# Baby Bees (18 & 19): Hidden when Quest 13023 is NotStarted (2); visible once started or completed
		if click_id == 18 or click_id == 19:
			if get_player_quest_state(quest_states, 13023) == QUEST_NOT_STARTED:
				return false
			return true
		
		# Staged Pigs (14 & 15):
		# PreEvents #0 & #1:
		# Pig 15 is the stray pig outside the pen (visible during Step 1).
		# Pig 14 is the pig returned to the pen (visible during Step >= 2 and Completed or flag 12021).
		if click_id == 14:
			var q12020_st: int = get_player_quest_state(quest_states, 12020)
			var q12020_step: int = get_player_quest_step(quest_states, 12020)
			var q12021_done: bool = (get_player_quest_state(quest_states, 12021) == 1 or int(quest_states.get(12021, 0)) == 1)
			if (q12020_st == QUEST_IN_PROGRESS and q12020_step >= 2) or q12020_st == QUEST_COMPLETED or q12021_done:
				return true
			return false
		
		if click_id == 15:
			var q12020_st: int = get_player_quest_state(quest_states, 12020)
			var q12020_step: int = get_player_quest_step(quest_states, 12020)
			if q12020_st == QUEST_IN_PROGRESS and q12020_step == 1:
				return true
			return false
		
		# Staged Pig (16): Hidden if Quest 13020 is NotStarted or flag 13021 is set
		if click_id == 16:
			if get_player_quest_state(quest_states, 13020) == QUEST_NOT_STARTED or get_player_quest_state(quest_states, 13021) == 1:
				return false
			return true
	
	# 5. Map 11016 (North Island Starter Beach): S. Monkey (ClickID 1, TID 17162)
	if map_id == 11016 and click_id == 1:
		var has_monkey: bool = party_companions.has(17162) or party_companions.has(10727) \
			or player_pets.has(17162) or player_pets.has(10727) \
			or (get_player_quest_state(quest_states, 12002) == QUEST_COMPLETED)
		if has_monkey:
			return false
		return true
	
	# 6. Map 11040: Clive's transient battle actor (ClickID 4)
	if map_id == 11040 and click_id == 4:
		var clive_offer_st := get_player_quest_state(quest_states, 13102)
		var clive_offer_step := get_player_quest_step(quest_states, 13102)
		var clive_done_st := get_player_quest_state(quest_states, 13103)
		var clive_done_step := get_player_quest_step(quest_states, 13103)
		if clive_offer_st == QUEST_IN_PROGRESS and clive_offer_step == 4 and not (clive_done_st == QUEST_IN_PROGRESS and clive_done_step > 0):
			return true
	
	# 7. Map 12002: Xaolan story stages
	if map_id == 12002:
		var xaolan_fate: bool = bool(quest_states.get("xaolan_in_fate", false)) \
			or int(quest_states.get(13004, 0)) == 1 or int(quest_states.get(13005, 0)) == 1
		if (click_id == 2 or click_id == 7) and xaolan_fate:
			return false
		if (click_id == 2 or click_id == 3):
			var rescue: int = get_player_quest_state(quest_states, 13033)
			var rescue_step: int = get_player_quest_step(quest_states, 13033)
			if rescue == QUEST_IN_PROGRESS and rescue_step == 1 and int(quest_states.get(13004, 0)) != 1 and int(quest_states.get(13005, 0)) != 1:
				return click_id != 2 or not party_companions.has(14156)
	
	# 8. Map 60002: Hot spring departure actors (43, 44)
	if map_id == 60002 and (click_id == 43 or click_id == 44):
		var spring: int = get_player_quest_state(quest_states, 50042)
		var spring_step: int = get_player_quest_step(quest_states, 50042)
		if spring == QUEST_IN_PROGRESS and (spring_step == 1 or (spring_step > 1 and int(quest_states.get(50047, 0)) == 1)):
			return true
	
	# 9. Generic PreEvent & initial visibility evaluation from Eve.emg bytecode
	# EVE's first NPC flag byte (unknownbyte1 / entity_type) uses bit 0 for initial visibility.
	# Ephemeral / staged actors marked with bit 0 == 0 (e.g. entity_type 2 or 4) are hidden by default!
	var visible: bool = true
	if npc_def != null:
		visible = ((npc_def.entity_type & 1) != 0)
	
	# Apply Category 9 PreEvents if available
	if eve_parser != null and eve_parser.has_method("get_preevents_for_map"):
		var pre_events: Array = eve_parser.get_preevents_for_map(map_id)
		for pe in pre_events:
			if not "rules" in pe:
				continue
			for rule in pe.rules:
				if evaluate_rule_conditions(rule, quest_states, party_companions, player_pets):
					if "actions" in rule and rule.actions != null:
						for act in rule.actions:
							if act.target_click_id == click_id:
								if act.action_type == 2:
									visible = false
								elif act.action_type == 3:
									visible = true
								elif act.state1 == 0xFF and act.state2 == 0xFF:
									visible = false
	
	return visible

## Evaluates whether all conditions in a PreEventRule block are satisfied
static func evaluate_rule_conditions(
	rule,
	quest_states: Dictionary,
	party_companions: Array = [],
	player_pets: Array = [],
	inventory: Dictionary = {}
) -> bool:
	if rule == null:
		return false
	if not _evaluate_single_condition(rule, quest_states, party_companions, player_pets, inventory):
		return false
	if "sub_conditions" in rule and rule.sub_conditions != null:
		for sub in rule.sub_conditions:
			if not _evaluate_single_condition(sub, quest_states, party_companions, player_pets, inventory):
				return false
	return true

static func _evaluate_single_condition(
	rule,
	quest_states: Dictionary,
	party_companions: Array = [],
	player_pets: Array = [],
	inventory: Dictionary = {}
) -> bool:
	if rule == null:
		return false
	
	var op: int = rule.condition_op
	match op:
		0:
			return true
		1:
			return rule.word1 == 0 and rule.word2 == 0 and rule.word3 == 0
		6:
			return true # Normal greeting / click fallback
		5:
			# Quest condition: word1 = quest_id, word2 = 1 (InProgress/step) or 2 (NotStarted)
			var q := get_player_quest_info(quest_states, rule.word1)
			var is_active: bool = (q.state == QUEST_IN_PROGRESS)
			if rule.word2 == 2:
				return not is_active
			if rule.word2 != 1:
				return false
			return compare_value(q.step, rule.value, rule.comparison)
		2:
			# Inventory / companion condition
			if rule.word1 == 1: # Item count check
				var count: int = inventory.get(rule.word3, 0)
				return compare_value(count, rule.value, rule.comparison)
			elif rule.word1 == 2: # Companion / Pet check
				var present: bool = party_companions.has(rule.word3) or player_pets.has(rule.word3)
				match rule.word2:
					1: return present
					2: return not present
					8: return present # Owned
					9: return not present
			return false
		_:
			return false

## Resolves full authentic NPC state matching C# QuestNpc defaults
static func get_npc_state(
	map_id: int,
	click_id: int,
	eve_parser = null,
	game_db = null
) -> Dictionary:
	var state: Dictionary = {
		"map_id": map_id,
		"click_id": click_id,
		"template_id": 0,
		"name": "NPC_%d" % click_id,
		"level": 1,
		"hp": 100,
		"max_hp": 100,
		"sp": 50,
		"max_sp": 50,
		"element": 0,
		"entity_type": 1,
		"walk_behavior": 1,
		"walksteps": [],
		"walkstep_delays": [],
		"rotation": 5,
		"heading": IsometricMath.Heading.SOUTH,
		"world_position": Vector2.ZERO,
		"is_wild_monster": false,
		"is_static": false,
		"talk_id": 0,
		"dialogue_text": "",
		"dialogue_choices": []
	}
	
	var spawn = null
	if eve_parser != null and eve_parser.has_method("get_npc_by_id"):
		spawn = eve_parser.get_npc_by_id(map_id, click_id)
	
	if spawn != null:
		state["template_id"] = spawn.npc_id
		state["name"] = spawn.name
		state["entity_type"] = spawn.entity_type
		state["walk_behavior"] = spawn.walk_behavior
		state["walksteps"] = spawn.walksteps.duplicate()
		state["walkstep_delays"] = spawn.walkstep_delays.duplicate()
		state["rotation"] = spawn.rotation
		state["heading"] = IsometricMath.rotation_to_heading(spawn.rotation)
		state["world_position"] = Vector2(spawn.world_x, spawn.world_y)
	
	# Lookup database record for stats & clean display name
	var tid: int = state["template_id"]
	var npc_rec = null
	if game_db != null and "npcs" in game_db and game_db.npcs != null:
		npc_rec = game_db.npcs.get_npc(tid)
	
	if npc_rec != null:
		if not npc_rec.name.is_empty() and not npc_rec.name.begins_with("NPC_"):
			state["name"] = npc_rec.name
		state["level"] = npc_rec.level if npc_rec.level > 0 else 1
		state["hp"] = npc_rec.max_hp if npc_rec.max_hp > 0 else 100
		state["max_hp"] = state["hp"]
		state["sp"] = npc_rec.max_sp if npc_rec.max_sp > 0 else 50
		state["max_sp"] = state["sp"]
		state["element"] = npc_rec.element
	
	state["is_wild_monster"] = is_wild_monster(tid, state["name"])
	state["is_static"] = is_static_prop(tid, state["name"])
	
	# Resolve dialogue
	if game_db != null and "talks" in game_db and game_db.talks != null:
		var talk_rec: Dictionary = game_db.talks.resolve_talk_for_npc(tid, map_id)
		if not talk_rec.is_empty():
			state["talk_id"] = talk_rec.get("id", 0)
			if talk_rec.get("text", "") != "":
				state["dialogue_text"] = talk_rec["text"]
			if talk_rec.has("choices") and not talk_rec["choices"].is_empty():
				var choices_arr: Array[String] = []
				for c in talk_rec["choices"]:
					if c is Dictionary and c.has("text"):
						choices_arr.append(c["text"])
					else:
						choices_arr.append(str(c))
				state["dialogue_choices"] = choices_arr
	
	return state

## Determines if an entity is an authentic wild monster (PvE overworld mob) matching C# QuestNpc.IsWildMonster()
static func is_wild_monster(template_id: int, npc_name: String = "") -> bool:
	if template_id == 0:
		return false
	
	var lower := npc_name.to_lower().strip_edges()
	
	# 1. Shops, services, keepers, doctors, hotels, signposts are NEVER monsters
	if lower.contains("shop") or lower.contains("store") or lower.contains("market") \
		or lower.contains("keep") or lower.contains("storage") or lower.contains("bank") \
		or lower.contains("exchanger") or lower.contains("doctor") or lower.contains("witch") \
		or lower.contains("clinic") or lower.contains("hotel") or lower.contains("inn") \
		or lower.contains("guidepost") or lower.contains("signpost") or lower.contains("statue") \
		or lower.contains("pig") or template_id == 17400:
		return false
	
	# 2. Non-monster template ID ranges in WLO:
	# 10000-12999: Story characters, Recruitable companions, Sailors
	# 13000-13999: Shops (Props Shop, Weapon Shop, Armor Shop)
	# 14000-14999: Human Villagers, Townspeople, Guards, Elders
	# 19000-24999: Props, Gathering nodes, Chests, Furniture
	# 25000+: Story cutscene actors
	if template_id < 17000 or template_id >= 18000:
		return false
	
	# 3. Friendly animals in 17000 range
	if template_id == 17400: # Kelan Village Pigs
		return false
	
	# 4. Friendly human / citizen / town keywords
	var friendly_keywords := [
		"villager", "citizen", "resident", "grandma", "grandmother", "grandfather",
		"elder", "chief", "guard", "soldier", "knight", "merchant", "vendor",
		"trader", "peddler", "innkeeper", "waitress", "nurse", "doctor", "priest",
		"monk", "clerk", "sailor", "captain", "chef", "cook", "maid", "blacksmith",
		"carpenter", "hunter", "miner", "guide", "girl", "boy", "kid", "child",
		"man", "woman", "lady", "sir", "robinson"
	]
	for kw in friendly_keywords:
		if lower.contains(kw):
			return false
	
	# 5. Authentic roaming monsters in WLO 17000-17999 range
	return (template_id >= 17000 and template_id <= 17999)

## Determines if an entity is a static prop/chest/gathering node matching C# QuestNpc.IsStaticNpc()
static func is_static_prop(template_id: int, npc_name: String = "") -> bool:
	if template_id == 0:
		return true
	if is_wild_monster(template_id, npc_name):
		return false
	
	if (template_id >= 12000 and template_id <= 12999) \
		or (template_id >= 16000 and template_id <= 16011) \
		or (template_id >= 19000 and template_id <= 19999) \
		or (template_id >= 25000 and template_id <= 35000):
		return true
	
	var lower := npc_name.to_lower().strip_edges()
	var prop_keywords := [
		"chest", "box", "crate", "barrel", "pot", "machine", "wood", "stone", "clay",
		"mine", "herb", "tree", "door", "switch", "lever", "cabinet", "desk", "bed",
		"chair", "stove", "grass", "flower", "shell", "mushroom", "ore", "statue",
		"fountain", "sign", "well", "grave", "cart", "boat", "wreck", "tent", "fence",
		"portal", "warp", "prop", "object", "game machine", "coconut", "driftwood",
		"bamboo", "iron ore", "copper ore", "comb", "honeycomb"
	]
	for kw in prop_keywords:
		if lower.contains(kw):
			return true
	if lower.is_empty() or lower.begins_with("npc_0") or lower.begins_with("unknown"):
		return true
	return false

## Retrieves player quest state (1=InProgress, 2=NotStarted, 3=Completed)
static func get_player_quest_state(quest_states: Dictionary, flag_id: int) -> int:
	return get_player_quest_info(quest_states, flag_id).state

## Retrieves player quest step
static func get_player_quest_step(quest_states: Dictionary, flag_id: int) -> int:
	return get_player_quest_info(quest_states, flag_id).step

## Normalizes quest state dictionary lookup
static func get_player_quest_info(quest_states: Dictionary, flag_id: int) -> Dictionary:
	if quest_states.is_empty() or flag_id == 0:
		return {"state": QUEST_NOT_STARTED, "step": 0}
	
	var val = null
	if quest_states.has(flag_id):
		val = quest_states[flag_id]
	elif quest_states.has(str(flag_id)):
		val = quest_states[str(flag_id)]
	else:
		return {"state": QUEST_NOT_STARTED, "step": 0}
	
	if val is int:
		if val == 1: return {"state": QUEST_IN_PROGRESS, "step": 1}
		elif val == 2: return {"state": QUEST_NOT_STARTED, "step": 0}
		elif val == 3: return {"state": QUEST_COMPLETED, "step": 99}
		elif val > 0: return {"state": QUEST_IN_PROGRESS, "step": val}
		return {"state": QUEST_NOT_STARTED, "step": 0}
	elif val is Dictionary:
		var st_val = val.get("state", QUEST_NOT_STARTED)
		var st_num := QUEST_NOT_STARTED
		if st_val is String:
			if st_val == "in_progress" or st_val == "active": st_num = QUEST_IN_PROGRESS
			elif st_val == "completed" or st_val == "done": st_num = QUEST_COMPLETED
			else: st_num = QUEST_NOT_STARTED
		else:
			st_num = int(st_val)
		var step_num := int(val.get("step", 0))
		return {"state": st_num, "step": step_num}
	elif val is String:
		if val == "in_progress" or val == "active": return {"state": QUEST_IN_PROGRESS, "step": 1}
		elif val == "completed" or val == "done": return {"state": QUEST_COMPLETED, "step": 99}
	return {"state": QUEST_NOT_STARTED, "step": 0}

## Compares values according to authentic WLO Eve.emg comparison opcode (1=<, 2=>, 3=<=, 4=>=, 5==, 6=!=)
static func compare_value(actual: int, expected: int, comparison: int) -> bool:
	match comparison:
		1: return actual < expected
		2: return actual > expected
		3: return actual <= expected
		4: return actual >= expected
		5: return actual == expected
		6: return actual != expected
		_: return false

## Resolves display name for an NPC. Prefers database template name when Eve.emg provides generic placeholder ("Npc", "none", "").
static func resolve_npc_display_name(raw_name: String, npc_rec) -> String:
	# Clean non-printable control characters (such as Delphi ShortString length prefix \x03)
	var clean_raw := ""
	for i in range(raw_name.length()):
		var c := raw_name.unicode_at(i)
		if c >= 32:
			clean_raw += raw_name[i]
	clean_raw = clean_raw.strip_edges()
	var lower_raw := clean_raw.to_lower()

	# If database record has a valid name, check if raw_name is placeholder or generic
	if npc_rec != null and "name" in npc_rec and not str(npc_rec.name).is_empty() and str(npc_rec.name) != "None":
		var db_name: String = str(npc_rec.name).strip_edges()
		if lower_raw.is_empty() or lower_raw == "npc" or lower_raw == "none" or lower_raw.begins_with("npc_") or lower_raw.begins_with("unknown"):
			return db_name
		if lower_raw == "npc" or lower_raw == db_name.to_lower():
			return db_name
		if clean_raw.begins_with("Npc") or clean_raw.begins_with("NPC"):
			return db_name
		return clean_raw

	if not clean_raw.is_empty() and lower_raw != "none" and lower_raw != "npc":
		return clean_raw

	if npc_rec != null and "name" in npc_rec and not str(npc_rec.name).is_empty():
		return str(npc_rec.name)

	if npc_rec != null and "id" in npc_rec:
		return "NPC_%d" % int(npc_rec.id)

	return "NPC"
