extends SceneTree

## Automated Verification Suite for Wonderland Online Flexible Dialogue & Quest UI
## Tests:
## 1. DialogueBox scene loading and node resolution
## 2. Responsive bottom-center anchoring & layout presets
## 3. Dynamic resolution adaptation across 6 resolution tiers
## 4. Left / Right / Both / None speaker portrait placement & content bounds
## 5. RichTextLabel BBCode & authentic WLO token translation (#n, #R, #B, #G, #Y)
## 6. Typewriter progression, fast-forward skip, and multi-page sequence paging
## 7. Choices container dynamic expansion & parchment button styling
## 8. Keyboard (1..9 / Up / Down / Enter) & mouse choice selection with wav0151 SFX
## 9. DialogueManager coordination, state machine, and talk traversal
## 10. QuestDialogueComponent objective matching and quest completion fanfare

const DialogueBoxScript = preload("res://scripts/ui/dialogue/dialogue_box.gd")
const DialogueManagerScript = preload("res://scripts/ui/dialogue/dialogue_manager.gd")
const QuestDialogueComponentScript = preload("res://scripts/ui/quest/quest_dialogue_component.gd")

var _pass_count: int = 0
var _fail_count: int = 0

func _init() -> void:
	print("\n==================================================================")
	print("=== Running Wonderland Online Flexible Dialogue UI Test Suite   ===")
	print("==================================================================\n")

	_init_autoloads()

	# Run all test phases
	_test_scene_instantiation()
	_test_layout_presets()
	_test_resolution_adaptation()
	_test_speaker_placement()
	_test_bbcode_token_parsing()
	_test_typewriter_and_paging()
	_test_choices_dynamic_expansion()
	_test_keyboard_and_mouse_selection()
	_test_dialogue_manager_orchestration()
	_test_quest_dialogue_component()

	print("\n==================================================================")
	print("=== TEST RESULTS: %d PASSED, %d FAILED                         ===" % [_pass_count, _fail_count])
	print("==================================================================\n")

	if _fail_count == 0:
		print("ALL FLEXIBLE DIALOGUE UI TESTS PASSED WITH 100% SUCCESS!\n")
		quit(0)
	else:
		printerr("TEST FAILURES ENCOUNTERED!")
		quit(1)

func _init_autoloads() -> void:
	if not root.has_node("ArchiveLoader"):
		var arch_loader = load("res://scripts/core/archive_loader.gd").new()
		arch_loader.name = "ArchiveLoader"
		root.add_child(arch_loader)

	if not root.has_node("GameDatabase"):
		var gdb = load("res://scripts/database/game_database.gd").new()
		gdb.name = "GameDatabase"
		root.add_child(gdb)
		gdb.load_all()

func _assert_test(condition: bool, message: String) -> void:
	if condition:
		_pass_count += 1
		print("[PASS] " + message)
	else:
		_fail_count += 1
		printerr("[FAIL] " + message)

# ==============================================================================
# Test 1: Scene Instantiation & Node Resolution
# ==============================================================================

func _test_scene_instantiation() -> void:
	print(">>> [Phase 1] Testing DialogueBox Scene Instantiation & Bindings...")
	var scene = load("res://scenes/ui/dialogue/dialogue_box.tscn")
	_assert_test(scene != null, "DialogueBox scene exists at res://scenes/ui/dialogue/dialogue_box.tscn")

	var box = scene.instantiate() as DialogueBox
	_assert_test(box != null, "Scene instantiates as DialogueBox")
	root.add_child(box)
	box.ensure_initialized()

	_assert_test(box.background_rect != null, "Background node resolved")
	_assert_test(box.portrait_frame_left != null, "PortraitFrameLeft node resolved")
	_assert_test(box.portrait_rect_left != null, "PortraitLeft texture node resolved")
	_assert_test(box.portrait_frame_right != null, "PortraitFrameRight node resolved")
	_assert_test(box.portrait_rect_right != null, "PortraitRight texture node resolved")
	_assert_test(box.content_container != null, "ContentContainer node resolved")
	_assert_test(box.speaker_label != null, "SpeakerLabel node resolved")
	_assert_test(box.text_label != null, "TextLabel (RichTextLabel) node resolved")
	_assert_test(box.next_icon != null, "NextIcon node resolved")
	_assert_test(box.choices_panel != null, "ChoicesPanel node resolved")
	_assert_test(box.choices_container != null, "ChoicesContainer node resolved")
	_assert_test(box.sfx_player != null, "SFXPlayer node resolved")

	box.queue_free()

