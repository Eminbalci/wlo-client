class_name CutsceneEditor
extends Control

## Wonderland Online Cutscene & In-Game Event Sequence Director Tool.
## Production-ready, strictly type-hinted visual editor for authoring, sequencing,
## previewing, and exporting cinematic in-game event sequences in Godot 4.

# --- Signals ---
signal playback_started
signal playback_paused
signal playback_stopped
signal time_updated(current_time: float)
signal keyframe_added(track_type: String, index: int)
signal keyframe_removed(track_type: String, index: int)
signal keyframe_modified(track_type: String, index: int)
signal track_cleared(track_type: String)
signal preset_loaded(preset_name: String)
signal cutscene_saved(file_path: String)
signal cutscene_loaded(file_path: String)
signal scene_exported(file_path: String)
signal actor_added(actor_id: String)
signal actor_removed(actor_id: String)

# --- Constants ---
const TRACK_CAMERA: String = "camera"
const TRACK_ACTOR: String = "actor"
const TRACK_DIALOGUE: String = "dialogue"
const TRACK_AUDIO: String = "audio"
const TRACK_SCREEN_FX: String = "screen_fx"

const ALL_TRACK_TYPES: Array[String] = [
	TRACK_CAMERA,
	TRACK_ACTOR,
	TRACK_DIALOGUE,
	TRACK_AUDIO,
	TRACK_SCREEN_FX
]

const DEFAULT_DURATION: float = 15.0
const DEFAULT_FPS: int = 30
const CUSTOM_CUTSCENES_DIR: String = "user://custom_cutscenes/"

# --- Cutscene State ---
var cutscene_title: String = "Ship Sinking Climax"
var total_duration: float = 15.0
var current_time: float = 0.0
var is_playing: bool = false
var time_scale: float = 1.0
var background_preset: String = "Ship Deck" # "Ship Deck", "Beach Shore", "Cavern", "Ocean Waves", "Isometric Grid"

# Tracks dictionary holding arrays of keyframe Dictionaries
var tracks: Dictionary = {
	TRACK_CAMERA: [],
	TRACK_ACTOR: [],
	TRACK_DIALOGUE: [],
	TRACK_AUDIO: [],
	TRACK_SCREEN_FX: []
}

# Actors roster: actor_id -> Dictionary
var actors: Dictionary = {}

# Selection state
var selected_track: String = TRACK_CAMERA
var selected_keyframe_index: int = -1

# --- UI Node References ---
@onready var title_edit: LineEdit = find_child("CutsceneTitleEdit", true, false)
@onready var duration_spin: SpinBox = find_child("DurationSpin", true, false)
@onready var preset_option: OptionButton = find_child("PresetOption", true, false)
@onready var btn_load_preset: Button = find_child("BtnLoadPreset", true, false)
@onready var btn_new: Button = find_child("BtnNew", true, false)
@onready var btn_load_json: Button = find_child("BtnLoadJSON", true, false)
@onready var btn_save_json: Button = find_child("BtnSaveJSON", true, false)
@onready var btn_export_scene: Button = find_child("BtnExportScene", true, false)

@onready var viewport_canvas: Control = find_child("ViewportCanvas", true, false)
@onready var btn_play: Button = find_child("BtnPlay", true, false)
@onready var btn_pause: Button = find_child("BtnPause", true, false)
@onready var btn_stop: Button = find_child("BtnStop", true, false)
@onready var time_label: Label = find_child("TimeLabel", true, false)
@onready var frame_label: Label = find_child("FrameLabel", true, false)
@onready var time_scale_option: OptionButton = find_child("TimeScaleOption", true, false)
@onready var time_slider: HSlider = find_child("TimeSlider", true, false)

# Track Lane Controls
@onready var camera_lane: Control = find_child("CameraTrackLane", true, false)
@onready var actor_lane: Control = find_child("ActorTrackLane", true, false)
@onready var dialogue_lane: Control = find_child("DialogueTrackLane", true, false)
@onready var audio_lane: Control = find_child("AudioTrackLane", true, false)
@onready var screen_fx_lane: Control = find_child("ScreenFXTrackLane", true, false)

# Inspector Controls
@onready var inspector_tabs: TabContainer = find_child("InspectorTabs", true, false)
@onready var track_select_option: OptionButton = find_child("TrackSelectOption", true, false)
@onready var keyframe_item_list: ItemList = find_child("KeyframeItemList", true, false)
@onready var btn_add_keyframe: Button = find_child("BtnAddKeyframe", true, false)
@onready var btn_remove_keyframe: Button = find_child("BtnRemoveKeyframe", true, false)
@onready var btn_clear_track: Button = find_child("BtnClearTrack", true, false)

# Keyframe Inspector Field Containers
@onready var key_time_spin: SpinBox = find_child("KeyTimeSpin", true, false)
@onready var prop_camera_box: Container = find_child("PropCameraBox", true, false)
@onready var prop_actor_box: Container = find_child("PropActorBox", true, false)
@onready var prop_dialogue_box: Container = find_child("PropDialogueBox", true, false)
@onready var prop_audio_box: Container = find_child("PropAudioBox", true, false)
@onready var prop_screen_fx_box: Container = find_child("PropScreenFXBox", true, false)

# Status bar
@onready var status_readout: Label = find_child("StatusReadoutLabel", true, false)
@onready var state_readout: Label = find_child("StateReadoutLabel", true, false)

