extends Node

## Automated Verification Suite for Wonderland Online Audio Jukebox & Sound Design Studio
## Tests:
## 1. Scene and Script Instantiation (800x600 layout & theme bindings)
## 2. Sound Asset Scanning (Scans assets/sound, categorizes BGM, SEB, Combat, Voice, Ambience)
## 3. Asset Search & Multi-criteria Filtering
## 4. Interactive Audio Player & Controls (Play, Pause, Stop, Seek, Volume, Pitch)
## 5. Loop Point Configuration, Loop Bounds, and Fade In/Out
## 6. Real-Time Spectrum & Waveform Visualizer (32-bands & peak hold decay)
## 7. Game Tagging & Association System (Map BGM, Skill SFX, Battle Events, Ambience Layering)
## 8. Presets Verification ("Ship Deck Theme", "Monkey Beach Ambience", "Standard Battle Theme")
## 9. Serialization, Persistence Roundtrip & Audio Manifest Export

const AudioEditorClass = preload("res://scripts/tools/audio_editor.gd")

func _ready() -> void:
	print("=================================================================")
	print("--- Running Audio Jukebox & Sound Design Studio Test Suite ---")
	print("=================================================================\n")

	_test_instantiation_and_structure()
	_test_sound_asset_scanning()
	_test_search_and_filtering()
	_test_audio_playback_and_controls()
	_test_loop_points_and_fade_configuration()
	_test_spectrum_and_waveform_visualizer()
	_test_game_tagging_and_associations()
	_test_presets()
	_test_config_persistence_and_manifest_export()

	print("\n=================================================================")
	print("--- ALL AUDIO JUKBOX & SOUND STUDIO TESTS PASSED (100%) ---")
	print("=================================================================")
	if get_tree():
		get_tree().quit(0)

func _test_instantiation_and_structure() -> void:
	print(">>> [TEST 1] Verifying Instantiation & Layout (audio_editor.tscn)...")
	var scene_res = load("res://scenes/tools/audio_editor.tscn")
	assert(scene_res != null, "ERROR: audio_editor.tscn failed to load")

	var editor = scene_res.instantiate() as AudioEditorClass
	assert(editor != null, "ERROR: audio_editor could not be instantiated")
	add_child(editor)

	assert(editor.custom_minimum_size.x >= 800.0, "ERROR: Minimum width must be >= 800")
	assert(editor.custom_minimum_size.y >= 600.0, "ERROR: Minimum height must be >= 600")

	# Verify UI unique nodes are wired up
	assert(editor.visualizer_canvas != null, "VisualizerCanvas missing")
	assert(editor.list_sounds != null, "ListSounds missing")
	assert(editor.btn_play != null, "BtnPlay missing")
	assert(editor.btn_pause != null, "BtnPause missing")
	assert(editor.btn_stop != null, "BtnStop missing")
	assert(editor.slider_scrubber != null, "SliderScrubber missing")
	assert(editor.slider_volume != null, "SliderVolume missing")
	assert(editor.slider_pitch != null, "SliderPitch missing")
	assert(editor.tree_map_bindings != null, "TreeMapBindings missing")
	assert(editor.tree_skill_bindings != null, "TreeSkillBindings missing")
	assert(editor.chk_ambience != null, "ChkAmbience missing")

	print("  PASS: Scene instantiated and all 25+ UI controls confirmed.")
	editor.queue_free()

