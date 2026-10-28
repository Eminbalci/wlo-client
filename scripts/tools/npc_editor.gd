class_name NpcEditor
extends Control

## Wonderland Online NPC Creator & Editing Tool
## Production-ready, strictly type-hinted visual editor for authoring, previewing,
## testing, and exporting NPC entities with authentic JMA / JMP animations, 
## Talk.dat dialogue integration, portrait bust previews, and patrol waypoints.

signal preset_loaded(preset_name: String)
signal npc_exported(file_path: String)
signal npc_created(entity: NpcEntity)
signal preview_updated()

const IsometricMath = preload("res://scripts/map/isometric_math.gd")
const CUSTOM_PRESETS_PATH: String = "user://custom_npcs.json"

enum PreviewStance {
	STAND = 0,
	WALK = 1,
	BATTLE_READY = 2,
	ATTACK = 3,
	DEFEND = 4,
	SIT = 5,
	KNOCKOUT = 6,
	VICTORY = 7,
	MANUAL = 8
}

const STANCE_NAMES: Dictionary = {
	PreviewStance.STAND: "Stand / Idle",
	PreviewStance.WALK: "Walk (Moving)",
	PreviewStance.BATTLE_READY: "Battle Ready (Combat)",
	PreviewStance.ATTACK: "Attack / Strike (Skill Action)",
	PreviewStance.DEFEND: "Defend / Hurt (Combat Recoil)",
	PreviewStance.SIT: "Sit / Rest",
	PreviewStance.KNOCKOUT: "Knockout / Prone (Defeat)",
	PreviewStance.VICTORY: "Victory Cheer (Emote)",
	PreviewStance.MANUAL: "Manual Frame Scrubber"
}

const COMMON_JMPS: Array[Dictionary] = [
	{"name": "1038.jmp - Captain Robinson (32f)", "file": "1038.jmp", "archive": "001.jma"},
	{"name": "1010.jmp - Sailor Jack (140f Combat)", "file": "1010.jmp", "archive": "001.jma"},
	{"name": "1068.jmp - Natasha (140f Combat)", "file": "1068.jmp", "archive": "001.jma"},
	{"name": "1131.jmp - Kelan Leader (78f Combat)", "file": "1131.jmp", "archive": "001.jma"},
	{"name": "1144.jmp - Chef (140f Combat)", "file": "1144.jmp", "archive": "001.jma"},
	{"name": "1223.jmp - Niss (140f Combat)", "file": "1223.jmp", "archive": "001.jma"},
	{"name": "1221.jmp - Roca (140f Combat)", "file": "1221.jmp", "archive": "001.jma"},
	{"name": "1155.jmp - Clive (140f Combat)", "file": "1155.jmp", "archive": "001.jma"},
	{"name": "4000.jmp - Daniel Role 6 (216f Full Combat)", "file": "4000.jmp", "archive": "004.jma"},
	{"name": "3000.jmp - Betty Role 2 (216f Full Combat)", "file": "3000.jmp", "archive": "003.jma"},
	{"name": "2000.jmp - Nina Role 1 (216f Full Combat)", "file": "2000.jmp", "archive": "002.jma"},
	{"name": "1050.jmp - Traveling Merchant (4f)", "file": "1050.jmp", "archive": "001.jma"},
	{"name": "1207.jmp - Ross (8f)", "file": "1207.jmp", "archive": "001.jma"},
	{"name": "1037.jmp - Deck Crew (32f)", "file": "1037.jmp", "archive": "001.jma"},
	{"name": "11000.jmp - Persian Cat", "file": "11000.jmp", "archive": "001.jma"},
	{"name": "8025.jmp - Captain Avatar / Bust", "file": "8025.jmp", "archive": "008.jma"},
	{"name": "Custom...", "file": "", "archive": "001.jma"}
]

const COMMON_PORTRAITS: Array[Dictionary] = [
	{"name": "8025 - Captain Robinson", "id": 8025},
	{"name": "8004 - Rocco / Sailor Jack", "id": 8004},
	{"name": "8005 - Ross", "id": 8005},
	{"name": "8021 - Chef", "id": 8021},
	{"name": "8083 - Natasha", "id": 8083},
	{"name": "8038 - Kelan Leader", "id": 8038},
	{"name": "8017 - Traveling Merchant", "id": 8017},
	{"name": "8091 - Niss", "id": 8091},
	{"name": "8090 - Roca", "id": 8090},
	{"name": "8065 - Clive", "id": 8065},
	{"name": "8011 - Jack / Crew", "id": 8011},
	{"name": "0 - None / Default", "id": 0}
]

const COMMON_MAPS: Array[Dictionary] = [
	{"name": "10001 - Ship Deck (S.S. Victoria)", "id": 10001},
	{"name": "10002 - Ship Cabin", "id": 10002},
	{"name": "10003 - Gangway to Island", "id": 10003},
	{"name": "10011 - North Island Beach", "id": 10011},
	{"name": "10012 - North Island Forest", "id": 10012},
	{"name": "10013 - Kelan Village", "id": 10013}
]

const HEADING_NAMES: Dictionary = {
	IsometricMath.Heading.NORTH: "North (0)",
	IsometricMath.Heading.NORTH_WEST: "North-West (1)",
	IsometricMath.Heading.WEST: "West (2)",
	IsometricMath.Heading.SOUTH_WEST: "South-West (3)",
	IsometricMath.Heading.SOUTH: "South (4)",
	IsometricMath.Heading.SOUTH_EAST: "South-East (5)",
	IsometricMath.Heading.EAST: "East (6)",
	IsometricMath.Heading.NORTH_EAST: "North-East (7)"
}

const BUILTIN_PRESETS: Dictionary = {
	"Captain Robinson": {
		"npc_id": 14003,
		"npc_name": "Captain Robinson",
		"model_jmp": "1038.jmp",
		"model_jma": "001.jma",
		"talk_image": 8025,
		"talk_id": 30124,
		"map_id": 10001,
		"spawn_pos": Vector2(1421.0, 632.0),
		"heading": IsometricMath.Heading.SOUTH_WEST,
		"move_speed": 60.0,
		"dialogue_text": "Welcome aboard the ship! I am the Captain. We are setting sail for North Island soon. Make sure you are prepared!",
		"dialogue_choices": ["I am ready!", "Tell me more about North Island."],
		"walksteps": [],
		"walkstep_delays": []
	},
	"Kelan Leader": {
		"npc_id": 14062,
		"npc_name": "Kelan Leader",
		"model_jmp": "1131.jmp",
		"model_jma": "001.jma",
		"talk_image": 8038,
		"talk_id": 10062,
		"map_id": 10011,
		"spawn_pos": Vector2(620.0, 1140.0),
		"heading": IsometricMath.Heading.SOUTH,
		"move_speed": 60.0,
		"dialogue_text": "Greetings, traveler! Welcome to North Island. I am the leader of Kelan Village. Be wary of wild beasts outside the village gates.",
		"dialogue_choices": ["Thank you, elder.", "Where can I buy supplies?"],
		"walksteps": [],
		"walkstep_delays": []
	},
	"Sailor Jack": {
		"npc_id": 14091,
		"npc_name": "Sailor Jack",
		"model_jmp": "1010.jmp",
		"model_jma": "001.jma",
		"talk_image": 8004,
		"talk_id": 10091,
		"map_id": 10001,
		"spawn_pos": Vector2(117.0, 1303.0),
		"heading": IsometricMath.Heading.SOUTH_WEST,
		"move_speed": 60.0,
		"dialogue_text": "When the sea wind is blowing, it feels great.",
		"dialogue_choices": ["The ocean is vast.", "Enjoy the breeze!"],
		"walksteps": [Vector2(117.0, 1303.0), Vector2(160.0, 1330.0)],
		"walkstep_delays": [4.0, 4.0]
	},
	"Chef": {
		"npc_id": 12006,
		"npc_name": "Chef",
		"model_jmp": "1144.jmp",
		"model_jma": "001.jma",
		"talk_image": 8021,
		"talk_id": 12006,
		"map_id": 10001,
		"spawn_pos": Vector2(850.0, 720.0),
		"heading": IsometricMath.Heading.WEST,
		"move_speed": 60.0,
		"dialogue_text": "Fresh seafood is the secret to high morale at sea! Would you like a hot meal before we reach port?",
		"dialogue_choices": ["I'd love some fish!", "No thanks, I'm full."],
		"walksteps": [],
		"walkstep_delays": []
	},
	"Natasha": {
		"npc_id": 14303,
		"npc_name": "Natasha",
		"model_jmp": "1068.jmp",
		"model_jma": "001.jma",
		"talk_image": 8083,
		"talk_id": 14303,
		"map_id": 10011,
		"spawn_pos": Vector2(1420.0, 890.0),
		"heading": IsometricMath.Heading.SOUTH_EAST,
		"move_speed": 60.0,
		"dialogue_text": "Hello there! The weather on North Island is so peaceful today. Are you also exploring the ancient ruins?",
		"dialogue_choices": ["Yes, I'm heading there.", "Just passing through."],
		"walksteps": [],
		"walkstep_delays": []
	},
	"Traveling Merchant": {
		"npc_id": 14941,
		"npc_name": "Traveling Merchant",
		"model_jmp": "1050.jmp",
		"model_jma": "001.jma",
		"talk_image": 8017,
		"talk_id": 14941,
		"map_id": 10011,
		"spawn_pos": Vector2(980.0, 1020.0),
		"heading": IsometricMath.Heading.SOUTH,
		"move_speed": 60.0,
		"dialogue_text": "Step right up! Potions, scrolls, rare items from across the seas! What do you need today?",
		"dialogue_choices": ["Show me your wares.", "Maybe next time."],
		"walksteps": [],
		"walkstep_delays": []
	},
	"Ross": {
		"npc_id": 14152,
		"npc_name": "Ross",
		"model_jmp": "1207.jmp",
		"model_jma": "001.jma",
		"talk_image": 8005,
		"talk_id": 14152,
		"map_id": 10001,
		"spawn_pos": Vector2(102.0, 1312.0),
		"heading": IsometricMath.Heading.SOUTH_WEST,
		"move_speed": 60.0,
		"dialogue_text": "I'm flying, Jack! It's wonderful...",
		"dialogue_choices": ["Hold on tight!", "Watch out!"],
		"walksteps": [],
		"walkstep_delays": []
	}
}