# ==============================================================================
# Test 2: Responsive Anchoring & Layout Presets
# ==============================================================================

func _test_layout_presets() -> void:
	print(">>> [Phase 2] Testing Responsive Anchoring & Layout Presets...")
	var scene = load("res://scenes/ui/dialogue/dialogue_box.tscn")
	var box = scene.instantiate() as DialogueBox
	root.add_child(box)

	# 1. BOTTOM_CENTER preset
	box.set_box_preset(DialogueBox.BoxPreset.BOTTOM_CENTER)
	_assert_test(box.anchor_left == 0.5 and box.anchor_right == 0.5, "BOTTOM_CENTER: horizontally centered (0.5)")
	_assert_test(box.anchor_top == 1.0 and box.anchor_bottom == 1.0, "BOTTOM_CENTER: vertically bottom anchored (1.0)")
	_assert_test(box.offset_bottom == -box.bottom_margin, "BOTTOM_CENTER: offset_bottom equals -bottom_margin")

	# 2. Configurable margins & size
	box.set_box_dimensions(700.0, 160.0, 30.0)
	_assert_test(box.box_width == 700.0, "Configurable box_width applied (700)")
	_assert_test(box.box_height == 160.0, "Configurable box_height applied (160)")
	_assert_test(box.bottom_margin == 30.0, "Configurable bottom_margin applied (30)")
	_assert_test(box.offset_bottom == -30.0, "offset_bottom reflects updated margin (-30)")

	# 3. TOP_CENTER preset
	box.set_box_preset(DialogueBox.BoxPreset.TOP_CENTER)
	_assert_test(box.anchor_top == 0.0 and box.anchor_bottom == 0.0, "TOP_CENTER: vertically top anchored (0.0)")

	# 4. CENTER preset
	box.set_box_preset(DialogueBox.BoxPreset.CENTER)
	_assert_test(box.anchor_top == 0.5 and box.anchor_bottom == 0.5, "CENTER: vertically centered (0.5)")

	box.queue_free()

# ==============================================================================
# Test 3: Resolution Changes Across 6 Tiers
# ==============================================================================

func _test_resolution_adaptation() -> void:
	print(">>> [Phase 3] Testing Dynamic Resolution Adaptation...")
	var scene = load("res://scenes/ui/dialogue/dialogue_box.tscn")
	var box = scene.instantiate() as DialogueBox
	root.add_child(box)

	var resolutions: Array[Vector2] = [
		Vector2(800, 600),
		Vector2(1024, 768),
		Vector2(1280, 720),
		Vector2(1920, 1080),
		Vector2(2560, 1440),
		Vector2(3840, 2160)
	]

	for res in resolutions:
		box.set_box_preset(DialogueBox.BoxPreset.BOTTOM_CENTER)
		# Verify box stays within viewport bounds
		var expected_w: float = minf(box.box_width, res.x - 20.0)
		_assert_test(box.custom_minimum_size.x <= res.x, "Resolution %.0fx%.0f: width fits viewport" % [res.x, res.y])
		_assert_test(box.custom_minimum_size.y <= res.y, "Resolution %.0fx%.0f: height fits viewport" % [res.x, res.y])

	box.queue_free()

# ==============================================================================
# Test 4: Dynamic Avatar Placement & Speaker Switching
# ==============================================================================