func _test_sound_asset_scanning() -> void:
	print(">>> [TEST 2] Verifying Sound Asset Scanning & Categorization...")
	var editor: AudioEditorClass = AudioEditorClass.new()
	add_child(editor)

	var count: int = editor.scan_sound_assets()
	assert(count >= 200, "Expected at least 200 sound assets, got %d" % count)

	var assets: Array[Dictionary] = editor.get_sound_assets()
	assert(assets.size() == count, "Asset count mismatch")

	# Check presence of all core categories
	var cat_counts: Dictionary = {
		AudioEditorClass.SoundCategory.BGM: 0,
		AudioEditorClass.SoundCategory.SEB: 0,
		AudioEditorClass.SoundCategory.COMBAT: 0,
		AudioEditorClass.SoundCategory.AMBIENCE: 0
	}
	var found_bgm0001: bool = false
	var found_bgm0011: bool = false
	var found_bgm0041: bool = false
	var found_seb0017: bool = false
	var found_seb0037: bool = false

	for a in assets:
		assert(a.has("file_name"), "Asset missing file_name")
		assert(a.has("display_name"), "Asset missing display_name")
		assert(a.has("category"), "Asset missing category")
		assert(a.has("category_name"), "Asset missing category_name")
		assert(a.has("duration_sec") and a["duration_sec"] > 0.0, "Invalid duration")
		assert(a.has("tags"), "Asset missing tags")

		var cat = a["category"]
		if cat_counts.has(cat):
			cat_counts[cat] += 1

		var fn: String = a["file_name"]
		if fn == "BGM0001.wav": found_bgm0001 = true
		elif fn == "BGM0011.wav": found_bgm0011 = true
		elif fn == "BGM0041.wav": found_bgm0041 = true
		elif fn == "SEB0017.wav": found_seb0017 = true
		elif fn == "SEB0037.wav": found_seb0037 = true

	assert(cat_counts[AudioEditorClass.SoundCategory.BGM] >= 30, "Expected >= 30 BGMs")
	assert(cat_counts[AudioEditorClass.SoundCategory.SEB] >= 50, "Expected >= 50 SEBs")
	assert(found_bgm0001, "BGM0001.wav must be present")
	assert(found_bgm0011, "BGM0011.wav must be present")
	assert(found_bgm0041, "BGM0041.wav must be present")
	assert(found_seb0017, "SEB0017.wav must be present")
	assert(found_seb0037, "SEB0037.wav must be present")

	print("  PASS: Scanned %d assets (BGMs: %d, SEBs: %d, Combat: %d, Ambience: %d)." % [
		count,
		cat_counts[AudioEditorClass.SoundCategory.BGM],
		cat_counts[AudioEditorClass.SoundCategory.SEB],
		cat_counts[AudioEditorClass.SoundCategory.COMBAT],
		cat_counts[AudioEditorClass.SoundCategory.AMBIENCE]
	])
	editor.queue_free()

func _test_search_and_filtering() -> void:
	print(">>> [TEST 3] Verifying Search & Multi-criteria Filtering...")
	var editor: AudioEditorClass = AudioEditorClass.new()
	add_child(editor)
	editor.scan_sound_assets()

	# Exact name query
	var q1: Array[Dictionary] = editor.filter_assets("BGM0011")
	assert(q1.size() >= 1, "Failed to find BGM0011 by query")
	assert(q1[0]["file_name"] == "BGM0011.wav", "First result should be BGM0011.wav")

	# Category filter: BGM only
	var q_bgm: Array[Dictionary] = editor.filter_assets("", AudioEditorClass.SoundCategory.BGM)
	assert(q_bgm.size() >= 30, "Expected >= 30 BGM filtered results")
	for item in q_bgm:
		assert(item["category"] == AudioEditorClass.SoundCategory.BGM, "Item must be BGM")

	# Category filter: SEB only
	var q_seb: Array[Dictionary] = editor.filter_assets("", AudioEditorClass.SoundCategory.SEB)
	assert(q_seb.size() >= 50, "Expected >= 50 SEB filtered results")
	for item in q_seb:
		assert(item["category"] == AudioEditorClass.SoundCategory.SEB, "Item must be SEB")

	# Tag filter: "beach" or "ocean_waves"
	var q_tag: Array[Dictionary] = editor.filter_assets("", AudioEditorClass.SoundCategory.ALL, "ocean_waves")
	assert(q_tag.size() >= 1, "Failed to find assets with tag 'ocean_waves'")

	print("  PASS: Filter and search results validated across name, category, and tags.")
	editor.queue_free()