# --- Runtime state ---
var _is_animating: bool = true
var _anim_timer: float = 0.0
var _anim_speed: float = 1.0
var _current_stance: int = PreviewStance.STAND
var _manual_frame_idx: int = 0
var is_preview_walking: bool = false:
	set(val):
		is_preview_walking = val
		if val and _current_stance == PreviewStance.STAND:
			_current_stance = PreviewStance.WALK
		elif not val and _current_stance == PreviewStance.WALK:
			_current_stance = PreviewStance.STAND
		if stance_option and stance_option.item_count > _current_stance:
			stance_option.select(_current_stance)
		_update_animation_frame()
var _current_heading: int = IsometricMath.Heading.SOUTH
var _cached_anim_data = null
var _total_anim_frames: int = 0
var _current_frame_idx: int = 0
var _cached_portrait_texture: ImageTexture = null

var _walksteps: Array[Vector2] = []
var _walkstep_delays: Array[float] = []
var _dialogue_choices: Array[String] = []
var _custom_presets: Dictionary = {}

# --- Undo / Redo History State ---
var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []
const MAX_UNDO_LEVELS: int = 50

var _archive_loader = null
var _game_database = null
var _signals_connected: bool = false

# --- UI Node References ---
@onready var preset_option: OptionButton = %PresetOption
@onready var btn_save_preset: Button = %BtnSavePreset
@onready var btn_load_presets: Button = %BtnLoadPresets
@onready var btn_new_npc: Button = %BtnNewNpc

# Appearance controls
@onready var model_jmp_option: OptionButton = %ModelJmpOption
@onready var model_jmp_edit: LineEdit = %ModelJmpEdit
@onready var model_jma_edit: LineEdit = %ModelJmaEdit
@onready var talk_image_spin: SpinBox = %TalkImageSpin
@onready var talk_image_option: OptionButton = %TalkImageOption
@onready var sprite_preview_rect: TextureRect = %SpritePreviewRect
@onready var portrait_preview_rect: TextureRect = %PortraitPreviewRect
@onready var crosshair_overlay: Control = %CrosshairOverlay
@onready var check_crosshair: CheckBox = %CheckCrosshair
@onready var heading_option: OptionButton = %HeadingOption
@onready var btn_turn_left: Button = %BtnTurnLeft
@onready var btn_turn_right: Button = %BtnTurnRight
@onready var btn_play_pause: Button = %BtnPlayPause
@onready var stance_option: OptionButton = %StanceOption
@onready var btn_prev_stance: Button = %BtnPrevStance
@onready var btn_next_stance: Button = %BtnNextStance
@onready var btn_prev_frame: Button = %BtnPrevFrame
@onready var frame_slider: HSlider = %FrameSlider
@onready var btn_next_frame: Button = %BtnNextFrame
@onready var anim_speed_spin: SpinBox = %AnimSpeedSpin
@onready var frame_info_label: Label = %FrameInfoLabel

# Parameters
@onready var npc_id_spin: SpinBox = %NpcIdSpin
@onready var btn_lookup_npc_db: Button = %BtnLookupNpcDb
@onready var npc_name_edit: LineEdit = %NpcNameEdit
@onready var map_id_spin: SpinBox = %MapIdSpin
@onready var map_quick_option: OptionButton = %MapQuickOption
@onready var spawn_x_spin: SpinBox = %SpawnXSpin
@onready var spawn_y_spin: SpinBox = %SpawnYSpin
@onready var move_speed_spin: SpinBox = %MoveSpeedSpin
@onready var talk_id_spin: SpinBox = %TalkIdSpin
@onready var btn_lookup_talk_db: Button = %BtnLookupTalkDb

# Dialogue
@onready var dialogue_text_edit: TextEdit = %DialogueTextEdit
@onready var choices_list: ItemList = %ChoicesList
@onready var choice_input: LineEdit = %ChoiceInput
@onready var btn_add_choice: Button = %BtnAddChoice
@onready var btn_remove_choice: Button = %BtnRemoveChoice
@onready var btn_clear_choices: Button = %BtnClearChoices

# Waypoints
@onready var waypoints_list: ItemList = %WaypointsList
@onready var waypoint_x_spin: SpinBox = %WaypointXSpin
@onready var waypoint_y_spin: SpinBox = %WaypointYSpin
@onready var waypoint_delay_spin: SpinBox = %WaypointDelaySpin
@onready var btn_add_waypoint: Button = %BtnAddWaypoint
@onready var btn_add_spawn_pos: Button = %BtnAddSpawnPos
@onready var btn_remove_waypoint: Button = %BtnRemoveWaypoint
@onready var btn_clear_waypoints: Button = %BtnClearWaypoints

# Export
@onready var export_path_edit: LineEdit = %ExportPathEdit
@onready var btn_export_scene: Button = %BtnExportScene
@onready var btn_test_entity: Button = %BtnTestEntity
@onready var btn_copy_snippet: Button = %BtnCopySnippet
@onready var code_preview_edit: TextEdit = %CodePreviewEdit
@onready var status_label: Label = %StatusLabel

func _ensure_node_refs() -> void:
	if model_jma_edit and npc_id_spin and preset_option:
		return
	preset_option = get_node_or_null("%PresetOption")
	btn_save_preset = get_node_or_null("%BtnSavePreset")
	btn_load_presets = get_node_or_null("%BtnLoadPresets")
	btn_new_npc = get_node_or_null("%BtnNewNpc")
	model_jmp_option = get_node_or_null("%ModelJmpOption")
	model_jmp_edit = get_node_or_null("%ModelJmpEdit")
	model_jma_edit = get_node_or_null("%ModelJmaEdit")
	talk_image_spin = get_node_or_null("%TalkImageSpin")
	talk_image_option = get_node_or_null("%TalkImageOption")
	sprite_preview_rect = get_node_or_null("%SpritePreviewRect")
	portrait_preview_rect = get_node_or_null("%PortraitPreviewRect")
	crosshair_overlay = get_node_or_null("%CrosshairOverlay")
	check_crosshair = get_node_or_null("%CheckCrosshair")
	heading_option = get_node_or_null("%HeadingOption")
	btn_turn_left = get_node_or_null("%BtnTurnLeft")
	btn_turn_right = get_node_or_null("%BtnTurnRight")
	btn_play_pause = get_node_or_null("%BtnPlayPause")
	stance_option = get_node_or_null("%StanceOption")
	btn_prev_stance = get_node_or_null("%BtnPrevStance")
	btn_next_stance = get_node_or_null("%BtnNextStance")
	btn_prev_frame = get_node_or_null("%BtnPrevFrame")
	frame_slider = get_node_or_null("%FrameSlider")
	btn_next_frame = get_node_or_null("%BtnNextFrame")
	anim_speed_spin = get_node_or_null("%AnimSpeedSpin")
	frame_info_label = get_node_or_null("%FrameInfoLabel")
	npc_id_spin = get_node_or_null("%NpcIdSpin")
	btn_lookup_npc_db = get_node_or_null("%BtnLookupNpcDb")
	npc_name_edit = get_node_or_null("%NpcNameEdit")
	map_id_spin = get_node_or_null("%MapIdSpin")
	map_quick_option = get_node_or_null("%MapQuickOption")
	spawn_x_spin = get_node_or_null("%SpawnXSpin")
	spawn_y_spin = get_node_or_null("%SpawnYSpin")
	move_speed_spin = get_node_or_null("%MoveSpeedSpin")
	talk_id_spin = get_node_or_null("%TalkIdSpin")
	btn_lookup_talk_db = get_node_or_null("%BtnLookupTalkDb")
	dialogue_text_edit = get_node_or_null("%DialogueTextEdit")
	choices_list = get_node_or_null("%ChoicesList")
	choice_input = get_node_or_null("%ChoiceInput")
	btn_add_choice = get_node_or_null("%BtnAddChoice")
	btn_remove_choice = get_node_or_null("%BtnRemoveChoice")
	btn_clear_choices = get_node_or_null("%BtnClearChoices")
	waypoints_list = get_node_or_null("%WaypointsList")
	waypoint_x_spin = get_node_or_null("%WaypointXSpin")
	waypoint_y_spin = get_node_or_null("%WaypointYSpin")
	waypoint_delay_spin = get_node_or_null("%WaypointDelaySpin")
	btn_add_waypoint = get_node_or_null("%BtnAddWaypoint")
	btn_add_spawn_pos = get_node_or_null("%BtnAddSpawnPos")
	btn_remove_waypoint = get_node_or_null("%BtnRemoveWaypoint")
	btn_clear_waypoints = get_node_or_null("%BtnClearWaypoints")
	export_path_edit = get_node_or_null("%ExportPathEdit")
	btn_export_scene = get_node_or_null("%BtnExportScene")
	btn_test_entity = get_node_or_null("%BtnTestEntity")
	btn_copy_snippet = get_node_or_null("%BtnCopySnippet")
	code_preview_edit = get_node_or_null("%CodePreviewEdit")
	status_label = get_node_or_null("%StatusLabel")
	if model_jmp_option and model_jmp_option.item_count == 0:
		_init_ui_dropdowns()

