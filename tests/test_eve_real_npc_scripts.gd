extends SceneTree

## The real Eve.emg of the original server drives Kelan Village NPCs: Doll's quest chain, Emilie's quiz start and the Guard.

const NpcEventScript = preload("res://scripts/map/npc_event_script.gd")
const EveParser = preload("res://scripts/map/eve_parser.gd")

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


func _ids(pages: Array) -> Array:
	var out: Array = []
	for p in pages:
		out.append(int(p["talk_id"]))
	return out


func _run() -> void:
	print("--- Real Eve NPC Script Suite ---")
	await process_frame
	await process_frame
	var talks = root.get_node("GameDatabase").talks
	var eve := EveParser.new()
	var lookup: Callable = func(id: int) -> Dictionary: return talks.get_talk(id)
	var events: Array = eve.get_events_for_map(12000)
	_check(events.size() > 20, "Eve.emg has the Kelan Village events (%d)" % events.size())
	var doll := {}
	var emilie := {}
	var guard := {}
	for sp in eve.get_npcs_for_map(12000):
		if sp.npc_id == 14141: doll = {"events": sp.events}
		if sp.npc_id == 14140: emilie = {"events": sp.events}
		if sp.npc_id == 14118 and guard.is_empty(): guard = {"events": sp.events}

	var fresh := {"quests": {}, "gold": 0, "level": 3, "free_slots": 20}
	var doll_first: Dictionary = NpcEventScript.build(events, doll["events"], fresh, lookup)
	_check(not doll_first["pages"].is_empty() and _ids(doll_first["pages"])[0] == 20222, "Doll's first line is 20222 for a fresh player: %s" % [_ids(doll_first["pages"])])
	var branch: Dictionary = {}
	for sub in NpcEventScript.find_event(events, int(doll_first["event_click_id"])).get("subs", []):
		if int(sub["index"]) == int(doll_first["branch_index"]) and not sub["ops"].is_empty():
			branch = sub
	_check(NpcEventScript.question_id(branch) == 1, "Doll ends the first talk with question 1 (Yes / No)")
	var doll_event: Dictionary = NpcEventScript.find_event(events, int(doll_first["event_click_id"]))
	var yes: Dictionary = NpcEventScript.find_branch(doll_event, fresh, 7, 1, NpcEventScript.ANSWER_BASE)
	var no: Dictionary = NpcEventScript.find_branch(doll_event, fresh, 7, 1, NpcEventScript.ANSWER_BASE + 1)
	_check(not yes.is_empty() and not no.is_empty(), "Yes (30) and No (31) answers both exist")
	var yes_actions: Array = NpcEventScript.branch_script(yes, lookup)["actions"]
	var starts := false
	for a in yes_actions:
		if a.get("quest_id", 0) == 12018 and a.get("kind", 0) == 1:
			starts = true
	_check(starts, "Yes starts quest 12018 (step 1)")
	var no_ids: Array = _ids(NpcEventScript.branch_script(no, lookup)["pages"])
	_check(no_ids.has(20229), "No answers with line 20229: %s" % [no_ids])

	var started := {"quests": {12018: 1}, "gold": 0, "level": 3, "free_slots": 20}
	var reminder: Dictionary = NpcEventScript.build(events, doll["events"], started, lookup)
	_check(_ids(reminder["pages"]).has(20228), "While quest 12018 is at step 1 Doll sends the player to Emilie (20228)")
	var no_pepper: Dictionary = NpcEventScript.build(events, doll["events"], {"quests": {12018: 2}, "item_count": func(_id: int) -> int: return 0, "gold": 0, "level": 3, "free_slots": 20}, lookup)
	_check(_ids(no_pepper["pages"]).has(20228), "At step 2 without the Hill Pepper (item 30028) Doll repeats the hint (20228)")
	var has_pepper: Callable = func(item_id: int) -> int: return 1 if item_id == 30028 else 0
	var finishing := {"quests": {12018: 2}, "item_count": has_pepper, "gold": 0, "level": 3, "free_slots": 20}
	var hand_in: Dictionary = NpcEventScript.build(events, doll["events"], finishing, lookup)
	var hand_ids: Array = _ids(hand_in["pages"])
	_check(hand_ids.has(20233) and hand_ids.has(20234) and hand_ids.has(20235), "At step 2 Doll takes the pepper and thanks the player (20233..20235): %s" % [hand_ids])
	var rewards := false
	for a in hand_in["actions"]:
		if a.get("reward_item", 0) == 34076:
			rewards = true
	_check(rewards, "The hand-in rewards the Radio Set (34076)")

	var emilie_built: Dictionary = NpcEventScript.build(events, emilie["events"], fresh, lookup)
	_check(not emilie_built["pages"].is_empty(), "Emilie says something to a fresh player: %s" % [_ids(emilie_built["pages"])])
	# Emilie's quiz while the pepper quest runs: lines, then question(s) whose answers chain on.
	var quiz: Dictionary = NpcEventScript.build(events, emilie["events"], started, lookup)
	var quiz_event: Dictionary = NpcEventScript.find_event(events, int(quiz["event_click_id"]))
	var quiz_branch: Dictionary = {}
	for sub in quiz_event.get("subs", []):
		if int(sub["index"]) == int(quiz["branch_index"]) and not sub["ops"].is_empty():
			quiz_branch = sub
	var q1: int = NpcEventScript.question_id(quiz_branch)
	_check(q1 > 0, "Emilie asks a riddle question during quest 12018: q=%d pages=%s" % [q1, _ids(quiz["pages"])])
	var answered := 0
	for i in 3:
		var ans: Dictionary = NpcEventScript.find_branch(quiz_event, started, 7, q1, NpcEventScript.ANSWER_BASE + i)
		if not ans.is_empty():
			answered += 1
	_check(answered == 3, "Emilie's first riddle has answers 30, 31 and 32 (%d)" % answered)
	var choices: Array = talks.get_talk(20337).get("choices", [])
	_check(choices.size() == 3, "The riddle prompt (Talk 20337) offers three options: %s" % [choices])

	# Play the whole quiz through the rules: correct = option 2 ("2") then Q11 option 2 ("3").
	var play := {"quests": {12018: 1}, "gold": 0, "level": 3, "free_slots": 20}
	var first: Dictionary = NpcEventScript.build(events, emilie["events"], play, lookup)
	NpcEventScript.apply_quest_actions(first["actions"], play["quests"])
	var a10: Dictionary = NpcEventScript.find_branch(quiz_event, play, 7, 10, NpcEventScript.ANSWER_BASE + 1)
	var s10: Dictionary = NpcEventScript.branch_script(a10, lookup)
	NpcEventScript.apply_quest_actions(s10["actions"], play["quests"])
	_check(int(s10["question"]) == 11, "A right first answer leads on to question 11")
	var a11: Dictionary = NpcEventScript.find_branch(quiz_event, play, 7, 11, NpcEventScript.ANSWER_BASE + 1)
	NpcEventScript.apply_quest_actions(NpcEventScript.branch_script(a11, lookup)["actions"], play["quests"])
	var done: Dictionary = NpcEventScript.find_branch(quiz_event, play, 0, 0, 0, NpcEventScript.position_of(quiz_event, a11) + 1)
	var done_script: Dictionary = NpcEventScript.branch_script(done, lookup)
	var got_pepper := false
	for a in done_script["actions"]:
		if a.get("reward_item", 0) == 30028:
			got_pepper = true
	_check(_ids(done_script["pages"]).has(20340) and got_pepper, "Two right answers: Emilie says 20340 and gives the Hill Pepper: %s" % [_ids(done_script["pages"])])
	var bad := {"quests": {12018: 1}, "gold": 0, "level": 3, "free_slots": 20}
	NpcEventScript.apply_quest_actions(first["actions"], bad["quests"])
	NpcEventScript.apply_quest_actions(NpcEventScript.branch_script(NpcEventScript.find_branch(quiz_event, bad, 7, 10, NpcEventScript.ANSWER_BASE), lookup)["actions"], bad["quests"])
	var wrong: Dictionary = NpcEventScript.find_branch(quiz_event, bad, 0, 0, 0, NpcEventScript.position_of(quiz_event, a11) + 1)
	_check(_ids(NpcEventScript.branch_script(wrong, lookup)["pages"]).has(20339), "A wrong first answer ends with 'Sorry, your answer is wrong' (20339)")

	var guard_built: Dictionary = NpcEventScript.build(events, guard["events"], fresh, lookup)
	_check(_ids(guard_built["pages"]).has(30037), "The Guard says 'house of our Village Leader' (30037)")

	print("\n--- %d TESTS, %d FAILED ---" % [_count, _failures])
	quit(1 if _failures > 0 else 0)
