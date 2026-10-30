## Turns the original server's Eve.emg event scripts into playable NPC conversations.
## The branch and condition rules are a port of the C# server (EveEventRuntime.FindBranch / MatchesCondition).
class_name NpcEventScript
extends RefCounted

## Condition kinds (cond_byte) the server understands; callbacks (4, 7, 8) only run as answers to a question.
const KIND_ALWAYS: int = 0
const KIND_ALL_ZERO: int = 1
const KIND_INVENTORY: int = 2
const KIND_CHEST: int = 3
const KIND_QUEST: int = 5
const KIND_GREETING: int = 6
const KIND_SKILL: int = 10
const KIND_FREE_SLOTS: int = 15

## First answer value of a question: option 1 = 30, option 2 = 31 ...
const ANSWER_BASE: int = 30


## `state`: {"quests": {quest_id: step} (absent = not in progress), "item_count": Callable(item_id) -> int,
## "gold": int, "level": int, "free_slots": int, "skills": {skill_id: grade}}.
static func build(eve_events: Array, npc_event_ids: Array, state: Dictionary, talk_lookup: Callable) -> Dictionary:
	var result: Dictionary = {"pages": [], "actions": [], "event_click_id": 0, "branch_index": 0, "question": 0}
	for click_id_raw in npc_event_ids:
		var event: Dictionary = find_event(eve_events, int(click_id_raw))
		if event.is_empty():
			continue
		# A branch that only changes quest marks (no talk, no question) runs and the search carries on behind it,
		# with the new marks visible (Emilie resets her quiz mark, then asks the riddle).
		var sim: Dictionary = state.duplicate()
		sim["quests"] = state.get("quests", {}).duplicate()
		var start := 0
		var carried: Array = []
		var found := false
		while true:
			var sub: Dictionary = find_branch(event, sim, 0, 0, 0, start)
			if sub.is_empty():
				break
			var script: Dictionary = branch_script(sub, talk_lookup)
			carried.append_array(script["actions"])
			found = true
			result["event_click_id"] = int(event.get("click_id", 0))
			result["branch_index"] = int(sub.get("index", 0))
			result["pages"] = script["pages"]
			result["question"] = script["question"]
			if script["pages"].is_empty() and int(script["question"]) == 0 and not script["actions"].is_empty():
				apply_quest_actions(script["actions"], sim["quests"])
				start = position_of(event, sub) + 1
				continue
			break
		if found:
			result["actions"] = carried
			return result
	return result


static func find_event(eve_events: Array, click_id: int) -> Dictionary:
	for ev in eve_events:
		if ev is Dictionary and int(ev.get("click_id", 0)) == click_id:
			return ev
	return {}


## The branch an event runs. `trigger` 0 = a click; 7 / 8 / 4 = the answer to question `question` (answer value `answer`).
static func find_branch(event: Dictionary, state: Dictionary, trigger: int = 0, question: int = 0, answer: int = 0, start: int = 0) -> Dictionary:
	var subs: Array = event.get("subs", [])
	for i in range(start, subs.size()):
		var sub: Dictionary = subs[i]
		if sub.get("ops", []).is_empty():
			continue
		var kind: int = int(sub.get("cond_byte", 0))
		var is_callback: bool = kind == 4 or kind == 7 or kind == 8
		if trigger == 0:
			if is_callback:
				continue
		else:
			if kind != trigger:
				continue
			var words: Array = sub.get("words", [])
			if words.size() < 5 or int(words[0]) != question:
				continue
			if trigger == 8:
				if not compare(answer, int(words[3]) >> 8, int(words[3]) & 255):
					continue
			elif int(words[1]) != answer:
				continue
		var matches: bool = trigger != 0 or condition_matches(sub, state)
		var words_all: Array = sub.get("words", [])
		var count: int = maxi(1, (int(words_all[5]) >> 8) if words_all.size() > 5 else 1)
		if i + count > subs.size():
			continue
		# The extra conditions belong to the action branch BEFORE them.
		for j in range(i + 1, i + count):
			var cond: Dictionary = subs[j]
			if not cond.get("ops", []).is_empty() or not condition_matches(cond, state):
				matches = false
		if matches:
			return sub
	return {}


## Array position of a branch inside its event (-1 when it is not there).
static func position_of(event: Dictionary, sub: Dictionary) -> int:
	var subs: Array = event.get("subs", [])
	for i in subs.size():
		if int(subs[i].get("index", -1)) == int(sub.get("index", -2)):
			return i
	return -1


## Quest marks as the server writes them: kind 1 adds the amount (and the quest runs), kind 2 completes it (no mark left).
static func apply_quest_actions(actions: Array, quests: Dictionary) -> void:
	for action in actions:
		if not (action is Dictionary) or not action.has("quest_id"):
			continue
		var quest_id: int = int(action["quest_id"])
		match int(action.get("kind", 0)):
			1: quests[quest_id] = int(quests.get(quest_id, 0)) + int(action.get("value", 0))
			2: quests.erase(quest_id)


## Comparison codes of the original: 1 <, 2 >, 3 <=, 4 >=, 5 ==, 6 !=.
static func compare(actual: int, expected: int, comparison: int) -> bool:
	match comparison:
		1: return actual < expected
		2: return actual > expected
		3: return actual <= expected
		4: return actual >= expected
		5: return actual == expected
		6: return actual != expected
	return false


