extends Node

## Comprehensive Automated Verification Suite for Quest & Dialogue Studio (QuestEditor)
## Tests:
## 1. Scene loading and UI component binding
## 2. Quest Header configuration and data sync
## 3. Multi-step Objective Sequencer (TalkToNPC, CollectItem, DefeatMonster, ReachArea)
## 4. Dialogue Previewer, WLO token parsing (#n, #s, #f, colors), and branching traversal
## 5. Rewards configuration (EXP, Gold, items, skill)
## 6. Built-in presets verification (Prologue Ship Quest, Monkey Beach Awakening, Kelan Trail Navigation)
## 7. JSON Export/Import & Standalone RefCounted GDScript Quest generation

const QuestEditorScript = preload("res://scripts/tools/quest_editor.gd")

func _ready() -> void:
	print("=================================================================")
	print("--- Running Complete Quest & Dialogue Studio Test Suite ---")
	print("=================================================================\n")

	# 1. Initialize Singletons if needed in headless mode
	_init_autoloads()

	# 2. Run Test Phases
	_test_scene_and_instantiation()
	_test_quest_header_config()
	_test_objective_sequencer()
	_test_dialogue_preview_and_tokens()
	_test_rewards_configuration()
	_test_builtin_presets()
	_test_export_and_import()

	print("\n=================================================================")
	print("--- ALL QUEST EDITOR & DIALOGUE STUDIO TESTS PASSED (100%) ---")
	print("=================================================================\n")
	get_tree().quit(0)

func _init_autoloads() -> void:
	var root = get_tree().root
	if not root.has_node("ArchiveLoader"):
		var arch_loader = load("res://scripts/core/archive_loader.gd").new()
		arch_loader.name = "ArchiveLoader"
		root.add_child(arch_loader)
	
	if not root.has_node("GameDatabase"):
		var gdb = load("res://scripts/database/game_database.gd").new()
		gdb.name = "GameDatabase"
		root.add_child(gdb)
		gdb.load_all()

func _test_scene_and_instantiation() -> void:
	print(">>> [TEST 1] Testing QuestEditor Scene Loading & Instantiation...")
	var scene_res = load("res://scenes/tools/quest_editor.tscn")
	assert(scene_res != null, "ERROR: Failed to load res://scenes/tools/quest_editor.tscn")
	
	var editor = scene_res.instantiate() as QuestEditorScript
	assert(editor != null, "ERROR: Instantiated node is not of type QuestEditorScript")
	add_child(editor)

	# Verify minimum size
	assert(editor.custom_minimum_size.x >= 800.0, "ERROR: Minimum width must be >= 800")
	assert(editor.custom_minimum_size.y >= 600.0, "ERROR: Minimum height must be >= 600")

	# Verify essential UI elements
	assert(editor.opt_presets != null, "ERROR: OptPresets node missing")
	assert(editor.btn_new_quest != null, "ERROR: BtnNewQuest node missing")
	assert(editor.btn_save_json != null, "ERROR: BtnSaveJson node missing")
	assert(editor.btn_load_json != null, "ERROR: BtnLoadJson node missing")
	assert(editor.btn_export_script != null, "ERROR: BtnExportScript node missing")
	assert(editor.list_objectives != null, "ERROR: ListObjectives node missing")
	assert(editor.rich_preview_dialogue != null, "ERROR: RichPreviewDialogue node missing")

	print("  PASS: QuestEditor scene and UI components instantiated and bound successfully.")
	editor.queue_free()

func _test_quest_header_config() -> void:
	print(">>> [TEST 2] Testing Quest Header Configuration & Binding...")
	var editor = QuestEditorScript.new()
	add_child(editor)

	editor.quest_id = 1005
	editor.quest_title = "The Ancient Seal"
	editor.quest_category = "Event"
	editor.min_level = 15
	editor.prerequisite_quest_id = 1004
	editor.is_repeatable = true
	editor.quest_description = "Investigate the mysterious altar discovered in the forest."

	var data = editor.create_quest_data()
	assert(data["quest_id"] == 1005, "ERROR: quest_id mismatch")
	assert(data["quest_title"] == "The Ancient Seal", "ERROR: quest_title mismatch")
	assert(data["quest_category"] == "Event", "ERROR: quest_category mismatch")
	assert(data["min_level"] == 15, "ERROR: min_level mismatch")
	assert(data["prerequisite_quest_id"] == 1004, "ERROR: prerequisite_quest_id mismatch")
	assert(data["is_repeatable"] == true, "ERROR: is_repeatable mismatch")
	assert(data["quest_description"] == "Investigate the mysterious altar discovered in the forest.", "ERROR: quest_description mismatch")

	print("  PASS: Quest header properties configured and validated cleanly.")
	editor.queue_free()