# --- Built-in Presets ---
const PRESETS: Dictionary = {
	"Ship Sinking Climax": {
		"title": "Ship Sinking Climax",
		"duration": 15.0,
		"background": "Ship Deck",
		"actors": {
			"captain": {
				"name": "Captain Robinson",
				"initial_pos": Vector2(420, 280),
				"initial_facing": 7,
				"initial_action": "Idle"
			},
			"crew_1": {
				"name": "Sailor Tom",
				"initial_pos": Vector2(300, 320),
				"initial_facing": 6,
				"initial_action": "Idle"
			},
			"player": {
				"name": "Daniel",
				"initial_pos": Vector2(360, 300),
				"initial_facing": 5,
				"initial_action": "Idle"
			}
		},
		"tracks": {
			"camera": [
				{
					"time": 0.0,
					"pan_target": Vector2(400, 300),
					"zoom": 1.0,
					"shake_intensity": 0.1,
					"shake_duration": 2.0,
					"interpolation": "Linear"
				},
				{
					"time": 4.0,
					"pan_target": Vector2(420, 290),
					"zoom": 1.15,
					"shake_intensity": 0.8,
					"shake_duration": 5.0,
					"interpolation": "EaseInOut"
				},
				{
					"time": 10.0,
					"pan_target": Vector2(450, 320),
					"zoom": 1.25,
					"shake_intensity": 0.9,
					"shake_duration": 5.0,
					"interpolation": "Linear"
				}
			],
			"actor": [
				{
					"time": 0.0,
					"actor_id": "captain",
					"actor_name": "Captain Robinson",
					"position": Vector2(420, 280),
					"facing": 7,
					"action": "Idle",
					"visible": true,
					"interpolation": "Linear"
				},
				{
					"time": 4.2,
					"actor_id": "captain",
					"actor_name": "Captain Robinson",
					"position": Vector2(420, 280),
					"facing": 1,
					"action": "Pose",
					"visible": true,
					"interpolation": "Linear"
				},
				{
					"time": 8.0,
					"actor_id": "captain",
					"actor_name": "Captain Robinson",
					"position": Vector2(440, 310),
					"facing": 6,
					"action": "Walk",
					"visible": true,
					"interpolation": "Linear"
				},
				{
					"time": 0.0,
					"actor_id": "crew_1",
					"actor_name": "Sailor Tom",
					"position": Vector2(300, 320),
					"facing": 6,
					"action": "Idle",
					"visible": true,
					"interpolation": "Linear"
				},
				{
					"time": 4.5,
					"actor_id": "crew_1",
					"actor_name": "Sailor Tom",
					"position": Vector2(300, 320),
					"facing": 6,
					"action": "Walk",
					"visible": true,
					"interpolation": "Linear"
				},
				{
					"time": 8.0,
					"actor_id": "crew_1",
					"actor_name": "Sailor Tom",
					"position": Vector2(520, 340),
					"facing": 6,
					"action": "Walk",
					"visible": true,
					"interpolation": "Linear"
				},
				{
					"time": 0.0,
					"actor_id": "player",
					"actor_name": "Daniel",
					"position": Vector2(360, 300),
					"facing": 5,
					"action": "Idle",
					"visible": true,
					"interpolation": "Linear"
				},
				{
					"time": 4.5,
					"actor_id": "player",
					"actor_name": "Daniel",
					"position": Vector2(360, 300),
					"facing": 3,
					"action": "Pose",
					"visible": true,
					"interpolation": "Linear"
				},
				{
					"time": 10.0,
					"actor_id": "player",
					"actor_name": "Daniel",
					"position": Vector2(380, 310),
					"facing": 2,
					"action": "Prone",
					"visible": true,
					"interpolation": "Linear"
				}
			],
			"dialogue": [
				{
					"time": 1.0,
					"duration": 3.0,
					"talk_id": 14001,
					"speaker": "Sailor Tom",
					"text": "Look out! The storm winds are tearing the rigging apart!",
					"typewriter_delay": 0.03
				},
				{
					"time": 4.5,
					"duration": 4.5,
					"talk_id": 14003,
					"speaker": "Captain Robinson",
					"text": "Hold tight everyone! We have struck a submerged reef!",
					"typewriter_delay": 0.035
				},
				{
					"time": 9.5,
					"duration": 4.5,
					"talk_id": 14003,
					"speaker": "Captain Robinson",
					"text": "The hull is breached! Abandon ship! Head for the lifeboats!",
					"typewriter_delay": 0.03
				}
			],
			"audio": [
				{
					"time": 0.0,
					"audio_type": "BGM",
					"resource_id": "BGM0041.wav",
					"volume_db": -2.0,
					"pitch_scale": 1.0,
					"fade_time": 0.0
				},
				{
					"time": 4.0,
					"audio_type": "SFX",
					"resource_id": "SEB0279_alarm.wav",
					"volume_db": 2.0,
					"pitch_scale": 1.05,
					"fade_time": 0.0
				},
				{
					"time": 9.0,
					"audio_type": "SFX",
					"resource_id": "ship_hull_creak.wav",
					"volume_db": 3.0,
					"pitch_scale": 0.9,
					"fade_time": 0.0
				}
			],
			"screen_fx": [
				{
					"time": 4.0,
					"duration": 4.0,
					"fx_type": "Flash",
					"color": Color(1.0, 0.1, 0.1, 0.45),
					"intensity": 0.8,
					"tilt_angle": 0.0,
					"pulse_frequency": 2.5
				},
				{
					"time": 4.0,
					"duration": 6.0,
					"fx_type": "CameraTilt",
					"color": Color(0, 0, 0, 0),
					"intensity": 1.0,
					"tilt_angle": 8.0,
					"pulse_frequency": 0.0
				},
				{
					"time": 10.0,
					"duration": 5.0,
					"fx_type": "CameraTilt",
					"color": Color(0, 0, 0, 0),
					"intensity": 1.0,
					"tilt_angle": 14.5,
					"pulse_frequency": 0.0
				},
				{
					"time": 13.0,
					"duration": 2.0,
					"fx_type": "FadeColor",
					"color": Color(0.0, 0.0, 0.0, 1.0),
					"intensity": 1.0,
					"tilt_angle": 0.0,
					"pulse_frequency": 0.0
				}
			]
		}
	},
	"Monkey Beach Awakening": {
		"title": "Monkey Beach Awakening",
		"duration": 14.0,
		"background": "Beach Shore",
		"actors": {
			"player": {
				"name": "Daniel",
				"initial_pos": Vector2(380, 320),
				"initial_facing": 1,
				"initial_action": "Prone"
			},
			"kelang": {
				"name": "Kelang",
				"initial_pos": Vector2(180, 260),
				"initial_facing": 6,
				"initial_action": "Idle"
			}
		},
		"tracks": {
			"camera": [
				{
					"time": 0.0,
					"pan_target": Vector2(400, 320),
					"zoom": 1.3,
					"shake_intensity": 0.0,
					"shake_duration": 0.0,
					"interpolation": "Linear"
				},
				{
					"time": 5.0,
					"pan_target": Vector2(400, 300),
					"zoom": 1.15,
					"shake_intensity": 0.0,
					"shake_duration": 0.0,
					"interpolation": "EaseInOut"
				},
				{
					"time": 9.0,
					"pan_target": Vector2(390, 290),
					"zoom": 1.0,
					"shake_intensity": 0.0,
					"shake_duration": 0.0,
					"interpolation": "Linear"
				}
			],
			"actor": [
				{
					"time": 0.0,
					"actor_id": "player",
					"actor_name": "Daniel",
					"position": Vector2(380, 320),
					"facing": 1,
					"action": "Prone",
					"visible": true,
					"interpolation": "Linear"
				},
				{
					"time": 4.0,
					"actor_id": "player",
					"actor_name": "Daniel",
					"position": Vector2(380, 320),
					"facing": 1,
					"action": "Pose",
					"visible": true,
					"interpolation": "Linear"
				},
				{
					"time": 6.5,
					"actor_id": "player",
					"actor_name": "Daniel",
					"position": Vector2(380, 320),
					"facing": 2,
					"action": "Idle",
					"visible": true,
					"interpolation": "Linear"
				},
				{
					"time": 0.0,
					"actor_id": "kelang",
					"actor_name": "Kelang",
					"position": Vector2(180, 260),
					"facing": 6,
					"action": "Idle",
					"visible": false,
					"interpolation": "Linear"
				},
				{
					"time": 4.0,
					"actor_id": "kelang",
					"actor_name": "Kelang",
					"position": Vector2(180, 260),
					"facing": 6,
					"action": "Walk",
					"visible": true,
					"interpolation": "Linear"
				},
				{
					"time": 7.5,
					"actor_id": "kelang",
					"actor_name": "Kelang",
					"position": Vector2(320, 300),
					"facing": 6,
					"action": "Walk",
					"visible": true,
					"interpolation": "Linear"
				},
				{
					"time": 8.5,
					"actor_id": "kelang",
					"actor_name": "Kelang",
					"position": Vector2(320, 300),
					"facing": 7,
					"action": "Idle",
					"visible": true,
					"interpolation": "Linear"
				}
			],
			"dialogue": [
				{
					"time": 2.0,
					"duration": 3.5,
					"talk_id": 0,
					"speaker": "Narrator",
					"text": "...The sound of rolling ocean waves greets your weary consciousness...",
					"typewriter_delay": 0.04
				},
				{
					"time": 6.5,
					"duration": 3.0,
					"talk_id": 0,
					"speaker": "Daniel",
					"text": "Ugh... my head hurts... Where am I? Did anyone else survive?",
					"typewriter_delay": 0.035
				},
				{
					"time": 9.0,
					"duration": 4.5,
					"talk_id": 10011,
					"speaker": "Kelang",
					"text": "Hey! You are finally awake! You washed ashore on South Island monkey beach. Are you injured?",
					"typewriter_delay": 0.03
				}
			],
			"audio": [
				{
					"time": 0.0,
					"audio_type": "Ambient",
					"resource_id": "ocean_waves_beach.wav",
					"volume_db": -4.0,
					"pitch_scale": 1.0,
					"fade_time": 0.0
				},
				{
					"time": 4.0,
					"audio_type": "BGM",
					"resource_id": "BGM0012_south_island.wav",
					"volume_db": -6.0,
					"pitch_scale": 1.0,
					"fade_time": 2.0
				}
			],
			"screen_fx": [
				{
					"time": 0.0,
					"duration": 3.5,
					"fx_type": "FadeColor",
					"color": Color(0.0, 0.0, 0.0, 1.0),
					"intensity": 1.0,
					"tilt_angle": 0.0,
					"pulse_frequency": 0.0
				}
			]
		}
	},
	"Kelan Cave Ambush": {
		"title": "Kelan Cave Ambush",
		"duration": 12.0,
		"background": "Cavern",
		"actors": {
			"player": {
				"name": "Daniel",
				"initial_pos": Vector2(300, 320),
				"initial_facing": 6,
				"initial_action": "Walk"
			},
			"bat_1": {
				"name": "Cave Bat",
				"initial_pos": Vector2(520, 180),
				"initial_facing": 2,
				"initial_action": "Idle"
			},
			"slime_1": {
				"name": "Kelan Slime",
				"initial_pos": Vector2(560, 280),
				"initial_facing": 2,
				"initial_action": "Idle"
			}
		},
		"tracks": {
			"camera": [
				{
					"time": 0.0,
					"pan_target": Vector2(350, 320),
					"zoom": 1.0,
					"shake_intensity": 0.0,
					"shake_duration": 0.0,
					"interpolation": "Linear"
				},
				{
					"time": 3.0,
					"pan_target": Vector2(480, 260),
					"zoom": 1.2,
					"shake_intensity": 0.0,
					"shake_duration": 0.0,
					"interpolation": "EaseInOut"
				},
				{
					"time": 5.5,
					"pan_target": Vector2(480, 260),
					"zoom": 1.35,
					"shake_intensity": 0.75,
					"shake_duration": 2.0,
					"interpolation": "Linear"
				},
				{
					"time": 9.0,
					"pan_target": Vector2(420, 290),
					"zoom": 1.1,
					"shake_intensity": 0.0,
					"shake_duration": 0.0,
					"interpolation": "Linear"
				}
			],
			"actor": [
				{
					"time": 0.0,
					"actor_id": "player",
					"actor_name": "Daniel",
					"position": Vector2(300, 320),
					"facing": 6,
					"action": "Walk",
					"visible": true,
					"interpolation": "Linear"
				},
				{
					"time": 3.5,
					"actor_id": "player",
					"actor_name": "Daniel",
					"position": Vector2(380, 300),
					"facing": 6,
					"action": "Idle",
					"visible": true,
					"interpolation": "Linear"
				},
				{
					"time": 5.5,
					"actor_id": "player",
					"actor_name": "Daniel",
					"position": Vector2(380, 300),
					"facing": 5,
					"action": "Pose",
					"visible": true,
					"interpolation": "Linear"
				},
				{
					"time": 8.0,
					"actor_id": "player",
					"actor_name": "Daniel",
					"position": Vector2(380, 300),
					"facing": 5,
					"action": "Attack",
					"visible": true,
					"interpolation": "Linear"
				},
				{
					"time": 0.0,
					"actor_id": "bat_1",
					"actor_name": "Cave Bat",
					"position": Vector2(520, 180),
					"facing": 2,
					"action": "Idle",
					"visible": false,
					"interpolation": "Linear"
				},
				{
					"time": 5.5,
					"actor_id": "bat_1",
					"actor_name": "Cave Bat",
					"position": Vector2(520, 180),
					"facing": 2,
					"action": "Attack",
					"visible": true,
					"interpolation": "Linear"
				},
				{
					"time": 7.5,
					"actor_id": "bat_1",
					"actor_name": "Cave Bat",
					"position": Vector2(440, 240),
					"facing": 1,
					"action": "Attack",
					"visible": true,
					"interpolation": "Linear"
				},
				{
					"time": 0.0,
					"actor_id": "slime_1",
					"actor_name": "Kelan Slime",
					"position": Vector2(560, 280),
					"facing": 2,
					"action": "Idle",
					"visible": false,
					"interpolation": "Linear"
				},
				{
					"time": 5.5,
					"actor_id": "slime_1",
					"actor_name": "Kelan Slime",
					"position": Vector2(560, 280),
					"facing": 2,
					"action": "Walk",
					"visible": true,
					"interpolation": "Linear"
				},
				{
					"time": 7.5,
					"actor_id": "slime_1",
					"actor_name": "Kelan Slime",
					"position": Vector2(470, 290),
					"facing": 2,
					"action": "Attack",
					"visible": true,
					"interpolation": "Linear"
				}
			],
			"dialogue": [
				{
					"time": 1.0,
					"duration": 3.5,
					"talk_id": 0,
					"speaker": "Daniel",
					"text": "The path narrows here... Watch your step, this cavern is pitch black.",
					"typewriter_delay": 0.03
				},
				{
					"time": 5.5,
					"duration": 2.0,
					"talk_id": 0,
					"speaker": "Cave Bat",
					"text": "SKREEEEEEECH!",
					"typewriter_delay": 0.02
				},
				{
					"time": 7.8,
					"duration": 2.5,
					"talk_id": 0,
					"speaker": "Daniel",
					"text": "Ambush! Prepare for battle!",
					"typewriter_delay": 0.025
				}
			],
			"audio": [
				{
					"time": 0.0,
					"audio_type": "Ambient",
					"resource_id": "cave_dripping_ambience.wav",
					"volume_db": -3.0,
					"pitch_scale": 0.95,
					"fade_time": 0.0
				},
				{
					"time": 5.5,
					"audio_type": "SFX",
					"resource_id": "monster_ambush_roar.wav",
					"volume_db": 2.0,
					"pitch_scale": 1.1,
					"fade_time": 0.0
				},
				{
					"time": 6.5,
					"audio_type": "BGM",
					"resource_id": "BGM_battle_encounter.wav",
					"volume_db": 0.0,
					"pitch_scale": 1.0,
					"fade_time": 0.0
				}
			],
			"screen_fx": [
				{
					"time": 0.0,
					"duration": 5.0,
					"fx_type": "TintPulse",
					"color": Color(0.1, 0.15, 0.3, 0.4),
					"intensity": 0.3,
					"tilt_angle": 0.0,
					"pulse_frequency": 0.5
				},
				{
					"time": 5.5,
					"duration": 1.5,
					"fx_type": "Flash",
					"color": Color(1.0, 0.9, 0.4, 0.6),
					"intensity": 0.7,
					"tilt_angle": 0.0,
					"pulse_frequency": 4.0
				},
				{
					"time": 10.5,
					"duration": 1.5,
					"fx_type": "FadeColor",
					"color": Color(0.0, 0.0, 0.0, 1.0),
					"intensity": 1.0,
					"tilt_angle": 0.0,
					"pulse_frequency": 0.0
				}
			]
		}
	}
}