func _ready() -> void:
	_ensure_node_refs()
	_init_ui_dropdowns()
	_connect_signals()
	load_custom_presets()
	_refresh_preset_dropdown()
	
	# Load default preset
	load_preset("Captain Robinson")
	_show_status_message("NPC Creator & Editor ready. Loaded default: Captain Robinson.")

func _process(delta: float) -> void:
	if not _is_animating:
		return
	
	_anim_timer += delta * _anim_speed
	_update_animation_frame()

# --- Fallback / Subsystem Access ---

func _get_archive_loader():
	if _archive_loader:
		return _archive_loader
	if is_inside_tree() and has_node("/root/ArchiveLoader"):
		_archive_loader = get_node("/root/ArchiveLoader")
		return _archive_loader
	var main_loop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree and main_loop.root.has_node("ArchiveLoader"):
		_archive_loader = main_loop.root.get_node("ArchiveLoader")
		return _archive_loader
	var script = load("res://scripts/core/archive_loader.gd")
	if script:
		_archive_loader = script.new()
		add_child(_archive_loader)
		return _archive_loader
	return null

func _get_game_database():
	if _game_database:
		return _game_database
	if is_inside_tree() and has_node("/root/GameDatabase"):
		_game_database = get_node("/root/GameDatabase")
		return _game_database
	var main_loop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree and main_loop.root.has_node("GameDatabase"):
		_game_database = main_loop.root.get_node("GameDatabase")
		return _game_database
	var script = load("res://scripts/database/game_database.gd")
	if script:
		_game_database = script.new()
		add_child(_game_database)
		_game_database.load_all()
		return _game_database
	return null

# --- UI Setup ---

func _init_ui_dropdowns() -> void:
	# Heading dropdown
	if heading_option:
		heading_option.clear()
		for h in [
			IsometricMath.Heading.SOUTH,
			IsometricMath.Heading.SOUTH_WEST,
			IsometricMath.Heading.WEST,
			IsometricMath.Heading.NORTH_WEST,
			IsometricMath.Heading.NORTH,
			IsometricMath.Heading.NORTH_EAST,
			IsometricMath.Heading.EAST,
			IsometricMath.Heading.SOUTH_EAST
		]:
			heading_option.add_item(HEADING_NAMES.get(h, str(h)), h)
		heading_option.select(0)
	
	# Model JMP quick dropdown
	if model_jmp_option:
		model_jmp_option.clear()
		for i in range(COMMON_JMPS.size()):
			var item: Dictionary = COMMON_JMPS[i]
			model_jmp_option.add_item(item["name"], i)
		model_jmp_option.select(0)
	
	# Talk Image quick dropdown
	if talk_image_option:
		talk_image_option.clear()
		for i in range(COMMON_PORTRAITS.size()):
			var item: Dictionary = COMMON_PORTRAITS[i]
			talk_image_option.add_item(item["name"], item["id"])
		talk_image_option.select(0)
	
	# Map quick dropdown
	if map_quick_option:
		map_quick_option.clear()
		for i in range(COMMON_MAPS.size()):
			var item: Dictionary = COMMON_MAPS[i]
			map_quick_option.add_item(item["name"], item["id"])
		map_quick_option.select(0)
	
	# Stance / Action dropdown
	if stance_option:
		stance_option.clear()
		for s in [
			PreviewStance.STAND,
			PreviewStance.WALK,
			PreviewStance.BATTLE_READY,
			PreviewStance.ATTACK,
			PreviewStance.DEFEND,
			PreviewStance.SIT,
			PreviewStance.KNOCKOUT,
			PreviewStance.VICTORY,
			PreviewStance.MANUAL
		]:
			stance_option.add_item(STANCE_NAMES.get(s, str(s)), s)
		stance_option.select(_current_stance)

func _connect_signals() -> void:
	if _signals_connected:
		return
	_signals_connected = true
	# Presets
	if preset_option:
		preset_option.item_selected.connect(_on_preset_selected)
	if btn_save_preset:
		btn_save_preset.pressed.connect(_on_save_preset_pressed)
	if btn_load_presets:
		btn_load_presets.pressed.connect(_on_load_presets_pressed)
	if btn_new_npc:
		btn_new_npc.pressed.connect(_on_new_npc_pressed)
	
	# Visual Model
	if model_jmp_option:
		model_jmp_option.item_selected.connect(_on_model_jmp_option_selected)
	if model_jmp_edit:
		model_jmp_edit.text_changed.connect(func(_t): _reload_model_art())
	if model_jma_edit:
		model_jma_edit.text_changed.connect(func(_t): _reload_model_art())
	if talk_image_spin:
		talk_image_spin.value_changed.connect(_on_talk_image_spin_changed)
	if talk_image_option:
		talk_image_option.item_selected.connect(_on_talk_image_option_selected)
	
	# Heading & Animation
	if crosshair_overlay:
		crosshair_overlay.draw.connect(_on_crosshair_draw)
	if heading_option:
		heading_option.item_selected.connect(_on_heading_option_selected)
	if btn_turn_left:
		btn_turn_left.pressed.connect(_turn_left)
	if btn_turn_right:
		btn_turn_right.pressed.connect(_turn_right)
	if btn_play_pause:
		btn_play_pause.pressed.connect(_toggle_play_pause)
	if anim_speed_spin:
		anim_speed_spin.value_changed.connect(func(v): _anim_speed = float(v))
	if check_crosshair:
		check_crosshair.toggled.connect(func(v):
			if crosshair_overlay:
				crosshair_overlay.visible = v
				crosshair_overlay.queue_redraw()
		)
	if stance_option:
		stance_option.item_selected.connect(_on_stance_option_selected)
	if btn_prev_stance:
		btn_prev_stance.pressed.connect(_prev_stance)
	if btn_next_stance:
		btn_next_stance.pressed.connect(_next_stance)
	if frame_slider:
		frame_slider.value_changed.connect(_on_frame_slider_value_changed)
	if btn_prev_frame:
		btn_prev_frame.pressed.connect(_prev_manual_frame)
	if btn_next_frame:
		btn_next_frame.pressed.connect(_next_manual_frame)
	
	# Parameters
	if btn_lookup_npc_db:
		btn_lookup_npc_db.pressed.connect(func(): lookup_npc_database(int(npc_id_spin.value)))
	if btn_lookup_talk_db:
		btn_lookup_talk_db.pressed.connect(func(): lookup_talk_database(int(talk_id_spin.value)))
	if map_quick_option:
		map_quick_option.item_selected.connect(_on_map_quick_option_selected)
	if map_id_spin:
		map_id_spin.value_changed.connect(_on_map_id_spin_changed)
	
	# Choices
	if btn_add_choice:
		btn_add_choice.pressed.connect(_on_add_choice_pressed)
	if btn_remove_choice:
		btn_remove_choice.pressed.connect(_on_remove_choice_pressed)
	if btn_clear_choices:
		btn_clear_choices.pressed.connect(_on_clear_choices_pressed)
	if choice_input:
		choice_input.text_submitted.connect(func(_t): _on_add_choice_pressed())
	
	# Waypoints
	if btn_add_waypoint:
		btn_add_waypoint.pressed.connect(_on_add_waypoint_pressed)
	if btn_add_spawn_pos:
		btn_add_spawn_pos.pressed.connect(_on_add_spawn_pos_as_waypoint_pressed)
	if btn_remove_waypoint:
		btn_remove_waypoint.pressed.connect(_on_remove_waypoint_pressed)
	if btn_clear_waypoints:
		btn_clear_waypoints.pressed.connect(_on_clear_waypoints_pressed)
	
	# Export
	if btn_export_scene:
		btn_export_scene.pressed.connect(func(): export_npc_scene(export_path_edit.text))
	if btn_test_entity:
		btn_test_entity.pressed.connect(_on_test_entity_pressed)
	if btn_copy_snippet:
		btn_copy_snippet.pressed.connect(func(): copy_gdscript_snippet())
	
	# Sync code preview on edit changes
	if npc_name_edit:
		npc_name_edit.text_changed.connect(func(_t): _update_code_preview())
	if dialogue_text_edit:
		dialogue_text_edit.text_changed.connect(_update_code_preview)
	if spawn_x_spin:
		spawn_x_spin.value_changed.connect(func(_v): _update_code_preview())
	if spawn_y_spin:
		spawn_y_spin.value_changed.connect(func(_v): _update_code_preview())

# --- Presets & Library ---