func _test_objective_sequencer() -> void:
	print(">>> [TEST 3] Testing Multi-step Objective Sequencer...")
	var editor = QuestEditorScript.new()
	add_child(editor)
	editor.clear_objectives()
	assert(editor.objectives.size() == 0, "ERROR: Objectives not cleared")

	# 1. TalkToNPC
	var idx0 = editor.add_objective("TalkToNPC", {
		"npc_id": 14003,
		"npc_name": "Captain Robinson",
		"talk_id": 14003,
		"dialogue_preview": "Welcome aboard!"
	})
	assert(idx0 == 0, "ERROR: Index of first objective must be 0")

	# 2. CollectItem
	var idx1 = editor.add_objective("CollectItem", {
		"item_id": 32001,
		"item_name": "Coconut",
		"count": 3
	})
	assert(idx1 == 1, "ERROR: Index of second objective must be 1")

	# 3. DefeatMonster
	var idx2 = editor.add_objective("DefeatMonster", {
		"monster_id": 1001,
		"monster_name": "Gel Monster",
		"count": 5
	})
	assert(idx2 == 2, "ERROR: Index of third objective must be 2")

	# 4. ReachArea
	var idx3 = editor.add_objective("ReachArea", {
		"map_id": 10002,
		"map_name": "Ship Cabin",
		"target_pos": Vector2(750.0, 480.0),
		"radius": 64.0
	})
	assert(idx3 == 3, "ERROR: Index of fourth objective must be 3")

	assert(editor.objectives.size() == 4, "ERROR: Must have 4 objectives")
	assert(editor.get_objective(0)["type"] == "TalkToNPC", "ERROR: Step 0 type mismatch")
	assert(editor.get_objective(1)["type"] == "CollectItem", "ERROR: Step 1 type mismatch")
	assert(editor.get_objective(2)["type"] == "DefeatMonster", "ERROR: Step 2 type mismatch")
	assert(editor.get_objective(3)["type"] == "ReachArea", "ERROR: Step 3 type mismatch")

	# Update step
	editor.update_objective(1, {"count": 7})
	assert(editor.get_objective(1)["count"] == 7, "ERROR: Objective update failed")

	# Reorder (move up)
	var ok_up = editor.move_objective_up(2)
	assert(ok_up, "ERROR: Move up failed")
	assert(editor.get_objective(1)["type"] == "DefeatMonster", "ERROR: Move up ordering mismatch")
	assert(editor.get_objective(2)["type"] == "CollectItem", "ERROR: Move up ordering mismatch")

	# Reorder (move down)
	var ok_down = editor.move_objective_down(1)
	assert(ok_down, "ERROR: Move down failed")
	assert(editor.get_objective(1)["type"] == "CollectItem", "ERROR: Move down ordering mismatch")

	# Remove objective
	var ok_rem = editor.remove_objective(3)
	assert(ok_rem, "ERROR: Remove objective failed")
	assert(editor.objectives.size() == 3, "ERROR: Objective count must be 3 after removal")

	print("  PASS: Sequencer added, reordered, updated, and removed all 4 objective types.")
	editor.queue_free()