func _ready() -> void:
	custom_minimum_size = Vector2(800.0, 600.0)
	_init_tracks()
	load_preset("Ship Sinking Climax")
	
	if is_inside_tree():
		_bind_ui_signals()
		_refresh_ui()

func _init_tracks() -> void:
	for t in ALL_TRACK_TYPES:
		if not tracks.has(t):
			tracks[t] = []

func _bind_ui_signals() -> void:
	if btn_play and not btn_play.pressed.is_connected(play):
		btn_play.pressed.connect(play)
	if btn_pause and not btn_pause.pressed.is_connected(pause):
		btn_pause.pressed.connect(pause)
	if btn_stop and not btn_stop.pressed.is_connected(stop):
		btn_stop.pressed.connect(stop)
	if btn_load_preset and not btn_load_preset.pressed.is_connected(_on_btn_load_preset_pressed):
		btn_load_preset.pressed.connect(_on_btn_load_preset_pressed)
	if btn_new and not btn_new.pressed.is_connected(_on_btn_new_pressed):
		btn_new.pressed.connect(_on_btn_new_pressed)
	if btn_save_json and not btn_save_json.pressed.is_connected(_on_btn_save_json_pressed):
		btn_save_json.pressed.connect(_on_btn_save_json_pressed)
	if btn_load_json and not btn_load_json.pressed.is_connected(_on_btn_load_json_pressed):
		btn_load_json.pressed.connect(_on_btn_load_json_pressed)
	if btn_export_scene and not btn_export_scene.pressed.is_connected(_on_btn_export_scene_pressed):
		btn_export_scene.pressed.connect(_on_btn_export_scene_pressed)
	
	if time_slider and not time_slider.value_changed.is_connected(seek):
		time_slider.value_changed.connect(seek)
	if time_scale_option and not time_scale_option.item_selected.is_connected(_on_time_scale_selected):
		time_scale_option.item_selected.connect(_on_time_scale_selected)
	if duration_spin and not duration_spin.value_changed.is_connected(set_total_duration):
		duration_spin.value_changed.connect(set_total_duration)
	if title_edit and not title_edit.text_changed.is_connected(_on_title_text_changed):
		title_edit.text_changed.connect(_on_title_text_changed)
		
	if track_select_option and not track_select_option.item_selected.is_connected(_on_track_selected_from_option):
		track_select_option.item_selected.connect(_on_track_selected_from_option)
	if keyframe_item_list and not keyframe_item_list.item_selected.is_connected(_on_keyframe_item_selected):
		keyframe_item_list.item_selected.connect(_on_keyframe_item_selected)
	if btn_add_keyframe and not btn_add_keyframe.pressed.is_connected(_on_btn_add_keyframe_pressed):
		btn_add_keyframe.pressed.connect(_on_btn_add_keyframe_pressed)
	if btn_remove_keyframe and not btn_remove_keyframe.pressed.is_connected(_on_btn_remove_keyframe_pressed):
		btn_remove_keyframe.pressed.connect(_on_btn_remove_keyframe_pressed)
	if btn_clear_track and not btn_clear_track.pressed.is_connected(_on_btn_clear_track_pressed):
		btn_clear_track.pressed.connect(_on_btn_clear_track_pressed)
	
	if viewport_canvas and not viewport_canvas.draw.is_connected(_on_viewport_canvas_draw):
		viewport_canvas.draw.connect(_on_viewport_canvas_draw)
		
	_bind_lane_draws()

func _bind_lane_draws() -> void:
	var lanes: Array = [
		{"node": camera_lane, "type": TRACK_CAMERA, "col": Color(0.2, 0.7, 0.9, 0.9)},
		{"node": actor_lane, "type": TRACK_ACTOR, "col": Color(0.3, 0.85, 0.4, 0.9)},
		{"node": dialogue_lane, "type": TRACK_DIALOGUE, "col": Color(0.95, 0.8, 0.25, 0.9)},
		{"node": audio_lane, "type": TRACK_AUDIO, "col": Color(0.75, 0.4, 0.9, 0.9)},
		{"node": screen_fx_lane, "type": TRACK_SCREEN_FX, "col": Color(0.9, 0.3, 0.3, 0.9)}
	]
	
	for l in lanes:
		var lane_node: Control = l["node"] as Control
		if lane_node:
			var t_type: String = l["type"]
			var col: Color = l["col"]
			if not lane_node.draw.is_connected(_draw_lane.bind(lane_node, t_type, col)):
				lane_node.draw.connect(_draw_lane.bind(lane_node, t_type, col))
			if not lane_node.gui_input.is_connected(_on_lane_gui_input.bind(lane_node, t_type)):
				lane_node.gui_input.connect(_on_lane_gui_input.bind(lane_node, t_type))

func _process(delta: float) -> void:
	if not is_playing:
		return
	
	current_time += delta * time_scale
	if current_time >= total_duration:
		current_time = total_duration
		is_playing = false
		playback_stopped.emit()
	
	seek(current_time)

# =========================================================================
# --- PLAYBACK & SCRUBBER METHODS ---
# =========================================================================

func play() -> void:
	is_playing = true
	if current_time >= total_duration:
		current_time = 0.0
	playback_started.emit()
	if status_readout:
		status_readout.text = "Playback: Playing (%.2fx)" % time_scale

func pause() -> void:
	is_playing = false
	playback_paused.emit()
	if status_readout:
		status_readout.text = "Playback: Paused at %.2fs" % current_time

func stop() -> void:
	is_playing = false
	current_time = 0.0
	seek(0.0)
	playback_stopped.emit()
	if status_readout:
		status_readout.text = "Playback: Stopped"

func seek(t: float) -> void:
	current_time = clampf(t, 0.0, total_duration)
	time_updated.emit(current_time)
	_update_scrubber_display()
	_update_viewport()
	_redraw_lanes()

func seek_frame(frame: int, fps: int = DEFAULT_FPS) -> void:
	seek(float(frame) / maxf(float(fps), 1.0))

func set_time_scale(scale: float) -> void:
	time_scale = clampf(scale, 0.1, 10.0)

func get_time_scale() -> float:
	return time_scale

func set_total_duration(duration: float) -> void:
	total_duration = maxf(duration, 0.1)
	if current_time > total_duration:
		seek(total_duration)
	if time_slider:
		time_slider.max_value = total_duration
	if duration_spin:
		duration_spin.value = total_duration
	_redraw_lanes()

func get_total_duration() -> float:
	return total_duration

func get_current_time() -> float:
	return current_time

func is_playback_active() -> bool:
	return is_playing

# =========================================================================
# --- TRACK & KEYFRAME MANAGEMENT ---
# =========================================================================

func add_keyframe(track_type: String, keyframe_data: Dictionary) -> int:
	if not ALL_TRACK_TYPES.has(track_type):
		push_error("CutsceneEditor: Unknown track type %s" % track_type)
		return -1
	
	var kf: Dictionary = _normalize_keyframe(track_type, keyframe_data)
	var track_list: Array = tracks[track_type]
	track_list.append(kf)
	_sort_track(track_type)
	
	var idx: int = track_list.find(kf)
	keyframe_added.emit(track_type, idx)
	_refresh_keyframe_list()
	_redraw_lanes()
	_update_viewport()
	return idx

func remove_keyframe(track_type: String, index: int) -> bool:
	if not tracks.has(track_type):
		return false
	var track_list: Array = tracks[track_type]
	if index < 0 or index >= track_list.size():
		return false
	
	track_list.remove_at(index)
	keyframe_removed.emit(track_type, index)
	if selected_keyframe_index == index:
		selected_keyframe_index = -1
	elif selected_keyframe_index > index:
		selected_keyframe_index -= 1
		
	_refresh_keyframe_list()
	_redraw_lanes()
	_update_viewport()
	return true