## One condition record (cond_byte + 6 words). Unsupported kinds never match, like on the server.
static func condition_matches(cond: Dictionary, state: Dictionary) -> bool:
	var w: Array = cond.get("words", [])
	while w.size() < 6:
		w.append(0)
	var value: int = (int(w[3]) >> 8) | (int(w[4]) << 8) | ((int(w[5]) & 255) << 24)
	var comparison: int = int(w[3]) & 255
	match int(cond.get("cond_byte", 0)):
		KIND_ALWAYS, KIND_GREETING:
			return true
		KIND_ALL_ZERO:
			return int(w[0]) == 0 and int(w[1]) == 0 and int(w[2]) == 0 and int(w[3]) == 0
		KIND_QUEST:
			var quests: Dictionary = state.get("quests", {})
			var active: bool = quests.has(int(w[0]))
			if int(w[1]) == 2:
				return not active
			if int(w[1]) != 1:
				return false
			return compare(int(quests.get(int(w[0]), 0)), value, comparison)
		KIND_INVENTORY:
			if int(w[0]) == 2:
				# pet sub-kind 5: how many pets are missing from a full stable of 4 (C# EveEventRuntime case 5)
				if int(w[1]) == 5:
					var pets: Array = state.get("pets", [])
					return compare(maxi(0, 4 - pets.size()), value, comparison)
				# companion following (sub-kind 6, C# case 6): the active companion must be the packed template
				if int(w[2]) != 0 or value <= 0 or value > 65535 or (comparison != 5 and comparison != 6):
					return false
				var following: bool = int(state.get("active_companion", 0)) == value
				return following if comparison == 5 else not following
			if int(w[0]) != 1:
				return false
			match int(w[1]):
				1:
					var counter: Callable = state.get("item_count", Callable())
					var count: int = int(counter.call(int(w[2]))) if counter.is_valid() else 0
					return compare(count, value, comparison)
				2:
					return compare(int(state.get("gold", 0)), value, comparison)
				3:
					return compare(int(state.get("level", 1)), value, comparison)
			return false
		KIND_CHEST:
			return compare(0, value, comparison) # chests are never opened yet
		KIND_SKILL:
			if int(w[1]) != 1 or int(w[2]) != 0:
				return false
			var skills: Dictionary = state.get("skills", {})
			return compare(int(skills.get(int(w[0]), 0)), value, comparison)
		KIND_FREE_SLOTS:
			return int(w[0]) == 1 and compare(int(state.get("free_slots", 0)), value, comparison)
	return false


## True when the branch ends by asking the player a question (opcode 2 with d2 == 6); returns its question id, else 0.
static func question_id(sub: Dictionary) -> int:
	for op_raw in sub.get("ops", []):
		if op_raw is Dictionary and int(op_raw.get("opcode", 0)) == 2 and int(op_raw.get("d2", 0)) == 6:
			return int(op_raw.get("d3", 0))
	return 0


## Pages and actions of one branch.
static func branch_script(sub: Dictionary, talk_lookup: Callable) -> Dictionary:
	var result: Dictionary = {"pages": [], "actions": [], "question": question_id(sub)}
	_process_ops(sub.get("ops", []), talk_lookup, result["pages"], result["actions"])
	return result


## Strips the original token markup (#c0, #e ...) while keeping BBCode colours (=#ff0000).
static func clean_text(raw: String) -> String:
	var regex := RegEx.new()
	regex.compile("(?<!=)#[a-z]\\d+|(?<!=)#[a-z](?![a-zA-Z0-9])")
	return regex.sub(raw, "", true)


static func _process_ops(ops: Array, talk_lookup: Callable, pages: Array, actions: Array) -> void:
	for op_raw in ops:
		if not (op_raw is Dictionary):
			continue
		var op: Dictionary = op_raw
		var opcode: int = int(op.get("opcode", 0))
		var d1: int = int(op.get("d1", 0))
		var d2: int = int(op.get("d2", 0))
		var d3: int = int(op.get("d3", 0))
		var d4: int = int(op.get("d4", 0))
		if opcode == 2:
			if d3 >= 10000:
				_add_talk_page("npc", d3, talk_lookup, pages)
		elif opcode == 1:
			if d1 == 2 and d2 >= 10000:
				_add_talk_page("player", d2, talk_lookup, pages)
			elif d1 == 1 and d2 == 1 and d3 >= 30000:
				actions.append({"reward_item": d3, "count": maxi(1, d4 >> 8)})
			elif d1 == 1 and d2 == 2 and d3 == 0:
				actions.append({"gold": _action_value(op)})
			elif d1 == 1 and d2 == 5 and d3 == 1:
				actions.append({"exp": _action_value(op)})
			elif d1 == 3:
				actions.append({"transition": d2})
		elif opcode == 5:
			actions.append({"quest_id": d1, "kind": d2, "value": _action_value(op)})


## The packed signed amount of an action: (d4 >> 8) | (dword1 << 8), as the server decodes it.
static func _action_value(op: Dictionary) -> int:
	var dw: Array = op.get("dw", [0, 0, 0])
	var raw: int = ((int(op.get("d4", 0)) >> 8) | (int(dw[0]) << 8)) & 0xFFFFFFFF
	return raw - 0x100000000 if raw >= 0x80000000 else raw


static func _add_talk_page(who: String, talk_id: int, talk_lookup: Callable, pages: Array) -> void:
	var talk_info: Dictionary = talk_lookup.call(talk_id)
	var cleaned: String = clean_text(str(talk_info.get("text", "")))
	if not cleaned.is_empty():
		pages.append({"who": who, "talk_id": talk_id, "text": cleaned})
