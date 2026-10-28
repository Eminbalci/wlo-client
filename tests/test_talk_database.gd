extends SceneTree

## Automated test suite for TalkDatabase, Talk.dat & Dialogue Engine.
## Executes headlessly via: godot_console.exe --headless -s tests/test_talk_database.gd

func _init() -> void:
	print("==================================================================")
	print("=== Running Wonderland Online Dialogue Engine Automated Tests  ===")
	print("==================================================================")
	
	# Determine data directory
	var data_dir: String = "D:/GitHub/WLRI/data"
	if not DirAccess.dir_exists_absolute(data_dir):
		data_dir = "res://assets/data"
	
	var talk_file: String = data_dir + "/Talk.dat"
	var npc_file: String = data_dir + "/Npc.dat"
	
	print("[Test] Loading Talk.dat from: %s" % talk_file)
	print("[Test] Loading Npc.dat from: %s" % npc_file)
	
	# -------------------------------------------------------------
	# Test 1: Fundamental Talk.dat Binary Loading
	# -------------------------------------------------------------
	var talk_cls = load("res://scripts/database/talk_database.gd")
	assert(talk_cls != null, "TalkDatabase class must load")
	var db = talk_cls.new()
	var loaded: bool = db.load_from_file(talk_file)
	assert(loaded, "Talk.dat must load successfully")
	print("PASS: Test 1 - Talk.dat loaded successfully.")
	
	var total_talks: int = db.get_count()
	print("[Test] Total dialogues decoded: %d" % total_talks)
	assert(total_talks >= 17000, "Expected at least 17,000 dialogues, got %d" % total_talks)
	print("PASS: Test 1 - Total decoded dialogue records verified (>= 17,000).")
	
	# -------------------------------------------------------------
	# Test 2: Core Dialogue Records (Yes/No, S.Monkey, Ship Deck NPCs)
	# -------------------------------------------------------------
	var t_yes: Dictionary = db.get_talk(10001)
	assert(not t_yes.is_empty(), "Talk 10001 must exist")
	assert(t_yes.text == "Yes." or t_yes.text.contains("Yes"), "Talk 10001 expected 'Yes.', got: %s" % t_yes.text)
	print("PASS: Test 2a - Talk 10001 (Yes.) verified.")
	
	var t_no: Dictionary = db.get_talk(10002)
	assert(not t_no.is_empty(), "Talk 10002 must exist")
	assert(t_no.text == "No." or t_no.text.contains("No"), "Talk 10002 expected 'No.', got: %s" % t_no.text)
	print("PASS: Test 2b - Talk 10002 (No.) verified.")
	
	var t_monkey: Dictionary = db.get_talk(20038)
	assert(not t_monkey.is_empty(), "Talk 20038 must exist")
	assert(t_monkey.text.to_lower().contains("monkey"), "Talk 20038 must mention Monkey, got: %s" % t_monkey.text)
	print("PASS: Test 2c - Talk 20038 (S.Monkey Quest Intro) verified.")
	
	# Captain Initial Line (30124) and Second Line (30125)
	var t_cap1: Dictionary = db.get_talk(30124)
	assert(not t_cap1.is_empty(), "Talk 30124 (Captain 1) must exist")
	assert(t_cap1.speaker == "Captain", "Talk 30124 speaker must be Captain, got: %s" % t_cap1.speaker)
	assert(t_cap1.next_talk_id == 30125, "Talk 30124 next_talk_id must be 30125, got: %d" % t_cap1.next_talk_id)
	
	var t_cap2: Dictionary = db.get_talk(30125)
	assert(not t_cap2.is_empty(), "Talk 30125 (Captain 2) must exist")
	assert(t_cap2.speaker == "Captain", "Talk 30125 speaker must be Captain")
	print("PASS: Test 2d - Captain dialogues (30124 -> 30125) parsed accurately.")
	
	# Jack (30126) & Ross (30120)
	var t_jack: Dictionary = db.get_talk(30126)
	assert(not t_jack.is_empty(), "Talk 30126 (Jack) must exist")
	assert(t_jack.speaker == "Jack", "Talk 30126 speaker must be Jack, got: %s" % t_jack.speaker)
	
	var t_ross: Dictionary = db.get_talk(30120)
	assert(not t_ross.is_empty(), "Talk 30120 (Ross) must exist")
	assert(t_ross.speaker == "Ross", "Talk 30120 speaker must be Ross, got: %s" % t_ross.speaker)
	print("PASS: Test 2e - Cabin NPCs Jack (30126) and Ross (30120) verified.")
	
	# -------------------------------------------------------------
	# Test 3: Dialogue Chaining (Multi-Page Conversations)
	# -------------------------------------------------------------
	var cap_chain: Array[Dictionary] = db.get_dialogue_chain(30124)
	print("[Test] Captain chain size: %d" % cap_chain.size())
	for step in cap_chain:
		print("  - Step: id=%d, speaker='%s', next=%d, text='%s'" % [step.id, step.speaker, step.next_talk_id, step.text.substr(0, 30)])
	assert(cap_chain.size() >= 2, "Captain dialogue chain must have at least 2 steps, got %d" % cap_chain.size())
	assert(cap_chain[0].id == 30124, "Step 1 must be 30124")
	assert(cap_chain[1].id == 30125, "Step 2 must be 30125")
	print("PASS: Test 3 - Dialogue chaining (get_dialogue_chain) returns multi-page sequence.")
	
	# -------------------------------------------------------------
	# Test 4: Dialogue Branching and Choices
	# -------------------------------------------------------------
	var t_lake: Dictionary = db.get_talk(30129)
	assert(not t_lake.is_empty(), "Talk 30129 (Lake Spirit) must exist")
	assert(not t_lake.choices.is_empty(), "Talk 30129 must have branching choices, got: %d" % t_lake.choices.size())
	print("[Test] Lake Spirit Choice count: %d" % t_lake.choices.size())
	for c in t_lake.choices:
		print("  - Choice: text='%s', next_talk=%d" % [c.text, c.next_talk_id])
	print("PASS: Test 4 - Dialogue branching & choice options verified.")
	
	# -------------------------------------------------------------
	# Test 5: Token Extraction and BBCode Formatting
	# -------------------------------------------------------------
	var raw_dialogue: String = "Welcome #n! #RBe careful#W of monsters! #s402 #f3"
	var formatted: String = db.format_dialogue_tokens(raw_dialogue, "Hero")
	assert(formatted.contains("Hero"), "Formatted text must contain player name 'Hero', got: %s" % formatted)
	assert(formatted.contains("[color=red]"), "Formatted text must contain BBCode [color=red], got: %s" % formatted)
	assert(formatted.contains("[/color]"), "Formatted text must contain BBCode [/color], got: %s" % formatted)
	
	var sfx: String = db.extract_sound_effect(raw_dialogue)
	assert(sfx == "402", "Extracted SFX must be '402', got '%s'" % sfx)
	
	var face: int = db.extract_face_index(raw_dialogue)
	assert(face == 3, "Extracted face index must be 3, got %d" % face)
	print("PASS: Test 5 - Token extraction (#n, #R/#W, #s, #f) verified.")
	
	# -------------------------------------------------------------
	# Test 6: NPC Talk Resolution (Map Context Binding)
	# -------------------------------------------------------------
	# Captain (ID 14003) on Ship Deck (Map 10001) -> 30124
	var res_cap: Dictionary = db.resolve_talk_for_npc(14003, 10001)
	assert(not res_cap.is_empty(), "Captain must resolve talk on Map 10001")
	assert(res_cap.id == 30124, "Captain must resolve to 30124, got %d" % res_cap.id)
	
	# Jack (ID 14091) on Ship Cabin (Map 10002) -> 30126
	var res_jack: Dictionary = db.resolve_talk_for_npc(14091, 10002)
	assert(not res_jack.is_empty(), "Jack must resolve talk on Map 10002")
	assert(res_jack.id == 30126, "Jack must resolve to 30126, got %d" % res_jack.id)
	
	# Ross (ID 14152) on Ship Cabin (Map 10002) -> 30120
	var res_ross: Dictionary = db.resolve_talk_for_npc(14152, 10002)
	assert(not res_ross.is_empty(), "Ross must resolve talk on Map 10002")
	assert(res_ross.id == 30120, "Ross must resolve to 30120, got %d" % res_ross.id)
	print("PASS: Test 6 - NPC talk resolution by NPC ID and Map ID verified.")
	
	# -------------------------------------------------------------
	# Test 7: NpcDatabase talk_image Decoding & Bit-Exact IDs
	# -------------------------------------------------------------
	var npc_cls = load("res://scripts/database/npc_database.gd")
	assert(npc_cls != null, "NpcDatabase class must load")
	var n_db = npc_cls.new()
	var n_loaded: bool = n_db.load_from_file(npc_file)
	assert(n_loaded, "Npc.dat must load successfully")
	
	# Check Captain (14003) -> talk_image == 8025
	var cap_npc = n_db.get_npc(14003)
	assert(cap_npc != null, "Captain (14003) must exist in NpcDatabase")
	assert(cap_npc.talk_image == 8025, "Captain talk_image must be 8025, got %d" % cap_npc.talk_image)
	
	# Check Jack (14091) -> talk_image == 8004
	var jack_npc = n_db.get_npc(14091)
	assert(jack_npc != null, "Jack (14091) must exist in NpcDatabase")
	assert(jack_npc.talk_image == 8004, "Jack talk_image must be 8004, got %d" % jack_npc.talk_image)
	
	# Check Ross (14152) -> talk_image == 8005
	var ross_npc = n_db.get_npc(14152)
	assert(ross_npc != null, "Ross (14152) must exist in NpcDatabase")
	assert(ross_npc.talk_image == 8005, "Ross talk_image must be 8005, got %d" % ross_npc.talk_image)
	print("PASS: Test 7 - NpcDatabase talk_image decoding verified (Captain=8025, Jack=8004, Ross=8005).")
	
	# -------------------------------------------------------------
	# Test 8: Portrait Loading from 008.jma (Talking & Blinking)
	# -------------------------------------------------------------
	var al_cls = load("res://scripts/core/archive_loader.gd")
	assert(al_cls != null, "ArchiveLoader class must load")
	var loader = al_cls.new()
	loader.initialize_archives()
	
	var cap_anim = loader.get_jma_animation("008.jma", "8025.jmp")
	assert(cap_anim != null, "Captain portrait 8025.jmp must exist in 008.jma")
	assert(cap_anim.frames.size() >= 2, "Captain 8025.jmp must have at least 2 frames (talk + blink), got %d" % cap_anim.frames.size())
	
	var frame0 = cap_anim.decode_frame(0)
	var frame1 = cap_anim.decode_frame(1)
	assert(frame0 != null, "Frame 0 (talking) must decode successfully")
	assert(frame1 != null, "Frame 1 (blinking) must decode successfully")
	print("[Test] Captain 8025.jmp frame 0 dimensions: %dx%d" % [frame0.get_width(), frame0.get_height()])
	print("PASS: Test 8 - 008.jma portrait extraction and frame decoding verified.")
	
	# -------------------------------------------------------------
	# Test 9: NPC Entity Emotion Bubbles & Quest Markers
	# -------------------------------------------------------------
	var npc_scene = load("res://scenes/world/npc.tscn")
	assert(npc_scene != null, "npc.tscn scene must load")
	var npc_node = npc_scene.instantiate()
	assert(npc_node != null, "NpcEntity node instantiated")
	root.add_child(npc_node)
	
	# Test emotion reaction
	npc_node.show_emotion("!")
	assert(npc_node.emotion_container != null, "emotion_container must be created")
	var el = npc_node.emotion_label
	assert(el != null, "EmotionLabel must exist in container")
	assert(el.text == "!", "Emotion text must be '!', got '%s'" % el.text)
	
	# Test quest marker
	npc_node.show_quest_marker(true, false)
	assert(npc_node.emotion_label != null, "EmotionLabel must exist in container")
	assert(npc_node.emotion_label.text == "!", "Quest marker must be '!' for available quest")
	
	npc_node.show_quest_marker(false, true)
	assert(npc_node.emotion_label.text == "?", "Quest marker must be '?' for turn-in quest")
	
	npc_node.queue_free()
	print("PASS: Test 9 - NPC Entity emotion bubbles and animated quest markers verified.")
	
	# -------------------------------------------------------------
	# Test 10: GameDatabase Autoload Singleton Integration
	# -------------------------------------------------------------
	var gd_cls = load("res://scripts/database/game_database.gd")
	assert(gd_cls != null, "GameDatabase class must load")
	var g_db = gd_cls.new()
	g_db.load_all()
	assert(g_db.talks != null, "GameDatabase.talks must be initialized")
	assert(g_db.talks.get_count() >= 17000, "GameDatabase.talks must contain >= 17,000 dialogues")
	
	var gd_talk: Dictionary = g_db.get_talk(30124)
	assert(not gd_talk.is_empty(), "GameDatabase.get_talk(30124) must return Captain dialogue")
	assert(gd_talk.speaker == "Captain", "GameDatabase.get_talk(30124) speaker must be Captain")
	print("PASS: Test 10 - GameDatabase autoload coordinator integration verified.")
	
	print("==================================================================")
	print("=== ALL TALK DATABASE TESTS PASSED SUCCESSFULLY (10/10)       ===")
	print("==================================================================")
	quit(0)