func _refresh_preset_dropdown() -> void:
	if not preset_option:
		return
	preset_option.clear()
	
	# Built-in presets header/items
	var idx: int = 0
	for p_name in BUILTIN_PRESETS:
		preset_option.add_item("[Built-in] " + p_name, idx)
		preset_option.set_item_metadata(idx, {"type": "builtin", "name": p_name})
		idx += 1
	
	# Custom presets
	for c_name in _custom_presets:
		preset_option.add_item("[Custom] " + c_name, idx)
		preset_option.set_item_metadata(idx, {"type": "custom", "name": c_name})
		idx += 1

func _on_preset_selected(index: int) -> void:
	if not preset_option or index < 0 or index >= preset_option.item_count:
		return
	var meta = preset_option.get_item_metadata(index)
	if meta is Dictionary and meta.has("name"):
		load_preset(meta["name"])

func load_preset(preset_name: String) -> void:
	_ensure_node_refs()
	var data: Dictionary = {}
	if BUILTIN_PRESETS.has(preset_name):
		data = BUILTIN_PRESETS[preset_name]
	elif _custom_presets.has(preset_name):
		data = _custom_presets[preset_name]
	else:
		_show_status_message("Preset not found: " + preset_name, true)
		return
	
	# Apply parameters
	if npc_id_spin:
		npc_id_spin.value = data.get("npc_id", 14003)
	if npc_name_edit:
		npc_name_edit.text = data.get("npc_name", "Captain Robinson")
	if model_jmp_edit:
		model_jmp_edit.text = data.get("model_jmp", "1038.jmp")
	if model_jma_edit:
		model_jma_edit.text = data.get("model_jma", "001.jma")
	if map_id_spin:
		map_id_spin.value = data.get("map_id", 10001)
	
	var spawn: Vector2 = data.get("spawn_pos", Vector2(1720.0, 906.0))
	if spawn_x_spin:
		spawn_x_spin.value = spawn.x
	if spawn_y_spin:
		spawn_y_spin.value = spawn.y
	
	var h_val: int = data.get("heading", IsometricMath.Heading.SOUTH)
	_set_heading(h_val)
	
	if move_speed_spin:
		move_speed_spin.value = data.get("move_speed", 60.0)
	if talk_id_spin:
		talk_id_spin.value = data.get("talk_id", 0)
	if talk_image_spin:
		talk_image_spin.value = data.get("talk_image", 8025)
	if dialogue_text_edit:
		dialogue_text_edit.text = data.get("dialogue_text", "")
	
	# Sync dropdowns
	if model_jmp_edit:
		_sync_model_jmp_option(model_jmp_edit.text)
	if talk_image_spin:
		_sync_talk_image_option(int(talk_image_spin.value))
	if map_id_spin:
		_sync_map_quick_option(int(map_id_spin.value))
	
	# Choices
	_dialogue_choices.clear()
	var raw_choices = data.get("dialogue_choices", [])
	for c in raw_choices:
		_dialogue_choices.append(str(c))
	_refresh_choices_list()
	
	# Waypoints
	_walksteps.clear()
	_walkstep_delays.clear()
	var raw_steps = data.get("walksteps", [])
	for s in raw_steps:
		if s is Vector2:
			_walksteps.append(s)
		elif s is Array and s.size() >= 2:
			_walksteps.append(Vector2(s[0], s[1]))
	
	var raw_delays = data.get("walkstep_delays", [])
	for d in raw_delays:
		_walkstep_delays.append(float(d))
	_refresh_waypoints_list()
	
	# Update default export path
	var safe_name := _get_safe_node_name().to_snake_case()
	if export_path_edit:
		export_path_edit.text = "res://scenes/world/npc_%s.tscn" % safe_name
	
	_reload_model_art()
	update_portrait_preview()
	_update_code_preview()
	
	_show_status_message("Loaded preset: %s" % preset_name)
	preset_loaded.emit(preset_name)

func save_custom_preset(preset_name: String = "", custom_data: Dictionary = {}) -> bool:
	var p_name: String = preset_name
	if p_name.is_empty() and npc_name_edit:
		p_name = npc_name_edit.text.strip_edges()
	if p_name.is_empty():
		p_name = "Custom_NPC"
	
	var data: Dictionary = {}
	if not custom_data.is_empty():
		data = custom_data.duplicate()
	else:
		data = {
			"npc_id": int(npc_id_spin.value) if npc_id_spin else 14003,
			"npc_name": npc_name_edit.text if npc_name_edit else p_name,
			"model_jmp": model_jmp_edit.text if model_jmp_edit else "1038.jmp",
			"model_jma": model_jma_edit.text if model_jma_edit else "001.jma",
			"talk_image": int(talk_image_spin.value) if talk_image_spin else 8025,
			"talk_id": int(talk_id_spin.value) if talk_id_spin else 0,
			"map_id": int(map_id_spin.value) if map_id_spin else 10001,
			"spawn_pos": [spawn_x_spin.value if spawn_x_spin else 1000.0, spawn_y_spin.value if spawn_y_spin else 1000.0],
			"heading": _current_heading,
			"move_speed": float(move_speed_spin.value) if move_speed_spin else 60.0,
			"dialogue_text": dialogue_text_edit.text if dialogue_text_edit else "",
			"dialogue_choices": _dialogue_choices.duplicate(),
			"walksteps": [],
			"walkstep_delays": _walkstep_delays.duplicate()
		}
		for st in _walksteps:
			data["walksteps"].append([st.x, st.y])
	
	_custom_presets[p_name] = data
	
	# Write to disk user://custom_npcs.json
	var file := FileAccess.open(CUSTOM_PRESETS_PATH, FileAccess.WRITE)
	if not file:
		_show_status_message("Failed to open %s for writing" % CUSTOM_PRESETS_PATH, true)
		return false
	
	var json_str := JSON.stringify({"presets": _custom_presets}, "  ")
	file.store_string(json_str)
	file.close()
	
	_refresh_preset_dropdown()
	_show_status_message("Saved custom preset: '%s' to %s" % [p_name, CUSTOM_PRESETS_PATH])
	return true

func load_custom_presets() -> Dictionary:
	_custom_presets.clear()
	if not FileAccess.file_exists(CUSTOM_PRESETS_PATH):
		return _custom_presets
	
	var file := FileAccess.open(CUSTOM_PRESETS_PATH, FileAccess.READ)
	if not file:
		return _custom_presets
	
	var json_str := file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(json_str)
	if parsed is Dictionary and parsed.has("presets") and parsed["presets"] is Dictionary:
		_custom_presets = parsed["presets"]
	elif parsed is Dictionary:
		_custom_presets = parsed
	
	return _custom_presets

func _on_save_preset_pressed() -> void:
	save_custom_preset()

func _on_load_presets_pressed() -> void:
	load_custom_presets()
	_refresh_preset_dropdown()
	_show_status_message("Loaded %d custom presets from disk" % _custom_presets.size())

func _on_new_npc_pressed() -> void:
	if npc_id_spin:
		npc_id_spin.value = 15000
	if npc_name_edit:
		npc_name_edit.text = "New NPC"
	if model_jmp_edit:
		model_jmp_edit.text = "1038.jmp"
	if model_jma_edit:
		model_jma_edit.text = "001.jma"
	if talk_image_spin:
		talk_image_spin.value = 8025
	if talk_id_spin:
		talk_id_spin.value = 0
	if dialogue_text_edit:
		dialogue_text_edit.text = "Hello, adventurer!"
	_dialogue_choices.clear()
	_refresh_choices_list()
	_walksteps.clear()
	_walkstep_delays.clear()
	_refresh_waypoints_list()
	_reload_model_art()
	update_portrait_preview()
	_update_code_preview()
	_show_status_message("Reset fields for new NPC creation.")

# --- Visual Model & Preview ---

func _on_model_jmp_option_selected(index: int) -> void:
	if index < 0 or index >= COMMON_JMPS.size():
		return
	var item: Dictionary = COMMON_JMPS[index]
	if not item["file"].is_empty():
		model_jmp_edit.text = item["file"]
		model_jma_edit.text = item["archive"]
		_reload_model_art()

func _sync_model_jmp_option(jmp_name: String) -> void:
	if not model_jmp_option or model_jmp_option.item_count == 0:
		return
	for i in range(COMMON_JMPS.size()):
		if COMMON_JMPS[i]["file"] == jmp_name:
			model_jmp_option.select(i)
			return
	model_jmp_option.select(COMMON_JMPS.size() - 1) # Custom

func _reload_model_art() -> void:
	_ensure_node_refs()
	var loader = _get_archive_loader()
	if not loader:
		return
	
	var jma: String = model_jma_edit.text.strip_edges() if model_jma_edit else "001.jma"
	var jmp: String = model_jmp_edit.text.strip_edges() if model_jmp_edit else "1038.jmp"
	if jma.is_empty():
		jma = "001.jma"
	if jmp.is_empty():
		jmp = "1038.jmp"
	
	_cached_anim_data = loader.get_jma_animation(jma, jmp)
	if _cached_anim_data and _cached_anim_data.frames:
		_total_anim_frames = _cached_anim_data.frames.size()
	else:
		_total_anim_frames = 0
	
	if frame_slider:
		frame_slider.max_value = maxi(0, _total_anim_frames - 1)
	
	_anim_timer = 0.0
	_update_animation_frame()
	_update_code_preview()

