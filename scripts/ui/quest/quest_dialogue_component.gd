class_name QuestDialogueComponent
extends Node

## Wonderland Online Quest Dialogue Component
## Bridges Quest objectives with NPC Dialogue, TalkDatabase chains, HUD dialogue, and reward fanfare.

signal quest_dialogue_started(quest_id: int, npc_id: int)
signal quest_objective_completed(quest_id: int, step_index: int)
signal quest_completed(quest_id: int, rewards: Dictionary)
signal quest_reward_displayed(msg: String)

@export var dialogue_manager: DialogueManager = null
@export var dialogue_box: DialogueBox = null
var hud: Control = null

# Active Quests buffer: Dictionary of { quest_id: { quest_id, quest_title, current_step, objectives, rewards, status } }
var active_quests: Dictionary = {}
var completed_quests: Dictionary = {}

var _sfx_reward: AudioStream = null

func _enter_tree() -> void:
	ensure_initialized()

func _ready() -> void:
	ensure_initialized()

func ensure_initialized() -> void:
	if not dialogue_manager:
		dialogue_manager = get_node_or_null("DialogueManager") as DialogueManager
	if not dialogue_box:
		dialogue_box = get_node_or_null("DialogueBox") as DialogueBox
	if not hud and get_parent() and "hud" in get_parent():
		hud = get_parent().hud

	_load_reward_sfx()

func _load_reward_sfx() -> void:
	if _sfx_reward != null:
		return
	var paths: Array[String] = [
		"res://assets/sound/wav9911.wav",
		"res://assets/sound/9911.wav"
	]
	for p in paths:
		if ResourceLoader.exists(p):
			_sfx_reward = load(p)
			break

## Registers a quest into active tracking
func register_quest(quest_data: Dictionary) -> void:
	ensure_initialized()
	var qid: int = int(quest_data.get("quest_id", 0))
	if qid <= 0:
		return

	active_quests[qid] = {
		"quest_id": qid,
		"quest_title": str(quest_data.get("quest_title", "Quest #%d" % qid)),
		"current_step": int(quest_data.get("current_step", 0)),
		"objectives": quest_data.get("objectives", []),
		"rewards": quest_data.get("rewards", {}),
		"status": "in_progress"
	}

## Interacts with an NPC, checking for active quest dialogue
## True when an active quest's current step is "talk to this NPC" (used to show the quest cursor).
func npc_has_pending_objective(npc_id: int, npc_name: String = "") -> bool:
	for qid in active_quests.keys():
		var q: Dictionary = active_quests[qid]
		if q.get("status", "") != "in_progress":
			continue
		var cur_step: int = int(q.get("current_step", 0))
		var objs: Array = q.get("objectives", [])
		if cur_step < 0 or cur_step >= objs.size():
			continue
		var obj: Dictionary = objs[cur_step]
		if str(obj.get("type", "")) != "TalkToNPC":
			continue
		var target_npc_id: int = int(obj.get("npc_id", 0))
		if target_npc_id > 0 and target_npc_id == npc_id:
			return true
		if npc_id in obj.get("alt_npc_ids", []):
			return true
		var target_npc_name: String = str(obj.get("npc_name", "")).to_lower()
		var n_low := npc_name.to_lower()
		if not target_npc_name.is_empty() and not n_low.is_empty() and (target_npc_name in n_low or n_low in target_npc_name):
			return true
	return false

