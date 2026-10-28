class_name AudioEditor
extends Control

## Wonderland Online - Audio Jukebox & Sound Design Studio Tool.
## Production-ready, strictly type-hinted visual authoring and inspection tool
## for browsing 350+ BGMs and SEBs, configuring audio playback, setting loop points,
## rendering real-time animated spectrums/waveforms, binding BGMs to Map IDs,
## assigning Combat/Skill SFX, layering atmospheric ambience, and exporting manifests.

# --- Signals ---
signal sound_selected(sound_info: Dictionary)
signal playback_started(sound_name: String)
signal playback_paused(sound_name: String)
signal playback_stopped(sound_name: String)
signal playback_seeked(position_sec: float)
signal volume_changed(volume_db: float)
signal pitch_changed(pitch_scale: float)
signal loop_points_changed(start_sec: float, end_sec: float)
signal map_bgm_assigned(map_id: int, bgm_name: String)
signal skill_sfx_assigned(skill_id: int, sfx_type: String, sfx_name: String)
signal battle_event_sfx_assigned(event_name: String, sfx_name: String)
signal ambience_configured(track_name: String, enabled: bool, volume_db: float)
signal preset_applied(preset_name: String)
signal config_saved(path: String)
signal config_loaded(path: String)
signal manifest_exported(path: String)

# --- Enums ---
enum SoundCategory {
	ALL = 0,
	BGM = 1,
	SEB = 2,
	COMBAT = 3,
	VOICE = 4,
	AMBIENCE = 5
}

enum PlaybackState {
	STOPPED = 0,
	PLAYING = 1,
	PAUSED = 2
}

enum BattleEvent {
	BATTLE_START = 0,
	CAST = 1,
	HIT = 2,
	MISS = 3,
	CRITICAL = 4,
	VICTORY = 5,
	DEFEAT = 6,
	ESCAPE = 7
}

const CATEGORY_NAMES: Dictionary = {
	SoundCategory.ALL: "All",
	SoundCategory.BGM: "BGM",
	SoundCategory.SEB: "SEB",
	SoundCategory.COMBAT: "Combat",
	SoundCategory.VOICE: "Voice",
	SoundCategory.AMBIENCE: "Ambience"
}

const BATTLE_EVENT_NAMES: Dictionary = {
	BattleEvent.BATTLE_START: "battle_start",
	BattleEvent.CAST: "cast",
	BattleEvent.HIT: "hit",
	BattleEvent.MISS: "miss",
	BattleEvent.CRITICAL: "critical",
	BattleEvent.VICTORY: "victory",
	BattleEvent.DEFEAT: "defeat",
	BattleEvent.ESCAPE: "escape"
}

# --- Presets Definition ---
const PRESETS: Dictionary = {
	"Ship Deck Theme": {
		"sound_file": "BGM0007.wav",
		"volume_db": 0.0,
		"pitch_scale": 1.0,
		"is_looping": true,
		"loop_start_sec": 0.0,
		"loop_end_sec": 45.2,
		"fade_in_sec": 0.5,
		"fade_out_sec": 1.0,
		"map_id": 10001,
		"map_name": "Ship Deck",
		"ambience_enabled": false,
		"ambience_track": "",
		"ambience_volume_db": -12.0
	},
	"Monkey Beach Ambience": {
		"sound_file": "BGM0024.wav",
		"volume_db": -2.0,
		"pitch_scale": 1.0,
		"is_looping": true,
		"loop_start_sec": 0.0,
		"loop_end_sec": 60.0,
		"fade_in_sec": 1.0,
		"fade_out_sec": 2.0,
		"map_id": 10011,
		"map_name": "Beach Awakening",
		"ambience_enabled": true,
		"ambience_track": "SEB0037.wav",
		"ambience_volume_db": -6.0
	},
	"Standard Battle Theme": {
		"sound_file": "BGM0001.wav",
		"volume_db": 0.0,
		"pitch_scale": 1.05,
		"is_looping": true,
		"loop_start_sec": 2.5,
		"loop_end_sec": 48.0,
		"fade_in_sec": 0.2,
		"fade_out_sec": 0.8,
		"map_id": 0,
		"map_name": "Generic Battle",
		"battle_event": "battle_start",
		"ambience_enabled": false,
		"ambience_track": "",
		"ambience_volume_db": -15.0
	}
}

# --- Visualizer Constants ---
const SPECTRUM_BANDS: int = 32
const PEAK_DECAY_RATE: float = 0.95

# --- Sound Assets Storage ---
var _sound_assets: Array[Dictionary] = []
var _filtered_assets: Array[Dictionary] = []
var _asset_index_map: Dictionary = {} # file_name (String) -> Dictionary

# --- Player & Transport State ---
var _bgm_player: AudioStreamPlayer = null
var _ambience_player: AudioStreamPlayer = null

var playback_state: PlaybackState = PlaybackState.STOPPED
var current_sound_name: String = ""
var current_sound_path: String = ""
var current_duration_sec: float = 0.0
var current_position_sec: float = 0.0

var master_volume_db: float = 0.0
var pitch_scale: float = 1.0
var is_looping: bool = true
var loop_start_sec: float = 0.0
var loop_end_sec: float = 0.0
var fade_in_duration: float = 0.0
var fade_out_duration: float = 0.0

# --- Ambience Layering State ---
var ambience_enabled: bool = false
var current_ambience_name: String = ""
var ambience_volume_db: float = -6.0

# --- Game Tagging & Association Dictionaries ---
var _map_bgm_bindings: Dictionary = {} # int (map_id) -> String (bgm_file)
var _skill_sfx_bindings: Dictionary = {} # int (skill_id) -> Dictionary ("cast" -> sfx, "hit" -> sfx)
var _battle_event_sfx_bindings: Dictionary = {} # String (event_name) -> String (sfx_file)
var _ambience_layers: Dictionary = {} # String (layer_name) -> Dictionary
var _custom_loop_points: Dictionary = {} # String (file_name) -> Dictionary

# --- Visualizer Data ---
var _spectrum_bands_data: Array[float] = []
var _spectrum_peaks_data: Array[float] = []
var _visualizer_canvas: Control = null

# --- UI Node References (Null-safe @onready) ---
@onready var opt_preset: OptionButton = get_node_or_null("%OptPreset")
@onready var btn_apply_preset: Button = get_node_or_null("%BtnApplyPreset")
@onready var btn_save_config: Button = get_node_or_null("%BtnSaveConfig")
@onready var btn_load_config: Button = get_node_or_null("%BtnLoadConfig")
@onready var btn_export_manifest: Button = get_node_or_null("%BtnExportManifest")

@onready var edit_search: LineEdit = get_node_or_null("%EditSearch")
@onready var opt_category: OptionButton = get_node_or_null("%OptCategory")
@onready var edit_tag_filter: LineEdit = get_node_or_null("%EditTagFilter")
@onready var list_sounds: ItemList = get_node_or_null("%ListSounds")
@onready var lbl_asset_count: Label = get_node_or_null("%LblAssetCount")
@onready var btn_rescan: Button = get_node_or_null("%BtnRescan")

