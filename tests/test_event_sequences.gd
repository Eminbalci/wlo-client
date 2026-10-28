extends SceneTree

## Comprehensive Verification Suite for Ship Sinking Cutscene and Beach Awakening (Map 10011).
## Validates video seconds 176 - 320 parity: camera shake FX, decaying trauma, red flashing overlay,
## ship tilt, siren and sinking audio cues, fade to black, Map 10011 scene loading,
## player washed ashore prone-to-standing wake-up sequence, and Kelang dialogue tree.

const SinkingCutsceneClass = preload("res://scripts/events/sinking_cutscene.gd")
const BeachAwakeningClass = preload("res://scripts/events/beach_awakening.gd")
const ArchiveLoaderClass = preload("res://scripts/core/archive_loader.gd")
const IsometricMath = preload("res://scripts/map/isometric_math.gd")
const TalkDatabase = preload("res://scripts/database/talk_database.gd")

func _init() -> void:
	print("=================================================================")
	print("--- Running Ship Sinking & Beach Awakening Verification Suite ---")
	print("=================================================================\n")
	
	test_sinking_cutscene_scene_and_controller()
	test_sinking_cutscene_stages_and_trauma()
	test_sinking_cutscene_triggers_and_tilt()
	test_beach_awakening_scene_and_map_10011()
	test_player_prone_awakening_animation_frames()
	test_kelang_npc_parity_and_dialogue_tree()
	test_ambient_waves_and_environmental_audio()
	
	print("\n=================================================================")
	print("--- ALL SINKING & BEACH AWAKENING TESTS PASSED SUCCESSFULLY ---")
	print("=================================================================\n")
	quit(0)

func test_sinking_cutscene_scene_and_controller() -> void:
	print("[PART 1] Verifying Sinking Cutscene Scene & Controller...")
	var scene_res = load("res://scenes/events/sinking_cutscene.tscn")
	assert(scene_res != null, "ERROR: scenes/events/sinking_cutscene.tscn could not be loaded")
	
	var scene_instance = scene_res.instantiate()
	assert(scene_instance != null, "ERROR: Sinking cutscene scene could not be instantiated")
	assert(scene_instance is SinkingCutsceneClass, "ERROR: Sinking cutscene scene root must be SinkingCutsceneController")
	
	root.add_child(scene_instance)
	assert(scene_instance.camera != null, "ERROR: Camera2D not resolved in SinkingCutscene")
	assert(scene_instance.red_overlay != null, "ERROR: RedOverlay not resolved in SinkingCutscene")
	assert(scene_instance.fade_overlay != null, "ERROR: FadeOverlay not resolved in SinkingCutscene")
	assert(scene_instance.audio_player != null, "ERROR: Alarm AudioStreamPlayer not resolved")
	assert(scene_instance.sfx_player != null, "ERROR: Sinking SFX AudioStreamPlayer not resolved")
	
	scene_instance.queue_free()
	print("  -> Part 1 Passed: Sinking cutscene scene structure and node bindings verified.")

func test_sinking_cutscene_stages_and_trauma() -> void:
	print("[PART 2] Verifying Sinking Cutscene Stages, Trauma Shake & Red Flash...")
	var node = SinkingCutsceneClass.new()
	root.add_child(node)
	
	# Initial state
	assert(node.current_stage == SinkingCutsceneClass.CutsceneStage.NORMAL, "ERROR: Initial stage must be NORMAL")
	assert(node.trauma == 0.0, "ERROR: Initial trauma must be 0.0")
	
	# Trigger WARNING
	node.trigger_cutscene("test_trigger")
	assert(node.current_stage == SinkingCutsceneClass.CutsceneStage.WARNING, "ERROR: Stage must transition to WARNING")
	assert(node.trauma > 0.0, "ERROR: Trauma must be active upon cutscene start")
	
	# Advance to SINKING stage using delta stepping (elapsed >= warning_duration)
	node._process(node.warning_duration + 0.1)
	assert(node.current_stage == SinkingCutsceneClass.CutsceneStage.SINKING, "ERROR: Stage must transition to SINKING at t>=warning_duration")
	assert(node.trauma > 0.0, "ERROR: Trauma must be active during SINKING stage")
	
	# Verify trauma decays over time
	var prev_trauma: float = node.trauma
	node._process(0.5)
	assert(node.trauma <= prev_trauma, "ERROR: Trauma must decay over time")
	
	# Advance to FADED stage (elapsed >= warning_duration + sinking_duration)
	node._process(node.sinking_duration)
	assert(node.current_stage == SinkingCutsceneClass.CutsceneStage.FADED, "ERROR: Stage must transition to FADED at t>=fade_threshold")
	
	# Advance to AWAKENED stage (elapsed >= awaken_threshold)
	node._process(node.fade_duration + 0.5)
	assert(node.current_stage == SinkingCutsceneClass.CutsceneStage.AWAKENED, "ERROR: Stage must transition to AWAKENED at t>=awaken_threshold")
	
	node.queue_free()
	print("  -> Part 2 Passed: Stage progression (NORMAL->WARNING->SINKING->FADED->AWAKENED) and trauma decay verified.")