func set_stance(stance: int) -> void:
	_current_stance = clampi(stance, 0, PreviewStance.MANUAL)
	is_preview_walking = (_current_stance == PreviewStance.WALK)
	if stance_option and stance_option.item_count > _current_stance:
		stance_option.select(_current_stance)
	_update_animation_frame()

func _on_stance_option_selected(idx: int) -> void:
	set_stance(stance_option.get_item_id(idx))

func _prev_stance() -> void:
	var next_idx: int = (_current_stance - 1 + 9) % 9
	set_stance(next_idx)

func _next_stance() -> void:
	var next_idx: int = (_current_stance + 1) % 9
	set_stance(next_idx)

func _on_frame_slider_value_changed(val: float) -> void:
	_manual_frame_idx = int(val)
	if _current_stance != PreviewStance.MANUAL:
		_current_stance = PreviewStance.MANUAL
		if stance_option:
			stance_option.select(PreviewStance.MANUAL)
	_update_animation_frame()

func _prev_manual_frame() -> void:
	if _total_anim_frames <= 0:
		return
	_manual_frame_idx = (_manual_frame_idx - 1 + _total_anim_frames) % _total_anim_frames
	if frame_slider:
		frame_slider.set_value_no_signal(_manual_frame_idx)
	if _current_stance != PreviewStance.MANUAL:
		_current_stance = PreviewStance.MANUAL
		if stance_option:
			stance_option.select(PreviewStance.MANUAL)
	_update_animation_frame()

func _next_manual_frame() -> void:
	if _total_anim_frames <= 0:
		return
	_manual_frame_idx = (_manual_frame_idx + 1) % _total_anim_frames
	if frame_slider:
		frame_slider.set_value_no_signal(_manual_frame_idx)
	if _current_stance != PreviewStance.MANUAL:
		_current_stance = PreviewStance.MANUAL
		if stance_option:
			stance_option.select(PreviewStance.MANUAL)
	_update_animation_frame()

func _compute_preview_frame(total_frames: int, heading_val: int) -> int:
	if total_frames <= 0:
		return 0
	
	if _current_stance == PreviewStance.MANUAL:
		return clampi(_manual_frame_idx, 0, total_frames - 1)
	
	var h: int = heading_val % 8
	var speed_mult: float = 6.0 if (_current_stance == PreviewStance.WALK or _current_stance == PreviewStance.ATTACK) else 2.0
	var sub_idx: int = int(_anim_timer * (_anim_speed * speed_mult)) % 4 if _is_animating else 0
	
	# --- 200+ frame composite / character models (e.g. 2000.jmp, 3000.jmp, 4000.jmp, 5000.jmp, 6000.jmp) ---
	if total_frames >= 200:
		match _current_stance:
			PreviewStance.WALK:
				return (h * 4 + sub_idx) % total_frames
			PreviewStance.STAND:
				return (32 + h * 4 + (sub_idx if _is_animating else 0)) % total_frames
			PreviewStance.BATTLE_READY:
				# Combat Battle Stance
				return (64 + h * 4 + (sub_idx % 4 if _is_animating else 0)) % total_frames
			PreviewStance.ATTACK:
				# Combat Weapon Strike
				return (112 + h * 4 + sub_idx) % total_frames
			PreviewStance.DEFEND:
				# Defend / Hurt Recoil
				return (144 + h * 4 + (sub_idx % 4 if _is_animating else 0)) % total_frames
			PreviewStance.SIT:
				# Sit / Rest
				return (64 + h * 4 + (sub_idx % 4 if _is_animating else 0)) % total_frames
			PreviewStance.KNOCKOUT:
				# Prone / Knockout / Defeat
				return (176 + (h % 8) * 2 + (sub_idx % 2)) % total_frames
			PreviewStance.VICTORY:
				# Victory Cheer / Emote
				return (200 + h * 2 + (sub_idx % 2)) % total_frames
			_:
				return (32 + h * 4 + (sub_idx if _is_animating else 0)) % total_frames

	# --- 140-frame NPC combat models (e.g. 1010.jmp Jack, 1068.jmp Natasha, 1144.jmp Chef, 1221.jmp Roca, 1223.jmp Niss, 1155.jmp Clive) ---
	elif total_frames >= 140:
		match _current_stance:
			PreviewStance.WALK:
				return (h * 4 + sub_idx) % total_frames
			PreviewStance.STAND:
				return (32 + h * 4 + (sub_idx if _is_animating else 0)) % total_frames
			PreviewStance.BATTLE_READY:
				# Battle Stance (Frames 80..111: 32-1..39-4)
				return (80 + h * 4 + (sub_idx % 2 if _is_animating else 0)) % total_frames
			PreviewStance.ATTACK:
				# Combat Attack Strike (Frames 80..111)
				return (80 + h * 4 + sub_idx) % total_frames
			PreviewStance.DEFEND:
				# Defend / Hurt Recoil (Frames 112..127: 40-1..43-4)
				return (112 + (h % 4) * 4 + (sub_idx % 4 if _is_animating else 0)) % total_frames
			PreviewStance.SIT:
				# Sit / Rest (Frames 64..71: 16-1..17-4)
				return (64 + (h % 2) * 4 + (sub_idx % 4 if _is_animating else 0)) % total_frames
			PreviewStance.KNOCKOUT:
				# Prone / Knockout (Frames 72..75: 26-1..27-2)
				return (72 + (sub_idx % 4)) % total_frames
			PreviewStance.VICTORY:
				# Victory Cheer (Frames 132..139: 64-1..65-4)
				return (132 + (sub_idx % 8)) % total_frames
			_:
				return (32 + h * 4 + (sub_idx if _is_animating else 0)) % total_frames

	# --- 64..139 frame humanoid models (e.g. 1131.jmp Kelang 78 frames) ---
	elif total_frames >= 64:
		match _current_stance:
			PreviewStance.WALK:
				return (h * 4 + sub_idx) % total_frames
			PreviewStance.STAND:
				return (32 + h * 4 + (sub_idx if _is_animating else 0)) % total_frames
			PreviewStance.BATTLE_READY, PreviewStance.ATTACK:
				var combat_cnt: int = total_frames - 64
				return (64 + (h * 4 + sub_idx) % combat_cnt) % total_frames
			PreviewStance.DEFEND, PreviewStance.SIT, PreviewStance.KNOCKOUT, PreviewStance.VICTORY:
				var combat_cnt: int = total_frames - 64
				return (64 + (sub_idx % combat_cnt)) % total_frames
			_:
				return (32 + h * 4 + (sub_idx if _is_animating else 0)) % total_frames

	# --- 32-frame models (1038.jmp Captain Robinson, 1037.jmp Crew, 1274.jmp) ---
	elif total_frames == 32:
		# Check if 8-way stationary stand character (e.g. 1274.jmp where frame 0 starts with '08')
		if _cached_anim_data != null and not _cached_anim_data.frames.is_empty() and _cached_anim_data.frames[0].name.begins_with("08"):
			return (h * 4 + (sub_idx if _is_animating else 0)) % total_frames
		
		# Standard 4-diagonal walk (frames 0..15) + 4-diagonal stand (frames 16..31)
		# 01/09: NW (diag 0), 03/11: SW (diag 1), 05/13: SE (diag 2), 07/15: NE (diag 3)
		var diag_idx: int = 0
		match h:
			IsometricMath.Heading.NORTH_WEST, IsometricMath.Heading.NORTH:
				diag_idx = 0
			IsometricMath.Heading.SOUTH_WEST, IsometricMath.Heading.WEST:
				diag_idx = 1
			IsometricMath.Heading.SOUTH_EAST, IsometricMath.Heading.SOUTH:
				diag_idx = 2
			IsometricMath.Heading.NORTH_EAST, IsometricMath.Heading.EAST:
				diag_idx = 3
		if _current_stance == PreviewStance.WALK:
			var base: int = diag_idx * 4
			return (base + sub_idx) % total_frames
		else:
			var base: int = 16 + diag_idx * 4
			return (base + (sub_idx if _is_animating else 0)) % total_frames

	# --- 16-frame 4-diagonal models (e.g. 1170.jmp Breillat) ---
	elif total_frames == 16:
		var diag_block: int = 0
		match h:
			IsometricMath.Heading.NORTH_WEST, IsometricMath.Heading.NORTH:
				diag_block = 0
			IsometricMath.Heading.SOUTH_WEST, IsometricMath.Heading.WEST:
				diag_block = 1
			IsometricMath.Heading.SOUTH_EAST, IsometricMath.Heading.SOUTH:
				diag_block = 2
			IsometricMath.Heading.NORTH_EAST, IsometricMath.Heading.EAST:
				diag_block = 3
		return (diag_block * 4 + (sub_idx if _is_animating else 0)) % total_frames

	# --- 8-frame models ---
	elif total_frames == 8:
		if _cached_anim_data != null and not _cached_anim_data.frames.is_empty() and _cached_anim_data.frames[0].name.begins_with("01"):
			var diag_idx: int = 0
			match h:
				IsometricMath.Heading.NORTH_WEST, IsometricMath.Heading.NORTH:
					diag_idx = 0
				IsometricMath.Heading.SOUTH_WEST, IsometricMath.Heading.WEST:
					diag_idx = 1
				IsometricMath.Heading.SOUTH_EAST, IsometricMath.Heading.SOUTH:
					diag_idx = 2
				IsometricMath.Heading.NORTH_EAST, IsometricMath.Heading.EAST:
					diag_idx = 3
			if _current_stance == PreviewStance.WALK:
				return diag_idx % total_frames
			else:
				return (4 + diag_idx) % total_frames
		return h

	# --- 4-frame models (1050.jmp) ---
	elif total_frames == 4:
		match h:
			IsometricMath.Heading.NORTH_WEST, IsometricMath.Heading.NORTH:
				return 0
			IsometricMath.Heading.SOUTH_WEST, IsometricMath.Heading.WEST:
				return 1
			IsometricMath.Heading.SOUTH_EAST, IsometricMath.Heading.SOUTH:
				return 2
			IsometricMath.Heading.NORTH_EAST, IsometricMath.Heading.EAST:
				return 3
		return 0
	else:
		return int(_anim_timer * 2.0) % total_frames