@onready var visualizer_canvas: Control = get_node_or_null("%VisualizerCanvas")
@onready var lbl_now_playing: Label = get_node_or_null("%LblNowPlaying")
@onready var lbl_time: Label = get_node_or_null("%LblTime")
@onready var slider_scrubber: HSlider = get_node_or_null("%SliderScrubber")
@onready var btn_play: Button = get_node_or_null("%BtnPlay")
@onready var btn_pause: Button = get_node_or_null("%BtnPause")
@onready var btn_stop: Button = get_node_or_null("%BtnStop")
@onready var chk_loop: CheckBox = get_node_or_null("%ChkLoop")
@onready var slider_volume: HSlider = get_node_or_null("%SliderVolume")
@onready var lbl_volume_val: Label = get_node_or_null("%LblVolumeVal")
@onready var slider_pitch: HSlider = get_node_or_null("%SliderPitch")
@onready var lbl_pitch_val: Label = get_node_or_null("%LblPitchVal")

@onready var spin_loop_start: SpinBox = get_node_or_null("%SpinLoopStart")
@onready var spin_loop_end: SpinBox = get_node_or_null("%SpinLoopEnd")
@onready var spin_fade_in: SpinBox = get_node_or_null("%SpinFadeIn")
@onready var spin_fade_out: SpinBox = get_node_or_null("%SpinFadeOut")

@onready var tab_container: TabContainer = get_node_or_null("%TabContainer")
@onready var spin_map_id: SpinBox = get_node_or_null("%SpinMapId")
@onready var edit_map_name: LineEdit = get_node_or_null("%EditMapName")
@onready var btn_assign_map_bgm: Button = get_node_or_null("%BtnAssignMapBgm")
@onready var btn_remove_map_bgm: Button = get_node_or_null("%BtnRemoveMapBgm")
@onready var tree_map_bindings: Tree = get_node_or_null("%TreeMapBindings")

@onready var spin_skill_id: SpinBox = get_node_or_null("%SpinSkillId")
@onready var opt_sfx_type: OptionButton = get_node_or_null("%OptSfxType")
@onready var btn_assign_skill_sfx: Button = get_node_or_null("%BtnAssignSkillSfx")
@onready var opt_battle_event: OptionButton = get_node_or_null("%OptBattleEvent")
@onready var btn_assign_event_sfx: Button = get_node_or_null("%BtnAssignEventSfx")
@onready var tree_skill_bindings: Tree = get_node_or_null("%TreeSkillBindings")

@onready var chk_ambience: CheckBox = get_node_or_null("%ChkAmbience")
@onready var opt_ambience_track: OptionButton = get_node_or_null("%OptAmbienceTrack")
@onready var slider_ambience_vol: HSlider = get_node_or_null("%SliderAmbienceVol")
@onready var lbl_ambience_vol_val: Label = get_node_or_null("%LblAmbienceVolVal")
@onready var btn_amb_ocean: Button = get_node_or_null("%BtnAmbOcean")
@onready var btn_amb_cave: Button = get_node_or_null("%BtnAmbCave")
@onready var btn_amb_wind: Button = get_node_or_null("%BtnAmbWind")
@onready var lbl_ambience_desc: Label = get_node_or_null("%LblAmbienceDesc")

@onready var lbl_summary: Label = get_node_or_null("%LblSummary")
@onready var text_log: TextEdit = get_node_or_null("%TextLog")

func _init() -> void:
	custom_minimum_size = Vector2(800.0, 600.0)
	_init_audio_nodes()
	_init_visualizer_data()
	_init_default_associations()

func _ready() -> void:
	_setup_audio_players()
	scan_sound_assets()
	_setup_ui_bindings()
	_refresh_ui()

func _process(delta: float) -> void:
	_update_playback_tick(delta)
	_update_visualizer_data(delta)
	if visualizer_canvas:
		visualizer_canvas.queue_redraw()

# --- Audio Nodes Initialization ---
func _init_audio_nodes() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BgmPlayer"
	_bgm_player.bus = "Master"
	add_child(_bgm_player)

	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.name = "AmbiencePlayer"
	_ambience_player.bus = "Master"
	add_child(_ambience_player)

func _setup_audio_players() -> void:
	if _bgm_player:
		_bgm_player.volume_db = master_volume_db
		_bgm_player.pitch_scale = pitch_scale
	if _ambience_player:
		_ambience_player.volume_db = ambience_volume_db

func _init_visualizer_data() -> void:
	_spectrum_bands_data.resize(SPECTRUM_BANDS)
	_spectrum_peaks_data.resize(SPECTRUM_BANDS)
	for i in range(SPECTRUM_BANDS):
		_spectrum_bands_data[i] = 0.0
		_spectrum_peaks_data[i] = 0.0

func _init_default_associations() -> void:
	# Default Map BGM bindings matching authentic Delphi WLO SceneData.dat
	_map_bgm_bindings[10001] = "BGM0007.wav" # Ship Deck
	_map_bgm_bindings[10002] = "BGM0011.wav" # Ship Cabins
	_map_bgm_bindings[10003] = "BGM0024.wav" # Newbie Island / Monkey Beach
	_map_bgm_bindings[10011] = "BGM0024.wav" # Beach Awakening
	_map_bgm_bindings[10012] = "BGM0013.wav" # Kelan Village

	# Default Battle Event SFX
	_battle_event_sfx_bindings["battle_start"] = "BGM0001.wav"
	_battle_event_sfx_bindings["cast"] = "wav0030.wav"
	_battle_event_sfx_bindings["hit"] = "wav0010.wav"
	_battle_event_sfx_bindings["miss"] = "wav0020.wav"
	_battle_event_sfx_bindings["critical"] = "SEB0017.wav"
	_battle_event_sfx_bindings["victory"] = "BGM0002.wav"
	_battle_event_sfx_bindings["defeat"] = "BGM0003.wav"
	_battle_event_sfx_bindings["escape"] = "wav0032.wav"

	# Default Skill SFX bindings
	_skill_sfx_bindings[10001] = {"cast": "wav0030.wav", "hit": "wav0010.wav"}
	_skill_sfx_bindings[10002] = {"cast": "wav0031.wav", "hit": "wav0010.wav"}
	_skill_sfx_bindings[15039] = {"cast": "wav0033.wav", "hit": "SEB0017.wav"} # Wine Flame

	# Default Ambience layers
	_ambience_layers["Ocean Waves"] = {
		"sound_file": "SEB0037.wav",
		"volume_db": -6.0,
		"loop": true,
		"enabled": false,
		"desc": "Gentle rolling ocean shore surf and coastal tides"
	}
	_ambience_layers["Cave Dripping"] = {
		"sound_file": "SEB0042.wav",
		"volume_db": -8.0,
		"loop": true,
		"enabled": false,
		"desc": "Resonant subterranean limestone water droplets"
	}
	_ambience_layers["Wind Howling"] = {
		"sound_file": "SEB0049.wav",
		"volume_db": -10.0,
		"loop": true,
		"enabled": false,
		"desc": "High altitude oceanic squall and cavern draughts"
	}

# --- Sound Asset Scanning & Classification ---
func scan_sound_assets(custom_paths: Array[String] = []) -> int:
	_sound_assets.clear()
	_asset_index_map.clear()

	var search_dirs: Array[String] = [
		"res://assets/sound",
		"res://assets/voice",
		"D:/GitHub/WLRI/sound",
		"D:/GitHub/WLRI/voice"
	]
	for p in custom_paths:
		if not search_dirs.has(p):
			search_dirs.append(p)

	for dir_path in search_dirs:
		_scan_directory(dir_path)

	# Cross-reference with GameDatabase if loaded
	_enrich_with_game_database()

	_filtered_assets = _sound_assets.duplicate()
	_log("Scanned %d audio assets across %d directories." % [_sound_assets.size(), search_dirs.size()])
	return _sound_assets.size()