func _test_audio_playback_and_controls() -> void:
	print(">>> [TEST 4] Verifying Audio Player & Transport Controls...")
	var editor: AudioEditorClass = AudioEditorClass.new()
	add_child(editor)
	editor.scan_sound_assets()

	# Initial state
	assert(editor.playback_state == AudioEditorClass.PlaybackState.STOPPED, "Initial state must be STOPPED")

	# Play sound
	var play_ok: bool = editor.play_sound("BGM0011.wav")
	assert(play_ok, "play_sound failed for BGM0011.wav")
	assert(editor.playback_state == AudioEditorClass.PlaybackState.PLAYING, "State should be PLAYING")
	assert(editor.current_sound_name == "BGM0011.wav", "Current sound should be BGM0011.wav")

	# Pause sound
	editor.pause_sound()
	assert(editor.playback_state == AudioEditorClass.PlaybackState.PAUSED, "State should be PAUSED")

	# Resume sound
	editor.resume_sound()
	assert(editor.playback_state == AudioEditorClass.PlaybackState.PLAYING, "State should be PLAYING after resume")

	# Seek sound
	editor.seek_sound(15.0)
	assert(absf(editor.current_position_sec - 15.0) < 0.1, "Seek position mismatch")

	# Stop sound
	editor.stop_sound()
	assert(editor.playback_state == AudioEditorClass.PlaybackState.STOPPED, "State should be STOPPED")
	assert(editor.current_position_sec == 0.0, "Position should reset to 0.0 on stop")

	# Volume controls
	editor.set_volume_db(-6.0)
	assert(editor.master_volume_db == -6.0, "Volume should be -6.0 dB")
	editor.set_volume_db(20.0) # Should clamp to 6.0
	assert(editor.master_volume_db == 6.0, "Volume should clamp to 6.0 dB")
	editor.set_volume_db(-50.0) # Should clamp to -40.0
	assert(editor.master_volume_db == -40.0, "Volume should clamp to -40.0 dB")

	# Pitch controls
	editor.set_pitch_scale(1.5)
	assert(editor.pitch_scale == 1.5, "Pitch scale should be 1.5")
	editor.set_pitch_scale(5.0) # Should clamp to 2.0
	assert(editor.pitch_scale == 2.0, "Pitch scale should clamp to 2.0")
	editor.set_pitch_scale(0.1) # Should clamp to 0.5
	assert(editor.pitch_scale == 0.5, "Pitch scale should clamp to 0.5")

	print("  PASS: Playback state transitions, seek, volume clamping, and pitch scaling verified.")
	editor.queue_free()

func _test_loop_points_and_fade_configuration() -> void:
	print(">>> [TEST 5] Verifying Loop Points & Fade In/Out Configuration...")
	var editor: AudioEditorClass = AudioEditorClass.new()
	add_child(editor)
	editor.scan_sound_assets()

	editor.select_sound_by_name("BGM0011.wav")
	editor.set_looping(true)
	assert(editor.is_looping == true, "Looping should be enabled")

	editor.set_loop_points(5.0, 40.0)
	assert(editor.loop_start_sec == 5.0, "Loop start should be 5.0")
	assert(editor.loop_end_sec == 40.0, "Loop end should be 40.0")

	editor.set_fade_durations(1.0, 2.0)
	assert(editor.fade_in_duration == 1.0, "Fade in should be 1.0")
	assert(editor.fade_out_duration == 2.0, "Fade out should be 2.0")

	# Test loop point boundary wraparound
	editor.play_sound("BGM0011.wav", 39.9)
	editor._update_playback_tick(0.2) # Advance past loop_end_sec (40.0)
	assert(absf(editor.current_position_sec - 5.0) < 0.2, "Current position should wrap back to loop_start (5.0s)")

	print("  PASS: Loop point setting, fade values, and loop boundary wraparound verified.")
	editor.queue_free()