func _update_animation_frame() -> void:
	if not sprite_preview_rect:
		return
	
	var loader = _get_archive_loader()
	if not loader:
		return
	
	_ensure_node_refs()
	var jma: String = model_jma_edit.text.strip_edges() if model_jma_edit else "001.jma"
	var jmp: String = model_jmp_edit.text.strip_edges() if model_jmp_edit else "1038.jmp"
	
	var frame_idx: int = _compute_preview_frame(_total_anim_frames, _current_heading)
	_current_frame_idx = frame_idx
	if frame_slider and int(frame_slider.value) != frame_idx:
		frame_slider.set_value_no_signal(frame_idx)
	
	var tex: ImageTexture = loader.get_jma_frame_128(jma, jmp, frame_idx)
	if tex and sprite_preview_rect:
		sprite_preview_rect.texture = tex
	
	if frame_info_label:
		var stance_str: String = STANCE_NAMES.get(_current_stance, "Stand")
		if _total_anim_frames == 32 and _current_stance >= PreviewStance.BATTLE_READY and _current_stance != PreviewStance.MANUAL:
			stance_str += " (32f model: Stand fallback)"
		var frame_name: String = ""
		if _cached_anim_data and frame_idx < _cached_anim_data.frames.size():
			frame_name = " [%s]" % _cached_anim_data.frames[frame_idx].name
		frame_info_label.text = "Frame: %d / %d%s | %s | %s" % [
			frame_idx,
			_total_anim_frames,
			frame_name,
			stance_str,
			_get_heading_name(_current_heading)
		]
	
	if crosshair_overlay and crosshair_overlay.visible:
		crosshair_overlay.queue_redraw()
	
	preview_updated.emit()

func _on_crosshair_draw() -> void:
	if not crosshair_overlay or not check_crosshair or not check_crosshair.button_pressed:
		return
	
	var sz: Vector2 = crosshair_overlay.size
	var center_x: float = sz.x * 0.5
	var center_y: float = sz.y * 0.5
	
	# The feet of the 128x128 sprite in a 160x150 preview box touch at bottom center:
	var foot_pos := Vector2(center_x, center_y + 58.0)
	
	# Isometric diamond tile guide (2:1 axonometric ratio matching WLO DirectDraw engine)
	var diamond_w := 40.0
	var diamond_h := 20.0
	var tile_pts := PackedVector2Array([
		foot_pos + Vector2(0, -diamond_h),
		foot_pos + Vector2(diamond_w, 0),
		foot_pos + Vector2(0, diamond_h),
		foot_pos + Vector2(-diamond_w, 0),
		foot_pos + Vector2(0, -diamond_h)
	])
	crosshair_overlay.draw_polyline(tile_pts, Color(0.2, 0.85, 1.0, 0.5), 1.5)
	
	# Ground horizontal axis
	crosshair_overlay.draw_line(Vector2(center_x - 50.0, foot_pos.y), Vector2(center_x + 50.0, foot_pos.y), Color(1.0, 0.85, 0.2, 0.7), 1.0)
	# Vertical central alignment axis
	crosshair_overlay.draw_line(Vector2(center_x, 10.0), Vector2(center_x, sz.y - 10.0), Color(1.0, 0.85, 0.2, 0.35), 1.0)
	# Center anchor dot
	crosshair_overlay.draw_circle(foot_pos, 2.5, Color(1.0, 0.9, 0.2, 1.0))

# --- Heading Controls ---

func _set_heading(h: int) -> void:
	_current_heading = (h % 8 + 8) % 8
	if heading_option:
		for i in range(heading_option.item_count):
			if heading_option.get_item_id(i) == _current_heading:
				heading_option.select(i)
				break
	_update_animation_frame()
	_update_code_preview()

func _turn_left() -> void:
	# Counter-clockwise in WLO isometric space
	_set_heading((_current_heading + 1) % 8)

func _turn_right() -> void:
	# Clockwise in WLO isometric space
	_set_heading((_current_heading + 7) % 8)

func rotate_preview(dir: int) -> void:
	if dir > 0:
		_turn_right()
	else:
		_turn_left()

func set_heading(p_heading: int) -> void:
	_set_heading(p_heading)

func toggle_preview_walk() -> void:
	is_preview_walking = not is_preview_walking

func set_preview_walking(p_walking: bool) -> void:
	is_preview_walking = p_walking

func _toggle_play_pause() -> void:
	_is_animating = not _is_animating
	if btn_play_pause:
		btn_play_pause.text = "Pause" if _is_animating else "Play"
	_update_animation_frame()

func _on_heading_option_selected(index: int) -> void:
	if heading_option:
		_set_heading(heading_option.get_item_id(index))

func _get_heading_name(h: int) -> String:
	match h % 8:
		IsometricMath.Heading.NORTH:
			return "NORTH"
		IsometricMath.Heading.NORTH_WEST:
			return "NORTH_WEST"
		IsometricMath.Heading.WEST:
			return "WEST"
		IsometricMath.Heading.SOUTH_WEST:
			return "SOUTH_WEST"
		IsometricMath.Heading.SOUTH:
			return "SOUTH"
		IsometricMath.Heading.SOUTH_EAST:
			return "SOUTH_EAST"
		IsometricMath.Heading.EAST:
			return "EAST"
		IsometricMath.Heading.NORTH_EAST:
			return "NORTH_EAST"
		_:
			return "UNKNOWN"

# --- Portrait Preview ---

func _on_talk_image_spin_changed(val: float) -> void:
	var tid: int = int(val)
	_sync_talk_image_option(tid)
	update_portrait_preview()
	_update_code_preview()

func _on_talk_image_option_selected(index: int) -> void:
	if not talk_image_option:
		return
	var tid: int = talk_image_option.get_item_id(index)
	if talk_image_spin:
		talk_image_spin.value = tid
	update_portrait_preview()
	_update_code_preview()

func _sync_talk_image_option(tid: int) -> void:
	if not talk_image_option or talk_image_option.item_count == 0:
		return
	for i in range(talk_image_option.item_count):
		if talk_image_option.get_item_id(i) == tid:
			talk_image_option.select(i)
			return
	# Custom / not in list
	talk_image_option.select(talk_image_option.item_count - 1)

func update_portrait_preview() -> void:
	if not portrait_preview_rect:
		return
	var tid: int = int(talk_image_spin.value) if talk_image_spin else 0
	if tid <= 0:
		portrait_preview_rect.texture = null
		return
	
	var loader = _get_archive_loader()
	if not loader:
		return
	
	var portrait: ImageTexture = loader.get_npc_portrait(tid)
	if portrait:
		portrait_preview_rect.texture = portrait
	else:
		portrait_preview_rect.texture = null

# --- Database Lookups ---

func lookup_npc_database(id: int) -> void:
	var gdb = _get_game_database()
	if not gdb or not gdb.npcs:
		_show_status_message("NpcDatabase not available", true)
		return
	
	var rec = gdb.npcs.get_npc(id)
	if not rec:
		_show_status_message("NPC ID %d not found in Npc.dat" % id, true)
		return
	
	npc_name_edit.text = rec.name
	if rec.sprite_id > 0:
		model_jmp_edit.text = "%d.jmp" % rec.sprite_id
		var pkg: int = int(rec.sprite_id / 1000)
		model_jma_edit.text = "%03d.jma" % pkg
		_sync_model_jmp_option(model_jmp_edit.text)
		_reload_model_art()
	
	if rec.talk_image > 0:
		talk_image_spin.value = rec.talk_image
		_sync_talk_image_option(rec.talk_image)
		update_portrait_preview()
	
	_show_status_message("Loaded NPC data from Npc.dat: %s (Sprite: %d, TID: %d)" % [
		rec.name, rec.sprite_id, rec.talk_image
	])
	_update_code_preview()

func lookup_talk_database(tid: int) -> void:
	var gdb = _get_game_database()
	if not gdb or not gdb.talks:
		_show_status_message("TalkDatabase not available", true)
		return
	
	var talk: Dictionary = gdb.get_talk(tid)
	if talk.is_empty():
		_show_status_message("Talk ID %d not found in Talk.dat" % tid, true)
		return
	
	var plain: String = talk.get("plain_text", "")
	if not plain.is_empty() and dialogue_text_edit:
		dialogue_text_edit.text = plain
	
	var raw_choices = talk.get("choices", [])
	_dialogue_choices.clear()
	for c in raw_choices:
		if c is Dictionary and c.has("text"):
			_dialogue_choices.append(str(c["text"]))
		elif c is String:
			_dialogue_choices.append(c)
	_refresh_choices_list()
	
	var face: int = talk.get("face_index", -1)
	if face > 0 and talk_image_spin and talk_image_spin.value == 0:
		talk_image_spin.value = face
		update_portrait_preview()
	
	_show_status_message("Loaded dialogue from Talk.dat for ID %d (%d choices)" % [tid, _dialogue_choices.size()])
	_update_code_preview()

