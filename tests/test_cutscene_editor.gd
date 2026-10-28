extends Node

const CutsceneEditorClass = preload("res://scripts/tools/cutscene_editor.gd")
const CutsceneRunnerClass = preload("res://scripts/events/cutscene_runner.gd")

## Automated Verification Suite for Wonderland Online Cutscene & Event Sequence Director
## Tests:
## 1. Instantiation, layout resolution & public API contract (800x600 dark UI)
## 2. Multi-track timeline system (Camera, Actor, Dialogue, Audio, Screen FX)
## 3. Keyframe insertion, ascending sort order, modification & removal
## 4. Timeline playback, scrubber seek, frame precision & time scaling
## 5. Mathematical state evaluation engine (lerp, decaying shake, typewriter, tilt, flash)
## 6. Built-in presets (Ship Sinking Climax, Monkey Beach Awakening, Kelan Cave Ambush)
## 7. Actor roster registration, custom staging & lifecycle
## 8. JSON data serialization & bidirectional file roundtrip
## 9. Standalone Godot 4 .tscn scene export & runtime instantiation

func _ready() -> void:
	print("=================================================================")
	print("--- Running WLO Cutscene & Event Sequence Director Test Suite ---")
	print("=================================================================\n")
	
	_test_instantiation_and_structure()
	_test_track_management_and_keyframes()
	_test_timeline_playback_and_scrubber()
	_test_state_evaluation_engine()
	_test_builtin_presets()
	_test_actor_roster_management()
	_test_json_serialization_roundtrip()
	_test_standalone_scene_export_and_instantiation()
	
	print("\n=================================================================")
	print("--- ALL CUTSCENE & EVENT DIRECTOR TESTS PASSED (100%) ---")
	print("=================================================================")
	get_tree().quit(0)

func _test_instantiation_and_structure() -> void:
	print(">>> [TEST 1] Verifying CutsceneEditor Instantiation & Layout (cutscene_editor.tscn)...")
	var scene_res = load("res://scenes/tools/cutscene_editor.tscn")
	assert(scene_res != null, "ERROR: cutscene_editor.tscn failed to load")
	
	var editor = scene_res.instantiate()
	assert(editor != null, "ERROR: cutscene_editor could not be instantiated")
	add_child(editor)
	
	assert(editor is CutsceneEditorClass, "ERROR: Instantiated node must be CutsceneEditor")
	assert(editor.custom_minimum_size.x >= 800.0, "ERROR: Custom min width must be >= 800")
	assert(editor.custom_minimum_size.y >= 600.0, "ERROR: Custom min height must be >= 600")
	
	# Verify essential public methods
	var required_methods: Array[String] = [
		"play",
		"pause",
		"stop",
		"seek",
		"seek_frame",
		"set_time_scale",
		"get_time_scale",
		"set_total_duration",
		"get_total_duration",
		"get_current_time",
		"is_playback_active",
		"add_keyframe",
		"remove_keyframe",
		"get_keyframes",
		"get_keyframe",
		"set_keyframe",
		"get_keyframe_count",
		"clear_track",
		"clear_all_tracks",
		"evaluate_at_time",
		"load_preset",
		"get_preset_names",
		"get_preset_data",
		"save_cutscene_json",
		"load_cutscene_json",
		"export_cutscene_scene",
		"create_cutscene_data",
		"add_actor",
		"remove_actor",
		"get_active_actors",
		"has_actor",
		"get_actor_info"
	]
	
	for m in required_methods:
		assert(editor.has_method(m), "ERROR: CutsceneEditor missing required method: %s" % m)
		
	print("  PASS: CutsceneEditor instantiated with 800x600 size and all %d required methods." % required_methods.size())
	editor.queue_free()