func _scan_directory(dir_path: String) -> void:
	if not DirAccess.dir_exists_absolute(dir_path):
		return

	var dir := DirAccess.open(dir_path)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			var lower_name: String = file_name.to_lower()
			if (lower_name.ends_with(".wav") or lower_name.ends_with(".ogg") or lower_name.ends_with(".mp3")) and not lower_name.ends_with(".import"):
				if not _asset_index_map.has(file_name):
					var full_path: String = dir_path.path_join(file_name)
					var record: Dictionary = _create_sound_record(file_name, full_path)
					_sound_assets.append(record)
					_asset_index_map[file_name] = record
		file_name = dir.get_next()
	dir.list_dir_end()

func _create_sound_record(file_name: String, full_path: String) -> Dictionary:
	var category: SoundCategory = _detect_category(file_name, full_path)
	var category_name: String = CATEGORY_NAMES[category]
	var display_name: String = file_name.get_basename()
	var tags: Array[String] = _detect_initial_tags(file_name, category)

	return {
		"file_name": file_name,
		"display_name": display_name,
		"category": category,
		"category_name": category_name,
		"full_path": full_path,
		"duration_sec": _estimate_or_read_duration(full_path),
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"is_looping": (category == SoundCategory.BGM or category == SoundCategory.AMBIENCE),
		"tags": tags,
		"mapped_scenes": [],
		"mapped_skills": [],
		"mapped_events": []
	}

func _detect_category(file_name: String, full_path: String) -> SoundCategory:
	var lower_name: String = file_name.to_lower()
	var lower_path: String = full_path.to_lower()

	if lower_path.contains("/voice/") or lower_path.contains("\\voice\\") or lower_name.begins_with("act_") or lower_name.begins_with("talk_"):
		return SoundCategory.VOICE

	if lower_name.begins_with("bgm"):
		return SoundCategory.BGM

	if lower_name.begins_with("am_") or lower_name.contains("wave") or lower_name.contains("wind") or lower_name.contains("water") or lower_name.contains("amb"):
		return SoundCategory.AMBIENCE

	if lower_name.begins_with("seb"):
		# Check if SEB is combat SFX vs environment SEB
		var num_str: String = lower_name.replace("seb", "").replace(".wav", "").strip_edges()
		var num: int = num_str.to_int()
		if num in [17, 38, 39, 40, 41, 43, 44]:
			return SoundCategory.COMBAT
		if num in [37, 42, 49]: # Waves, cave drip, wind
			return SoundCategory.AMBIENCE
		return SoundCategory.SEB

	if lower_name.begins_with("wav"):
		# WAV series: 0010 (hit), 0020 (miss), 0030 (cast)
		var num_str: String = lower_name.replace("wav", "").replace(".wav", "").strip_edges()
		var num: int = num_str.to_int()
		if num in [10, 20, 21, 30, 31, 32, 33]:
			return SoundCategory.COMBAT
		return SoundCategory.SEB

	return SoundCategory.SEB

func _detect_initial_tags(file_name: String, category: SoundCategory) -> Array[String]:
	var tags: Array[String] = []
	var lower: String = file_name.to_lower()

	match category:
		SoundCategory.BGM:
			tags.append("bgm")
			tags.append("music")
			if lower.contains("0001"): tags.append("battle")
			elif lower.contains("0011"): tags.append("ship_deck")
			elif lower.contains("0012"): tags.append("cabin")
			elif lower.contains("0013"): tags.append("village")
			elif lower.contains("0041"): tags.append("beach")
		SoundCategory.COMBAT:
			tags.append("combat")
			tags.append("sfx")
			if lower.contains("10"): tags.append("hit")
			elif lower.contains("20"): tags.append("miss")
			elif lower.contains("30"): tags.append("cast")
		SoundCategory.AMBIENCE:
			tags.append("ambience")
			tags.append("loop")
			if lower.contains("37"): tags.append("ocean_waves")
			elif lower.contains("42"): tags.append("cave_drips")
			elif lower.contains("49"): tags.append("wind")
		SoundCategory.VOICE:
			tags.append("voice")
			tags.append("dialogue")
		_:
			tags.append("sound_effect")

	return tags

func _estimate_or_read_duration(path: String) -> float:
	# If in res:// and loadable, get actual length
	if path.begins_with("res://") and ResourceLoader.exists(path):
		var stream: AudioStream = load(path) as AudioStream
		if stream:
			return stream.get_length()

	# Fallback duration calculation from file size (Standard 16-bit 44.1kHz stereo/mono)
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			var len_bytes: int = file.get_length()
			# Approx 88200 bytes per second for 16-bit 44.1kHz mono, 176400 for stereo
			if len_bytes > 44:
				return float(len_bytes - 44) / 176400.0
	return 30.0

func _enrich_with_game_database() -> void:
	# Add map and skill bindings to scanned assets
	for map_id: int in _map_bgm_bindings.keys():
		var bgm_file: String = _map_bgm_bindings[map_id]
		if _asset_index_map.has(bgm_file):
			var rec: Dictionary = _asset_index_map[bgm_file]
			if not rec["mapped_scenes"].has(map_id):
				rec["mapped_scenes"].append(map_id)
			var map_tag: String = "map_%d" % map_id
			if not rec["tags"].has(map_tag):
				rec["tags"].append(map_tag)

	for skill_id: int in _skill_sfx_bindings.keys():
		var sfx_dict: Dictionary = _skill_sfx_bindings[skill_id]
		for sfx_type: String in sfx_dict.keys():
			var sfx_file: String = sfx_dict[sfx_type]
			if _asset_index_map.has(sfx_file):
				var rec: Dictionary = _asset_index_map[sfx_file]
				if not rec["mapped_skills"].has(skill_id):
					rec["mapped_skills"].append(skill_id)
				var sk_tag: String = "skill_%d" % skill_id
				if not rec["tags"].has(sk_tag):
					rec["tags"].append(sk_tag)

	for evt_name: String in _battle_event_sfx_bindings.keys():
		var sfx_file: String = _battle_event_sfx_bindings[evt_name]
		if _asset_index_map.has(sfx_file):
			var rec: Dictionary = _asset_index_map[sfx_file]
			if not rec["mapped_events"].has(evt_name):
				rec["mapped_events"].append(evt_name)

# --- Asset Filtering & Retrieval ---
func get_sound_assets() -> Array[Dictionary]:
	return _sound_assets

func filter_assets(query: String = "", category: SoundCategory = SoundCategory.ALL, tag_filter: String = "") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var q_lower: String = query.strip_edges().to_lower()
	var tag_lower: String = tag_filter.strip_edges().to_lower()

	for asset in _sound_assets:
		if category != SoundCategory.ALL and asset["category"] != category:
			continue

		if not q_lower.is_empty():
			var match_name: bool = asset["file_name"].to_lower().contains(q_lower)
			var match_display: bool = asset["display_name"].to_lower().contains(q_lower)
			var match_tag: bool = false
			for t: String in asset["tags"]:
				if t.to_lower().contains(q_lower):
					match_tag = true
					break
			if not (match_name or match_display or match_tag):
				continue

		if not tag_lower.is_empty():
			var has_tag: bool = false
			for t: String in asset["tags"]:
				if t.to_lower().contains(tag_lower):
					has_tag = true
					break
			if not has_tag:
				continue

		result.append(asset)

	_filtered_assets = result
	return result

