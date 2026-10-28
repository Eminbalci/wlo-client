extends SceneTree

## Master Headless Automated Test Suite: Quest Dialogue Connection & Starter Quests
## Tests:
## 1. QuestDialogueComponent registration of Quest 1001 and Quest 1002
## 2. TalkToNPC objective matching, dialogue triggering, and objective completion
## 3. Sinking cutscene awakening progression (SurviveSinking)
## 4. Monkey Beach Kelang dialogue, quest completion signal, and reward dispatch
## 5. Beach chest container searching objective progression (SearchContainer)
## 6. Kelang report-back and Quest 1002 completion with Protective EXP Pill
## 7. QuestWindow / QuestLogRichText rich BBCode generation & formatted status
## 8. MapView quest component integration, signal wiring, and NPC interaction helper

const MapViewScript = preload("res://scripts/map/map_view.gd")
const QuestDialogueComponentScript = preload("res://scripts/ui/quest/quest_dialogue_component.gd")
const HUDWindowManagerScript = preload("res://scripts/ui/hud/hud_window_manager.gd")

func _init() -> void:
	print("=================================================================")
	print("--- Running Quest to Dialogue Connection Automated Test Suite ---")
	print("=================================================================\n")

	_init_autoloads()

	_test_quest_dialogue_registration()
	_test_quest_1001_progression_and_completion()
	_test_quest_1002_container_and_completion()
	_test_quest_window_bbcode_formatting()
	_test_map_view_quest_component_integration()

	print("\n=================================================================")
	print("--- ALL QUEST TO DIALOGUE TESTS PASSED (100% ZERO-ERROR) ---")
	print("=================================================================\n")
	quit(0)

func _init_autoloads() -> void:
	if not root.has_node("ArchiveLoader"):
		var arch_loader = load("res://scripts/core/archive_loader.gd").new()
		arch_loader.name = "ArchiveLoader"
		root.add_child(arch_loader)
	
	if not root.has_node("GameDatabase"):
		var gdb = load("res://scripts/database/game_database.gd").new()
		gdb.name = "GameDatabase"
		root.add_child(gdb)

func _test_quest_dialogue_registration() -> void:
	print(">>> [TEST 1] Testing QuestDialogueComponent registration...")
	var q_comp := QuestDialogueComponentScript.new()
	root.add_child(q_comp)

	# Verify empty initial state
	assert(q_comp.active_quests.is_empty(), "ERROR: Initial active quests must be empty")
	assert(q_comp.completed_quests.is_empty(), "ERROR: Initial completed quests must be empty")

	# Register Quest 1001: The Awakening Voyage
	q_comp.register_quest({
		"quest_id": 1001,
		"quest_title": "The Awakening Voyage",
		"current_step": 0,
		"objectives": [
			{
				"step_index": 0,
				"type": "TalkToNPC",
				"npc_id": 14003,
				"npc_name": "Captain Robinson",
				"description": "Talk to Captain Robinson (NPC 14003) on Ship Deck (Map 10001)."
			},
			{
				"step_index": 1,
				"type": "SurviveSinking",
				"description": "Survive Ship Sinking & Awaken on Deserted Island (Map 10003)."
			},
			{
				"step_index": 2,
				"type": "TalkToNPC",
				"npc_id": 12032,
				"alt_npc_ids": [14062],
				"npc_name": "Kelang",
				"description": "Talk to Kelang (NPC 12032) on Monkey Beach."
			}
		],
		"rewards": {
			"reward_gold": 100,
			"reward_exp": 250,
			"reward_items": [
				{"item_id": 41066, "item_name": "Fresh Coconut", "count": 3, "icon_id": 1379}
			]
		}
	})

	assert(q_comp.is_quest_active(1001), "ERROR: Quest 1001 must be active")
	var q1 := q_comp.get_active_quest(1001)
	assert(q1.get("quest_title") == "The Awakening Voyage", "ERROR: Quest title mismatch")
	assert(int(q1.get("current_step")) == 0, "ERROR: Initial step must be 0")
	assert(q1.get("objectives", []).size() == 3, "ERROR: Objectives count mismatch")

	# Register Quest 1002: Supplies from the Wreck
	q_comp.register_quest({
		"quest_id": 1002,
		"quest_title": "Supplies from the Wreck",
		"current_step": 0,
		"objectives": [
			{
				"step_index": 0,
				"type": "SearchContainer",
				"target": "beach_chest",
				"description": "Search washed up beach chests/containers."
			},
			{
				"step_index": 1,
				"type": "TalkToNPC",
				"npc_id": 12032,
				"npc_name": "Kelang",
				"description": "Report back to Kelang (NPC 12032)."
			}
		],
		"rewards": {
			"reward_gold": 150,
			"reward_exp": 300,
			"reward_items": [
				{"item_id": 34026, "item_name": "Protective EXP Pill", "count": 1, "icon_id": 1768}
			]
		}
	})

	assert(q_comp.is_quest_active(1002), "ERROR: Quest 1002 must be active")
	q_comp.queue_free()
	print("  [PASS] Registration and data structures verified.")