func _test_track_management_and_keyframes() -> void:
	print(">>> [TEST 2] Verifying Multi-Track Management & Keyframe Sorting...")
	var editor: CutsceneEditorClass = CutsceneEditorClass.new()
	add_child(editor)
	editor.clear_all_tracks()
	
	# Verify all 5 track types exist and are empty
	for t in CutsceneEditorClass.ALL_TRACK_TYPES:
		assert(editor.get_keyframe_count(t) == 0, "ERROR: Track %s must be empty after clear" % t)
		
	# 1. Camera Track
	editor.add_keyframe(CutsceneEditorClass.TRACK_CAMERA, {
		"time": 5.0,
		"pan_target": Vector2(500, 400),
		"zoom": 1.5,
		"shake_intensity": 0.5,
		"shake_duration": 2.0
	})
	editor.add_keyframe(CutsceneEditorClass.TRACK_CAMERA, {
		"time": 1.0,
		"pan_target": Vector2(400, 300),
		"zoom": 1.0,
		"shake_intensity": 0.0,
		"shake_duration": 0.0
	})
	editor.add_keyframe(CutsceneEditorClass.TRACK_CAMERA, {
		"time": 8.0,
		"pan_target": Vector2(600, 500),
		"zoom": 2.0,
		"shake_intensity": 0.0,
		"shake_duration": 0.0
	})
	
	assert(editor.get_keyframe_count(CutsceneEditorClass.TRACK_CAMERA) == 3, "ERROR: Camera track count must be 3")
	var cam_keys: Array[Dictionary] = editor.get_keyframes(CutsceneEditorClass.TRACK_CAMERA)
	# Verify ascending sort order by time
	assert(cam_keys[0]["time"] == 1.0, "ERROR: Keyframe 0 must be time 1.0")
	assert(cam_keys[1]["time"] == 5.0, "ERROR: Keyframe 1 must be time 5.0")
	assert(cam_keys[2]["time"] == 8.0, "ERROR: Keyframe 2 must be time 8.0")
	
	# 2. Actor Track
	editor.add_keyframe(CutsceneEditorClass.TRACK_ACTOR, {
		"time": 0.0,
		"actor_id": "player",
		"actor_name": "Daniel",
		"position": Vector2(100, 200),
		"facing": 0,
		"action": "Idle",
		"visible": true
	})
	editor.add_keyframe(CutsceneEditorClass.TRACK_ACTOR, {
		"time": 3.0,
		"actor_id": "player",
		"actor_name": "Daniel",
		"position": Vector2(300, 200),
		"facing": 6,
		"action": "Walk",
		"visible": true
	})
	assert(editor.get_keyframe_count(CutsceneEditorClass.TRACK_ACTOR) == 2, "ERROR: Actor track count must be 2")
	
	# 3. Dialogue Track
	editor.add_keyframe(CutsceneEditorClass.TRACK_DIALOGUE, {
		"time": 2.0,
		"duration": 4.0,
		"speaker": "Daniel",
		"text": "Hello Wonderland!",
		"typewriter_delay": 0.03
	})
	assert(editor.get_keyframe_count(CutsceneEditorClass.TRACK_DIALOGUE) == 1, "ERROR: Dialogue track count must be 1")
	
	# 4. Audio Track
	editor.add_keyframe(CutsceneEditorClass.TRACK_AUDIO, {
		"time": 0.0,
		"audio_type": "BGM",
		"resource_id": "BGM001.wav",
		"volume_db": -3.0
	})
	assert(editor.get_keyframe_count(CutsceneEditorClass.TRACK_AUDIO) == 1, "ERROR: Audio track count must be 1")
	
	# 5. Screen FX Track
	editor.add_keyframe(CutsceneEditorClass.TRACK_SCREEN_FX, {
		"time": 4.0,
		"duration": 2.5,
		"fx_type": "Flash",
		"color": Color.RED,
		"intensity": 0.8
	})
	assert(editor.get_keyframe_count(CutsceneEditorClass.TRACK_SCREEN_FX) == 1, "ERROR: Screen FX track count must be 1")
	
	# Test keyframe modification
	var mod_ok: bool = editor.set_keyframe(CutsceneEditorClass.TRACK_CAMERA, 0, {
		"time": 0.5,
		"pan_target": Vector2(350, 250),
		"zoom": 1.1
	})
	assert(mod_ok, "ERROR: set_keyframe failed")
	var updated_k: Dictionary = editor.get_keyframe(CutsceneEditorClass.TRACK_CAMERA, 0)
	assert(updated_k["time"] == 0.5, "ERROR: Updated keyframe time must be 0.5")
	assert(updated_k["zoom"] == 1.1, "ERROR: Updated keyframe zoom must be 1.1")
	
	# Test keyframe removal
	var rem_ok: bool = editor.remove_keyframe(CutsceneEditorClass.TRACK_CAMERA, 0)
	assert(rem_ok, "ERROR: remove_keyframe failed")
	assert(editor.get_keyframe_count(CutsceneEditorClass.TRACK_CAMERA) == 2, "ERROR: Camera keyframes count must now be 2")
	
	# Test track clearing
	editor.clear_track(CutsceneEditorClass.TRACK_CAMERA)
	assert(editor.get_keyframe_count(CutsceneEditorClass.TRACK_CAMERA) == 0, "ERROR: Camera track must be empty after clear_track")
	
	print("  PASS: Multi-track insertion, ascending sort order, modification & deletion verified across all 5 tracks.")
	editor.queue_free()

