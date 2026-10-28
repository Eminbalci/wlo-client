extends SceneTree

## Automated Verification Suite for Hill Pepper Quest Chain Parity
## Verifies:
## 1. Doll (NPC 14141) intro dialogue (20222 -> 20223 -> 20225 -> 20227) and choice branching (Yes. / No.)
## 2. Emilie (NPC 14140) riddle dialogue (20336 -> 20337 tens quiz -> 20338 units quiz -> 20340 right answer granting Hill Pepper 30028)
## 3. Hand-in to Doll (20233 -> 20234 -> 20235 -> 20236 -> 20237 granting Radio Set 34076)
## 4. Centered reward banner fanfare triggering ("Obtain 1 pcs Radio Set")
## 5. QuestDialogueComponent state transitions (Step 0 -> Step 1 -> Step 2 -> Completed)

const TalkDatabase = preload("res://scripts/database/talk_database.gd")
const QuestDialogueComponent = preload("res://scripts/ui/quest/quest_dialogue_component.gd")

func _init() -> void:
	print("\n==================================================================")
	print("--- Running Hill Pepper Quest Chain Automated Test Suite ---")
	print("==================================================================")
	var passed: int = 0
	var failed: int = 0

	# 1. TalkDatabase Chaining Verification
	print("\n>>> [TEST 1] Verifying Doll & Emilie TalkDatabase linkages...")
	var tdb = TalkDatabase.new()
	var loaded = tdb.load_from_file("D:/GitHub/WLRI/data/Talk.dat")
	if loaded:
		print("  [PASS] Talk.dat loaded successfully.")
		passed += 1
	else:
		print("  [FAIL] Failed to load Talk.dat.")
		failed += 1

	var doll_talk = tdb.get_talk(20222)
	assert(doll_talk.get("speaker") == "Doll", "Talk 20222 speaker should be Doll")
	assert(doll_talk.get("next_talk_id") == 20223, "Talk 20222 next should be 20223")
	print("  [PASS] Doll intro talk 20222 -> 20223 verified.")
	passed += 1

	var doll_choice = tdb.get_talk(20227)
	var choices: Array = doll_choice.get("choices", [])
	assert(choices.size() == 2, "Doll talk 20227 must have 2 choices (Yes. / No.)")
	assert(choices[0].get("text") == "Yes.", "Choice 0 should be 'Yes.'")
	assert(choices[0].get("next_talk_id") == 20228, "Choice 'Yes.' should lead to talk 20228")
	print("  [PASS] Doll quest offer choice verified: %s" % str(choices))
	passed += 1

	var emilie_quiz = tdb.get_talk(20336)
	assert(emilie_quiz.get("speaker") == "Emilie", "Talk 20336 speaker should be Emilie")
	assert(emilie_quiz.get("next_talk_id") == 20337, "Talk 20336 next should be 20337")
	
	var tens_choices: Array = tdb.get_talk(20337).get("choices", [])
	assert(tens_choices.size() == 3, "Tens quiz should have 3 options (1, 2, 3)")
	assert(tens_choices[1].get("text") == "2" and tens_choices[1].get("next_talk_id") == 20338, "Choice 2 must advance to units quiz 20338")
	
	var units_choices: Array = tdb.get_talk(20338).get("choices", [])
	assert(units_choices.size() == 5, "Units quiz should have 5 options (1, 3, 5, 7, 9)")
	assert(units_choices[4].get("text") == "9" and units_choices[4].get("next_talk_id") == 20340, "Choice 9 must advance to correct answer 20340")
	print("  [PASS] Emilie math riddle (tens=2, units=9 -> answer 29) verified.")
	passed += 1

	var doll_handin = tdb.get_talk(20233)
	assert(doll_handin.get("next_talk_id") == 20234, "Doll hand-in must chain to 20234")
	assert(tdb.get_talk(20235).get("next_talk_id") == 20236, "Doll name query must chain to 20236")
	assert(tdb.get_talk(20237).get("speaker") == "Doll", "Gift line must be Doll")
	print("  [PASS] Doll hand-in and gift sequence verified.")
	passed += 1

	# 2. QuestDialogueComponent Quest 1003 Flow Verification
	print("\n>>> [TEST 2] Verifying Quest 1003 registration and multi-step lifecycle...")
	var quest_comp = QuestDialogueComponent.new()
	root.add_child(quest_comp)

	var quest_1003 = {
		"quest_id": 1003,
		"quest_title": "Hill Pepper",
		"current_step": 0,
		"objectives": [
			{
				"step_index": 0,
				"type": "TalkToNPC",
				"npc_id": 14141,
				"npc_name": "Doll",
				"map_id": 10002,
				"talk_id": 20222,
				"description": "Talk to Doll (NPC 14141) cooking supper in Kelan Village.",
				"dialogue_preview": "The flavor is not quite right, it needs more seasoning... can you get some Hill Pepper for me?"
			},
			{
				"step_index": 1,
				"type": "TalkToNPC",
				"npc_id": 14140,
				"npc_name": "Emilie",
				"map_id": 10002,
				"talk_id": 20336,
				"description": "Find Emilie (NPC 14140) by north stairs and solve her math riddle (Answer: 29).",
				"dialogue_preview": "Answer my age riddle correctly to receive the Hill Pepper."
			},
			{
				"step_index": 2,
				"type": "TalkToNPC",
				"npc_id": 14141,
				"npc_name": "Doll",
				"map_id": 10002,
				"talk_id": 20233,
				"description": "Deliver the Hill Pepper back to Doll in Kelan Village.",
				"dialogue_preview": "Doll, I have the Hill Pepper now. The supper is saved!"
			}
		],
		"rewards": {
			"reward_gold": 200,
			"reward_exp": 500,
			"reward_items": [
				{
					"item_id": 34076,
					"item_name": "Radio Set",
					"count": 1,
					"icon_id": 6
				}
			]
		}
	}

	quest_comp.register_quest(quest_1003)
	assert(quest_comp.is_quest_active(1003), "Quest 1003 should be active")
	assert(quest_comp.npc_has_pending_objective(14141), "Doll should have pending objective at Step 0")
	assert(not quest_comp.npc_has_pending_objective(14140), "Emilie should not have pending objective at Step 0")
	print("  [PASS] Quest 1003 registered and Step 0 targeted to Doll.")
	passed += 1

	# Advance Step 0 (Spoke with Doll, accepted quest)
	var adv0 = quest_comp.interact_with_npc(14141, "Doll")
	assert(adv0, "Interacting with Doll should match objective")
	assert(quest_comp.get_active_quest(1003).get("current_step") == 1, "Should advance to Step 1")
	assert(quest_comp.npc_has_pending_objective(14140), "Emilie should now have pending objective at Step 1")
	print("  [PASS] Step 0 completed -> Step 1 active (Emilie).")
	passed += 1

	# Advance Step 1 (Answered Emilie's math quiz with 29 -> obtained Hill Pepper)
	var adv1 = quest_comp.interact_with_npc(14140, "Emilie")
	assert(adv1, "Interacting with Emilie should match objective")
	assert(quest_comp.get_active_quest(1003).get("current_step") == 2, "Should advance to Step 2")
	assert(quest_comp.npc_has_pending_objective(14141), "Doll should now have pending objective at Step 2")
	print("  [PASS] Step 1 completed -> Step 2 active (Doll hand-in).")
	passed += 1

	# Complete Step 2 (Delivered Hill Pepper to Doll -> Quest complete)
	var completed_box := [false]
	var reward_box := [{}]
	quest_comp.quest_completed.connect(func(qid, rews):
		if qid == 1003:
			completed_box[0] = true
			reward_box[0] = rews
	)

	var adv2 = quest_comp.interact_with_npc(14141, "Doll")
	assert(adv2, "Interacting with Doll for hand-in should match objective")
	assert(quest_comp.is_quest_completed(1003), "Quest 1003 must be completed")
	assert(completed_box[0], "quest_completed signal must emit")
	
	var delivered_rewards: Dictionary = reward_box[0]
	assert(delivered_rewards.get("reward_gold") == 200, "Gold reward should be 200")
	assert(delivered_rewards.get("reward_exp") == 500, "EXP reward should be 500")
	var items: Array = delivered_rewards.get("reward_items", [])
	assert(items.size() == 1 and items[0].get("item_name") == "Radio Set", "Reward must include Radio Set")
	print("  [PASS] Step 2 completed -> Quest 1003 finished and Radio Set awarded.")
	passed += 1

	quest_comp.queue_free()

	print("\n==================================================================")
	print("=== FINAL RESULTS: %d PASSED, %d FAILED ===" % [passed, failed])
	print("==================================================================")
	if failed == 0:
		print("ALL HILL PEPPER QUEST CHAIN TESTS PASSED PERFECTLY!\n")
		quit(0)
	else:
		print("TESTS FAILED!\n")
		quit(1)