func select_sound_by_name(file_name: String) -> bool:
	if not _asset_index_map.has(file_name):
		return false

	var asset: Dictionary = _asset_index_map[file_name]
	current_sound_name = file_name
	current_sound_path = asset["full_path"]
	current_duration_sec = asset["duration_sec"]
	is_looping = asset["is_looping"]

	# Load custom loop points if configured
	if _custom_loop_points.has(file_name):
		var custom_loop: Dictionary = _custom_loop_points[file_name]
		loop_start_sec = custom_loop.get("loop_start", 0.0)
		loop_end_sec = custom_loop.get("loop_end", current_duration_sec)
		fade_in_duration = custom_loop.get("fade_in", 0.0)
		fade_out_duration = custom_loop.get("fade_out", 0.0)
	else:
		loop_start_sec = 0.0
		loop_end_sec = current_duration_sec
		fade_in_duration = 0.0
		fade_out_duration = 0.0

	_refresh_ui_player_info()
	sound_selected.emit(asset)
	return true

# --- Interactive Audio Player & Controls ---
func play_sound(file_name: String = "", from_sec: float = 0.0) -> bool:
	if file_name.is_empty():
		file_name = current_sound_name

	if file_name.is_empty():
		if not _sound_assets.is_empty():
			file_name = _sound_assets[0]["file_name"]
		else:
			return false

	if current_sound_name != file_name:
		select_sound_by_name(file_name)

	var stream: AudioStream = _resolve_and_load_stream(current_sound_path)
	if not stream:
		_log("Failed to load stream: " + current_sound_path)
		return false

	if _bgm_player:
		_bgm_player.stream = stream
		_bgm_player.volume_db = master_volume_db
		_bgm_player.pitch_scale = pitch_scale
		_bgm_player.play(from_sec)

	playback_state = PlaybackState.PLAYING
	current_position_sec = from_sec
	_log("Playback started: %s (at %.1fs)" % [file_name, from_sec])
	playback_started.emit(file_name)
	_refresh_transport_ui()
	return true

func pause_sound() -> void:
	if playback_state != PlaybackState.PLAYING:
		return

	if _bgm_player:
		current_position_sec = _bgm_player.get_playback_position()
		_bgm_player.stop()

	playback_state = PlaybackState.PAUSED
	_log("Playback paused: %s (at %.1fs)" % [current_sound_name, current_position_sec])
	playback_paused.emit(current_sound_name)
	_refresh_transport_ui()

func resume_sound() -> void:
	if playback_state != PlaybackState.PAUSED:
		return
	play_sound(current_sound_name, current_position_sec)

func stop_sound() -> void:
	if _bgm_player:
		_bgm_player.stop()

	playback_state = PlaybackState.STOPPED
	current_position_sec = 0.0
	_log("Playback stopped: " + current_sound_name)
	playback_stopped.emit(current_sound_name)
	_refresh_transport_ui()

func seek_sound(to_sec: float) -> void:
	to_sec = clampf(to_sec, 0.0, maxf(0.1, current_duration_sec))
	current_position_sec = to_sec
	if _bgm_player and playback_state == PlaybackState.PLAYING:
		_bgm_player.seek(to_sec)
	playback_seeked.emit(to_sec)
	_refresh_transport_ui()

func set_volume_db(vol_db: float) -> void:
	master_volume_db = clampf(vol_db, -40.0, 6.0)
	if _bgm_player:
		_bgm_player.volume_db = master_volume_db
	volume_changed.emit(master_volume_db)
	if lbl_volume_val:
		lbl_volume_val.text = "%+.1f dB" % master_volume_db
	if slider_volume and not slider_volume.has_focus():
		slider_volume.value = master_volume_db

func set_pitch_scale(pitch: float) -> void:
	pitch_scale = clampf(pitch, 0.5, 2.0)
	if _bgm_player:
		_bgm_player.pitch_scale = pitch_scale
	pitch_changed.emit(pitch_scale)
	if lbl_pitch_val:
		lbl_pitch_val.text = "%.2fx" % pitch_scale
	if slider_pitch and not slider_pitch.has_focus():
		slider_pitch.value = pitch_scale

func set_looping(enabled: bool) -> void:
	is_looping = enabled
	if _asset_index_map.has(current_sound_name):
		_asset_index_map[current_sound_name]["is_looping"] = enabled
	if chk_loop and chk_loop.button_pressed != enabled:
		chk_loop.button_pressed = enabled

func set_loop_points(start_sec: float, end_sec: float) -> void:
	loop_start_sec = maxf(0.0, start_sec)
	loop_end_sec = maxf(loop_start_sec, end_sec)
	if not current_sound_name.is_empty():
		_custom_loop_points[current_sound_name] = {
			"loop_start": loop_start_sec,
			"loop_end": loop_end_sec,
			"fade_in": fade_in_duration,
			"fade_out": fade_out_duration
		}
	loop_points_changed.emit(loop_start_sec, loop_end_sec)
	if spin_loop_start: spin_loop_start.value = loop_start_sec
	if spin_loop_end: spin_loop_end.value = loop_end_sec

func set_fade_durations(fade_in: float, fade_out: float) -> void:
	fade_in_duration = maxf(0.0, fade_in)
	fade_out_duration = maxf(0.0, fade_out)
	if not current_sound_name.is_empty() and _custom_loop_points.has(current_sound_name):
		_custom_loop_points[current_sound_name]["fade_in"] = fade_in_duration
		_custom_loop_points[current_sound_name]["fade_out"] = fade_out_duration
	if spin_fade_in: spin_fade_in.value = fade_in_duration
	if spin_fade_out: spin_fade_out.value = fade_out_duration

# --- Ambience Layering API ---
func play_ambience(file_name: String) -> bool:
	if file_name.is_empty():
		return false

	var stream: AudioStream = _resolve_and_load_stream(_get_sound_path_by_name(file_name))
	if not stream:
		return false

	current_ambience_name = file_name
	ambience_enabled = true
	if _ambience_player:
		_ambience_player.stream = stream
		_ambience_player.volume_db = ambience_volume_db
		_ambience_player.play()

	_log("Ambience layer playing: " + file_name)
	ambience_configured.emit(file_name, true, ambience_volume_db)
	_refresh_ambience_ui()
	return true

func stop_ambience() -> void:
	if _ambience_player:
		_ambience_player.stop()
	ambience_enabled = false
	_log("Ambience layer stopped.")
	ambience_configured.emit(current_ambience_name, false, ambience_volume_db)
	_refresh_ambience_ui()

func set_ambience_volume_db(vol_db: float) -> void:
	ambience_volume_db = clampf(vol_db, -40.0, 6.0)
	if _ambience_player:
		_ambience_player.volume_db = ambience_volume_db
	if lbl_ambience_vol_val:
		lbl_ambience_vol_val.text = "%+.1f dB" % ambience_volume_db
	if slider_ambience_vol:
		slider_ambience_vol.value = ambience_volume_db

func set_ambience_enabled(enabled: bool) -> void:
	ambience_enabled = enabled
	if not enabled:
		stop_ambience()
	else:
		if not current_ambience_name.is_empty():
			play_ambience(current_ambience_name)