func _test_timeline_playback_and_scrubber() -> void:
	print(">>> [TEST 3] Verifying Timeline Playback, Scrubber & Time Scaling...")
	var editor: CutsceneEditorClass = CutsceneEditorClass.new()
	add_child(editor)
	
	editor.set_total_duration(20.0)
	assert(editor.get_total_duration() == 20.0, "ERROR: Total duration must be 20.0")
	
	# Seek testing
	editor.seek(5.5)
	assert(is_equal_approx(editor.get_current_time(), 5.5), "ERROR: Current time must be 5.5 after seek")
	
	# Seek beyond total_duration must clamp
	editor.seek(99.0)
	assert(is_equal_approx(editor.get_current_time(), 20.0), "ERROR: Current time must clamp to total_duration")
	
	# Seek below 0 must clamp
	editor.seek(-5.0)
	assert(is_equal_approx(editor.get_current_time(), 0.0), "ERROR: Current time must clamp to 0.0")
	
	# Frame seek: frame 60 at 30 FPS = 2.0s
	editor.seek_frame(60, 30)
	assert(is_equal_approx(editor.get_current_time(), 2.0), "ERROR: Frame 60 at 30fps must seek to 2.0s")
	
	# Playback controls
	assert(not editor.is_playback_active(), "ERROR: Playback must initially be inactive")
	editor.play()
	assert(editor.is_playback_active(), "ERROR: Playback must be active after play()")
	
	# Advance via _process(1.0) with time_scale=1.0
	editor._process(1.0)
	assert(is_equal_approx(editor.get_current_time(), 3.0), "ERROR: Time must advance from 2.0 to 3.0")
	
	# Time scale = 2.0x
	editor.set_time_scale(2.0)
	assert(editor.get_time_scale() == 2.0, "ERROR: Time scale must be 2.0")
	editor._process(1.0)
	assert(is_equal_approx(editor.get_current_time(), 5.0), "ERROR: Time must advance by 2.0s with 2.0x time scale")
	
	# Pause
	editor.pause()
	assert(not editor.is_playback_active(), "ERROR: Playback must be inactive after pause()")
	var paused_t: float = editor.get_current_time()
	editor._process(1.0)
	assert(is_equal_approx(editor.get_current_time(), paused_t), "ERROR: Time must not advance while paused")
	
	# Stop
	editor.stop()
	assert(not editor.is_playback_active(), "ERROR: Playback must be inactive after stop()")
	assert(is_equal_approx(editor.get_current_time(), 0.0), "ERROR: Time must reset to 0.0 after stop()")
	
	print("  PASS: Playback, pause, stop, frame seek, time scaling & bounds clamping verified.")
	editor.queue_free()