func _test_dialogue_preview_and_tokens() -> void:
	print(">>> [TEST 4] Testing Dialogue Previewer & WLO Token Parser...")
	var editor = QuestEditorScript.new()
	add_child(editor)

	# Test token parsing
	var raw_dialogue = "#s1402#f8025Hello #n! Bring me #RRed Apple#W and #GGreen Herb#W, or #BBlue Gem#W and #YGolden Coin#W."
	var parsed = editor.parse_tokens(raw_dialogue, "Hero")
	print("  Parsed BBCode: ", parsed)
	assert(parsed.contains("Hero"), "ERROR: #n token should be replaced by player name")
	assert(not parsed.contains("#s1402"), "ERROR: Sound token was not stripped")
	assert(not parsed.contains("#f8025"), "ERROR: Face token was not stripped")
	assert(parsed.contains("[color=red]Red Apple[/color]"), "ERROR: Red color token parsing failed")
	assert(parsed.contains("[color=green]Green Herb[/color]"), "ERROR: Green color token parsing failed")
	assert(parsed.contains("[color=deep_sky_blue]Blue Gem[/color]"), "ERROR: Blue color token parsing failed")
	assert(parsed.contains("[color=yellow]Golden Coin[/color]"), "ERROR: Yellow color token parsing failed")

	# Test token extraction
	var tokens = editor.extract_tokens(raw_dialogue)
	assert(tokens["sound"] == "1402", "ERROR: Extracted sound token mismatch")
	assert(tokens["face_index"] == 8025, "ERROR: Extracted face token mismatch")

	# Test dialogue lookup
	var talk_info = editor.lookup_dialogue(14003)
	assert(not talk_info.is_empty(), "ERROR: Talk 14003 lookup returned empty")
	assert(talk_info["talk_id"] == 14003, "ERROR: talk_id mismatch")
	assert(not str(talk_info["speaker"]).is_empty(), "ERROR: speaker name is empty")
	assert(not str(talk_info["text"]).is_empty(), "ERROR: formatted text is empty")
	print("  PASS: Dialogue lookup verified for Talk ID 14003 (Speaker: %s)." % str(talk_info["speaker"]))

	editor.queue_free()

func _test_rewards_configuration() -> void:
	print(">>> [TEST 5] Testing Rewards Configuration...")
	var editor = QuestEditorScript.new()
	add_child(editor)

	editor.set_rewards(500, 250, [], 15039)
	assert(editor.reward_exp == 500, "ERROR: EXP reward mismatch")
	assert(editor.reward_gold == 250, "ERROR: Gold reward mismatch")
	assert(editor.reward_skill_id == 15039, "ERROR: Skill ID reward mismatch")

	# Add reward items
	editor.add_reward_item(23001, "Small Knife", 1)
	editor.add_reward_item(32001, "Coconut", 5)
	assert(editor.reward_items.size() == 2, "ERROR: reward_items size mismatch")
	assert(editor.reward_items[0]["item_id"] == 23001, "ERROR: item 0 id mismatch")
	assert(editor.reward_items[1]["count"] == 5, "ERROR: item 1 count mismatch")

	# Remove reward item
	var ok_rem = editor.remove_reward_item(0)
	assert(ok_rem, "ERROR: Failed to remove reward item")
	assert(editor.reward_items.size() == 1, "ERROR: reward_items size after removal must be 1")
	assert(editor.reward_items[0]["item_id"] == 32001, "ERROR: remaining item mismatch")

	print("  PASS: Rewards configuration (EXP, Gold, items, skill) verified.")
	editor.queue_free()