func interact_with_npc(npc_id: int, npc_name: String = "", default_talk_id: int = 0) -> bool:
	ensure_initialized()

	for qid in active_quests.keys():
		var q: Dictionary = active_quests[qid]
		if q.get("status", "") != "in_progress":
			continue

		var cur_step: int = int(q.get("current_step", 0))
		var objs: Array = q.get("objectives", [])

		if cur_step >= 0 and cur_step < objs.size():
			var obj: Dictionary = objs[cur_step]
			var obj_type: String = str(obj.get("type", ""))

			if obj_type == "TalkToNPC":
				var target_npc_id: int = int(obj.get("npc_id", 0))
				var alt_ids: Array = obj.get("alt_npc_ids", [])
				var target_npc_name: String = str(obj.get("npc_name", ""))
				
				var matches: bool = (target_npc_id > 0 and target_npc_id == npc_id)
				if not matches and npc_id in alt_ids:
					matches = true
				if not matches and not target_npc_name.is_empty() and not npc_name.is_empty():
					var t_low := target_npc_name.to_lower()
					var n_low := npc_name.to_lower()
					if t_low in n_low or n_low in t_low:
						matches = true

				if matches:
					# Objective match!
					var talk_id: int = int(obj.get("talk_id", default_talk_id))
					var preview: String = str(obj.get("dialogue_preview", ""))

					quest_dialogue_started.emit(qid, npc_id)

					# 1. DialogueManager path
					if dialogue_manager:
						if talk_id > 0 and dialogue_manager.start_talk_id(talk_id, "", npc_name):
							_connect_objective_completion(qid, cur_step)
							return true
						elif not preview.is_empty():
							dialogue_manager.start_dialogue(npc_name, preview)
							_connect_objective_completion(qid, cur_step)
							return true

					# 2. DialogueBox path
					if dialogue_box:
						var display_text := preview if not preview.is_empty() else "Greetings, traveler!"
						dialogue_box.show_dialogue(npc_name, display_text)
						_connect_box_completion(qid, cur_step)
						return true

					# 3. HUD Dialogue path
					if hud:
						var display_text := preview if not preview.is_empty() else "Greetings, traveler!"
						if hud.has_method("show_dialogue"):
							hud.show_dialogue(npc_name, display_text)
							_connect_hud_completion(qid, cur_step)
							return true

					# Headless / fallback: complete objective directly
					complete_objective(qid, cur_step)
					return true

	# No quest objective matched: trigger default talk if available
	if default_talk_id > 0 and dialogue_manager:
		return dialogue_manager.start_talk_id(default_talk_id, "", npc_name)

	return false

func _connect_objective_completion(quest_id: int, step_index: int) -> void:
	if not dialogue_manager:
		return
	var wrapper := {"cb": Callable()}
	wrapper["cb"] = func():
		if dialogue_manager and dialogue_manager.dialogue_closed.is_connected(wrapper["cb"]):
			dialogue_manager.dialogue_closed.disconnect(wrapper["cb"])
		complete_objective(quest_id, step_index)

	dialogue_manager.dialogue_closed.connect(wrapper["cb"])

func _connect_box_completion(quest_id: int, step_index: int) -> void:
	if not dialogue_box:
		return
	var wrapper := {"cb": Callable()}
	wrapper["cb"] = func():
		if dialogue_box and dialogue_box.dialogue_finished.is_connected(wrapper["cb"]):
			dialogue_box.dialogue_finished.disconnect(wrapper["cb"])
		complete_objective(quest_id, step_index)

	dialogue_box.dialogue_finished.connect(wrapper["cb"])

func _connect_hud_completion(quest_id: int, step_index: int) -> void:
	if not hud or not hud.has_signal("dialogue_closed"):
		complete_objective(quest_id, step_index)
		return
	var wrapper := {"cb": Callable()}
	wrapper["cb"] = func():
		if hud and hud.has_signal("dialogue_closed") and hud.dialogue_closed.is_connected(wrapper["cb"]):
			hud.dialogue_closed.disconnect(wrapper["cb"])
		complete_objective(quest_id, step_index)

	hud.dialogue_closed.connect(wrapper["cb"])

## Explicitly advances an active quest objective
func advance_objective(quest_id: int, step_index: int = -1) -> bool:
	if not active_quests.has(quest_id):
		return false
	var cur_step: int = int(active_quests[quest_id].get("current_step", 0))
	var target_step: int = step_index if step_index >= 0 else cur_step
	complete_objective(quest_id, target_step)
	return true

## Advances the first active quest matching objective type and criteria
func advance_objective_by_type(obj_type: String, criteria: Dictionary = {}) -> bool:
	var advanced: bool = false
	for qid in active_quests.keys():
		var q: Dictionary = active_quests[qid]
		if q.get("status", "") != "in_progress":
			continue
		var cur_step: int = int(q.get("current_step", 0))
		var objs: Array = q.get("objectives", [])
		if cur_step >= 0 and cur_step < objs.size():
			var obj: Dictionary = objs[cur_step]
			if str(obj.get("type", "")) == obj_type:
				var matches: bool = true
				for k in criteria.keys():
					if obj.get(k) != criteria[k]:
						matches = false
						break
				if matches:
					complete_objective(qid, cur_step)
					advanced = true
	return advanced

## Advances a quest objective and handles quest rewards upon completion
func complete_objective(quest_id: int, step_index: int) -> void:
	if not active_quests.has(quest_id):
		return

	var q: Dictionary = active_quests[quest_id]
	var objs: Array = q.get("objectives", [])
	var next_step: int = step_index + 1
	q["current_step"] = next_step

	quest_objective_completed.emit(quest_id, step_index)

	if next_step >= objs.size():
		# Quest complete!
		q["status"] = "completed"
		completed_quests[quest_id] = q
		active_quests.erase(quest_id)

		var rewards: Dictionary = q.get("rewards", {})
		quest_completed.emit(quest_id, rewards)
		show_quest_reward_fanfare(q.get("quest_title", ""), rewards)