func get_keyframes(track_type: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if tracks.has(track_type):
		for item in tracks[track_type]:
			if item is Dictionary:
				result.append(item)
	return result

func get_keyframe(track_type: String, index: int) -> Dictionary:
	if tracks.has(track_type):
		var track_list: Array = tracks[track_type]
		if index >= 0 and index < track_list.size():
			return track_list[index]
	return {}

func set_keyframe(track_type: String, index: int, data: Dictionary) -> bool:
	if not tracks.has(track_type):
		return false
	var track_list: Array = tracks[track_type]
	if index < 0 or index >= track_list.size():
		return false
		
	var updated: Dictionary = _normalize_keyframe(track_type, data)
	track_list[index] = updated
	_sort_track(track_type)
	
	var new_idx: int = track_list.find(updated)
	keyframe_modified.emit(track_type, new_idx)
	_refresh_keyframe_list()
	_redraw_lanes()
	_update_viewport()
	return true

func get_keyframe_count(track_type: String) -> int:
	if tracks.has(track_type):
		return tracks[track_type].size()
	return 0

func clear_track(track_type: String) -> void:
	if tracks.has(track_type):
		tracks[track_type].clear()
		track_cleared.emit(track_type)
		selected_keyframe_index = -1
		_refresh_keyframe_list()
		_redraw_lanes()
		_update_viewport()

func clear_all_tracks() -> void:
	for t in ALL_TRACK_TYPES:
		tracks[t] = []
	selected_keyframe_index = -1
	_refresh_keyframe_list()
	_redraw_lanes()
	_update_viewport()

func _sort_track(track_type: String) -> void:
	if not tracks.has(track_type):
		return
	var track_list: Array = tracks[track_type]
	track_list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("time", 0.0)) < float(b.get("time", 0.0))
	)

func _normalize_keyframe(track_type: String, data: Dictionary) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	var t: float = float(result.get("time", current_time))
	result["time"] = clampf(t, 0.0, total_duration)
	
	match track_type:
		TRACK_CAMERA:
			if not result.has("pan_target"):
				result["pan_target"] = Vector2(400.0, 300.0)
			else:
				result["pan_target"] = _parse_vector2(result["pan_target"])
			result["zoom"] = float(result.get("zoom", 1.0))
			result["shake_intensity"] = float(result.get("shake_intensity", 0.0))
			result["shake_duration"] = float(result.get("shake_duration", 0.0))
			result["interpolation"] = str(result.get("interpolation", "Linear"))
		TRACK_ACTOR:
			result["actor_id"] = str(result.get("actor_id", "player"))
			result["actor_name"] = str(result.get("actor_name", "Player"))
			if not result.has("position"):
				result["position"] = Vector2(400.0, 300.0)
			else:
				result["position"] = _parse_vector2(result["position"])
			result["facing"] = int(result.get("facing", 0))
			result["action"] = str(result.get("action", "Idle"))
			result["visible"] = bool(result.get("visible", true))
			result["interpolation"] = str(result.get("interpolation", "Linear"))
		TRACK_DIALOGUE:
			result["duration"] = float(result.get("duration", 3.0))
			result["talk_id"] = int(result.get("talk_id", 0))
			result["speaker"] = str(result.get("speaker", "Speaker"))
			result["text"] = str(result.get("text", "Text..."))
			result["typewriter_delay"] = float(result.get("typewriter_delay", 0.03))
		TRACK_AUDIO:
			result["audio_type"] = str(result.get("audio_type", "BGM"))
			result["resource_id"] = str(result.get("resource_id", "BGM001.wav"))
			result["volume_db"] = float(result.get("volume_db", 0.0))
			result["pitch_scale"] = float(result.get("pitch_scale", 1.0))
			result["fade_time"] = float(result.get("fade_time", 0.0))
		TRACK_SCREEN_FX:
			result["duration"] = float(result.get("duration", 2.0))
			result["fx_type"] = str(result.get("fx_type", "FadeColor"))
			if not result.has("color"):
				result["color"] = Color.BLACK
			else:
				result["color"] = _parse_color(result["color"])
			result["intensity"] = float(result.get("intensity", 1.0))
			result["tilt_angle"] = float(result.get("tilt_angle", 0.0))
			result["pulse_frequency"] = float(result.get("pulse_frequency", 2.0))
			
	return result

# =========================================================================
# --- ACTOR ROSTER MANAGEMENT ---
# =========================================================================

func add_actor(actor_id: String, actor_name: String, initial_pos: Vector2 = Vector2(400, 300), initial_facing: int = 0, initial_action: String = "Idle") -> bool:
	if actor_id.is_empty():
		return false
	actors[actor_id] = {
		"id": actor_id,
		"name": actor_name,
		"initial_pos": initial_pos,
		"initial_facing": initial_facing,
		"initial_action": initial_action
	}
	actor_added.emit(actor_id)
	_update_viewport()
	return true

func remove_actor(actor_id: String) -> bool:
	if not actors.has(actor_id):
		return false
	actors.erase(actor_id)
	# Also remove keyframes for this actor
	var actor_keys: Array = tracks.get(TRACK_ACTOR, [])
	var remaining: Array = []
	for k in actor_keys:
		if str(k.get("actor_id", "")) != actor_id:
			remaining.append(k)
	tracks[TRACK_ACTOR] = remaining
	actor_removed.emit(actor_id)
	_refresh_keyframe_list()
	_redraw_lanes()
	_update_viewport()
	return true

func get_active_actors() -> Array[String]:
	var result: Array[String] = []
	for aid in actors.keys():
		result.append(str(aid))
	return result

func has_actor(actor_id: String) -> bool:
	return actors.has(actor_id)

func get_actor_info(actor_id: String) -> Dictionary:
	return actors.get(actor_id, {})

# =========================================================================
# --- STATE EVALUATION ENGINE ---
# =========================================================================

func evaluate_at_time(t: float) -> Dictionary:
	return {
		"time": t,
		"camera": _eval_camera(t),
		"actors": _eval_actors(t),
		"dialogue": _eval_dialogue(t),
		"audio": _eval_audio(t),
		"screen_fx": _eval_screen_fx(t)
	}

func _eval_camera(t: float) -> Dictionary:
	var cam_keys: Array = tracks.get(TRACK_CAMERA, [])
	if cam_keys.is_empty():
		return {
			"position": Vector2(400.0, 300.0),
			"zoom": 1.0,
			"shake_intensity": 0.0,
			"shake_offset": Vector2.ZERO
		}
	
	var pos: Vector2 = Vector2(400.0, 300.0)
	var zoom: float = 1.0
	
	if t <= float(cam_keys[0].get("time", 0.0)):
		pos = _parse_vector2(cam_keys[0].get("pan_target", Vector2(400, 300)))
		zoom = float(cam_keys[0].get("zoom", 1.0))
	elif t >= float(cam_keys[cam_keys.size() - 1].get("time", 0.0)):
		var last_k: Dictionary = cam_keys[cam_keys.size() - 1]
		pos = _parse_vector2(last_k.get("pan_target", Vector2(400, 300)))
		zoom = float(last_k.get("zoom", 1.0))
	else:
		for i in range(cam_keys.size() - 1):
			var k1: Dictionary = cam_keys[i]
			var k2: Dictionary = cam_keys[i + 1]
			var t1: float = float(k1.get("time", 0.0))
			var t2: float = float(k2.get("time", 0.0))
			if t >= t1 and t <= t2:
				var factor: float = (t - t1) / maxf(t2 - t1, 0.0001)
				var interp: String = str(k1.get("interpolation", "Linear"))
				factor = _apply_interp(factor, interp)
				var p1: Vector2 = _parse_vector2(k1.get("pan_target", Vector2(400, 300)))
				var p2: Vector2 = _parse_vector2(k2.get("pan_target", Vector2(400, 300)))
				pos = p1.lerp(p2, factor)
				var z1: float = float(k1.get("zoom", 1.0))
				var z2: float = float(k2.get("zoom", 1.0))
				zoom = lerpf(z1, z2, factor)
				break
	
	# Shake evaluation
	var total_shake: float = 0.0
	for k in cam_keys:
		var k_time: float = float(k.get("time", 0.0))
		var k_dur: float = float(k.get("shake_duration", 0.0))
		var k_int: float = float(k.get("shake_intensity", 0.0))
		if k_int > 0.0 and t >= k_time and t <= k_time + k_dur:
			var r: float = 1.0 - (t - k_time) / maxf(k_dur, 0.0001)
			total_shake = maxf(total_shake, k_int * r)
			
	var shake_offset: Vector2 = Vector2.ZERO
	if total_shake > 0.001:
		shake_offset = Vector2(
			sin(t * 43.7) * total_shake * 18.0,
			cos(t * 37.3) * total_shake * 14.0
		)
		
	return {
		"position": pos,
		"zoom": zoom,
		"shake_intensity": total_shake,
		"shake_offset": shake_offset
	}