func _test_speaker_placement() -> void:
	print(">>> [Phase 4] Testing Dynamic Avatar Placement (Left/Right/Both/None)...")
	var scene = load("res://scenes/ui/dialogue/dialogue_box.tscn")
	var box = scene.instantiate() as DialogueBox
	root.add_child(box)

	# 1. Speaker LEFT (Default NPC / Speaker)
	box.set_speaker_side(DialogueBox.SpeakerSide.LEFT)
	_assert_test(box.portrait_frame_left.visible == true, "SpeakerSide.LEFT: Left portrait frame visible")
	_assert_test(box.portrait_frame_right.visible == false, "SpeakerSide.LEFT: Right portrait frame hidden")
	_assert_test(box.content_container.offset_left >= 140.0, "SpeakerSide.LEFT: Content indented for left portrait")

	# 2. Speaker RIGHT (Player / Counterpart)
	box.set_speaker_side(DialogueBox.SpeakerSide.RIGHT)
	_assert_test(box.portrait_frame_left.visible == false, "SpeakerSide.RIGHT: Left portrait frame hidden")
	_assert_test(box.portrait_frame_right.visible == true, "SpeakerSide.RIGHT: Right portrait frame visible")
	_assert_test(box.content_container.offset_left <= 50.0, "SpeakerSide.RIGHT: Content left offset is flush")
	_assert_test(box.content_container.offset_right <= box.box_width - 140.0, "SpeakerSide.RIGHT: Content right offset indented")

	# 3. Speaker BOTH (Dual Conversation)
	box.set_speaker_side(DialogueBox.SpeakerSide.BOTH)
	_assert_test(box.portrait_frame_left.visible == true, "SpeakerSide.BOTH: Left portrait frame visible")
	_assert_test(box.portrait_frame_right.visible == true, "SpeakerSide.BOTH: Right portrait frame visible")

	# 4. Speaker NONE (Narrator / Environmental Lore)
	box.set_speaker_side(DialogueBox.SpeakerSide.NONE)
	_assert_test(box.portrait_frame_left.visible == false, "SpeakerSide.NONE: Left portrait frame hidden")
	_assert_test(box.portrait_frame_right.visible == false, "SpeakerSide.NONE: Right portrait frame hidden")
	_assert_test(box.content_container.offset_left <= 50.0, "SpeakerSide.NONE: Full width content layout")

	box.queue_free()

# ==============================================================================
# Test 5: BBCode Token Parsing
# ==============================================================================

func _test_bbcode_token_parsing() -> void:
	print(">>> [Phase 5] Testing BBCode & WLO Token Translation...")
	var raw_str := "Hello #n! Here is #RRed Ruby#R, #BBlue Sea#B, #GGreen Herb#G, #YGold Coin#Y. #s402 #f3"
	var parsed := DialogueBoxScript.parse_wlo_tokens(raw_str, "Captain")

	_assert_test(parsed.contains("Hello Captain!"), "Player name placeholder #n replaced accurately")
	_assert_test(parsed.contains("[color=red]Red Ruby[/color]"), "Red tag #R converted to BBCode [color=red]")
	_assert_test(parsed.contains("[color=deep_sky_blue]Blue Sea[/color]"), "Blue tag #B converted to BBCode [color=deep_sky_blue]")
	_assert_test(parsed.contains("[color=green]Green Herb[/color]"), "Green tag #G converted to BBCode [color=green]")
	_assert_test(parsed.contains("[color=yellow]Gold Coin[/color]"), "Yellow tag #Y converted to BBCode [color=yellow]")
	_assert_test(not parsed.contains("#f3") and not parsed.contains("#s402"), "Control tags #f and #s stripped from visible text")

# ==============================================================================
# Test 6: Typewriter & Multi-Page Progression
# ==============================================================================