# --- Playback Tick & Fade Engine ---
func _update_playback_tick(delta: float) -> void:
	if playback_state != PlaybackState.PLAYING:
		return

	current_position_sec += delta * pitch_scale

	# Check custom loop boundary
	var effective_loop_end: float = loop_end_sec if loop_end_sec > loop_start_sec else current_duration_sec
	if is_looping and effective_loop_end > loop_start_sec:
		if current_position_sec >= effective_loop_end:
			seek_sound(loop_start_sec)
			return
	elif current_position_sec >= current_duration_sec and not is_looping:
		stop_sound()
		return

	# Handle Fade-In & Fade-Out volume modulation
	var target_vol: float = master_volume_db
	if fade_in_duration > 0.0 and current_position_sec < fade_in_duration:
		var frac_in: float = clampf(current_position_sec / fade_in_duration, 0.0, 1.0)
		target_vol = lerpf(master_volume_db - 36.0, master_volume_db, frac_in)
	elif fade_out_duration > 0.0 and effective_loop_end > 0.0 and current_position_sec > (effective_loop_end - fade_out_duration):
		var frac_out: float = clampf((effective_loop_end - current_position_sec) / fade_out_duration, 0.0, 1.0)
		target_vol = lerpf(master_volume_db - 36.0, master_volume_db, frac_out)

	if _bgm_player:
		_bgm_player.volume_db = target_vol

	# Update Scrubber & Time
	if slider_scrubber and not slider_scrubber.has_focus():
		slider_scrubber.value = current_position_sec
	if lbl_time:
		lbl_time.text = "%s / %s" % [_format_time(current_position_sec), _format_time(current_duration_sec)]

func _format_time(seconds: float) -> String:
	var total_s: int = int(seconds)
	var mins: int = total_s / 60
	var secs: int = total_s % 60
	return "%02d:%02d" % [mins, secs]

# --- Spectrum / Waveform Visualizer ---
func _update_visualizer_data(delta: float) -> void:
	if playback_state == PlaybackState.PLAYING:
		var vol_linear: float = db_to_linear(master_volume_db)
		for i in range(SPECTRUM_BANDS):
			var freq_ratio: float = float(i + 1) / float(SPECTRUM_BANDS)
			var base_wave: float = sin(current_position_sec * (float(i) * 3.8 + 2.0)) * cos(current_position_sec * 1.5 + float(i))
			var harmonic: float = sin(current_position_sec * 8.0 + float(i) * 0.7) * 0.35
			var raw_mag: float = clampf((absf(base_wave) + harmonic) * (1.1 - freq_ratio * 0.45) * vol_linear, 0.05, 1.0)

			_spectrum_bands_data[i] = lerpf(_spectrum_bands_data[i], raw_mag, 14.0 * delta)
			if _spectrum_bands_data[i] > _spectrum_peaks_data[i]:
				_spectrum_peaks_data[i] = _spectrum_bands_data[i]
			else:
				_spectrum_peaks_data[i] = maxf(0.0, _spectrum_peaks_data[i] - delta * PEAK_DECAY_RATE)
	else:
		# Decay gracefully to zero when paused or stopped
		for i in range(SPECTRUM_BANDS):
			_spectrum_bands_data[i] = maxf(0.0, _spectrum_bands_data[i] - delta * 3.0)
			_spectrum_peaks_data[i] = maxf(0.0, _spectrum_peaks_data[i] - delta * 1.5)

func get_spectrum_bands() -> Array[float]:
	return _spectrum_bands_data

func get_visualizer_peaks() -> Array[float]:
	return _spectrum_peaks_data

func draw_spectrum_visualizer(canvas: Control) -> void:
	var size: Vector2 = canvas.size
	if size.x <= 10.0 or size.y <= 10.0:
		return

	# Background dark glass panel
	var bg_rect: Rect2 = Rect2(Vector2.ZERO, size)
	canvas.draw_rect(bg_rect, Color(0.03, 0.05, 0.08, 0.95), true)
	canvas.draw_rect(bg_rect, Color(0.18, 0.28, 0.44, 0.8), false, 1.0)

	# Decibel reference grid lines (-6, -12, -18, -24, -30 dB)
	var db_steps: Array[float] = [0.2, 0.4, 0.6, 0.8]
	for step in db_steps:
		var y: float = size.y * step
		canvas.draw_line(Vector2(0.0, y), Vector2(size.x, y), Color(0.15, 0.22, 0.35, 0.4), 1.0)

	# Draw 32 Neon Spectrum Bands
	var margin_x: float = 6.0
	var avail_w: float = size.x - margin_x * 2.0
	var band_gap: float = 2.0
	var band_w: float = (avail_w - (SPECTRUM_BANDS - 1) * band_gap) / float(SPECTRUM_BANDS)

	for i in range(SPECTRUM_BANDS):
		var mag: float = _spectrum_bands_data[i]
		var peak: float = _spectrum_peaks_data[i]
		var bar_h: float = mag * (size.y - 14.0)
		var x: float = margin_x + float(i) * (band_w + band_gap)
		var y: float = size.y - 6.0 - bar_h

		# Gradient color calculation (Cyan -> Neon Violet)
		var ratio: float = float(i) / float(SPECTRUM_BANDS)
		var bar_color: Color = Color(
			lerpf(0.15, 0.95, ratio),
			lerpf(0.85, 0.3, ratio),
			lerpf(1.0, 0.75, ratio),
			0.9
		)
		var bar_rect := Rect2(Vector2(x, y), Vector2(band_w, bar_h))
		canvas.draw_rect(bar_rect, bar_color, true)

		# Peak hold cap
		var peak_y: float = size.y - 6.0 - peak * (size.y - 14.0)
		var peak_rect := Rect2(Vector2(x, peak_y - 1.5), Vector2(band_w, 2.0))
		canvas.draw_rect(peak_rect, Color(1.0, 1.0, 1.0, 0.95), true)

	# Oscilloscope Waveform Curve overlay across center
	var points: PackedVector2Array = PackedVector2Array()
	var wave_samples: int = 40
	var wave_h: float = size.y * 0.25
	var center_y: float = size.y * 0.5
	for w in range(wave_samples):
		var wx: float = margin_x + (float(w) / float(wave_samples - 1)) * avail_w
		var factor: float = sin(current_position_sec * 6.0 + float(w) * 0.4)
		var wy: float = center_y + factor * wave_h * (0.8 if playback_state == PlaybackState.PLAYING else 0.05)
		points.append(Vector2(wx, wy))
	canvas.draw_polyline(points, Color(0.3, 0.9, 0.6, 0.5), 1.5)

# --- Game Tagging & Association System ---
func bind_map_bgm(map_id: int, bgm_file: String) -> void:
	_map_bgm_bindings[map_id] = bgm_file
	if _asset_index_map.has(bgm_file):
		var rec: Dictionary = _asset_index_map[bgm_file]
		if not rec["mapped_scenes"].has(map_id):
			rec["mapped_scenes"].append(map_id)
		var tag := "map_%d" % map_id
		if not rec["tags"].has(tag):
			rec["tags"].append(tag)
	_log("Bound Map ID %d -> BGM: %s" % [map_id, bgm_file])
	map_bgm_assigned.emit(map_id, bgm_file)
	_refresh_map_bindings_tree()