func _eval_actors(t: float) -> Dictionary:
	var result: Dictionary = {}
	var actor_keys: Array = tracks.get(TRACK_ACTOR, [])
	
	# Initial states from roster
	for aid in actors.keys():
		var am: Dictionary = actors[aid]
		result[aid] = {
			"actor_id": aid,
			"actor_name": am.get("name", aid),
			"position": _parse_vector2(am.get("initial_pos", Vector2(400, 300))),
			"facing": int(am.get("initial_facing", 0)),
			"action": str(am.get("initial_action", "Idle")),
			"visible": true
		}
		
	# Group keyframes by actor
	var keys_by_actor: Dictionary = {}
	for k in actor_keys:
		var aid: String = str(k.get("actor_id", "player"))
		if not keys_by_actor.has(aid):
			keys_by_actor[aid] = []
		keys_by_actor[aid].append(k)
		
	for aid in keys_by_actor.keys():
		var a_keys: Array = keys_by_actor[aid]
		if a_keys.is_empty():
			continue
		
		if not result.has(aid):
			result[aid] = {
				"actor_id": aid,
				"actor_name": aid,
				"position": Vector2(400, 300),
				"facing": 0,
				"action": "Idle",
				"visible": true
			}
			
		if t <= float(a_keys[0].get("time", 0.0)):
			var k0: Dictionary = a_keys[0]
			result[aid]["position"] = _parse_vector2(k0.get("position", Vector2(400, 300)))
			result[aid]["facing"] = int(k0.get("facing", 0))
			result[aid]["action"] = str(k0.get("action", "Idle"))
			result[aid]["visible"] = bool(k0.get("visible", true))
		elif t >= float(a_keys[a_keys.size() - 1].get("time", 0.0)):
			var kn: Dictionary = a_keys[a_keys.size() - 1]
			result[aid]["position"] = _parse_vector2(kn.get("position", Vector2(400, 300)))
			result[aid]["facing"] = int(kn.get("facing", 0))
			result[aid]["action"] = str(kn.get("action", "Idle"))
			result[aid]["visible"] = bool(kn.get("visible", true))
		else:
			for i in range(a_keys.size() - 1):
				var k1: Dictionary = a_keys[i]
				var k2: Dictionary = a_keys[i + 1]
				var t1: float = float(k1.get("time", 0.0))
				var t2: float = float(k2.get("time", 0.0))
				if (t >= t1 and t < t2) or (i == a_keys.size() - 2 and t <= t2):
					var factor: float = (t - t1) / maxf(t2 - t1, 0.0001)
					var p1: Vector2 = _parse_vector2(k1.get("position", Vector2(400, 300)))
					var p2: Vector2 = _parse_vector2(k2.get("position", Vector2(400, 300)))
					result[aid]["position"] = p1.lerp(p2, factor)
					result[aid]["facing"] = int(k1.get("facing", 0))
					result[aid]["action"] = str(k1.get("action", "Idle"))
					result[aid]["visible"] = bool(k1.get("visible", true))
					break
					
	return result

func _eval_dialogue(t: float) -> Dictionary:
	var dlg_keys: Array = tracks.get(TRACK_DIALOGUE, [])
	for k in dlg_keys:
		var k_time: float = float(k.get("time", 0.0))
		var k_dur: float = float(k.get("duration", 3.0))
		if t >= k_time and t < k_time + k_dur:
			var full_txt: String = str(k.get("text", ""))
			var type_delay: float = float(k.get("typewriter_delay", 0.03))
			var visible_txt: String = full_txt
			if type_delay > 0.001:
				var chars_count: int = int((t - k_time) / type_delay)
				visible_txt = full_txt.substr(0, mini(chars_count, full_txt.length()))
				
			return {
				"is_active": true,
				"speaker": str(k.get("speaker", "")),
				"text": visible_txt,
				"full_text": full_txt,
				"talk_id": int(k.get("talk_id", 0)),
				"time": k_time,
				"duration": k_dur
			}
			
	return {
		"is_active": false,
		"speaker": "",
		"text": "",
		"full_text": "",
		"talk_id": 0,
		"time": 0.0,
		"duration": 0.0
	}

func _eval_audio(t: float) -> Dictionary:
	var aud_keys: Array = tracks.get(TRACK_AUDIO, [])
	var active_bgm: String = ""
	var volume_db: float = 0.0
	var pitch_scale: float = 1.0
	var triggers: Array[String] = []
	
	for k in aud_keys:
		var k_time: float = float(k.get("time", 0.0))
		var a_type: String = str(k.get("audio_type", "BGM"))
		var r_id: String = str(k.get("resource_id", ""))
		
		if a_type == "BGM" or a_type == "Ambient":
			if t >= k_time:
				active_bgm = r_id
				volume_db = float(k.get("volume_db", 0.0))
				pitch_scale = float(k.get("pitch_scale", 1.0))
		elif a_type == "SFX":
			if absf(t - k_time) <= 0.2:
				triggers.append(r_id)
				
	return {
		"bgm": active_bgm,
		"volume_db": volume_db,
		"pitch_scale": pitch_scale,
		"sfx_triggers": triggers
	}

func _eval_screen_fx(t: float) -> Dictionary:
	var fx_keys: Array = tracks.get(TRACK_SCREEN_FX, [])
	var fade_col: Color = Color(0, 0, 0, 0)
	var flash_col: Color = Color(1, 0, 0, 0)
	var tilt_ang: float = 0.0
	
	for k in fx_keys:
		var k_time: float = float(k.get("time", 0.0))
		var k_dur: float = float(k.get("duration", 2.0))
		if t >= k_time and t <= k_time + k_dur:
			var fx_type: String = str(k.get("fx_type", "None"))
			var intensity: float = float(k.get("intensity", 1.0))
			var progress: float = (t - k_time) / maxf(k_dur, 0.0001)
			
			if fx_type == "FadeColor":
				var c: Color = _parse_color(k.get("color", Color.BLACK))
				fade_col = Color(c.r, c.g, c.b, intensity * (1.0 - progress if progress > 0.8 else 1.0))
			elif fx_type == "Flash":
				var c: Color = _parse_color(k.get("color", Color.RED))
				var freq: float = float(k.get("pulse_frequency", 2.0))
				var pulse: float = maxf(0.0, sin((t - k_time) * freq * TAU))
				flash_col = Color(c.r, c.g, c.b, c.a * pulse * intensity)
			elif fx_type == "CameraTilt":
				var target_tilt: float = float(k.get("tilt_angle", 0.0))
				tilt_ang = lerpf(0.0, target_tilt, clampf(progress * 2.0, 0.0, 1.0))
			elif fx_type == "TintPulse":
				var c: Color = _parse_color(k.get("color", Color(0.2, 0.2, 0.4, 0.3)))
				var freq: float = float(k.get("pulse_frequency", 1.0))
				var pulse: float = 0.5 + 0.5 * sin((t - k_time) * freq * TAU)
				fade_col = Color(c.r, c.g, c.b, c.a * pulse * intensity)
				
	return {
		"fade_color": fade_col,
		"flash_color": flash_col,
		"tilt_angle": tilt_ang
	}

func _apply_interp(factor: float, interp: String) -> float:
	match interp:
		"EaseIn":
			return factor * factor
		"EaseOut":
			return 1.0 - (1.0 - factor) * (1.0 - factor)
		"EaseInOut":
			return smoothstep(0.0, 1.0, factor)
		"Step":
			return 0.0 if factor < 1.0 else 1.0
		_:
			return factor

# =========================================================================
# --- BUILT-IN PRESETS ---
# =========================================================================

func load_preset(preset_name: String) -> bool:
	if not PRESETS.has(preset_name):
		push_error("CutsceneEditor: Preset '%s' not found" % preset_name)
		return false
	
	var data: Dictionary = PRESETS[preset_name]
	cutscene_title = str(data.get("title", preset_name))
	set_total_duration(float(data.get("duration", 15.0)))
	background_preset = str(data.get("background", "Ship Deck"))
	
	# Clear & populate actors
	actors.clear()
	var preset_actors: Dictionary = data.get("actors", {})
	for aid in preset_actors.keys():
		var a: Dictionary = preset_actors[aid]
		add_actor(
			aid,
			str(a.get("name", aid)),
			_parse_vector2(a.get("initial_pos", Vector2(400, 300))),
			int(a.get("initial_facing", 0)),
			str(a.get("initial_action", "Idle"))
		)
		
	# Clear & populate tracks
	clear_all_tracks()
	var preset_tracks: Dictionary = data.get("tracks", {})
	for t in ALL_TRACK_TYPES:
		var k_list: Array = preset_tracks.get(t, [])
		for k in k_list:
			if k is Dictionary:
				add_keyframe(t, k)
				
	seek(0.0)
	preset_loaded.emit(preset_name)
	_refresh_ui()
	if status_readout:
		status_readout.text = "Loaded preset: %s" % preset_name
	return true

func get_preset_names() -> Array[String]:
	var names: Array[String] = []
	for k in PRESETS.keys():
		names.append(str(k))
	return names

func get_preset_data(preset_name: String) -> Dictionary:
	return PRESETS.get(preset_name, {})

# =========================================================================
# --- SERIALIZATION & EXPORT PIPELINE ---
# =========================================================================

func create_cutscene_data() -> Dictionary:
	var tracks_out: Dictionary = {}
	for t in ALL_TRACK_TYPES:
		var raw_keys: Array = tracks.get(t, [])
		var clean_keys: Array = []
		for k in raw_keys:
			var ck: Dictionary = k.duplicate(true)
			# Convert Vector2 and Color to serializable types
			if ck.has("pan_target") and ck["pan_target"] is Vector2:
				ck["pan_target"] = {"x": ck["pan_target"].x, "y": ck["pan_target"].y}
			if ck.has("position") and ck["position"] is Vector2:
				ck["position"] = {"x": ck["position"].x, "y": ck["position"].y}
			if ck.has("color") and ck["color"] is Color:
				ck["color"] = {"r": ck["color"].r, "g": ck["color"].g, "b": ck["color"].b, "a": ck["color"].a}
			clean_keys.append(ck)
		tracks_out[t] = clean_keys
	
	var actors_out: Dictionary = {}
	for aid in actors.keys():
		var a: Dictionary = actors[aid].duplicate(true)
		if a.has("initial_pos") and a["initial_pos"] is Vector2:
			a["initial_pos"] = {"x": a["initial_pos"].x, "y": a["initial_pos"].y}
		actors_out[aid] = a
		
	return {
		"title": cutscene_title,
		"total_duration": total_duration,
		"background": background_preset,
		"actors": actors_out,
		"tracks": tracks_out
	}

func save_cutscene_json(path: String = "") -> bool:
	var target_path: String = path
	if target_path.is_empty():
		var safe_name: String = cutscene_title.to_lower().replace(" ", "_").validate_node_name()
		target_path = CUSTOM_CUTSCENES_DIR + "%s.json" % safe_name
	
	var base_dir: String = target_path.get_base_dir()
	if not base_dir.is_empty() and not DirAccess.dir_exists_absolute(base_dir):
		DirAccess.make_dir_recursive_absolute(base_dir)
		
	var payload: Dictionary = create_cutscene_data()
	var json_str: String = JSON.stringify(payload, "\t")
	
	var file := FileAccess.open(target_path, FileAccess.WRITE)
	if not file:
		push_error("CutsceneEditor: Failed to write to %s" % target_path)
		return false
	
	file.store_string(json_str)
	file.close()
	cutscene_saved.emit(target_path)
	if status_readout:
		status_readout.text = "Cutscene JSON saved: %s" % target_path
	return true