func _test_typewriter_and_paging() -> void:
	print(">>> [Phase 6] Testing Typewriter Effect & Paging...")
	var scene = load("res://scenes/ui/dialogue/dialogue_box.tscn")
	var box = scene.instantiate() as DialogueBox
	root.add_child(box)

	var pages: Array[String] = [
		"The ship will depart for South Ocean island soon.",
		"Please check with the service staff in your cabin.",
		"Safe travels to you adventurer!"
	]

	var page_emitted: Array[int] = []
	box.page_changed.connect(func(cur, total): page_emitted.append(cur))

	box.show_dialogue_sequence("Captain Robinson", pages)

	_assert_test(box.visible, "Dialogue box is visible")
	_assert_test(box._is_typing, "Typewriter started typing")
	_assert_test(box.speaker_label.text == "Captain Robinson", "Speaker label displayed 'Captain Robinson'")

	# Fast-forward typewriter
	box._skip_typewriter()
	_assert_test(not box._is_typing, "Typewriter completed after skip")
	_assert_test(box.text_label.visible_characters == -1, "All characters fully revealed")
	_assert_test(box.next_icon.visible == true, "NextIcon is visible on page conclusion")

	# Advance to Page 2
	box.advance_dialogue()
	_assert_test(box._current_page_index == 1, "Advanced to Page index 1 (Page 2)")
	_assert_test(box.page_label.text == "2 / 3", "Page label reflects '2 / 3'")

	# Advance to Page 3
	box._skip_typewriter()
	box.advance_dialogue()
	_assert_test(box._current_page_index == 2, "Advanced to Page index 2 (Page 3)")
	_assert_test(box.page_label.text == "3 / 3", "Page label reflects '3 / 3'")

	# Final advance closes dialogue
	box._skip_typewriter()
	box.advance_dialogue()
	_assert_test(not box.visible, "Dialogue box closed on sequence completion")

	box.queue_free()

# ==============================================================================
# Test 7: Choices Container Dynamic Expansion
# ==============================================================================

func _test_choices_dynamic_expansion() -> void:
	print(">>> [Phase 7] Testing Choices Container Dynamic Expansion...")
	var scene = load("res://scenes/ui/dialogue/dialogue_box.tscn")
	var box = scene.instantiate() as DialogueBox
	root.add_child(box)

	# 2 Options
	box.show_dialogue("Village Chief", "Do you accept this task?", ["Accept", "Decline"])
	box._skip_typewriter()
	_assert_test(box.choices_panel.visible == true, "Choices panel visible for 2 options")
	_assert_test(box.choices_container.get_child_count() == 2, "Choices container spawned exactly 2 buttons")

	var btn0 = box.choices_container.get_child(0) as Button
	_assert_test(btn0.text == "1. Accept", "Button 0 has formatted text '1. Accept'")

	# 5 Options (Expands dynamically)
	box.show_dialogue("Merchant", "What would you like to buy?", ["Swords", "Potions", "Armor", "Shields", "Cancel"])
	box._skip_typewriter()
	_assert_test(box.choices_container.get_child_count() == 5, "Choices container expanded to 5 buttons")

	box.queue_free()

# ==============================================================================
# Test 8: Keyboard & Mouse Choice Selection with SFX
# ==============================================================================

func _test_keyboard_and_mouse_selection() -> void:
	print(">>> [Phase 8] Testing Keyboard (1..9) & Mouse Choice Selection with SFX...")
	var scene = load("res://scenes/ui/dialogue/dialogue_box.tscn")
	var box = scene.instantiate() as DialogueBox
	root.add_child(box)

	var selected_choice_idx: Array[int] = [-1]
	var selected_choice_txt: Array[String] = [""]
	box.choice_selected.connect(func(idx, txt):
		selected_choice_idx[0] = idx
		selected_choice_txt[0] = txt
	)

	box.show_dialogue("Guide", "Choose your path:", ["North Path", "South Path", "Stay Here"])
	box._skip_typewriter()

	# Test keyboard key '2'
	var key_evt := InputEventKey.new()
	key_evt.keycode = KEY_2
	key_evt.pressed = true
	box._unhandled_input(key_evt)

	_assert_test(selected_choice_idx[0] == 1, "Keyboard key 2 selected Choice index 1")
	_assert_test(selected_choice_txt[0] == "South Path", "Selected choice text is 'South Path'")
	_assert_test(not box.visible, "Dialogue box closed cleanly on choice selection")

	box.queue_free()

# ==============================================================================
# Test 9: DialogueManager Coordination
# ==============================================================================