func _test_quest_1001_progression_and_completion() -> void:
	print(">>> [TEST 2] Testing Quest 1001 multi-step progression & rewards...")
	var q_comp := QuestDialogueComponentScript.new()
	root.add_child(q_comp)

	q_comp.register_quest({
		"quest_id": 1001,
		"quest_title": "The Awakening Voyage",
		"current_step": 0,
		"objectives": [
			{"step_index": 0, "type": "TalkToNPC", "npc_id": 14003, "npc_name": "Captain Robinson", "description": "Talk to Captain Robinson"},
			{"step_index": 1, "type": "SurviveSinking", "description": "Survive Ship Sinking"},
			{"step_index": 2, "type": "TalkToNPC", "npc_id": 12032, "alt_npc_ids": [14062], "npc_name": "Kelang", "description": "Talk to Kelang"}
		],
		"rewards": {
			"reward_gold": 100,
			"reward_exp": 250,
			"reward_items": [
				{"item_id": 41066, "item_name": "Fresh Coconut", "count": 3, "icon_id": 1379}
			]
		}
	})

	var signals_received := {
		"started": 0,
		"obj_completed": 0,
		"quest_completed": 0,
		"reward_displayed": 0,
		"last_rewards": {},
		"last_msg": ""
	}

	q_comp.quest_dialogue_started.connect(func(qid: int, _nid: int):
		if qid == 1001: signals_received["started"] += 1
	)
	q_comp.quest_objective_completed.connect(func(qid: int, _step: int):
		if qid == 1001: signals_received["obj_completed"] += 1
	)
	q_comp.quest_completed.connect(func(qid: int, rewards: Dictionary):
		if qid == 1001:
			signals_received["quest_completed"] += 1
			signals_received["last_rewards"] = rewards
	)
	q_comp.quest_reward_displayed.connect(func(msg: String):
		signals_received["reward_displayed"] += 1
		signals_received["last_msg"] = msg
	)

	# Step 0: Player talks to Captain Robinson (NPC 14003)
	var handled := q_comp.interact_with_npc(14003, "Captain Robinson")
	assert(handled == true, "ERROR: Captain Robinson interaction must be handled")
	assert(signals_received["started"] == 1, "ERROR: quest_dialogue_started not emitted")
	assert(signals_received["obj_completed"] == 1, "ERROR: Step 0 must be completed")
	assert(int(q_comp.get_active_quest(1001).get("current_step")) == 1, "ERROR: Current step must now be 1")

	# Step 1: Ship Sinking Cutscene awakens on Deserted Island
	var adv_sinking := q_comp.advance_objective_by_type("SurviveSinking")
	assert(adv_sinking == true, "ERROR: SurviveSinking objective must advance")
	assert(signals_received["obj_completed"] == 2, "ERROR: Step 1 must be completed")
	assert(int(q_comp.get_active_quest(1001).get("current_step")) == 2, "ERROR: Current step must now be 2")

	# Step 2: Player talks to Kelang (NPC 12032 or 14062) on Monkey Beach
	var kelang_handled := q_comp.interact_with_npc(12032, "Kelang")
	assert(kelang_handled == true, "ERROR: Kelang interaction must be handled")
	assert(signals_received["obj_completed"] == 3, "ERROR: Step 2 must be completed")
	assert(signals_received["quest_completed"] == 1, "ERROR: Quest 1001 must emit quest_completed")
	assert(signals_received["reward_displayed"] == 1, "ERROR: quest_reward_displayed not emitted")

	# Verify quest completed status and rewards
	assert(q_comp.is_quest_completed(1001), "ERROR: Quest 1001 must be in completed_quests")
	assert(not q_comp.is_quest_active(1001), "ERROR: Quest 1001 must no longer be active")
	var rew: Dictionary = signals_received["last_rewards"]
	assert(int(rew.get("reward_gold")) == 100, "ERROR: Expected 100 gold reward")
	assert(int(rew.get("reward_exp")) == 250, "ERROR: Expected 250 exp reward")
	assert(rew.get("reward_items", []).size() == 1, "ERROR: Expected 1 item reward")
	assert(rew.get("reward_items")[0].get("item_name") == "Fresh Coconut", "ERROR: Item name mismatch")

	q_comp.queue_free()
	print("  [PASS] Quest 1001 3-step lifecycle and reward delivery verified.")