func load_cutscene_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("CutsceneEditor: File not found: %s" % path)
		return {}
	
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("CutsceneEditor: Failed to read %s" % path)
		return {}
	
	var text: String = file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary):
		push_error("CutsceneEditor: Invalid JSON dictionary in %s" % path)
		return {}
	
	var data: Dictionary = parsed as Dictionary
	cutscene_title = str(data.get("title", "Imported Cutscene"))
	set_total_duration(float(data.get("total_duration", 15.0)))
	background_preset = str(data.get("background", "Ship Deck"))
	
	# Load actors
	actors.clear()
	var raw_actors: Dictionary = data.get("actors", {})
	for aid in raw_actors.keys():
		var a: Dictionary = raw_actors[aid]
		add_actor(
			aid,
			str(a.get("name", aid)),
			_parse_vector2(a.get("initial_pos", Vector2(400, 300))),
			int(a.get("initial_facing", 0)),
			str(a.get("initial_action", "Idle"))
		)
		
	# Load tracks
	clear_all_tracks()
	var raw_tracks: Dictionary = data.get("tracks", {})
	for t in ALL_TRACK_TYPES:
		var raw_keys: Array = raw_tracks.get(t, [])
		for k in raw_keys:
			if k is Dictionary:
				add_keyframe(t, k)
				
	seek(0.0)
	cutscene_loaded.emit(path)
	_refresh_ui()
	if status_readout:
		status_readout.text = "Cutscene loaded from JSON: %s" % path
	return data

func export_cutscene_scene(path: String) -> String:
	var target_path: String = path
	if target_path.is_empty():
		var safe_name: String = cutscene_title.to_lower().replace(" ", "_").validate_node_name()
		target_path = CUSTOM_CUTSCENES_DIR + "%s.tscn" % safe_name
	
	var base_dir: String = target_path.get_base_dir()
	if not base_dir.is_empty() and not DirAccess.dir_exists_absolute(base_dir):
		DirAccess.make_dir_recursive_absolute(base_dir)
		
	var scene_content: String = _generate_tscn_content()
	var file := FileAccess.open(target_path, FileAccess.WRITE)
	if not file:
		push_error("CutsceneEditor: Failed to export scene to %s" % target_path)
		return ""
		
	file.store_string(scene_content)
	file.close()
	scene_exported.emit(target_path)
	if status_readout:
		status_readout.text = "Cutscene scene exported: %s" % target_path
	return target_path

func _generate_tscn_content() -> String:
	var data: Dictionary = create_cutscene_data()
	var lines: PackedStringArray = []
	
	lines.append("[gd_scene load_steps=3 format=3 uid=\"uid://cutscene_event_%s\"]" % cutscene_title.to_lower().replace(" ", "_").validate_node_name())
	lines.append("")
	lines.append("[ext_resource type=\"Script\" path=\"res://scripts/events/cutscene_runner.gd\" id=\"1_runner\"]")
	lines.append("")
	
	var safe_root: String = cutscene_title.replace(" ", "").validate_node_name()
	if safe_root.is_empty():
		safe_root = "CutsceneSequence"
	lines.append("[node name=\"%s\" type=\"Node2D\"]" % safe_root)
	lines.append("script = ExtResource(\"1_runner\")")
	lines.append("total_duration = %.2f" % total_duration)
	lines.append("metadata/cutscene_data = %s" % var_to_str(data))
	lines.append("")
	
	# Camera2D
	lines.append("[node name=\"Camera2D\" type=\"Camera2D\" parent=\".\"]")
	lines.append("position = Vector2(400, 300)")
	lines.append("zoom = Vector2(1, 1)")
	lines.append("position_smoothing_enabled = true")
	lines.append("")
	
	# Actors container
	lines.append("[node name=\"Actors\" type=\"Node2D\" parent=\".\"]")
	lines.append("")
	for aid in actors.keys():
		var a: Dictionary = actors[aid]
		var safe_aid: String = aid.validate_node_name()
		var p: Vector2 = a.get("initial_pos", Vector2(400, 300))
		lines.append("[node name=\"%s\" type=\"Node2D\" parent=\"Actors\"]" % safe_aid)
		lines.append("position = Vector2(%.1f, %.1f)" % [p.x, p.y])
		lines.append("metadata/actor_id = \"%s\"" % aid)
		lines.append("metadata/actor_name = \"%s\"" % str(a.get("name", aid)))
		lines.append("metadata/facing = %d" % int(a.get("initial_facing", 0)))
		lines.append("metadata/action = \"%s\"" % str(a.get("initial_action", "Idle")))
		lines.append("")
		
		# Name Label inside actor
		lines.append("[node name=\"Label\" type=\"Label\" parent=\"Actors/%s\"]" % safe_aid)
		lines.append("offset_left = -50.0")
		lines.append("offset_top = -36.0")
		lines.append("offset_right = 50.0")
		lines.append("offset_bottom = -13.0")
		lines.append("text = \"%s\"" % str(a.get("name", aid)))
		lines.append("horizontal_alignment = 1")
		lines.append("")
		
	# Screen FX Layer
	lines.append("[node name=\"ScreenFX\" type=\"CanvasLayer\" parent=\".\"]")
	lines.append("")
	lines.append("[node name=\"FadeRect\" type=\"ColorRect\" parent=\"ScreenFX\"]")
	lines.append("anchors_preset = 15")
	lines.append("anchor_right = 1.0")
	lines.append("anchor_bottom = 1.0")
	lines.append("color = Color(0, 0, 0, 0)")
	lines.append("")
	lines.append("[node name=\"FlashRect\" type=\"ColorRect\" parent=\"ScreenFX\"]")
	lines.append("anchors_preset = 15")
	lines.append("anchor_right = 1.0")
	lines.append("anchor_bottom = 1.0")
	lines.append("color = Color(1, 0, 0, 0)")
	lines.append("")
	
	# Dialogue Layer
	lines.append("[node name=\"Dialogue\" type=\"CanvasLayer\" parent=\".\"]")
	lines.append("")
	lines.append("[node name=\"DialogueBox\" type=\"PanelContainer\" parent=\"Dialogue\"]")
	lines.append("visible = false")
	lines.append("anchors_preset = 12")
	lines.append("anchor_top = 1.0")
	lines.append("anchor_right = 1.0")
	lines.append("anchor_bottom = 1.0")
	lines.append("offset_left = 30.0")
	lines.append("offset_top = -90.0")
	lines.append("offset_right = -30.0")
	lines.append("offset_bottom = -15.0")
	lines.append("")
	lines.append("[node name=\"Margin\" type=\"MarginContainer\" parent=\"Dialogue/DialogueBox\"]")
	lines.append("theme_override_constants/margin_left = 10")
	lines.append("theme_override_constants/margin_top = 6")
	lines.append("theme_override_constants/margin_right = 10")
	lines.append("theme_override_constants/margin_bottom = 6")
	lines.append("")
	lines.append("[node name=\"VBox\" type=\"VBoxContainer\" parent=\"Dialogue/DialogueBox/Margin\"]")
	lines.append("")
	lines.append("[node name=\"SpeakerLabel\" type=\"Label\" parent=\"Dialogue/DialogueBox/Margin/VBox\"]")
	lines.append("text = \"Speaker\"")
	lines.append("")
	lines.append("[node name=\"TextLabel\" type=\"Label\" parent=\"Dialogue/DialogueBox/Margin/VBox\"]")
	lines.append("text = \"Dialogue text...\"")
	lines.append("autowrap_mode = 2")
	lines.append("")
	
	# Audio Players
	lines.append("[node name=\"Audio\" type=\"Node\" parent=\".\"]")
	lines.append("")
	lines.append("[node name=\"AudioBGM\" type=\"AudioStreamPlayer\" parent=\"Audio\"]")
	lines.append("")
	lines.append("[node name=\"AudioSFX\" type=\"AudioStreamPlayer\" parent=\"Audio\"]")
	lines.append("")
	
	return "\n".join(lines)

# =========================================================================
# --- LIVE VIEWPORT PREVIEW CANVAS ---
# =========================================================================

func _update_viewport() -> void:
	if viewport_canvas:
		viewport_canvas.queue_redraw()
	if state_readout:
		var st: Dictionary = evaluate_at_time(current_time)
		var cam: Dictionary = st.get("camera", {})
		var fx: Dictionary = st.get("screen_fx", {})
		var dlg: Dictionary = st.get("dialogue", {})
		var p: Vector2 = cam.get("position", Vector2.ZERO)
		state_readout.text = "Cam: (%.0f, %.0f) Z: %.2f | Tilt: %.1f deg | Dlg: %s" % [
			p.x, p.y, float(cam.get("zoom", 1.0)),
			float(fx.get("tilt_angle", 0.0)),
			"Active" if bool(dlg.get("is_active", false)) else "None"
		]

func _on_viewport_canvas_draw() -> void:
	if not viewport_canvas:
		return
	draw_preview(viewport_canvas)