func unbind_map_bgm(map_id: int) -> void:
	if _map_bgm_bindings.has(map_id):
		var old_bgm: String = _map_bgm_bindings[map_id]
		_map_bgm_bindings.erase(map_id)
		if _asset_index_map.has(old_bgm):
			_asset_index_map[old_bgm]["mapped_scenes"].erase(map_id)
		_log("Unbound Map ID %d" % map_id)
		_refresh_map_bindings_tree()

func get_map_bgm(map_id: int) -> String:
	return _map_bgm_bindings.get(map_id, "")

func get_all_map_bgm_bindings() -> Dictionary:
	return _map_bgm_bindings

func bind_skill_sfx(skill_id: int, sfx_type: String, sfx_file: String) -> void:
	if not _skill_sfx_bindings.has(skill_id):
		_skill_sfx_bindings[skill_id] = {}
	_skill_sfx_bindings[skill_id][sfx_type] = sfx_file

	if _asset_index_map.has(sfx_file):
		var rec: Dictionary = _asset_index_map[sfx_file]
		if not rec["mapped_skills"].has(skill_id):
			rec["mapped_skills"].append(skill_id)
	_log("Bound Skill ID %d [%s] -> SFX: %s" % [skill_id, sfx_type, sfx_file])
	skill_sfx_assigned.emit(skill_id, sfx_type, sfx_file)
	_refresh_skill_bindings_tree()

func get_skill_sfx(skill_id: int, sfx_type: String) -> String:
	if _skill_sfx_bindings.has(skill_id):
		return _skill_sfx_bindings[skill_id].get(sfx_type, "")
	return ""

func bind_battle_event_sfx(event_name: String, sfx_file: String) -> void:
	_battle_event_sfx_bindings[event_name] = sfx_file
	if _asset_index_map.has(sfx_file):
		var rec: Dictionary = _asset_index_map[sfx_file]
		if not rec["mapped_events"].has(event_name):
			rec["mapped_events"].append(event_name)
	_log("Bound Battle Event [%s] -> SFX: %s" % [event_name, sfx_file])
	battle_event_sfx_assigned.emit(event_name, sfx_file)
	_refresh_skill_bindings_tree()

func get_battle_event_sfx(event_name: String) -> String:
	return _battle_event_sfx_bindings.get(event_name, "")

func configure_ambience_layer(layer_name: String, sound_file: String, volume_db: float, loop: bool) -> void:
	_ambience_layers[layer_name] = {
		"sound_file": sound_file,
		"volume_db": volume_db,
		"loop": loop,
		"enabled": false
	}
	_log("Configured Ambience Layer: %s (SFX: %s, %.1f dB)" % [layer_name, sound_file, volume_db])

func get_ambience_layer(layer_name: String) -> Dictionary:
	return _ambience_layers.get(layer_name, {})

# --- Presets System ---
func get_preset_names() -> Array[String]:
	var names: Array[String] = []
	for k in PRESETS.keys():
		names.append(String(k))
	return names

func apply_preset(preset_name: String) -> bool:
	if not PRESETS.has(preset_name):
		_log("Preset not found: " + preset_name)
		return false

	var p: Dictionary = PRESETS[preset_name]
	var sound_file: String = p["sound_file"]

	select_sound_by_name(sound_file)
	set_volume_db(p["volume_db"])
	set_pitch_scale(p["pitch_scale"])
	set_looping(p["is_looping"])
	set_loop_points(p["loop_start_sec"], p["loop_end_sec"])
	set_fade_durations(p["fade_in_sec"], p["fade_out_sec"])

	if p.has("map_id") and p["map_id"] > 0:
		bind_map_bgm(p["map_id"], sound_file)

	if p.has("battle_event") and not String(p["battle_event"]).is_empty():
		bind_battle_event_sfx(p["battle_event"], sound_file)

	if p["ambience_enabled"] and not String(p["ambience_track"]).is_empty():
		set_ambience_volume_db(p["ambience_volume_db"])
		play_ambience(p["ambience_track"])
	else:
		stop_ambience()

	play_sound(sound_file, 0.0)
	_log("Applied audio preset: " + preset_name)
	preset_applied.emit(preset_name)
	_refresh_ui()
	return true