func _on_map_quick_option_selected(index: int) -> void:
	if map_quick_option and map_id_spin:
		map_id_spin.value = map_quick_option.get_item_id(index)
		_update_code_preview()

func _on_map_id_spin_changed(val: float) -> void:
	_sync_map_quick_option(int(val))
	_update_code_preview()

func _sync_map_quick_option(mid: int) -> void:
	if not map_quick_option or map_quick_option.item_count == 0:
		return
	for i in range(map_quick_option.item_count):
		if map_quick_option.get_item_id(i) == mid:
			map_quick_option.select(i)
			return

# --- Dialogue Choices List Management ---

func _on_add_choice_pressed() -> void:
	if not choice_input:
		return
	var text: String = choice_input.text.strip_edges()
	if text.is_empty():
		return
	_dialogue_choices.append(text)
	choice_input.text = ""
	_refresh_choices_list()
	_update_code_preview()
	record_action({"type": "add_choice", "text": text})

func _on_remove_choice_pressed() -> void:
	if not choices_list or choices_list.get_selected_items().is_empty():
		return
	var sel: int = choices_list.get_selected_items()[0]
	if sel >= 0 and sel < _dialogue_choices.size():
		var removed_text: String = _dialogue_choices[sel]
		_dialogue_choices.remove_at(sel)
		_refresh_choices_list()
		_update_code_preview()
		record_action({"type": "remove_choice", "text": removed_text, "index": sel})

func _on_clear_choices_pressed() -> void:
	var old_choices := _dialogue_choices.duplicate()
	_dialogue_choices.clear()
	_refresh_choices_list()
	_update_code_preview()
	record_action({"type": "clear_choices", "choices": old_choices})

func _refresh_choices_list() -> void:
	if not choices_list:
		return
	choices_list.clear()
	for i in range(_dialogue_choices.size()):
		choices_list.add_item("%d. %s" % [i + 1, _dialogue_choices[i]])

# --- Waypoints (Walksteps) Management ---

func _on_add_waypoint_pressed() -> void:
	if not waypoint_x_spin or not waypoint_y_spin or not waypoint_delay_spin:
		return
	var pos := Vector2(waypoint_x_spin.value, waypoint_y_spin.value)
	var delay: float = float(waypoint_delay_spin.value)
	_walksteps.append(pos)
	_walkstep_delays.append(delay)
	_refresh_waypoints_list()
	_update_code_preview()
	record_action({"type": "add_waypoint", "pos": pos, "delay": delay})

func _on_add_spawn_pos_as_waypoint_pressed() -> void:
	if not spawn_x_spin or not spawn_y_spin:
		return
	var pos := Vector2(spawn_x_spin.value, spawn_y_spin.value)
	_walksteps.append(pos)
	_walkstep_delays.append(2.0)
	_refresh_waypoints_list()
	_update_code_preview()
	record_action({"type": "add_waypoint", "pos": pos, "delay": 2.0})

func _on_remove_waypoint_pressed() -> void:
	if not waypoints_list or waypoints_list.get_selected_items().is_empty():
		return
	var sel: int = waypoints_list.get_selected_items()[0]
	if sel >= 0 and sel < _walksteps.size():
		var p: Vector2 = _walksteps[sel]
		var d: float = _walkstep_delays[sel] if sel < _walkstep_delays.size() else 0.0
		_walksteps.remove_at(sel)
		if sel < _walkstep_delays.size():
			_walkstep_delays.remove_at(sel)
		_refresh_waypoints_list()
		_update_code_preview()
		record_action({"type": "remove_waypoint", "pos": p, "delay": d, "index": sel})

func _on_clear_waypoints_pressed() -> void:
	var old_steps := _walksteps.duplicate()
	var old_delays := _walkstep_delays.duplicate()
	_walksteps.clear()
	_walkstep_delays.clear()
	_refresh_waypoints_list()
	_update_code_preview()
	record_action({"type": "clear_waypoints", "steps": old_steps, "delays": old_delays})

func _refresh_waypoints_list() -> void:
	if not waypoints_list:
		return
	waypoints_list.clear()
	for i in range(_walksteps.size()):
		var delay: float = _walkstep_delays[i] if i < _walkstep_delays.size() else 0.0
		waypoints_list.add_item("Step %d: (%.0f, %.0f) - Wait: %.1fs" % [
			i + 1, _walksteps[i].x, _walksteps[i].y, delay
		])

# --- Undo / Redo History Operations ---

func record_action(action: Dictionary) -> void:
	undo_stack.append(action)
	if undo_stack.size() > MAX_UNDO_LEVELS:
		undo_stack.pop_front()
	redo_stack.clear()

func undo() -> bool:
	if undo_stack.is_empty():
		return false
	var action: Dictionary = undo_stack.pop_back()
	_apply_undo_action(action)
	redo_stack.append(action)
	_refresh_choices_list()
	_refresh_waypoints_list()
	_update_code_preview()
	return true

func redo() -> bool:
	if redo_stack.is_empty():
		return false
	var action: Dictionary = redo_stack.pop_back()
	_apply_redo_action(action)
	undo_stack.append(action)
	_refresh_choices_list()
	_refresh_waypoints_list()
	_update_code_preview()
	return true

func _apply_undo_action(action: Dictionary) -> void:
	match action.get("type", ""):
		"add_choice":
			if not _dialogue_choices.is_empty():
				_dialogue_choices.pop_back()
		"remove_choice":
			var idx: int = clampi(int(action.get("index", 0)), 0, _dialogue_choices.size())
			_dialogue_choices.insert(idx, str(action.get("text", "")))
		"clear_choices":
			var raw: Array = action.get("choices", [])
			_dialogue_choices.clear()
			for c in raw:
				_dialogue_choices.append(str(c))
		"add_waypoint":
			if not _walksteps.is_empty():
				_walksteps.pop_back()
			if not _walkstep_delays.is_empty():
				_walkstep_delays.pop_back()
		"remove_waypoint":
			var idx: int = clampi(int(action.get("index", 0)), 0, _walksteps.size())
			_walksteps.insert(idx, action.get("pos", Vector2.ZERO))
			_walkstep_delays.insert(idx, float(action.get("delay", 0.0)))
		"clear_waypoints":
			var steps: Array = action.get("steps", [])
			var delays: Array = action.get("delays", [])
			_walksteps.clear()
			_walkstep_delays.clear()
			for s in steps:
				_walksteps.append(s)
			for d in delays:
				_walkstep_delays.append(float(d))

func _apply_redo_action(action: Dictionary) -> void:
	match action.get("type", ""):
		"add_choice":
			_dialogue_choices.append(str(action.get("text", "")))
		"remove_choice":
			var idx: int = int(action.get("index", 0))
			if idx >= 0 and idx < _dialogue_choices.size():
				_dialogue_choices.remove_at(idx)
		"clear_choices":
			_dialogue_choices.clear()
		"add_waypoint":
			_walksteps.append(action.get("pos", Vector2.ZERO))
			_walkstep_delays.append(float(action.get("delay", 0.0)))
		"remove_waypoint":
			var idx: int = int(action.get("index", 0))
			if idx >= 0 and idx < _walksteps.size():
				_walksteps.remove_at(idx)
			if idx >= 0 and idx < _walkstep_delays.size():
				_walkstep_delays.remove_at(idx)
		"clear_waypoints":
			_walksteps.clear()
			_walkstep_delays.clear()

# --- Export & Instantiation ---