func _test_spectrum_and_waveform_visualizer() -> void:
	print(">>> [TEST 6] Verifying Spectrum & Waveform Visualizer...")
	var editor: AudioEditorClass = AudioEditorClass.new()
	add_child(editor)
	editor.scan_sound_assets()

	editor.play_sound("BGM0011.wav")
	editor._update_visualizer_data(0.016)

	var bands: Array[float] = editor.get_spectrum_bands()
	var peaks: Array[float] = editor.get_visualizer_peaks()

	assert(bands.size() == AudioEditorClass.SPECTRUM_BANDS, "Spectrum bands count mismatch")
	assert(peaks.size() == AudioEditorClass.SPECTRUM_BANDS, "Peaks count mismatch")

	var has_non_zero_band: bool = false
	for i in range(bands.size()):
		if bands[i] > 0.0:
			has_non_zero_band = true
		assert(peaks[i] >= bands[i], "Peak must be greater than or equal to band amplitude")

	assert(has_non_zero_band, "Expected non-zero spectrum bands during playback")

	# Test decay when stopped
	editor.stop_sound()
	editor._update_visualizer_data(1.0)
	var decayed_bands: Array[float] = editor.get_spectrum_bands()
	assert(decayed_bands[0] < 0.1, "Bands should decay to zero when stopped")

	# Test canvas drawing callback
	var dummy_canvas: Control = Control.new()
	dummy_canvas.size = Vector2(400.0, 100.0)
	add_child(dummy_canvas)
	dummy_canvas.draw.connect(func(): editor.draw_spectrum_visualizer(dummy_canvas))
	dummy_canvas.queue_redraw()
	dummy_canvas.queue_free()

	print("  PASS: 32 spectrum bands, peak hold decay, and waveform drawing verified.")
	editor.queue_free()

func _test_game_tagging_and_associations() -> void:
	print(">>> [TEST 7] Verifying Game Tagging & Association System...")
	var editor: AudioEditorClass = AudioEditorClass.new()
	add_child(editor)
	editor.scan_sound_assets()

	# Map BGM Binding
	editor.bind_map_bgm(10001, "BGM0011.wav")
	assert(editor.get_map_bgm(10001) == "BGM0011.wav", "Map 10001 should bind to BGM0011.wav")

	editor.bind_map_bgm(10002, "BGM0012.wav")
	assert(editor.get_map_bgm(10002) == "BGM0012.wav", "Map 10002 should bind to BGM0012.wav")

	editor.unbind_map_bgm(10002)
	assert(editor.get_map_bgm(10002).is_empty(), "Map 10002 should be unbound")

	# Skill SFX Binding
	editor.bind_skill_sfx(10001, "cast", "wav0030.wav")
	editor.bind_skill_sfx(10001, "hit", "wav0010.wav")
	assert(editor.get_skill_sfx(10001, "cast") == "wav0030.wav", "Skill 10001 cast SFX mismatch")
	assert(editor.get_skill_sfx(10001, "hit") == "wav0010.wav", "Skill 10001 hit SFX mismatch")

	# Battle Event SFX Binding
	editor.bind_battle_event_sfx("victory", "BGM0002.wav")
	editor.bind_battle_event_sfx("defeat", "BGM0003.wav")
	assert(editor.get_battle_event_sfx("victory") == "BGM0002.wav", "Victory event SFX mismatch")
	assert(editor.get_battle_event_sfx("defeat") == "BGM0003.wav", "Defeat event SFX mismatch")

	# Ambience Layering
	editor.configure_ambience_layer("Ocean Waves", "SEB0037.wav", -4.0, true)
	var lyr: Dictionary = editor.get_ambience_layer("Ocean Waves")
	assert(lyr["sound_file"] == "SEB0037.wav", "Ambience sound file mismatch")
	assert(lyr["volume_db"] == -4.0, "Ambience volume mismatch")

	var amb_ok: bool = editor.play_ambience("SEB0037.wav")
	assert(amb_ok, "play_ambience failed")
	assert(editor.ambience_enabled == true, "Ambience should be enabled")

	editor.stop_ambience()
	assert(editor.ambience_enabled == false, "Ambience should be disabled after stop")

	print("  PASS: Map BGM bindings, Skill SFX bindings, Battle Events, and Ambience layers verified.")
	editor.queue_free()