func _test_state_evaluation_engine() -> void:
	print(">>> [TEST 4] Verifying State Evaluation Engine (Interpolation, Shake & Typewriter)...")
	var editor: CutsceneEditorClass = CutsceneEditorClass.new()
	add_child(editor)
	editor.clear_all_tracks()
	editor.set_total_duration(10.0)
	
	# Setup camera with pan and shake
	editor.add_keyframe(CutsceneEditorClass.TRACK_CAMERA, {
		"time": 0.0,
		"pan_target": Vector2(100.0, 100.0),
		"zoom": 1.0,
		"shake_intensity": 0.0,
		"shake_duration": 0.0,
		"interpolation": "Linear"
	})
	editor.add_keyframe(CutsceneEditorClass.TRACK_CAMERA, {
		"time": 4.0,
		"pan_target": Vector2(500.0, 300.0),
		"zoom": 2.0,
		"shake_intensity": 1.0,
		"shake_duration": 4.0, # Shake from t=4.0 to t=8.0
		"interpolation": "Linear"
	})
	
	# Setup actor
	editor.add_actor("daniel", "Daniel", Vector2(100, 200), 6, "Walk")
	editor.add_keyframe(CutsceneEditorClass.TRACK_ACTOR, {
		"time": 0.0,
		"actor_id": "daniel",
		"position": Vector2(100.0, 200.0),
		"facing": 6,
		"action": "Walk"
	})
	editor.add_keyframe(CutsceneEditorClass.TRACK_ACTOR, {
		"time": 4.0,
		"actor_id": "daniel",
		"position": Vector2(300.0, 400.0),
		"facing": 7,
		"action": "Pose"
	})
	
	# Setup dialogue
	editor.add_keyframe(CutsceneEditorClass.TRACK_DIALOGUE, {
		"time": 2.0,
		"duration": 4.0,
		"speaker": "Daniel",
		"text": "ABCDEFGHIJ", # 10 characters
		"typewriter_delay": 0.1 # 1 char per 0.1s
	})
	
	# Setup screen FX
	editor.add_keyframe(CutsceneEditorClass.TRACK_SCREEN_FX, {
		"time": 4.0,
		"duration": 4.0,
		"fx_type": "CameraTilt",
		"tilt_angle": 12.0
	})
	
	# Evaluate at t = 2.0s (midpoint of 0.0 to 4.0)
	var state_2s: Dictionary = editor.evaluate_at_time(2.0)
	
	# Camera pan midpoint: lerp( (100,100), (500,300), 0.5 ) = (300, 200)
	var cam_pos: Vector2 = state_2s["camera"]["position"]
	assert(is_equal_approx(cam_pos.x, 300.0) and is_equal_approx(cam_pos.y, 200.0), "ERROR: Camera pan at 2.0s must be (300, 200), got: %s" % cam_pos)
	assert(is_equal_approx(state_2s["camera"]["zoom"], 1.5), "ERROR: Zoom at 2.0s must be 1.5")
	assert(state_2s["camera"]["shake_intensity"] == 0.0, "ERROR: Shake at 2.0s must be 0.0")
	
	# Actor position midpoint: lerp( (100,200), (300,400), 0.5 ) = (200, 300)
	var actor_pos: Vector2 = state_2s["actors"]["daniel"]["position"]
	assert(is_equal_approx(actor_pos.x, 200.0) and is_equal_approx(actor_pos.y, 300.0), "ERROR: Actor pos at 2.0s must be (200, 300), got: %s" % actor_pos)
	
	# Dialogue at t = 2.5s (0.5s into dialogue => 5 chars of "ABCDEFGHIJ" = "ABCDE")
	var state_25s: Dictionary = editor.evaluate_at_time(2.5)
	assert(state_25s["dialogue"]["is_active"] == true, "ERROR: Dialogue must be active at 2.5s")
	assert(state_25s["dialogue"]["text"] == "ABCDE", "ERROR: Dialogue text at 2.5s must be 'ABCDE', got '%s'" % state_25s["dialogue"]["text"])
	
	# Evaluate shake at t = 6.0s (midway through shake duration [4..8])
	var state_6s: Dictionary = editor.evaluate_at_time(6.0)
	assert(state_6s["camera"]["shake_intensity"] > 0.4 and state_6s["camera"]["shake_intensity"] <= 0.6, "ERROR: Shake trauma at 6.0s should be ~0.5, got: %f" % state_6s["camera"]["shake_intensity"])
	assert(state_6s["camera"]["shake_offset"] != Vector2.ZERO, "ERROR: Shake offset must be non-zero during active trauma")
	
	# Camera tilt at t = 6.0s
	assert(state_6s["screen_fx"]["tilt_angle"] > 0.0, "ERROR: Tilt angle at 6.0s must be active")
	
	print("  PASS: Mathematical state evaluation (linear pan/zoom lerp, typewriter chunking, decaying shake & tilt) verified.")
	editor.queue_free()

