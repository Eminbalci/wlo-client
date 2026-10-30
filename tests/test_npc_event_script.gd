extends SceneTree

const NpcEventScript = preload("res://scripts/map/npc_event_script.gd")

var _count: int = 0
var _failures: int = 0


func _init() -> void:
	_run()


func _check(ok: bool, label: String) -> void:
	_count += 1
	if ok:
		print("  [PASS] " + label)
	else:
		print("  [FAIL] " + label)
		_failures += 1


func _make_op(opcode: int, d1: int = 0, d2: int = 0, d3: int = 0, d4: int = 0) -> Dictionary:
	return {"index": 0, "opcode": opcode, "d1": d1, "d2": d2, "d3": d3, "d4": d4, "dw": [0, 0, 0]}


func _state(quests: Dictionary) -> Dictionary:
	return {"quests": quests, "gold": 0, "level": 1, "free_slots": 10}


func _run() -> void:
	var talk_lookup: Callable = func(talk_id: int) -> Dictionary:
		if talk_id == 20224:
			return {}
		return {"text": "T" + str(talk_id)}

	var sub_1: Dictionary = {"index": 1, "cond_byte": 5, "words": [12018, 2, 1, 0, 0, 512], "ops": [
		_make_op(2, 0, 0, 20222, 0), _make_op(2, 0, 0, 20223, 0), _make_op(1, 2, 20224, 0, 0), _make_op(2, 0, 0, 20225, 0)]}
	var sub_5: Dictionary = {"index": 5, "cond_byte": 5, "words": [12018, 1, 1, 261, 0, 256], "ops": [_make_op(2, 0, 0, 20228, 0)]}
	var sub_10: Dictionary = {"index": 10, "cond_byte": 5, "words": [12018, 1, 1, 517, 0, 256], "ops": [
		_make_op(1, 2, 20233, 0, 0), _make_op(2, 0, 0, 20234, 0), _make_op(5, 12018, 2, 1, 0), _make_op(1, 1, 1, 34076, 256)]}
	var cond_12019: Dictionary = {"index": 2, "cond_byte": 5, "words": [12019, 1, 1, 5, 0, 0], "ops": []}
	var event_14: Dictionary = {"click_id": 14, "name": "Eh", "subs": [sub_1, cond_12019, sub_5, sub_10]}
	var sub_e7: Dictionary = {"index": 1, "cond_byte": 6, "words": [0, 0, 0, 0, 0, 0], "ops": [_make_op(2, 0, 0, 30037, 0)]}
	var event_7: Dictionary = {"click_id": 7, "name": "s7", "subs": [sub_e7]}
	var eve_events: Array = [event_14, event_7]

	var res1: Dictionary = NpcEventScript.build(eve_events, [14], _state({}), talk_lookup)
	_check(res1.get("event_click_id", 0) == 14, "Fresh player: event 14 is chosen")
	_check(res1.get("branch_index", -1) == 1, "Fresh player: branch 1 is chosen")
	var pages1: Array = res1.get("pages", [])
	_check(pages1.size() == 3, "Fresh player: 3 pages (the unknown player line 20224 is skipped)")
	if pages1.size() == 3:
		_check(pages1[0].get("talk_id") == 20222 and pages1[1].get("talk_id") == 20223 and pages1[2].get("talk_id") == 20225, "Fresh player: pages in order 20222, 20223, 20225")

	var res2: Dictionary = NpcEventScript.build(eve_events, [14], _state({12018: 1}), talk_lookup)
	_check(res2.get("branch_index", -1) == 5, "Quest step 1: branch 5")
	_check(res2.get("pages", []).size() == 1 and res2["pages"][0].get("talk_id") == 20228, "Quest step 1: single page 20228")

	var res3: Dictionary = NpcEventScript.build(eve_events, [14], _state({12018: 2}), talk_lookup)
	_check(res3.get("branch_index", -1) == 10, "Quest step 2: branch 10")
	var pages3: Array = res3.get("pages", [])
	_check(pages3.size() == 2 and pages3[0].get("who") == "player" and pages3[1].get("who") == "npc", "Quest step 2: the player speaks first, then the NPC")
	var found_quest := false
	var found_reward := false
	for act in res3.get("actions", []):
		if act.get("quest_id") == 12018 and act.get("kind") == 2:
			found_quest = true
		if act.get("reward_item") == 34076 and act.get("count") == 1:
			found_reward = true
	_check(found_quest, "Quest step 2: quest 12018 finish action")
	_check(found_reward, "Quest step 2: reward item 34076 x1")

	var res4: Dictionary = NpcEventScript.build(eve_events, [7], _state({}), talk_lookup)
	_check(res4.get("event_click_id", 0) == 7 and res4.get("pages", []).size() == 1, "Event 7 gives its single line")
	var res5: Dictionary = NpcEventScript.build(eve_events, [14, 7], _state({12018: 2}), talk_lookup)
	_check(res5.get("event_click_id", 0) == 14, "Event order: 14 wins before 7")
	var res6: Dictionary = NpcEventScript.build(eve_events, [9999], _state({}), talk_lookup)
	_check(res6.get("pages", []).is_empty() and res6.get("event_click_id", -1) == 0, "Unknown event ids give nothing")
	var sub_15: Dictionary = {"cond_byte": 15, "words": [0, 0, 0, 0, 0, 0], "ops": [_make_op(2, 0, 0, 10001, 0)]}
	_check(not NpcEventScript.condition_matches(sub_15, _state({})), "Unsupported condition kinds never match")
	_check(NpcEventScript.clean_text("a#c0b#e[color=#ff0000]x[/color]") == "ab[color=#ff0000]x[/color]", "Token markup is stripped, BBCode kept")

	var shut: Dictionary = NpcEventScript.build(eve_events, [14], _state({12019: 1}), talk_lookup)
	_check(shut.get("branch_index", -1) != 1, "A trailing condition (quest 12019 active) shuts the first branch")
	var yes_sub: Dictionary = {"index": 3, "cond_byte": 7, "words": [1, 30, 0, 0, 0, 256], "ops": [_make_op(5, 12018, 1, 1, 256)]}
	var no_sub: Dictionary = {"index": 4, "cond_byte": 7, "words": [1, 31, 0, 0, 0, 256], "ops": [_make_op(2, 0, 0, 20229, 0)]}
	var asking: Dictionary = {"click_id": 20, "name": "q", "subs": [yes_sub, no_sub]}
	_check(NpcEventScript.find_branch(asking, _state({}), 7, 1, 30).get("index", 0) == 3, "Answer 30 runs the Yes branch")
	_check(NpcEventScript.find_branch(asking, _state({}), 7, 1, 31).get("index", 0) == 4, "Answer 31 runs the No branch")
	_check(NpcEventScript.find_branch(asking, _state({})).is_empty(), "Answer branches never run on a plain click")
	_check(NpcEventScript.question_id({"ops": [_make_op(2, 12, 6, 1, 0)]}) == 1, "Opcode 2 with d2 == 6 asks question d3")
	var gold_cond: Dictionary = {"cond_byte": 2, "words": [1, 2, 0, 4 | (100 << 8), 0, 0]}
	_check(NpcEventScript.condition_matches(gold_cond, {"gold": 150}) and not NpcEventScript.condition_matches(gold_cond, {"gold": 50}), "Kind 2 / gold compares with >= 100")
	var item_cond: Dictionary = {"cond_byte": 2, "words": [1, 1, 34076, 4 | (1 << 8), 0, 0]}
	var has_item: Callable = func(item_id: int) -> int: return 1 if item_id == 34076 else 0
	_check(NpcEventScript.condition_matches(item_cond, {"item_count": has_item}), "Kind 2 / item count finds the item")
	var slots_cond: Dictionary = {"cond_byte": 15, "words": [1, 0, 0, 4 | (2 << 8), 0, 0]}
	_check(NpcEventScript.condition_matches(slots_cond, {"free_slots": 3}) and not NpcEventScript.condition_matches(slots_cond, {"free_slots": 1}), "Kind 15 needs free bag slots")

	# Pet sub-kind 5: 4 minus the pets owned must satisfy the comparison (C# case 5)
	var pet_cond_zero_owned: Dictionary = {"cond_byte": 2, "words": [2, 5, 0, 4 | (3 << 8), 0, 0]}
	_check(NpcEventScript.condition_matches(pet_cond_zero_owned, {"pets": []}), "Pet count: 4 missing pets is >= 3")
	_check(not NpcEventScript.condition_matches(pet_cond_zero_owned, {"pets": [1, 2, 3, 4]}), "Pet count: a full stable (0 missing) is not >= 3")
	var pet_companion: Dictionary = {"cond_byte": 2, "words": [2, 6, 0, 5 | (1 << 8), 0, 0]}
	_check(not NpcEventScript.condition_matches(pet_companion, {"pets": [1]}), "Companion following stays unmodelled (never matches)")

	# Companion following (sub-kind 6): the active companion must equal the packed template
	var companion_cond: Dictionary = {"cond_byte": 2, "words": [2, 6, 0, 5 | (8090 << 8), 0, 0]}
	_check(NpcEventScript.condition_matches(companion_cond, {"active_companion": 8090}), "Companion 8090 following matches the == test")
	_check(not NpcEventScript.condition_matches(companion_cond, {"active_companion": 0}), "No active companion does not match")
	var companion_not: Dictionary = {"cond_byte": 2, "words": [2, 6, 0, 6 | (8090 << 8), 0, 0]}
	_check(not NpcEventScript.condition_matches(companion_not, {"active_companion": 8090}), "Companion 8090 following fails the != test")
	# Chest (kind 3): an opened chest is the completed key map*1000 + event click id
	var chest_opened: Dictionary = {"cond_byte": 3, "words": [0, 0, 0, 5 | (1 << 8), 0, 0]}
	_check(NpcEventScript.condition_matches(chest_opened, {"map_id": 10003, "event_click": 1, "completed_keys": {10003001: true}}), "Opened chest (key 10003001) satisfies == 1")
	_check(not NpcEventScript.condition_matches(chest_opened, {"map_id": 10003, "event_click": 1, "completed_keys": {}}), "Unopened chest does not satisfy == 1")
	_check(not NpcEventScript.condition_matches(chest_opened, {"map_id": 10003, "event_click": 2, "completed_keys": {10003001: true}}), "A different chest (click 2) is not opened by key 10003001")

	print("\n--- %d TESTS, %d FAILED ---" % [_count, _failures])
	quit(1 if _failures > 0 else 0)