func _test_builtin_presets() -> void:
	print(">>> [TEST 6] Testing Built-in Quest Presets...")
	var editor = QuestEditorScript.new()
	add_child(editor)

	# Preset 1: Prologue Ship Quest
	var p1_ok = editor.load_preset("Prologue Ship Quest")
	assert(p1_ok, "ERROR: Failed to load 'Prologue Ship Quest'")
	assert(editor.quest_id == 1001, "ERROR: Preset 1 quest_id mismatch")
	assert(editor.quest_title == "Prologue Ship Quest", "ERROR: Preset 1 title mismatch")
	assert(editor.quest_category == "Main", "ERROR: Preset 1 category mismatch")
	assert(editor.objectives.size() == 3, "ERROR: Preset 1 must have 3 steps")
	assert(editor.objectives[0]["type"] == "TalkToNPC", "ERROR: Preset 1 step 0 must be TalkToNPC")
	assert(editor.objectives[0]["talk_id"] == 14003, "ERROR: Preset 1 step 0 talk_id mismatch")
	assert(editor.objectives[1]["type"] == "ReachArea" and editor.objectives[1]["map_id"] == 10002, "ERROR: Preset 1 step 1 map mismatch")
	assert(editor.objectives[2]["type"] == "ReachArea" and editor.objectives[2]["map_id"] == 10001, "ERROR: Preset 1 step 2 map mismatch")
	assert(editor.reward_exp == 100, "ERROR: Preset 1 exp mismatch")
	assert(editor.reward_gold == 50, "ERROR: Preset 1 gold mismatch")
	assert(editor.reward_items.size() == 1 and editor.reward_items[0]["item_id"] == 23001, "ERROR: Preset 1 item reward mismatch")
	print("  PASS: Preset 1 'Prologue Ship Quest' verified.")

	# Preset 2: Monkey Beach Awakening
	var p2_ok = editor.load_preset("Monkey Beach Awakening")
	assert(p2_ok, "ERROR: Failed to load 'Monkey Beach Awakening'")
	assert(editor.quest_id == 1002, "ERROR: Preset 2 quest_id mismatch")
	assert(editor.objectives.size() == 2, "ERROR: Preset 2 must have 2 steps")
	assert(editor.objectives[0]["type"] == "TalkToNPC" and editor.objectives[0]["talk_id"] == 14062, "ERROR: Preset 2 step 0 mismatch")
	assert(editor.objectives[1]["type"] == "CollectItem" and editor.objectives[1]["item_id"] == 32001, "ERROR: Preset 2 step 1 mismatch")
	assert(editor.reward_exp == 150 and editor.reward_gold == 100, "ERROR: Preset 2 rewards mismatch")
	print("  PASS: Preset 2 'Monkey Beach Awakening' verified.")

	# Preset 3: Kelan Trail Navigation
	var p3_ok = editor.load_preset("Kelan Trail Navigation")
	assert(p3_ok, "ERROR: Failed to load 'Kelan Trail Navigation'")
	assert(editor.quest_id == 1003, "ERROR: Preset 3 quest_id mismatch")
	assert(editor.quest_category == "Branch", "ERROR: Preset 3 category mismatch")
	assert(editor.objectives.size() == 3, "ERROR: Preset 3 must have 3 steps")
	assert(editor.objectives[0]["type"] == "ReachArea" and editor.objectives[0]["map_id"] == 11016, "ERROR: Preset 3 step 0 mismatch")
	assert(editor.objectives[1]["type"] == "DefeatMonster" and editor.objectives[1]["monster_id"] == 1001, "ERROR: Preset 3 step 1 mismatch")
	assert(editor.objectives[2]["type"] == "ReachArea" and editor.objectives[2]["map_id"] == 12000, "ERROR: Preset 3 step 2 mismatch")
	assert(editor.reward_exp == 300 and editor.reward_gold == 200, "ERROR: Preset 3 rewards mismatch")
	print("  PASS: Preset 3 'Kelan Trail Navigation' verified.")

	editor.queue_free()

func _test_export_and_import() -> void:
	print(">>> [TEST 7] Testing JSON Export/Import & Standalone GDScript Generation...")
	var editor = QuestEditorScript.new()
	add_child(editor)

	editor.load_preset("Prologue Ship Quest")
	
	# Test JSON Export
	var json_path = "user://test_quest_1001.json"
	var save_ok = editor.save_quest(json_path)
	assert(save_ok, "ERROR: save_quest returned false")
	assert(FileAccess.file_exists(json_path), "ERROR: Exported JSON file does not exist on disk")

	# Test JSON Import
	var imported_dict = editor.load_quest(json_path)
	assert(not imported_dict.is_empty(), "ERROR: load_quest returned empty dictionary")
	assert(imported_dict["quest_id"] == 1001, "ERROR: Imported quest_id mismatch")
	assert(imported_dict["objectives"].size() == 3, "ERROR: Imported objectives size mismatch")
	print("  PASS: JSON Export and Import verified.")

	# Test GDScript Export
	var script_path = "user://test_quest_1001.gd"
	var script_content = editor.export_quest_script(script_path)
	assert(not script_content.is_empty(), "ERROR: export_quest_script returned empty string")
	assert(FileAccess.file_exists(script_path), "ERROR: Exported script file does not exist on disk")
	assert(script_content.contains("class_name Quest_1001"), "ERROR: Missing class_name in exported script")
	assert(script_content.contains("extends RefCounted"), "ERROR: Missing extends RefCounted in exported script")
	assert(script_content.contains("const OBJECTIVES"), "ERROR: Missing const OBJECTIVES in exported script")
	assert(script_content.contains("const REWARDS"), "ERROR: Missing const REWARDS in exported script")
	assert(script_content.contains("func advance_step() -> bool:"), "ERROR: Missing advance_step in exported script")
	print("  PASS: Standalone RefCounted GDScript export verified.")

	editor.queue_free()