func _test_builtin_presets() -> void:
	print(">>> [TEST 5] Verifying 3 Built-in Authentic Presets...")
	var editor: CutsceneEditorClass = CutsceneEditorClass.new()
	add_child(editor)
	
	var preset_names: Array[String] = editor.get_preset_names()
	assert(preset_names.has("Ship Sinking Climax"), "ERROR: Missing Ship Sinking Climax preset")
	assert(preset_names.has("Monkey Beach Awakening"), "ERROR: Missing Monkey Beach Awakening preset")
	assert(preset_names.has("Kelan Cave Ambush"), "ERROR: Missing Kelan Cave Ambush preset")
	
	# 1. Ship Sinking Climax
	var p1_ok: bool = editor.load_preset("Ship Sinking Climax")
	assert(p1_ok, "ERROR: Failed to load Ship Sinking Climax preset")
	assert(editor.cutscene_title == "Ship Sinking Climax", "ERROR: Title mismatch for Ship Sinking Climax")
	assert(editor.get_total_duration() == 15.0, "ERROR: Ship sinking duration must be 15.0s")
	assert(editor.has_actor("captain"), "ERROR: Captain actor must be registered in ship sinking")
	assert(editor.has_actor("crew_1"), "ERROR: Sailor Tom actor must be registered in ship sinking")
	assert(editor.has_actor("player"), "ERROR: Player actor must be registered in ship sinking")
	# At t=4.5s: tremor shake is active, captain is posing
	var st_ship_45: Dictionary = editor.evaluate_at_time(4.5)
	assert(st_ship_45["camera"]["shake_intensity"] > 0.6, "ERROR: Ship collision shake must be violent at 4.5s")
	assert(st_ship_45["screen_fx"]["flash_color"].a > 0.0, "ERROR: Red emergency alarm flash must be active at 4.5s")
	assert(st_ship_45["dialogue"]["is_active"] == true, "ERROR: Captain dialogue must be active at 4.5s")
	assert(st_ship_45["dialogue"]["speaker"] == "Captain Robinson", "ERROR: Speaker must be Captain Robinson")
	
	# 2. Monkey Beach Awakening
	var p2_ok: bool = editor.load_preset("Monkey Beach Awakening")
	assert(p2_ok, "ERROR: Failed to load Monkey Beach Awakening preset")
	assert(editor.has_actor("player"), "ERROR: Player actor must be in Monkey Beach Awakening")
	assert(editor.has_actor("kelang"), "ERROR: Kelang actor must be in Monkey Beach Awakening")
	# At t=0.0s: player is prone washed ashore on sand
	var st_beach_0: Dictionary = editor.evaluate_at_time(0.0)
	assert(st_beach_0["actors"]["player"]["action"] == "Prone", "ERROR: Player must be Prone at t=0 on beach")
	assert(st_beach_0["screen_fx"]["fade_color"].a >= 0.99, "ERROR: Cutscene must start with fade from black")
	# At t=7.0s: player stands up (Idle), Kelang approaches
	var st_beach_7: Dictionary = editor.evaluate_at_time(7.0)
	assert(st_beach_7["actors"]["player"]["action"] == "Idle", "ERROR: Player must be Idle after standing up")
	assert(st_beach_7["actors"]["kelang"]["visible"] == true, "ERROR: Kelang must be visible approaching")
	
	# 3. Kelan Cave Ambush
	var p3_ok: bool = editor.load_preset("Kelan Cave Ambush")
	assert(p3_ok, "ERROR: Failed to load Kelan Cave Ambush preset")
	assert(editor.has_actor("bat_1"), "ERROR: Cave bat must be in Kelan Cave Ambush")
	assert(editor.has_actor("slime_1"), "ERROR: Kelan slime must be in Kelan Cave Ambush")
	# At t=5.5s: monster spawn shockwave
	var st_cave_55: Dictionary = editor.evaluate_at_time(5.5)
	assert(st_cave_55["camera"]["shake_intensity"] >= 0.7, "ERROR: Ambush shockwave shake must be active at 5.5s")
	assert(st_cave_55["actors"]["bat_1"]["action"] == "Attack", "ERROR: Cave bat must be in Attack pose at 5.5s")
	assert(st_cave_55["dialogue"]["is_active"] == true, "ERROR: Dialogue must be active at 5.5s")
	
	print("  PASS: All 3 authentic presets loaded and verified at critical story timestamps.")
	editor.queue_free()