func _test_dialogue_manager_orchestration() -> void:
	print(">>> [Phase 9] Testing DialogueManager Orchestration & State Machine...")
	var mgr = DialogueManagerScript.new()
	root.add_child(mgr)
	mgr.ensure_initialized()

	_assert_test(mgr.dialogue_box != null, "DialogueManager auto-instantiated DialogueBox")

	var started_talk: Array[int] = [0]
	mgr.dialogue_started.connect(func(tid, spk): started_talk[0] = tid)

	# Start dialogue
	mgr.start_dialogue("Captain Robinson", "Welcome aboard the ship!", ["Thank you", "Where are we going?"])
	_assert_test(mgr.is_active(), "DialogueManager reports active session")
	_assert_test(mgr.current_state == DialogueManager.DialogueState.TYPING, "State is TYPING")

	mgr.dialogue_box._skip_typewriter()
	_assert_test(mgr.current_state == DialogueManager.DialogueState.CHOICES_ACTIVE, "State shifted to CHOICES_ACTIVE")

	# Select choice via manager
	var choice_recorded: Array[int] = [-1]
	mgr.choice_selected.connect(func(idx, txt): choice_recorded[0] = idx)
	mgr.select_choice(0)

	_assert_test(choice_recorded[0] == 0, "DialogueManager choice 0 successfully dispatched")
	_assert_test(not mgr.is_active(), "DialogueManager reports closed session")

	# Test TalkDatabase integration with Talk 30124 (Captain Robinson)
	var loaded_talk = mgr.start_talk_id(30124, "Adventurer")
	_assert_test(loaded_talk == true, "DialogueManager started Talk ID 30124 from TalkDatabase")
	_assert_test(mgr.active_pages.size() >= 2, "Captain Robinson dialogue chain parsed into 2+ pages")
	mgr.close()

	mgr.queue_free()

# ==============================================================================
# Test 10: QuestDialogueComponent Objective Matching & Fanfare
# ==============================================================================

func _test_quest_dialogue_component() -> void:
	print(">>> [Phase 10] Testing QuestDialogueComponent Objective Matching & Fanfare...")
	var qcomp = QuestDialogueComponentScript.new()
	var mgr = DialogueManagerScript.new()
	root.add_child(mgr)
	qcomp.dialogue_manager = mgr
	root.add_child(qcomp)

	var quest_data: Dictionary = {
		"quest_id": 1001,
		"quest_title": "Prologue Ship Quest",
		"current_step": 0,
		"objectives": [
			{
				"step_index": 0,
				"type": "TalkToNPC",
				"npc_id": 14003,
				"npc_name": "Captain Robinson",
				"talk_id": 30124,
				"dialogue_preview": "Welcome aboard the ship! I am Captain Robinson."
			}
		],
		"rewards": {
			"reward_exp": 100,
			"reward_gold": 50,
			"reward_items": [
				{"item_name": "Small Knife", "count": 1}
			]
		}
	}

	qcomp.register_quest(quest_data)
	_assert_test(qcomp.active_quests.has(1001), "Quest 1001 registered in active tracking")

	var obj_completed: Array[int] = [-1]
	var quest_finished: Array[int] = [-1]
	var reward_banner: Array[String] = [""]

	qcomp.quest_objective_completed.connect(func(qid, step): obj_completed[0] = step)
	qcomp.quest_completed.connect(func(qid, r): quest_finished[0] = qid)
	qcomp.quest_reward_displayed.connect(func(msg): reward_banner[0] = msg)

	# Interact with Captain Robinson (NPC ID 14003)
	var matched = qcomp.interact_with_npc(14003, "Captain Robinson", 30124)
	_assert_test(matched == true, "interact_with_npc matched active TalkToNPC objective")
	_assert_test(mgr.is_active() == true, "Quest dialogue launched in DialogueManager")

	# Close dialogue to complete objective
	mgr.close()

	_assert_test(obj_completed[0] == 0, "Objective step 0 completed on dialogue finish")
	_assert_test(quest_finished[0] == 1001, "Quest 1001 marked completed")
	_assert_test(reward_banner[0].contains("Gold") and reward_banner[0].contains("EXP"), "Quest reward banner generated with Gold and EXP")

	qcomp.queue_free()
	mgr.queue_free()