func _test_quest_1002_container_and_completion() -> void:
	print(">>> [TEST 3] Testing Quest 1002 container search & Kelang report-back...")
	var q_comp := QuestDialogueComponentScript.new()
	root.add_child(q_comp)

	q_comp.register_quest({
		"quest_id": 1002,
		"quest_title": "Supplies from the Wreck",
		"current_step": 0,
		"objectives": [
			{"step_index": 0, "type": "SearchContainer", "target": "beach_chest", "description": "Search beach chests"},
			{"step_index": 1, "type": "TalkToNPC", "npc_id": 12032, "npc_name": "Kelang", "description": "Report to Kelang"}
		],
		"rewards": {
			"reward_gold": 150,
			"reward_exp": 300,
			"reward_items": [
				{"item_id": 34026, "item_name": "Protective EXP Pill", "count": 1, "icon_id": 1768}
			]
		}
	})

	var completed_tracker := {"fired": false}
	q_comp.quest_completed.connect(func(qid: int, _r: Dictionary):
		if qid == 1002: completed_tracker["fired"] = true
	)

	# Step 0: SearchContainer
	var cont_advanced := q_comp.advance_objective_by_type("SearchContainer")
	assert(cont_advanced == true, "ERROR: SearchContainer objective must advance")
	assert(int(q_comp.get_active_quest(1002).get("current_step")) == 1, "ERROR: Expected current_step == 1")

	# Step 1: Report back to Kelang
	var kelang_done := q_comp.interact_with_npc(12032, "Kelang")
	assert(kelang_done == true, "ERROR: Kelang report-back must be handled")
	assert(completed_tracker["fired"] == true, "ERROR: Quest 1002 quest_completed must fire")
	assert(q_comp.is_quest_completed(1002), "ERROR: Quest 1002 must be marked completed")

	var completed_q := q_comp.get_completed_quest(1002)
	var rew: Dictionary = completed_q.get("rewards", {})
	assert(int(rew.get("reward_gold")) == 150, "ERROR: Expected 150 gold")
	assert(int(rew.get("reward_exp")) == 300, "ERROR: Expected 300 exp")
	assert(rew.get("reward_items")[0].get("item_name") == "Protective EXP Pill", "ERROR: Item mismatch")

	q_comp.queue_free()
	print("  [PASS] Quest 1002 container search and completion verified.")