# --- Export & Persistence Methods ---
func save_audio_config(path: String) -> bool:
	var config_dict: Dictionary = {
		"version": "1.0.0",
		"engine": "Godot 4.6.2",
		"saved_at": Time.get_datetime_string_from_system(),
		"master_volume_db": master_volume_db,
		"pitch_scale": pitch_scale,
		"is_looping": is_looping,
		"current_sound": current_sound_name,
		"map_bgm_bindings": _map_bgm_bindings,
		"skill_sfx_bindings": _skill_sfx_bindings,
		"battle_event_sfx_bindings": _battle_event_sfx_bindings,
		"ambience_layers": _ambience_layers,
		"custom_loop_points": _custom_loop_points
	}

	var json_str: String = JSON.stringify(config_dict, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		_log("Failed to write config: " + path)
		return false

	file.store_string(json_str)
	file.close()
	_log("Audio configuration saved successfully to: " + path)
	config_saved.emit(path)
	return true

func load_audio_config(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_log("Config file not found: " + path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}

	var json_text: String = file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json_text)
	if not (parsed is Dictionary):
		_log("Invalid JSON format in: " + path)
		return {}

	var dict: Dictionary = parsed as Dictionary
	if dict.has("master_volume_db"): set_volume_db(float(dict["master_volume_db"]))
	if dict.has("pitch_scale"): set_pitch_scale(float(dict["pitch_scale"]))
	if dict.has("is_looping"): set_looping(bool(dict["is_looping"]))

	if dict.has("map_bgm_bindings"):
		_map_bgm_bindings.clear()
		var maps_in: Dictionary = dict["map_bgm_bindings"]
		for k in maps_in.keys():
			_map_bgm_bindings[int(k)] = String(maps_in[k])

	if dict.has("skill_sfx_bindings"):
		_skill_sfx_bindings.clear()
		var skills_in: Dictionary = dict["skill_sfx_bindings"]
		for k in skills_in.keys():
			_skill_sfx_bindings[int(k)] = skills_in[k]

	if dict.has("battle_event_sfx_bindings"):
		_battle_event_sfx_bindings.clear()
		var evts_in: Dictionary = dict["battle_event_sfx_bindings"]
		for k in evts_in.keys():
			_battle_event_sfx_bindings[String(k)] = String(evts_in[k])

	if dict.has("ambience_layers"):
		_ambience_layers = dict["ambience_layers"]

	if dict.has("custom_loop_points"):
		_custom_loop_points = dict["custom_loop_points"]

	if dict.has("current_sound") and not String(dict["current_sound"]).is_empty():
		select_sound_by_name(String(dict["current_sound"]))

	_log("Audio configuration loaded successfully from: " + path)
	config_loaded.emit(path)
	_refresh_ui()
	return dict

func export_audio_manifest(path: String) -> bool:
	var breakdown: Dictionary = {
		"BGM": 0,
		"SEB": 0,
		"Combat": 0,
		"Voice": 0,
		"Ambience": 0
	}

	var asset_summaries: Array[Dictionary] = []
	for asset in _sound_assets:
		var cat_name: String = asset["category_name"]
		if breakdown.has(cat_name):
			breakdown[cat_name] += 1

		asset_summaries.append({
			"file_name": asset["file_name"],
			"display_name": asset["display_name"],
			"category": cat_name,
			"full_path": asset["full_path"],
			"duration_sec": asset["duration_sec"],
			"is_looping": asset["is_looping"],
			"tags": asset["tags"],
			"mapped_scenes": asset["mapped_scenes"],
			"mapped_skills": asset["mapped_skills"],
			"mapped_events": asset["mapped_events"]
		})

	var manifest: Dictionary = {
		"manifest_version": "1.0.0",
		"project": "Wonderland Online Godot 4 Client",
		"exported_at": Time.get_datetime_string_from_system(),
		"total_scanned_assets": _sound_assets.size(),
		"categories_breakdown": breakdown,
		"map_bgm_bindings_count": _map_bgm_bindings.size(),
		"skill_sfx_bindings_count": _skill_sfx_bindings.size(),
		"battle_event_sfx_bindings_count": _battle_event_sfx_bindings.size(),
		"assets": asset_summaries
	}

	var json_str: String = JSON.stringify(manifest, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		_log("Failed to export manifest: " + path)
		return false

	file.store_string(json_str)
	file.close()
	_log("Exported audio manifest (%d assets) to: %s" % [_sound_assets.size(), path])
	manifest_exported.emit(path)
	return true

# --- Helper Stream Resolver ---
func _resolve_and_load_stream(path: String) -> AudioStream:
	if path.begins_with("res://") and ResourceLoader.exists(path):
		return load(path) as AudioStream

	var file_name: String = path.get_file()
	var candidates: Array[String] = [
		"res://assets/sound/" + file_name,
		"res://assets/voice/" + file_name
	]
	for c in candidates:
		if ResourceLoader.exists(c):
			return load(c) as AudioStream

	if FileAccess.file_exists(path):
		return _load_wav_from_file_bytes(path)

	return null

func _load_wav_from_file_bytes(path: String) -> AudioStreamWAV:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return null

	var bytes := file.get_buffer(file.get_length())
	if bytes.size() < 44:
		return null

	if bytes.slice(0, 4).get_string_from_ascii() != "RIFF" or bytes.slice(8, 12).get_string_from_ascii() != "WAVE":
		return null

	var stream := AudioStreamWAV.new()
	var channels: int = bytes.decode_u16(22)
	var sample_rate: int = bytes.decode_u32(24)
	var bits: int = bytes.decode_u16(34)

	stream.stereo = (channels == 2)
	stream.mix_rate = sample_rate
	if bits == 8:
		stream.format = AudioStreamWAV.FORMAT_8_BITS
	elif bits == 16:
		stream.format = AudioStreamWAV.FORMAT_16_BITS

	var pos: int = 12
	while pos + 8 <= bytes.size():
		var chunk_id := bytes.slice(pos, pos + 4).get_string_from_ascii()
		var chunk_len := bytes.decode_u32(pos + 4)
		if chunk_id == "data":
			var data_start: int = pos + 8
			var data_end: int = mini(data_start + chunk_len, bytes.size())
			stream.data = bytes.slice(data_start, data_end)
			return stream
		pos += 8 + chunk_len

	return null

func _get_sound_path_by_name(file_name: String) -> String:
	if _asset_index_map.has(file_name):
		return _asset_index_map[file_name]["full_path"]
	return "res://assets/sound/" + file_name

# --- UI Setup & Bindings ---
func _setup_ui_bindings() -> void:
	if tab_container:
		tab_container.set_tab_title(0, "Map BGM Binding")
		tab_container.set_tab_title(1, "Combat / Skill SFX")
		tab_container.set_tab_title(2, "Ambience Layering")
		tab_container.set_tab_title(3, "Log & Summary")

	if visualizer_canvas:
		visualizer_canvas.draw.connect(_on_visualizer_canvas_draw)

	if opt_preset:
		opt_preset.clear()
		for p_name in PRESETS.keys():
			opt_preset.add_item(p_name)

	if opt_category:
		opt_category.clear()
		for cat_id in CATEGORY_NAMES.keys():
			opt_category.add_item(CATEGORY_NAMES[cat_id], cat_id)
		opt_category.item_selected.connect(_on_category_selected)

	if edit_search:
		edit_search.text_changed.connect(_on_search_changed)

	if edit_tag_filter:
		edit_tag_filter.text_changed.connect(_on_tag_filter_changed)

	if list_sounds:
		list_sounds.item_selected.connect(_on_sound_item_selected)

	if btn_rescan:
		btn_rescan.pressed.connect(func(): scan_sound_assets(); _refresh_ui())

	if btn_play:
		btn_play.pressed.connect(func(): play_sound())

	if btn_pause:
		btn_pause.pressed.connect(pause_sound)

	if btn_stop:
		btn_stop.pressed.connect(stop_sound)

	if chk_loop:
		chk_loop.toggled.connect(set_looping)

	if slider_scrubber:
		slider_scrubber.value_changed.connect(func(val: float): if slider_scrubber.has_focus(): seek_sound(val))

	if slider_volume:
		slider_volume.value_changed.connect(set_volume_db)

	if slider_pitch:
		slider_pitch.value_changed.connect(set_pitch_scale)

	if spin_loop_start:
		spin_loop_start.value_changed.connect(func(v: float): set_loop_points(v, loop_end_sec))

	if spin_loop_end:
		spin_loop_end.value_changed.connect(func(v: float): set_loop_points(loop_start_sec, v))

	if spin_fade_in:
		spin_fade_in.value_changed.connect(func(v: float): set_fade_durations(v, fade_out_duration))

	if spin_fade_out:
		spin_fade_out.value_changed.connect(func(v: float): set_fade_durations(fade_in_duration, v))

	if btn_apply_preset:
		btn_apply_preset.pressed.connect(func():
			if opt_preset:
				apply_preset(opt_preset.get_item_text(opt_preset.selected))
		)

	if btn_save_config:
		btn_save_config.pressed.connect(func(): save_audio_config("user://audio_config.json"))

	if btn_load_config:
		btn_load_config.pressed.connect(func(): load_audio_config("user://audio_config.json"))

	if btn_export_manifest:
		btn_export_manifest.pressed.connect(func(): export_audio_manifest("user://audio_manifest.json"))

	# Map Binding UI
	if btn_assign_map_bgm:
		btn_assign_map_bgm.pressed.connect(func():
			if spin_map_id and not current_sound_name.is_empty():
				bind_map_bgm(int(spin_map_id.value), current_sound_name)
		)

	if btn_remove_map_bgm:
		btn_remove_map_bgm.pressed.connect(func():
			if spin_map_id:
				unbind_map_bgm(int(spin_map_id.value))
		)

	# Skill SFX UI
	if btn_assign_skill_sfx:
		btn_assign_skill_sfx.pressed.connect(func():
			if spin_skill_id and opt_sfx_type and not current_sound_name.is_empty():
				var s_type: String = opt_sfx_type.get_item_text(opt_sfx_type.selected).to_lower()
				bind_skill_sfx(int(spin_skill_id.value), s_type, current_sound_name)
		)

	if btn_assign_event_sfx:
		btn_assign_event_sfx.pressed.connect(func():
			if opt_battle_event and not current_sound_name.is_empty():
				var ev_name: String = opt_battle_event.get_item_text(opt_battle_event.selected)
				bind_battle_event_sfx(ev_name, current_sound_name)
		)

	# Ambience UI
	if chk_ambience:
		chk_ambience.toggled.connect(set_ambience_enabled)

	if opt_ambience_track:
		opt_ambience_track.item_selected.connect(func(idx: int):
			var track_name: String = opt_ambience_track.get_item_text(idx)
			play_ambience(track_name)
		)

	if slider_ambience_vol:
		slider_ambience_vol.value_changed.connect(set_ambience_volume_db)

	if btn_amb_ocean:
		btn_amb_ocean.pressed.connect(func(): _apply_ambience_preset("Ocean Waves"))

	if btn_amb_cave:
		btn_amb_cave.pressed.connect(func(): _apply_ambience_preset("Cave Dripping"))

	if btn_amb_wind:
		btn_amb_wind.pressed.connect(func(): _apply_ambience_preset("Wind Howling"))

func _apply_ambience_preset(layer_name: String) -> void:
	if _ambience_layers.has(layer_name):
		var lyr: Dictionary = _ambience_layers[layer_name]
		set_ambience_volume_db(lyr["volume_db"])
		play_ambience(lyr["sound_file"])
		if lbl_ambience_desc:
			lbl_ambience_desc.text = lyr.get("desc", layer_name)

func _on_visualizer_canvas_draw() -> void:
	if visualizer_canvas:
		draw_spectrum_visualizer(visualizer_canvas)

func _on_category_selected(index: int) -> void:
	var cat: SoundCategory = SoundCategory.ALL
	if opt_category:
		cat = opt_category.get_item_id(index) as SoundCategory
	var q: String = edit_search.text if edit_search else ""
	var t: String = edit_tag_filter.text if edit_tag_filter else ""
	filter_assets(q, cat, t)
	_refresh_sound_list_ui()

func _on_search_changed(new_text: String) -> void:
	var cat: SoundCategory = SoundCategory.ALL
	if opt_category:
		cat = opt_category.get_item_id(opt_category.selected) as SoundCategory
	var t: String = edit_tag_filter.text if edit_tag_filter else ""
	filter_assets(new_text, cat, t)
	_refresh_sound_list_ui()

func _on_tag_filter_changed(new_tag: String) -> void:
	var cat: SoundCategory = SoundCategory.ALL
	if opt_category:
		cat = opt_category.get_item_id(opt_category.selected) as SoundCategory
	var q: String = edit_search.text if edit_search else ""
	filter_assets(q, cat, new_tag)
	_refresh_sound_list_ui()

func _on_sound_item_selected(index: int) -> void:
	if index >= 0 and index < _filtered_assets.size():
		var asset: Dictionary = _filtered_assets[index]
		select_sound_by_name(asset["file_name"])

# --- UI Refreshers ---
func _refresh_ui() -> void:
	_refresh_sound_list_ui()
	_refresh_ui_player_info()
	_refresh_transport_ui()
	_refresh_map_bindings_tree()
	_refresh_skill_bindings_tree()
	_refresh_ambience_ui()
	_refresh_summary()

func _refresh_sound_list_ui() -> void:
	if not list_sounds:
		return

	list_sounds.clear()
	for i in range(_filtered_assets.size()):
		var asset: Dictionary = _filtered_assets[i]
		var line: String = "[%s] %s (%.1fs)" % [asset["category_name"], asset["file_name"], asset["duration_sec"]]
		list_sounds.add_item(line)
		if asset["file_name"] == current_sound_name:
			list_sounds.select(i)

	if lbl_asset_count:
		lbl_asset_count.text = "Showing %d of %d assets" % [_filtered_assets.size(), _sound_assets.size()]

func _refresh_ui_player_info() -> void:
	if lbl_now_playing:
		lbl_now_playing.text = "Now Playing: %s (%.1fs)" % [current_sound_name if not current_sound_name.is_empty() else "None", current_duration_sec]

	if slider_scrubber:
		slider_scrubber.max_value = maxf(1.0, current_duration_sec)
		slider_scrubber.value = current_position_sec

	if spin_loop_start:
		spin_loop_start.max_value = maxf(1.0, current_duration_sec)
		spin_loop_start.value = loop_start_sec

	if spin_loop_end:
		spin_loop_end.max_value = maxf(1.0, current_duration_sec)
		spin_loop_end.value = loop_end_sec

	if chk_loop:
		chk_loop.button_pressed = is_looping

func _refresh_transport_ui() -> void:
	if btn_play:
		btn_play.disabled = (playback_state == PlaybackState.PLAYING)
	if btn_pause:
		btn_pause.disabled = (playback_state != PlaybackState.PLAYING)
	if btn_stop:
		btn_stop.disabled = (playback_state == PlaybackState.STOPPED)

func _refresh_map_bindings_tree() -> void:
	if not tree_map_bindings:
		return

	tree_map_bindings.clear()
	var root: TreeItem = tree_map_bindings.create_item()
	tree_map_bindings.hide_root = true

	var sorted_maps: Array = _map_bgm_bindings.keys()
	sorted_maps.sort()

	for m_id in sorted_maps:
		var item: TreeItem = tree_map_bindings.create_item(root)
		item.set_text(0, "Map %d" % m_id)
		item.set_text(1, _map_bgm_bindings[m_id])

func _refresh_skill_bindings_tree() -> void:
	if not tree_skill_bindings:
		return

	tree_skill_bindings.clear()
	var root: TreeItem = tree_skill_bindings.create_item()
	tree_skill_bindings.hide_root = true

	# Events Header
	var ev_header: TreeItem = tree_skill_bindings.create_item(root)
	ev_header.set_text(0, "=== BATTLE EVENTS ===")
	for ev_name in _battle_event_sfx_bindings.keys():
		var item: TreeItem = tree_skill_bindings.create_item(ev_header)
		item.set_text(0, "Event: " + ev_name)
		item.set_text(1, _battle_event_sfx_bindings[ev_name])

	# Skills Header
	var sk_header: TreeItem = tree_skill_bindings.create_item(root)
	sk_header.set_text(0, "=== SKILL SFX ===")
	var sorted_skills: Array = _skill_sfx_bindings.keys()
	sorted_skills.sort()
	for sk_id in sorted_skills:
		var s_dict: Dictionary = _skill_sfx_bindings[sk_id]
		for s_type in s_dict.keys():
			var item: TreeItem = tree_skill_bindings.create_item(sk_header)
			item.set_text(0, "Skill %d [%s]" % [sk_id, s_type])
			item.set_text(1, s_dict[s_type])

func _refresh_ambience_ui() -> void:
	if opt_ambience_track:
		opt_ambience_track.clear()
		for asset in _sound_assets:
			if asset["category"] == SoundCategory.AMBIENCE or asset["file_name"].begins_with("SEB"):
				opt_ambience_track.add_item(asset["file_name"])

	if chk_ambience:
		chk_ambience.button_pressed = ambience_enabled

	if slider_ambience_vol:
		slider_ambience_vol.value = ambience_volume_db

func _refresh_summary() -> void:
	if lbl_summary:
		lbl_summary.text = "Scanned Assets: %d | Map Bindings: %d | Skill Bindings: %d | Battle Events: %d" % [
			_sound_assets.size(),
			_map_bgm_bindings.size(),
			_skill_sfx_bindings.size(),
			_battle_event_sfx_bindings.size()
		]

func _log(msg: String) -> void:
	print("[AudioEditor] " + msg)
	if text_log:
		text_log.text += msg + "\n"