func draw_preview(canvas: Control) -> void:
	var sz: Vector2 = canvas.size
	var state: Dictionary = evaluate_at_time(current_time)
	var cam: Dictionary = state.get("camera", {})
	var cam_pos: Vector2 = cam.get("position", Vector2(400, 300))
	var zoom: float = float(cam.get("zoom", 1.0))
	var shake: Vector2 = cam.get("shake_offset", Vector2.ZERO)
	var tilt_deg: float = float(state.get("screen_fx", {}).get("tilt_angle", 0.0))
	
	# 1. Background
	_draw_preview_background(canvas, sz)
	
	# 2. Actors
	var center: Vector2 = sz * 0.5
	var actors_state: Dictionary = state.get("actors", {})
	for aid in actors_state.keys():
		var a: Dictionary = actors_state[aid]
		if not bool(a.get("visible", true)):
			continue
		
		var world_pos: Vector2 = a.get("position", Vector2(400, 300))
		# Transform from world space to preview canvas space
		var screen_pos: Vector2 = (world_pos - cam_pos) * zoom + center + shake
		
		# Skip offscreen
		if screen_pos.x < -60.0 or screen_pos.x > sz.x + 60.0 or screen_pos.y < -60.0 or screen_pos.y > sz.y + 60.0:
			continue
			
		_draw_preview_actor(canvas, screen_pos, a, zoom)
	
	# 3. Screen FX (Fade and Flash)
	var fx: Dictionary = state.get("screen_fx", {})
	var fade_c: Color = fx.get("fade_color", Color(0, 0, 0, 0))
	if fade_c.a > 0.01:
		canvas.draw_rect(Rect2(Vector2.ZERO, sz), fade_c)
		
	var flash_c: Color = fx.get("flash_color", Color(1, 0, 0, 0))
	if flash_c.a > 0.01:
		canvas.draw_rect(Rect2(Vector2.ZERO, sz), flash_c)
		
	# 4. Dialogue Box Overlay
	var dlg: Dictionary = state.get("dialogue", {})
	if bool(dlg.get("is_active", false)):
		_draw_preview_dialogue(canvas, sz, dlg)
		
	# 5. Framing border and camera info HUD
	canvas.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.25, 0.38, 0.55, 0.8), false, 2.0)
	var info_str: String = "T: %05.2fs | Cam: (%.0f, %.0f) Zoom: %.2fx | Shake: %.2f | Tilt: %.1f deg" % [
		current_time, cam_pos.x, cam_pos.y, zoom, float(cam.get("shake_intensity", 0.0)), tilt_deg
	]
	canvas.draw_string(ThemeDB.fallback_font, Vector2(10.0, 18.0), info_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.85, 0.9, 0.95, 0.9))

func _draw_preview_background(canvas: Control, sz: Vector2) -> void:
	match background_preset:
		"Ship Deck":
			# Dark nautical wood planks
			canvas.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.18, 0.13, 0.09, 1.0))
			for y in range(0, int(sz.y), 24):
				canvas.draw_line(Vector2(0, y), Vector2(sz.x, y), Color(0.12, 0.09, 0.06, 0.8), 1.0)
			# Ship railings
			canvas.draw_line(Vector2(0, 30), Vector2(sz.x, 30), Color(0.35, 0.25, 0.15, 0.9), 3.0)
			canvas.draw_line(Vector2(0, 40), Vector2(sz.x, 40), Color(0.25, 0.18, 0.10, 0.7), 2.0)
		"Beach Shore":
			# Sea water gradient to sand
			canvas.draw_rect(Rect2(Vector2.ZERO, Vector2(sz.x, sz.y * 0.45)), Color(0.1, 0.28, 0.45, 1.0))
			canvas.draw_rect(Rect2(Vector2(0, sz.y * 0.45), Vector2(sz.x, sz.y * 0.55)), Color(0.78, 0.68, 0.45, 1.0))
			# Foam wave line
			canvas.draw_line(Vector2(0, sz.y * 0.45), Vector2(sz.x, sz.y * 0.45), Color(0.85, 0.95, 1.0, 0.8), 3.0)
		"Cavern":
			# Dark subterranean rock
			canvas.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.08, 0.09, 0.12, 1.0))
			for i in range(8):
				var px: float = i * (sz.x / 8.0) + 20.0
				canvas.draw_line(Vector2(px, 0), Vector2(px + 15, 35), Color(0.2, 0.22, 0.26, 0.9), 3.0)
		"Ocean Waves":
			canvas.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.06, 0.15, 0.28, 1.0))
			for y in range(20, int(sz.y), 32):
				var offset_wave: float = sin(current_time * 2.0 + y) * 12.0
				canvas.draw_line(Vector2(0, y + offset_wave), Vector2(sz.x, y - offset_wave), Color(0.15, 0.35, 0.55, 0.6), 2.0)
		_:
			# Axonometric Grid
			canvas.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.05, 0.07, 0.1, 1.0))
			for x in range(0, int(sz.x), 48):
				canvas.draw_line(Vector2(x, 0), Vector2(x + 24, sz.y), Color(0.15, 0.22, 0.3, 0.4), 1.0)
				canvas.draw_line(Vector2(x, 0), Vector2(x - 24, sz.y), Color(0.15, 0.22, 0.3, 0.4), 1.0)

func _draw_preview_actor(canvas: Control, pos: Vector2, a_data: Dictionary, zoom: float) -> void:
	var aid: String = str(a_data.get("actor_id", "player"))
	var a_name: String = str(a_data.get("actor_name", aid))
	var action: String = str(a_data.get("action", "Idle"))
	var facing: int = int(a_data.get("facing", 0))
	
	# Determine color theme by actor role
	var base_col: Color = Color(0.2, 0.6, 0.9, 1.0) # Player default blue
	if aid.begins_with("captain"):
		base_col = Color(0.9, 0.3, 0.2, 1.0)
	elif aid.begins_with("crew"):
		base_col = Color(0.95, 0.6, 0.15, 1.0)
	elif aid.begins_with("kelang"):
		base_col = Color(0.25, 0.85, 0.45, 1.0)
	elif aid.begins_with("bat") or aid.begins_with("slime") or aid.begins_with("monster"):
		base_col = Color(0.75, 0.25, 0.85, 1.0)
	
	var r: float = 14.0 * zoom
	
	# Draw shadow
	canvas.draw_circle(pos + Vector2(0, r * 0.7), r * 0.9, Color(0, 0, 0, 0.35))
	
	if action == "Prone":
		# Lying horizontally flat
		canvas.draw_rect(Rect2(pos - Vector2(r * 1.5, r * 0.4), Vector2(r * 3.0, r * 0.8)), base_col, true)
		canvas.draw_rect(Rect2(pos - Vector2(r * 1.5, r * 0.4), Vector2(r * 3.0, r * 0.8)), Color.WHITE, false, 1.5)
	else:
		# Upright circle standee
		canvas.draw_circle(pos, r, base_col)
		canvas.draw_circle(pos, r, Color.WHITE, false, 1.5)
		
		# Facing vector arrow
		var facing_dirs: Array[Vector2] = [
			Vector2(0, 1),
			Vector2(-0.7, 0.7),
			Vector2(-1, 0),
			Vector2(-0.7, -0.7),
			Vector2(0, -1),
			Vector2(0.7, -0.7),
			Vector2(1, 0),
			Vector2(0.7, 0.7)
		]
		var dir: Vector2 = facing_dirs[facing % 8]
		var arrow_tip: Vector2 = pos + dir * (r + 7.0 * zoom)
		canvas.draw_line(pos, arrow_tip, Color.YELLOW, 2.0)
		canvas.draw_circle(arrow_tip, 3.0 * zoom, Color.YELLOW)
		
		if action == "Attack":
			# Red attack slash halo
			canvas.draw_arc(pos, r + 5.0, 0.0, TAU, 16, Color(1, 0.2, 0.2, 0.8), 2.0)
		elif action == "Pose":
			# Gold star aura
			canvas.draw_arc(pos, r + 4.0, 0.0, TAU, 16, Color(1, 0.85, 0.2, 0.8), 2.0)
	
	# Name & Action tag
	var tag_str: String = "%s [%s]" % [a_name, action]
	var font_sz: int = 10
	var text_w: float = ThemeDB.fallback_font.get_string_size(tag_str, HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz).x
	var tag_rect: Rect2 = Rect2(pos.x - text_w * 0.5 - 4.0, pos.y - r - 18.0, text_w + 8.0, 14.0)
	canvas.draw_rect(tag_rect, Color(0.06, 0.08, 0.12, 0.85))
	canvas.draw_rect(tag_rect, Color(0.3, 0.45, 0.65, 0.8), false, 1.0)
	canvas.draw_string(ThemeDB.fallback_font, Vector2(pos.x - text_w * 0.5, pos.y - r - 7.0), tag_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_sz, Color.WHITE)

func _draw_preview_dialogue(canvas: Control, sz: Vector2, dlg: Dictionary) -> void:
	var box_w: float = sz.x - 32.0
	var box_h: float = 64.0
	var box_rect: Rect2 = Rect2(16.0, sz.y - box_h - 12.0, box_w, box_h)
	
	# Background
	canvas.draw_rect(box_rect, Color(0.05, 0.08, 0.14, 0.92))
	canvas.draw_rect(box_rect, Color(0.85, 0.72, 0.28, 0.9), false, 1.5)
	
	# Speaker header
	var spk: String = str(dlg.get("speaker", "Speaker"))
	canvas.draw_string(ThemeDB.fallback_font, Vector2(28.0, sz.y - box_h + 6.0), spk, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.84, 0.3, 1.0))
	canvas.draw_line(Vector2(28.0, sz.y - box_h + 10.0), Vector2(box_w, sz.y - box_h + 10.0), Color(0.4, 0.35, 0.2, 0.6), 1.0)
	
	# Text with typewriter cursor
	var txt: String = str(dlg.get("text", "")) + "_"
	canvas.draw_string(ThemeDB.fallback_font, Vector2(28.0, sz.y - box_h + 28.0), txt, HORIZONTAL_ALIGNMENT_LEFT, box_w - 24.0, 11, Color(0.95, 0.95, 0.95, 1.0))

# =========================================================================
# --- TIMELINE TRACK LANES DRAWING ---
# =========================================================================

func _draw_lane(lane: Control, t_type: String, accent_color: Color) -> void:
	var sz: Vector2 = lane.size
	# Dark background
	lane.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.08, 0.11, 0.16, 0.95))
	lane.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.18, 0.24, 0.35, 0.6), false, 1.0)
	
	# Draw keyframe markers
	var key_list: Array = tracks.get(t_type, [])
	for i in range(key_list.size()):
		var k: Dictionary = key_list[i]
		var k_time: float = float(k.get("time", 0.0))
		var x: float = (k_time / total_duration) * sz.x
		
		# Diamond marker
		var is_selected: bool = (selected_track == t_type and selected_keyframe_index == i)
		var mk_col: Color = Color.WHITE if is_selected else accent_color
		var r: float = 5.0 if is_selected else 4.0
		var points: PackedVector2Array = PackedVector2Array([
			Vector2(x, sz.y * 0.5 - r),
			Vector2(x + r, sz.y * 0.5),
			Vector2(x, sz.y * 0.5 + r),
			Vector2(x - r, sz.y * 0.5)
		])
		lane.draw_colored_polygon(points, mk_col)
		lane.draw_polyline(points, Color.BLACK, 1.0)
		
	# Draw scrubber head line
	var cur_x: float = (current_time / total_duration) * sz.x
	lane.draw_line(Vector2(cur_x, 0), Vector2(cur_x, sz.y), Color(1.0, 0.9, 0.3, 0.9), 1.5)