## Displays authentic quest reward notification and plays wav9911 fanfare
func show_quest_reward_fanfare(quest_title: String, rewards: Dictionary) -> void:
	# 1. Play authentic fanfare
	if hud and hud.has_method("play_sfx"):
		hud.play_sfx("wav9911")
	elif _sfx_reward:
		var player: AudioStreamPlayer = null
		if dialogue_box and dialogue_box.sfx_player:
			player = dialogue_box.sfx_player
		elif dialogue_manager and dialogue_manager.dialogue_box and dialogue_manager.dialogue_box.sfx_player:
			player = dialogue_manager.dialogue_box.sfx_player
		if player and player.is_inside_tree():
			player.stream = _sfx_reward
			player.play()

	# 2. Build reward text
	var gold: int = int(rewards.get("reward_gold", rewards.get("gold", 0)))
	var exp_pts: int = int(rewards.get("reward_exp", rewards.get("exp", 0)))
	var items: Array = rewards.get("reward_items", rewards.get("items", []))

	var summary: String = "Quest Completed: %s!" % quest_title
	if gold > 0:
		summary += " +%d Gold" % gold
	if exp_pts > 0:
		summary += " +%d EXP" % exp_pts
	if not items.is_empty():
		var item_names: Array[String] = []
		for it in items:
			if it is Dictionary:
				item_names.append("%s x%d" % [it.get("item_name", "Item"), int(it.get("count", 1))])
		summary += " [Items: %s]" % ", ".join(item_names)

	quest_reward_displayed.emit(summary)

## Status helpers
func is_quest_completed(quest_id: int) -> bool:
	return completed_quests.has(quest_id)

func is_quest_active(quest_id: int) -> bool:
	return active_quests.has(quest_id)

func get_active_quest(quest_id: int) -> Dictionary:
	return active_quests.get(quest_id, {})

func get_completed_quest(quest_id: int) -> Dictionary:
	return completed_quests.get(quest_id, {})

func get_all_active_quests() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for qid in active_quests.keys():
		list.append(active_quests[qid])
	return list

func get_all_completed_quests() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for qid in completed_quests.keys():
		list.append(completed_quests[qid])
	return list

## Generates unified quest log entries for QuestWindow / HUD
func get_quest_log_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	
	# Active Quests
	for qid in active_quests.keys():
		var q: Dictionary = active_quests[qid]
		var cur_step: int = int(q.get("current_step", 0))
		var objs: Array = q.get("objectives", [])
		var step_desc: String = ""
		if cur_step >= 0 and cur_step < objs.size():
			step_desc = str(objs[cur_step].get("description", objs[cur_step].get("dialogue_preview", "")))
		var rew_str: String = _format_rewards_string(q.get("rewards", {}))
		entries.append({
			"id": qid,
			"title": q.get("quest_title", "Quest #%d" % qid),
			"status": "In Progress",
			"current_step": cur_step,
			"total_steps": objs.size(),
			"objective": step_desc,
			"objectives": objs,
			"reward": rew_str,
			"rewards": q.get("rewards", {})
		})

	# Completed Quests
	for qid in completed_quests.keys():
		var q: Dictionary = completed_quests[qid]
		var objs: Array = q.get("objectives", [])
		var rew_str: String = _format_rewards_string(q.get("rewards", {}))
		entries.append({
			"id": qid,
			"title": q.get("quest_title", "Quest #%d" % qid),
			"status": "Completed",
			"current_step": objs.size(),
			"total_steps": objs.size(),
			"objective": "All objectives completed.",
			"objectives": objs,
			"reward": rew_str,
			"rewards": q.get("rewards", {})
		})

	return entries

func _format_rewards_string(rewards: Dictionary) -> String:
	var parts: Array[String] = []
	var gold: int = int(rewards.get("reward_gold", rewards.get("gold", 0)))
	var exp_pts: int = int(rewards.get("reward_exp", rewards.get("exp", 0)))
	var items: Array = rewards.get("reward_items", rewards.get("items", []))
	if gold > 0:
		parts.append("%d Gold" % gold)
	if exp_pts > 0:
		parts.append("%d EXP" % exp_pts)
	for it in items:
		if it is Dictionary:
			parts.append("%s x%d" % [it.get("item_name", "Item"), int(it.get("count", 1))])
	return ", ".join(parts)