func _test_quest_window_bbcode_formatting() -> void:
	print(">>> [TEST 4] Testing QuestWindow & QuestLogRichText BBCode rendering...")
	var q_comp := QuestDialogueComponentScript.new()
	root.add_child(q_comp)

	# Register one active and one completed quest
	q_comp.register_quest({
		"quest_id": 1001,
		"quest_title": "The Awakening Voyage",
		"current_step": 1,
		"objectives": [
			{"step_index": 0, "description": "Talk to Captain Robinson"},
			{"step_index": 1, "description": "Survive Ship Sinking & Awaken on Island"},
			{"step_index": 2, "description": "Talk to Kelang on Monkey Beach"}
		],
		"rewards": {"reward_gold": 100, "reward_exp": 250, "reward_items": [{"item_id": 41066, "item_name": "Fresh Coconut", "count": 3}]}
	})

	q_comp.register_quest({
		"quest_id": 1002,
		"quest_title": "Supplies from the Wreck",
		"current_step": 0,
		"objectives": [
			{"step_index": 0, "description": "Search washed up beach chests"},
			{"step_index": 1, "description": "Report back to Kelang"}
		],
		"rewards": {"reward_gold": 150, "reward_exp": 300, "reward_items": [{"item_id": 34026, "item_name": "Protective EXP Pill", "count": 1}]}
	})

	# Complete Quest 1002
	q_comp.complete_objective(1002, 0)
	q_comp.complete_objective(1002, 1)
	assert(q_comp.is_quest_completed(1002), "ERROR: Quest 1002 must be completed")

	var entries: Array[Dictionary] = q_comp.get_quest_log_entries()
	assert(entries.size() == 2, "ERROR: Expected 2 log entries (1 active, 1 completed)")

	# Build mock QuestWindow with QuestLogRichText
	var mock_win := Control.new()
	mock_win.name = "QuestWindow"
	var rich_text := RichTextLabel.new()
	rich_text.name = "QuestLogRichText"
	mock_win.add_child(rich_text)
	root.add_child(mock_win)

	var wm := HUDWindowManagerScript.new()
	wm.quest_window = mock_win
	wm.update_quest_log(entries)

	var text: String = rich_text.text
	assert("--- ACTIVE QUESTS ---" in text, "ERROR: Active quests header missing")
	assert("The Awakening Voyage" in text, "ERROR: Active quest title missing")
	assert("--- COMPLETED QUESTS ---" in text, "ERROR: Completed quests header missing")
	assert("Supplies from the Wreck" in text, "ERROR: Completed quest title missing")
	assert("[x] Talk to Captain Robinson" in text, "ERROR: Completed step checkmark missing")
	assert("[→] Survive Ship Sinking & Awaken on Island" in text, "ERROR: Active step arrow missing")
	assert("[ ] Talk to Kelang on Monkey Beach" in text, "ERROR: Future step checkbox missing")
	assert("Rewards: 100 Gold, 250 EXP, Fresh Coconut x3" in text, "ERROR: Formatted reward summary missing")

	mock_win.queue_free()
	q_comp.queue_free()
	print("  [PASS] Rich BBCode formatting with active/completed sections verified.")

func _test_map_view_quest_component_integration() -> void:
	print(">>> [TEST 5] Testing MapView quest_component integration & NPC helper...")
	var map_view_scene: PackedScene = load("res://scenes/world/map_view.tscn")
	var map_view: MapViewScript = (map_view_scene.instantiate() if map_view_scene else MapViewScript.new()) as MapViewScript
	root.add_child(map_view)
	map_view.ensure_quest_component()

	# Verify quest_component initialized in MapView
	assert(map_view.quest_component != null, "ERROR: MapView.quest_component must be instantiated")
	assert(map_view.quest_component.is_quest_active(1001), "ERROR: Quest 1001 must be registered by default")
	assert(map_view.quest_component.is_quest_active(1002), "ERROR: Quest 1002 must be registered by default")

	# Test interact_with_npc_quest
	var handled_robinson: bool = map_view.interact_with_npc_quest(14003, "Captain Robinson", 30124)
	assert(handled_robinson == true, "ERROR: interact_with_npc_quest for Robinson must return true")

	# Robinson interaction advances Step 0
	var q1001: Dictionary = map_view.quest_component.get_active_quest(1001)
	assert(int(q1001.get("current_step")) == 1, "ERROR: Step must now be 1")

	# Non-quest NPC returns false
	var handled_random: bool = map_view.interact_with_npc_quest(99999, "Random Sailor", 0)
	assert(handled_random == false, "ERROR: Unrelated NPC must return false")

	map_view.queue_free()
	print("  [PASS] MapView quest_component lifecycle and helper methods verified.")