func _get_safe_node_name() -> String:
	var raw_name: String = npc_name_edit.text.strip_edges() if npc_name_edit else "NPC"
	if raw_name.is_empty():
		raw_name = "NPC_%d" % int(npc_id_spin.value)
	
	# Strip non-alphanumeric characters
	var safe := ""
	for c in raw_name:
		if (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (c >= '0' and c <= '9') or c == '_':
			safe += c
		elif c == ' ':
			safe += "_"
	if safe.is_empty():
		safe = "NPC"
	return safe

## Generates a valid .tscn scene file extending NpcEntity with all exported variables.
func export_npc_scene(file_path: String = "") -> String:
	_ensure_node_refs()
	var path: String = file_path.strip_edges()
	if path.is_empty():
		var node_name := _get_safe_node_name().to_snake_case()
		path = "res://scenes/world/npc_%s.tscn" % node_name
	elif not path.begins_with("res://") and not path.begins_with("user://"):
		path = "res://" + path
	
	# Ensure directory exists
	var dir_path := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir_path)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
	
	# Format choices string
	var choices_tscn := ""
	for i in range(_dialogue_choices.size()):
		choices_tscn += '"%s"' % _dialogue_choices[i].c_escape()
		if i < _dialogue_choices.size() - 1:
			choices_tscn += ", "
	
	# Format walksteps string
	var walksteps_tscn := ""
	for i in range(_walksteps.size()):
		walksteps_tscn += "Vector2(%d, %d)" % [int(_walksteps[i].x), int(_walksteps[i].y)]
		if i < _walksteps.size() - 1:
			walksteps_tscn += ", "
	
	# Format walkstep delays
	var delays_tscn := ""
	for i in range(_walkstep_delays.size()):
		delays_tscn += "%.1f" % _walkstep_delays[i]
		if i < _walkstep_delays.size() - 1:
			delays_tscn += ", "
	
	var node_name := _get_safe_node_name()
	var dialogue_text_escaped := dialogue_text_edit.text.c_escape() if dialogue_text_edit else ""
	var display_name := npc_name_edit.text if npc_name_edit else "NPC"
	var id_val: int = int(npc_id_spin.value) if npc_id_spin else 14003
	var jmp_val: String = model_jmp_edit.text if model_jmp_edit else "1038.jmp"
	var jma_val: String = model_jma_edit.text if model_jma_edit else "001.jma"
	var sx_val: int = int(spawn_x_spin.value) if spawn_x_spin else 1720
	var sy_val: int = int(spawn_y_spin.value) if spawn_y_spin else 906
	var tid_val: int = int(talk_id_spin.value) if talk_id_spin else 0
	var timg_val: int = int(talk_image_spin.value) if talk_image_spin else 8025
	var spd_val: float = float(move_speed_spin.value) if move_speed_spin else 60.0
	
	# Generate standalone scene definition extending NpcEntity
	var tscn_content := """[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/world/npc.gd" id="1_npc"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_npc"]
size = Vector2(40, 70)

[node name="%s" type="Node2D"]
script = ExtResource("1_npc")
npc_id = %d
npc_name = "%s"
model_jmp = "%s"
model_jma = "%s"
world_position = Vector2(%d, %d)
heading = %d
talk_id = %d
talk_image = %d
dialogue_text = "%s"
dialogue_choices = [%s]
move_speed = %.1f
walksteps = [%s]
walkstep_delays = [%s]

[node name="Sprite2D" type="Sprite2D" parent="."]
offset = Vector2(0, -41)

[node name="Nameplate" type="Label" parent="."]
anchors_preset = 7
anchor_left = 0.5
anchor_top = 1.0
anchor_right = 0.5
anchor_bottom = 1.0
offset_left = -60.0
offset_top = -108.0
offset_right = 60.0
offset_bottom = -88.0
grow_horizontal = 2
grow_vertical = 0
theme_override_colors/font_color = Color(0.4, 0.9, 1, 1)
theme_override_colors/font_outline_color = Color(0, 0, 0, 0.8)
theme_override_constants/outline_size = 2
theme_override_font_sizes/font_size = 11
text = "%s"
horizontal_alignment = 1
vertical_alignment = 1

[node name="ClickArea" type="Area2D" parent="."]
position = Vector2(0, -43)

[node name="CollisionShape2D" type="CollisionShape2D" parent="ClickArea"]
shape = SubResource("RectangleShape2D_npc")
""" % [
		node_name,
		id_val,
		display_name.c_escape(),
		jmp_val,
		jma_val,
		sx_val,
		sy_val,
		_current_heading,
		tid_val,
		timg_val,
		dialogue_text_escaped,
		choices_tscn,
		spd_val,
		walksteps_tscn,
		delays_tscn,
		display_name.c_escape()
	]
	
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		var err := FileAccess.get_open_error()
		var msg := "Failed to export scene to %s (Error code: %d)" % [path, err]
		_show_status_message(msg, true)
		return ""
	
	file.store_string(tscn_content)
	file.close()
	
	_show_status_message("Exported NPC scene successfully to %s" % path)
	npc_exported.emit(path)
	return path

## Instantiates and returns a configured NpcEntity ready to be added to any map's Entities container.
func create_npc_entity() -> NpcEntity:
	var npc_scene = load("res://scenes/world/npc.tscn")
	var entity: NpcEntity
	if npc_scene:
		entity = npc_scene.instantiate() as NpcEntity
	else:
		entity = NpcEntity.new()
	
	entity.name = _get_safe_node_name() if has_method("_get_safe_node_name") else "Captain_Robinson"
	entity.npc_id = int(npc_id_spin.value) if npc_id_spin else 14003
	entity.npc_name = npc_name_edit.text if npc_name_edit else "Captain Robinson"
	entity.model_jmp = model_jmp_edit.text if model_jmp_edit else "1038.jmp"
	entity.model_jma = model_jma_edit.text if model_jma_edit else "001.jma"
	entity.world_position = Vector2(spawn_x_spin.value if spawn_x_spin else 1720.0, spawn_y_spin.value if spawn_y_spin else 906.0)
	entity.heading = _current_heading
	entity.talk_id = int(talk_id_spin.value) if talk_id_spin else 0
	entity.talk_image = int(talk_image_spin.value) if talk_image_spin else 8025
	entity.dialogue_text = dialogue_text_edit.text if dialogue_text_edit else "Welcome aboard the ship!"
	entity.dialogue_choices = _dialogue_choices.duplicate()
	entity.move_speed = float(move_speed_spin.value) if move_speed_spin else 60.0
	entity.walksteps = _walksteps.duplicate()
	entity.walkstep_delays = _walkstep_delays.duplicate()
	
	npc_created.emit(entity)
	return entity

func _on_test_entity_pressed() -> void:
	var entity := create_npc_entity()
	if not entity:
		_show_status_message("Failed to instantiate NpcEntity", true)
		return
	
	# Verify properties
	var msg := "NpcEntity created: '%s' (ID: %d, Sprite: %s, Heading: %d, Pos: %s, Waypoints: %d)" % [
		entity.npc_name, entity.npc_id, entity.model_jmp, entity.heading, entity.world_position, entity.walksteps.size()
	]
	_show_status_message(msg)
	entity.free()

## Copies a ready-to-paste GDScript code snippet.
func copy_gdscript_snippet() -> String:
	var snippet := _generate_gdscript_snippet()
	DisplayServer.clipboard_set(snippet)
	_show_status_message("GDScript code snippet copied to clipboard!")
	return snippet

func _generate_gdscript_snippet() -> String:
	_ensure_node_refs()
	var choices_str := ""
	for i in range(_dialogue_choices.size()):
		choices_str += '"%s"' % _dialogue_choices[i].c_escape()
		if i < _dialogue_choices.size() - 1:
			choices_str += ", "
	
	var walksteps_str := ""
	for i in range(_walksteps.size()):
		walksteps_str += "Vector2(%d, %d)" % [int(_walksteps[i].x), int(_walksteps[i].y)]
		if i < _walksteps.size() - 1:
			walksteps_str += ", "
	
	var delays_str := ""
	for i in range(_walkstep_delays.size()):
		delays_str += "%.1f" % _walkstep_delays[i]
		if i < _walkstep_delays.size() - 1:
			delays_str += ", "
	
	var heading_name := _get_heading_name(_current_heading)
	var dialogue_escaped := dialogue_text_edit.text.c_escape() if dialogue_text_edit else ""
	var npc_name_val := npc_name_edit.text if npc_name_edit else "NPC"
	var jmp_val := model_jmp_edit.text if model_jmp_edit else "1038.jmp"
	var jma_val := model_jma_edit.text if model_jma_edit else "001.jma"
	var id_val: int = int(npc_id_spin.value) if npc_id_spin else 14003
	var map_val: int = int(map_id_spin.value) if map_id_spin else 10001
	var sx_val: int = int(spawn_x_spin.value) if spawn_x_spin else 1720
	var sy_val: int = int(spawn_y_spin.value) if spawn_y_spin else 906
	var tid_val: int = int(talk_id_spin.value) if talk_id_spin else 0
	var timg_val: int = int(talk_image_spin.value) if talk_image_spin else 8025
	var spd_val: float = float(move_speed_spin.value) if move_speed_spin else 60.0
	
	var snippet := """# --- Wonderland Online NPC Spawn Snippet ---
# NPC: %s (ID: %d) | Target Map: %d
var npc_scene = preload("res://scenes/world/npc.tscn")
var npc = npc_scene.instantiate() as NpcEntity
npc.name = "%s"
npc.npc_id = %d
npc.npc_name = "%s"
npc.model_jmp = "%s"
npc.model_jma = "%s"
npc.world_position = Vector2(%d, %d)
npc.heading = %d # %s
npc.talk_id = %d
npc.talk_image = %d
npc.dialogue_text = "%s"
npc.dialogue_choices = [%s]
npc.move_speed = %.1f
npc.walksteps = [%s]
npc.walkstep_delays = [%s]

# Add to active map scene container:
$Entities.add_child(npc)
""" % [
		npc_name_val,
		id_val,
		map_val,
		_get_safe_node_name(),
		id_val,
		npc_name_val.c_escape(),
		jmp_val,
		jma_val,
		sx_val,
		sy_val,
		_current_heading,
		heading_name,
		tid_val,
		timg_val,
		dialogue_escaped,
		choices_str,
		spd_val,
		walksteps_str,
		delays_str
	]
	return snippet

func _update_code_preview() -> void:
	if code_preview_edit:
		code_preview_edit.text = _generate_gdscript_snippet()

func _show_status_message(msg: String, is_error: bool = false) -> void:
	if not status_label:
		return
	status_label.text = msg
	if is_error:
		status_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 1.0))
	else:
		status_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.6, 1.0))