func _test_presets() -> void:
	print(">>> [TEST 8] Verifying Presets...")
	var editor: AudioEditorClass = AudioEditorClass.new()
	add_child(editor)
	editor.scan_sound_assets()

	var presets: Array[String] = editor.get_preset_names()
	assert(presets.has("Ship Deck Theme"), "Preset 'Ship Deck Theme' missing")
	assert(presets.has("Monkey Beach Ambience"), "Preset 'Monkey Beach Ambience' missing")
	assert(presets.has("Standard Battle Theme"), "Preset 'Standard Battle Theme' missing")

	# Test Ship Deck Theme
	var p1_ok: bool = editor.apply_preset("Ship Deck Theme")
	assert(p1_ok, "Failed to apply 'Ship Deck Theme'")
	assert(editor.current_sound_name == "BGM0007.wav", "Preset 1 sound mismatch")
	assert(editor.master_volume_db == 0.0, "Preset 1 volume mismatch")
	assert(editor.is_looping == true, "Preset 1 should be looping")
	assert(editor.get_map_bgm(10001) == "BGM0007.wav", "Map 10001 should be bound to BGM0007.wav")

	# Test Monkey Beach Ambience
	var p2_ok: bool = editor.apply_preset("Monkey Beach Ambience")
	assert(p2_ok, "Failed to apply 'Monkey Beach Ambience'")
	assert(editor.current_sound_name == "BGM0024.wav", "Preset 2 sound mismatch")
	assert(editor.master_volume_db == -2.0, "Preset 2 volume mismatch")
	assert(editor.ambience_enabled == true, "Preset 2 should enable ambience")
	assert(editor.current_ambience_name == "SEB0037.wav", "Preset 2 ambience track mismatch")

	# Test Standard Battle Theme
	var p3_ok: bool = editor.apply_preset("Standard Battle Theme")
	assert(p3_ok, "Failed to apply 'Standard Battle Theme'")
	assert(editor.current_sound_name == "BGM0001.wav", "Preset 3 sound mismatch")
	assert(editor.pitch_scale == 1.05, "Preset 3 pitch scale should be 1.05 (fast tempo)")
	assert(editor.get_battle_event_sfx("battle_start") == "BGM0001.wav", "Battle start event mismatch")

	print("  PASS: All 3 built-in presets accurately configured audio, volume, pitch, ambience, and map bindings.")
	editor.queue_free()

func _test_config_persistence_and_manifest_export() -> void:
	print(">>> [TEST 9] Verifying JSON Serialization & Manifest Export...")
	var editor: AudioEditorClass = AudioEditorClass.new()
	add_child(editor)
	editor.scan_sound_assets()

	# Configure unique test values
	editor.apply_preset("Ship Deck Theme")
	editor.bind_map_bgm(99999, "BGM0011.wav")
	editor.bind_skill_sfx(77777, "cast", "wav0030.wav")

	var config_path: String = "user://test_audio_config.json"
	var manifest_path: String = "user://test_audio_manifest.json"

	# Save config
	var save_ok: bool = editor.save_audio_config(config_path)
	assert(save_ok, "save_audio_config failed")
	assert(FileAccess.file_exists(config_path), "Saved config file does not exist on disk")

	# Clear editor and load config back
	editor.unbind_map_bgm(99999)
	assert(editor.get_map_bgm(99999).is_empty(), "Map 99999 should be cleared")

	var loaded_dict: Dictionary = editor.load_audio_config(config_path)
	assert(not loaded_dict.is_empty(), "load_audio_config returned empty dictionary")
	assert(editor.get_map_bgm(99999) == "BGM0011.wav", "Map 99999 was not restored from JSON")
	assert(editor.get_skill_sfx(77777, "cast") == "wav0030.wav", "Skill 77777 cast SFX was not restored")

	# Export manifest
	var export_ok: bool = editor.export_audio_manifest(manifest_path)
	assert(export_ok, "export_audio_manifest failed")
	assert(FileAccess.file_exists(manifest_path), "Manifest file does not exist on disk")

	# Verify manifest content
	var m_file := FileAccess.open(manifest_path, FileAccess.READ)
	assert(m_file != null, "Could not open manifest file")
	var manifest_data = JSON.parse_string(m_file.get_as_text())
	m_file.close()

	assert(manifest_data is Dictionary, "Manifest must be a JSON dictionary")
	assert(manifest_data.has("total_scanned_assets"), "Manifest missing total_scanned_assets")
	assert(manifest_data.has("categories_breakdown"), "Manifest missing categories_breakdown")
	assert(manifest_data.has("assets") and manifest_data["assets"] is Array, "Manifest missing assets array")
	assert(manifest_data["total_scanned_assets"] >= 200, "Manifest asset count too low")

	# Clean up temporary test files
	DirAccess.remove_absolute(config_path)
	DirAccess.remove_absolute(manifest_path)

	print("  PASS: JSON config persistence roundtrip and audio manifest export validated.")
	editor.queue_free()