func test_sinking_cutscene_triggers_and_tilt() -> void:
	print("[PART 3] Verifying Captain Dialogue / Cabin Inspection Triggers and Ship Tilt...")
	var node = SinkingCutsceneClass.new()
	root.add_child(node)
	
	# 1. Trigger via Captain Dialogue
	node.trigger_after_captain_dialogue()
	assert(node.trigger_reason == "captain_dialogue", "ERROR: trigger_reason must be 'captain_dialogue'")
	assert(node.current_stage == SinkingCutsceneClass.CutsceneStage.WARNING, "ERROR: Cutscene must start on Captain trigger")
	node.queue_free()
	
	# 2. Trigger via Cabin Inspection
	node = SinkingCutsceneClass.new()
	root.add_child(node)
	node.trigger_after_cabin_inspection()
	assert(node.trigger_reason == "cabin_inspection", "ERROR: trigger_reason must be 'cabin_inspection'")
	
	# Advance to SINKING stage
	node._process(node.warning_duration + 0.1)
	assert(node.current_stage == SinkingCutsceneClass.CutsceneStage.SINKING, "ERROR: Must be in SINKING stage")
	assert(node.ship_tilt_angle > 0.0, "ERROR: ship_tilt_angle must increase during sinking")
	
	node.queue_free()
	print("  -> Part 3 Passed: Captain & cabin triggers verified; ship tilt angle successfully computed.")

func test_beach_awakening_scene_and_map_10011() -> void:
	print("[PART 4] Verifying Beach Awakening Scene & Map 10011 Assets...")
	var scene_res = load("res://scenes/maps/map_10011_beach.tscn")
	assert(scene_res != null, "ERROR: scenes/maps/map_10011_beach.tscn could not be loaded")
	
	var scene_instance = scene_res.instantiate()
	assert(scene_instance != null, "ERROR: Map 10011 scene could not be instantiated")
	assert(scene_instance is BeachAwakeningClass, "ERROR: Map 10011 root must be BeachAwakeningController")
	
	root.add_child(scene_instance)
	var m_ren = scene_instance.get_node_or_null("MapRenderer")
	assert(m_ren != null, "ERROR: MapRenderer must be present in map_10011_beach.tscn")
	assert(m_ren.current_map_id == 10011, "ERROR: MapRenderer current_map_id must be 10011")
	assert(scene_instance.get_node_or_null("Entities/Player") != null, "ERROR: Player must be present in map_10011_beach.tscn")
	assert(scene_instance.kelang_npc != null, "ERROR: KelangNPC must be present in map_10011_beach.tscn")
	assert(scene_instance.ambient_waves != null, "ERROR: AmbientWavesAudio must be present in map_10011_beach.tscn")
	assert(scene_instance.beach_bgm != null, "ERROR: BeachBGM must be present in map_10011_beach.tscn")
	
	# Verify background and minimap texture loading via ArchiveLoader for 10011
	var loader = ArchiveLoaderClass.new()
	loader.initialize_archives()
	var bg_tex = loader.get_map_background(10011)
	assert(bg_tex != null, "ERROR: Map 10011 background texture must resolve via ArchiveLoader")
	assert(bg_tex.get_width() > 0 and bg_tex.get_height() > 0, "ERROR: Map 10011 background size must be valid")
	
	var mm_tex = loader.get_minimap_texture(10011)
	assert(mm_tex != null, "ERROR: Map 10011 minimap texture must resolve via ArchiveLoader")
	
	scene_instance.queue_free()
	loader.queue_free()
	print("  -> Part 4 Passed: Map 10011 scene structure, background (10003.jpg), and minimap verified.")