func _test_actor_roster_management() -> void:
	print(">>> [TEST 6] Verifying Actor Roster Registration & Staging...")
	var editor: CutsceneEditorClass = CutsceneEditorClass.new()
	add_child(editor)
	editor.actors.clear()
	
	var a1_ok: bool = editor.add_actor("hero", "Hero", Vector2(250, 350), 2, "Walk")
	assert(a1_ok, "ERROR: add_actor failed for hero")
	assert(editor.has_actor("hero"), "ERROR: has_actor must return true for hero")
	
	var a2_ok: bool = editor.add_actor("villain", "Shadow Knight", Vector2(500, 350), 6, "Attack")
	assert(a2_ok, "ERROR: add_actor failed for villain")
	
	var active: Array[String] = editor.get_active_actors()
	assert(active.has("hero") and active.has("villain"), "ERROR: Active actors list must contain both actors")
	
	var info: Dictionary = editor.get_actor_info("hero")
	assert(info["name"] == "Hero", "ERROR: Actor name mismatch")
	assert(info["initial_facing"] == 2, "ERROR: Actor initial facing mismatch")
	
	# Remove actor
	var rem_ok: bool = editor.remove_actor("villain")
	assert(rem_ok, "ERROR: remove_actor failed")
	assert(not editor.has_actor("villain"), "ERROR: villain must no longer exist")
	
	print("  PASS: Actor roster add, lookup, info retrieval and removal verified.")
	editor.queue_free()