func _on_lane_gui_input(event: InputEvent, lane: Control, t_type: String) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var ratio: float = clampf(mb.position.x / maxf(lane.size.x, 1.0), 0.0, 1.0)
			var target_t: float = ratio * total_duration
			seek(target_t)
			
			# Check if clicked close to an existing keyframe
			selected_track = t_type
			_select_keyframe_near_time(t_type, target_t)
			_refresh_keyframe_list()

func _select_keyframe_near_time(t_type: String, t: float) -> void:
	var key_list: Array = tracks.get(t_type, [])
	var best_idx: int = -1
	var best_dist: float = 0.4 # Seconds threshold
	for i in range(key_list.size()):
		var k: Dictionary = key_list[i]
		var kt: float = float(k.get("time", 0.0))
		var d: float = absf(kt - t)
		if d < best_dist:
			best_dist = d
			best_idx = i
			
	selected_keyframe_index = best_idx
	if selected_keyframe_index != -1 and keyframe_item_list:
		keyframe_item_list.select(selected_keyframe_index)
	_sync_inspector_fields()

func _redraw_lanes() -> void:
	if camera_lane:
		camera_lane.queue_redraw()
	if actor_lane:
		actor_lane.queue_redraw()
	if dialogue_lane:
		dialogue_lane.queue_redraw()
	if audio_lane:
		audio_lane.queue_redraw()
	if screen_fx_lane:
		screen_fx_lane.queue_redraw()

# =========================================================================
# --- UI SYNC & INSPECTOR METHODS ---
# =========================================================================

func _refresh_ui() -> void:
	if title_edit:
		title_edit.text = cutscene_title
	if duration_spin:
		duration_spin.value = total_duration
	if time_slider:
		time_slider.max_value = total_duration
		time_slider.value = current_time
	_update_scrubber_display()
	_refresh_keyframe_list()
	_sync_inspector_fields()
	_redraw_lanes()
	_update_viewport()

func _update_scrubber_display() -> void:
	if time_slider and not is_playing:
		time_slider.value = current_time
	if time_label:
		time_label.text = "%05.2fs / %05.2fs" % [current_time, total_duration]
	if frame_label:
		frame_label.text = "Frame: %d" % int(current_time * DEFAULT_FPS)

func _refresh_keyframe_list() -> void:
	if not keyframe_item_list:
		return
	keyframe_item_list.clear()
	var key_list: Array = tracks.get(selected_track, [])
	for i in range(key_list.size()):
		var k: Dictionary = key_list[i]
		var kt: float = float(k.get("time", 0.0))
		var summary: String = "[%05.2fs] " % kt
		
		match selected_track:
			TRACK_CAMERA:
				var p: Vector2 = _parse_vector2(k.get("pan_target", Vector2.ZERO))
				summary += "Pan (%.0f, %.0f) Z: %.1f Shake: %.1f" % [p.x, p.y, float(k.get("zoom", 1.0)), float(k.get("shake_intensity", 0.0))]
			TRACK_ACTOR:
				summary += "%s: %s @ (%.0f, %.0f) F:%d" % [
					str(k.get("actor_id", "player")),
					str(k.get("action", "Idle")),
					_parse_vector2(k.get("position", Vector2.ZERO)).x,
					_parse_vector2(k.get("position", Vector2.ZERO)).y,
					int(k.get("facing", 0))
				]
			TRACK_DIALOGUE:
				summary += "%s: '%s'" % [str(k.get("speaker", "Speaker")), str(k.get("text", "")).substr(0, 18)]
			TRACK_AUDIO:
				summary += "%s: %s (%.1fdB)" % [str(k.get("audio_type", "BGM")), str(k.get("resource_id", "")), float(k.get("volume_db", 0.0))]
			TRACK_SCREEN_FX:
				summary += "%s: Dur %.1fs (Int: %.1f)" % [str(k.get("fx_type", "FadeColor")), float(k.get("duration", 2.0)), float(k.get("intensity", 1.0))]
				
		keyframe_item_list.add_item(summary)
		
	if selected_keyframe_index >= 0 and selected_keyframe_index < key_list.size():
		keyframe_item_list.select(selected_keyframe_index)

func _sync_inspector_fields() -> void:
	var k: Dictionary = get_keyframe(selected_track, selected_keyframe_index)
	var has_key: bool = not k.is_empty()
	
	if key_time_spin:
		key_time_spin.editable = has_key
		key_time_spin.value = float(k.get("time", current_time)) if has_key else current_time
		
	if prop_camera_box:
		prop_camera_box.visible = (selected_track == TRACK_CAMERA)
	if prop_actor_box:
		prop_actor_box.visible = (selected_track == TRACK_ACTOR)
	if prop_dialogue_box:
		prop_dialogue_box.visible = (selected_track == TRACK_DIALOGUE)
	if prop_audio_box:
		prop_audio_box.visible = (selected_track == TRACK_AUDIO)
	if prop_screen_fx_box:
		prop_screen_fx_box.visible = (selected_track == TRACK_SCREEN_FX)

# =========================================================================
# --- UI EVENT HANDLERS ---
# =========================================================================

func _on_btn_load_preset_pressed() -> void:
	if not preset_option:
		return
	var pname: String = preset_option.get_item_text(preset_option.selected)
	load_preset(pname)

func _on_btn_new_pressed() -> void:
	cutscene_title = "New Cutscene"
	set_total_duration(15.0)
	clear_all_tracks()
	actors.clear()
	add_actor("player", "Player", Vector2(400, 300), 0, "Idle")
	seek(0.0)
	_refresh_ui()

func _on_btn_save_json_pressed() -> void:
	save_cutscene_json()

func _on_btn_load_json_pressed() -> void:
	var safe_name: String = cutscene_title.to_lower().replace(" ", "_").validate_node_name()
	var default_path: String = CUSTOM_CUTSCENES_DIR + "%s.json" % safe_name
	load_cutscene_json(default_path)

func _on_btn_export_scene_pressed() -> void:
	var safe_name: String = cutscene_title.to_lower().replace(" ", "_").validate_node_name()
	var default_path: String = CUSTOM_CUTSCENES_DIR + "%s.tscn" % safe_name
	export_cutscene_scene(default_path)

func _on_time_scale_selected(index: int) -> void:
	match index:
		0:
			set_time_scale(0.5)
		1:
			set_time_scale(1.0)
		2:
			set_time_scale(2.0)

func _on_title_text_changed(new_text: String) -> void:
	cutscene_title = new_text

func _on_track_selected_from_option(index: int) -> void:
	if index >= 0 and index < ALL_TRACK_TYPES.size():
		selected_track = ALL_TRACK_TYPES[index]
		selected_keyframe_index = -1
		_refresh_keyframe_list()
		_sync_inspector_fields()
		_redraw_lanes()

func _on_keyframe_item_selected(index: int) -> void:
	selected_keyframe_index = index
	var k: Dictionary = get_keyframe(selected_track, selected_keyframe_index)
	if not k.is_empty():
		seek(float(k.get("time", current_time)))
	_sync_inspector_fields()
	_redraw_lanes()

func _on_btn_add_keyframe_pressed() -> void:
	var new_k: Dictionary = {"time": current_time}
	match selected_track:
		TRACK_CAMERA:
			new_k["pan_target"] = Vector2(400, 300)
			new_k["zoom"] = 1.0
			new_k["shake_intensity"] = 0.0
			new_k["shake_duration"] = 0.0
		TRACK_ACTOR:
			var act_id: String = actors.keys()[0] if not actors.is_empty() else "player"
			new_k["actor_id"] = act_id
			new_k["actor_name"] = actors.get(act_id, {}).get("name", "Player")
			new_k["position"] = Vector2(400, 300)
			new_k["facing"] = 0
			new_k["action"] = "Idle"
			new_k["visible"] = true
		TRACK_DIALOGUE:
			new_k["duration"] = 3.0
			new_k["speaker"] = "Player"
			new_k["text"] = "New dialogue..."
			new_k["typewriter_delay"] = 0.03
		TRACK_AUDIO:
			new_k["audio_type"] = "SFX"
			new_k["resource_id"] = "SEB001.wav"
			new_k["volume_db"] = 0.0
			new_k["pitch_scale"] = 1.0
		TRACK_SCREEN_FX:
			new_k["duration"] = 2.0
			new_k["fx_type"] = "Flash"
			new_k["color"] = Color.RED
			new_k["intensity"] = 0.5
			
	var idx: int = add_keyframe(selected_track, new_k)
	selected_keyframe_index = idx

func _on_btn_remove_keyframe_pressed() -> void:
	if selected_keyframe_index >= 0:
		remove_keyframe(selected_track, selected_keyframe_index)

func _on_btn_clear_track_pressed() -> void:
	clear_track(selected_track)

# Helper parsers
func _parse_vector2(val: Variant) -> Vector2:
	if val is Vector2:
		return val
	if val is Dictionary:
		return Vector2(float(val.get("x", 0.0)), float(val.get("y", 0.0)))
	if val is Array and val.size() >= 2:
		return Vector2(float(val[0]), float(val[1]))
	return Vector2.ZERO

func _parse_color(val: Variant) -> Color:
	if val is Color:
		return val
	if val is String:
		return Color.from_string(val, Color.BLACK)
	if val is Dictionary:
		return Color(
			float(val.get("r", 0.0)),
			float(val.get("g", 0.0)),
			float(val.get("b", 0.0)),
			float(val.get("a", 1.0))
		)
	if val is Array and val.size() >= 4:
		return Color(float(val[0]), float(val[1]), float(val[2]), float(val[3]))
	return Color.BLACK