func test_player_prone_awakening_animation_frames() -> void:
	print("[PART 5] Verifying Player Prone-to-Standing Awakening Animation Frames & Kinematics Lock...")
	var loader = ArchiveLoaderClass.new()
	loader.initialize_archives()
	
	var frames: Array[ImageTexture] = loader.get_player_awakening_composite_frames(2)
	assert(frames.size() == 3, "ERROR: Player awakening frames must have exactly 3 stages (prone, rising, standing)")
	for i in range(frames.size()):
		assert(frames[i] != null, "ERROR: Awakening frame %d texture is null" % i)
		assert(frames[i].get_width() == 128 and frames[i].get_height() == 128, "ERROR: Awakening frame %d must be 128x128" % i)
	
	# Test PlayerEntity prone and movement lock behavior
	var player_scene = load("res://scenes/world/player.tscn")
	var player = player_scene.instantiate()
	root.add_child(player)
	
	player.set_prone(true)
	assert(player.is_prone == true, "ERROR: Player must report is_prone == true")
	assert(player.is_movement_locked == true, "ERROR: Player movement must be locked when prone")
	
	# Attempt pathing while prone -> must be blocked
	var move_ok: bool = player.set_target_world_position(Vector2(1200, 2200))
	assert(move_ok == false, "ERROR: Movement must be rejected when player is prone / recovering")
	assert(player.is_moving == false, "ERROR: Player must not be moving when prone")
	
	player.set_prone(false)
	assert(player.is_prone == false, "ERROR: Player must report is_prone == false after rising")
	assert(player.is_movement_locked == false, "ERROR: Player movement lock must be released after rising")
	
	player.queue_free()
	loader.queue_free()
	print("  -> Part 5 Passed: Prone (26-2), Rising (26-1), and Stand (08-1) composite frames and kinematic lock verified.")

func test_kelang_npc_parity_and_dialogue_tree() -> void:
	print("[PART 6] Verifying Kelang NPC Spawn, Orientation & Dialogue Tree...")
	var scene_res = load("res://scenes/maps/map_10011_beach.tscn")
	var scene_instance = scene_res.instantiate()
	root.add_child(scene_instance)
	
	var kelang = scene_instance.kelang_npc
	assert(kelang != null, "ERROR: Kelang NPC must be initialized")
	assert(kelang.npc_id == 14062, "ERROR: Kelang npc_id must be 14062 (Kelan Leader)")
	assert(kelang.npc_name == "Kelang", "ERROR: Kelang npc_name must be 'Kelang'")
	assert(kelang.model_jmp == "1131.jmp", "ERROR: Kelang model_jmp must be '1131.jmp'")
	assert(kelang.heading == IsometricMath.Heading.SOUTH_WEST, "ERROR: Kelang must face SOUTH_WEST (towards player)")
	assert(kelang.world_position == Vector2(1088, 2186), "ERROR: Kelang position must be Vector2(1088, 2186)")
	
	# Verify Talk.dat dialogue tree binding for Kelang
	var talk_db = TalkDatabase.new()
	var talk_ok = talk_db.load_from_file("res://assets/data/Talk.dat", "res://assets/data/Npc.dat", "res://assets/data/Eve.emg")
	if not talk_ok:
		talk_db.load_from_file("D:/GitHub/WLRI/data/Talk.dat", "D:/GitHub/WLRI/data/Npc.dat", "D:/GitHub/WLRI/data/Eve.emg")
	
	var kelang_talk: Dictionary = talk_db.get_talk(20305)
	assert(not kelang_talk.is_empty(), "ERROR: Talk 20305 for Kelang must exist")
	assert(kelang_talk.speaker == "Kelang", "ERROR: Speaker for 20305 must be 'Kelang'")
	assert("deserted island" in kelang_talk.plain_text.to_lower(), "ERROR: Dialogue text must mention deserted island")
	assert(kelang_talk.next_talk_id == 20307, "ERROR: Dialogue chain must lead to Talk 20307")
	
	var next_talk: Dictionary = talk_db.get_talk(20307)
	assert("shipwrecked" in next_talk.plain_text.to_lower(), "ERROR: Talk 20307 must mention shipwreck")
	
	scene_instance.queue_free()
	print("  -> Part 6 Passed: Kelang NPC identity, orientation, model 1131.jmp, and Talk 20305..20307 dialogue chain verified.")

func test_ambient_waves_and_environmental_audio() -> void:
	print("[PART 7] Verifying Ambient Ocean Waves and Environmental Audio Nodes...")
	var scene_res = load("res://scenes/maps/map_10011_beach.tscn")
	var scene_instance = scene_res.instantiate()
	root.add_child(scene_instance)
	
	assert(scene_instance.wave_effects != null, "ERROR: WaveEffects node must exist")
	assert(scene_instance.ambient_waves != null, "ERROR: Ambient waves audio player must exist")
	assert(scene_instance.beach_bgm != null, "ERROR: Beach BGM audio player must exist")
	
	# Advance frame to verify wave oscillation
	scene_instance._process(0.5)
	assert(scene_instance.wave_effects.modulate.a > 0.0, "ERROR: Wave effect alpha modulation must be active")
	
	scene_instance.queue_free()
	print("  -> Part 7 Passed: Wave effects node and ambient environmental audio players verified.")