func _test_json_serialization_roundtrip() -> void:
	print(">>> [TEST 7] Verifying JSON Serialization & Bidirectional File Roundtrip...")
	var editor: CutsceneEditorClass = CutsceneEditorClass.new()
	add_child(editor)
	
	editor.load_preset("Monkey Beach Awakening")
	var save_path: String = "user://custom_cutscenes/test_roundtrip.json"
	var save_ok: bool = editor.save_cutscene_json(save_path)
	assert(save_ok, "ERROR: save_cutscene_json failed to write: %s" % save_path)
	assert(FileAccess.file_exists(save_path), "ERROR: JSON file not created at %s" % save_path)
	
	# Create a second editor and load the file
	var editor2: CutsceneEditorClass = CutsceneEditorClass.new()
	add_child(editor2)
	var loaded_data: Dictionary = editor2.load_cutscene_json(save_path)
	assert(not loaded_data.is_empty(), "ERROR: load_cutscene_json returned empty dictionary")
	
	assert(editor2.cutscene_title == "Monkey Beach Awakening", "ERROR: Loaded title mismatch")
	assert(editor2.get_total_duration() == 14.0, "ERROR: Loaded duration mismatch")
	assert(editor2.has_actor("kelang"), "ERROR: Loaded actor kelang missing")
	assert(editor2.get_keyframe_count(CutsceneEditorClass.TRACK_CAMERA) > 0, "ERROR: Camera keyframes missing")
	assert(editor2.get_keyframe_count(CutsceneEditorClass.TRACK_DIALOGUE) > 0, "ERROR: Dialogue keyframes missing")
	
	print("  PASS: JSON serialization, disk file write, parsing & state restoration verified.")
	editor.queue_free()
	editor2.queue_free()

func _test_standalone_scene_export_and_instantiation() -> void:
	print(">>> [TEST 8] Verifying Standalone Godot 4 .tscn Scene Export & Execution...")
	var editor: CutsceneEditorClass = CutsceneEditorClass.new()
	add_child(editor)
	
	editor.load_preset("Ship Sinking Climax")
	var tscn_path: String = "user://custom_cutscenes/test_ship_sinking.tscn"
	var exported_path: String = editor.export_cutscene_scene(tscn_path)
	assert(not exported_path.is_empty(), "ERROR: export_cutscene_scene returned empty path")
	assert(FileAccess.file_exists(tscn_path), "ERROR: Exported .tscn file does not exist on disk")
	
	# Load and instantiate the exported scene
	var scene_res = load(tscn_path)
	assert(scene_res != null, "ERROR: Failed to load exported scene from %s" % tscn_path)
	
	var runner = scene_res.instantiate()
	assert(runner != null, "ERROR: Failed to instantiate exported scene")
	add_child(runner)
	
	# Verify node hierarchy in exported scene
	assert(runner is CutsceneRunnerClass, "ERROR: Exported scene root must be CutsceneRunner")
	assert(runner.has_node("Camera2D"), "ERROR: Exported scene missing Camera2D")
	assert(runner.has_node("Actors"), "ERROR: Exported scene missing Actors container")
	assert(runner.has_node("ScreenFX/FadeRect"), "ERROR: Exported scene missing FadeRect")
	assert(runner.has_node("ScreenFX/FlashRect"), "ERROR: Exported scene missing FlashRect")
	assert(runner.has_node("Dialogue/DialogueBox"), "ERROR: Exported scene missing DialogueBox")
	assert(runner.has_node("Audio/AudioBGM"), "ERROR: Exported scene missing AudioBGM")
	assert(runner.has_node("Audio/AudioSFX"), "ERROR: Exported scene missing AudioSFX")
	
	# Verify runner execution
	assert(runner.has_method("play"), "ERROR: Runner missing play method")
	assert(runner.has_method("pause"), "ERROR: Runner missing pause method")
	assert(runner.has_method("stop"), "ERROR: Runner missing stop method")
	assert(runner.has_method("seek"), "ERROR: Runner missing seek method")
	
	runner.seek(4.5)
	assert(is_equal_approx(runner.current_time, 4.5), "ERROR: Runner current_time should be 4.5 after seek")
	
	runner.play()
	assert(runner.is_playback_active(), "ERROR: Runner play() failed")
	runner._process(0.5)
	assert(runner.current_time > 4.5, "ERROR: Runner _process did not advance time")
	runner.stop()
	assert(runner.current_time == 0.0, "ERROR: Runner stop did not reset time")
	
	runner.queue_free()
	editor.queue_free()
	print("  PASS: Standalone .tscn exported, loaded, instantiated and runtime execution verified.")
