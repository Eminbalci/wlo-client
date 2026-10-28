class_name QuestEditor
extends Control

## Wonderland Online Quest & Dialogue Tree Authoring Tool
## Production-ready, strictly type-hinted visual editor for designing, sequencing,
## previewing, and exporting multi-step quests and branching dialogue trees.

signal quest_loaded(quest_id: int)
signal quest_saved(file_path: String)
signal quest_script_exported(file_path: String)
signal objective_added(step_index: int, objective_type: String)
signal objective_removed(step_index: int)
signal objective_updated(step_index: int)
signal reward_item_added(item_id: int, count: int)
signal reward_item_removed(index: int)
signal dialogue_previewed(talk_id: int, preview_text: String)
signal preset_loaded(preset_name: String)

const CUSTOM_QUESTS_DIR: String = "user://custom_quests/"
const ASSETS_DATA_DIR: String = "res://assets/data/"

# --- Core Singletons & Data Sources ---
var _game_database: Node = null

# --- Quest Header State ---
var quest_id: int = 1001
var quest_title: String = "Prologue Ship Quest"
var quest_category: String = "Main" # "Main", "Branch", "Daily", "Event"
var min_level: int = 1
var prerequisite_quest_id: int = 0
var is_repeatable: bool = false
var quest_description: String = ""

# --- Multi-step Objective Sequencer State ---
var objectives: Array[Dictionary] = []
var selected_objective_index: int = -1

# --- Rewards Configuration State ---
var reward_exp: int = 100
var reward_gold: int = 50
var reward_items: Array[Dictionary] = []
var reward_skill_id: int = 0

# --- Built-in Presets ---
const PRESETS: Dictionary = {
	"Prologue Ship Quest": {
		"quest_id": 1001,
		"quest_title": "Prologue Ship Quest",
		"quest_category": "Main",
		"min_level": 1,
		"prerequisite_quest_id": 0,
		"is_repeatable": false,
		"quest_description": "Speak with Captain Robinson on the ship deck, check your cabin downstairs, and return safely.",
		"objectives": [
			{
				"step_index": 0,
				"type": "TalkToNPC",
				"npc_id": 14003,
				"npc_name": "Captain Robinson",
				"talk_id": 14003,
				"dialogue_preview": "Welcome aboard the ship! I am Captain Robinson. We are setting sail for North Island soon."
			},
			{
				"step_index": 1,
				"type": "ReachArea",
				"map_id": 10002,
				"map_name": "Ship Cabin",
				"target_pos": Vector2(750.0, 480.0),
				"radius": 64.0
			},
			{
				"step_index": 2,
				"type": "ReachArea",
				"map_id": 10001,
				"map_name": "Ship Deck",
				"target_pos": Vector2(1720.0, 906.0),
				"radius": 64.0
			}
		],
		"rewards": {
			"reward_exp": 100,
			"reward_gold": 50,
			"reward_items": [
				{
					"item_id": 23001,
					"item_name": "Small Knife",
					"count": 1
				}
			],
			"reward_skill_id": 0
		}
	},
	"Monkey Beach Awakening": {
		"quest_id": 1002,
		"quest_title": "Monkey Beach Awakening",
		"quest_category": "Main",
		"min_level": 1,
		"prerequisite_quest_id": 1001,
		"is_repeatable": false,
		"quest_description": "Awake on the shores of North Island beach, talk to Kelang the village leader, and collect coconuts.",
		"objectives": [
			{
				"step_index": 0,
				"type": "TalkToNPC",
				"npc_id": 14062,
				"npc_name": "Kelang",
				"talk_id": 14062,
				"dialogue_preview": "Greetings, traveler! Welcome to North Island. I am Kelang, leader of Kelan Village."
			},
			{
				"step_index": 1,
				"type": "CollectItem",
				"item_id": 32001,
				"item_name": "Coconut",
				"count": 3
			}
		],
		"rewards": {
			"reward_exp": 150,
			"reward_gold": 100,
			"reward_items": [],
			"reward_skill_id": 0
		}
	},
	"Kelan Trail Navigation": {
		"quest_id": 1003,
		"quest_title": "Kelan Trail Navigation",
		"quest_category": "Branch",
		"min_level": 3,
		"prerequisite_quest_id": 1002,
		"is_repeatable": false,
		"quest_description": "Travel across Kelan Trail, defeat wild Gel Monsters, and report safely to Kelan Village gates.",
		"objectives": [
			{
				"step_index": 0,
				"type": "ReachArea",
				"map_id": 11016,
				"map_name": "Kelan Trail",
				"target_pos": Vector2(400.0, 600.0),
				"radius": 80.0
			},
			{
				"step_index": 1,
				"type": "DefeatMonster",
				"monster_id": 1001,
				"monster_name": "Gel Monster",
				"count": 3
			},
			{
				"step_index": 2,
				"type": "ReachArea",
				"map_id": 12000,
				"map_name": "Kelan Village",
				"target_pos": Vector2(1200.0, 850.0),
				"radius": 64.0
			}
		],
		"rewards": {
			"reward_exp": 300,
			"reward_gold": 200,
			"reward_items": [],
			"reward_skill_id": 0
		}
	}
}

# --- UI Node References (Safely bound via unique names or path lookup) ---
var opt_presets: OptionButton = null
var btn_new_quest: Button = null
var btn_save_json: Button = null
var btn_load_json: Button = null
var btn_export_script: Button = null
var status_label: Label = null

# Header UI
var spin_quest_id: SpinBox = null
var edit_quest_title: LineEdit = null
var opt_quest_category: OptionButton = null
var spin_min_level: SpinBox = null
var spin_prereq_id: SpinBox = null
var chk_repeatable: CheckBox = null
var edit_quest_desc: TextEdit = null

# Objectives UI
var list_objectives: ItemList = null
var btn_add_step: Button = null
var btn_remove_step: Button = null
var btn_move_up_step: Button = null
var btn_move_down_step: Button = null
var btn_clear_steps: Button = null

var opt_step_type: OptionButton = null
var panel_step_talk: Control = null
var spin_talk_npc_id: SpinBox = null
var edit_talk_npc_name: LineEdit = null
var spin_talk_id: SpinBox = null
var edit_talk_preview: LineEdit = null
var btn_fetch_dialogue: Button = null

var panel_step_item: Control = null
var spin_item_id: SpinBox = null
var edit_item_name: LineEdit = null
var spin_item_count: SpinBox = null

var panel_step_monster: Control = null
var spin_monster_id: SpinBox = null
var edit_monster_name: LineEdit = null
var spin_monster_count: SpinBox = null

var panel_step_area: Control = null
var spin_area_map_id: SpinBox = null
var edit_area_map_name: LineEdit = null
var spin_area_pos_x: SpinBox = null
var spin_area_pos_y: SpinBox = null
var spin_area_radius: SpinBox = null

var btn_commit_step: Button = null

# Rewards UI
var spin_reward_exp: SpinBox = null
var spin_reward_gold: SpinBox = null
var spin_reward_skill_id: SpinBox = null
var lbl_reward_skill_name: Label = null
var list_reward_items: ItemList = null
var spin_add_item_id: SpinBox = null
var edit_add_item_name: LineEdit = null
var spin_add_item_count: SpinBox = null
var btn_add_reward_item: Button = null
var btn_remove_reward_item: Button = null

# Dialogue Previewer UI
var spin_preview_talk_id: SpinBox = null
var btn_preview_talk: Button = null
var lbl_preview_speaker: Label = null
var lbl_preview_meta: Label = null
var rich_preview_dialogue: RichTextLabel = null
var edit_preview_raw: TextEdit = null
var list_preview_choices: ItemList = null
var btn_follow_choice: Button = null

# Regex patterns for authentic WLO token extraction
var _sound_regex: RegEx = null
var _face_regex: RegEx = null
var _color_r_regex: RegEx = null
var _color_g_regex: RegEx = null
var _color_b_regex: RegEx = null
var _color_y_regex: RegEx = null
var _general_tag_regex: RegEx = null

func _init() -> void:
	_init_regexes()

func _ready() -> void:
	# The objective sequencer and dialogue preview need this much room to stay usable inside a tab.
	custom_minimum_size = Vector2(maxf(custom_minimum_size.x, 800.0), maxf(custom_minimum_size.y, 600.0))
	_ensure_node_refs()
	_init_ui_dropdowns()
	_connect_signals()
	
	# Load default initial preset
	load_preset("Prologue Ship Quest")
	_show_status("Quest & Dialogue Studio ready. Loaded: Prologue Ship Quest.")

# --- Database & Singleton Resolution ---

func _get_game_database() -> Node:
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

# --- UI Setup & Binding ---

func _ensure_node_refs() -> void:
	opt_presets = get_node_or_null("%OptPresets")
	btn_new_quest = get_node_or_null("%BtnNewQuest")
	btn_save_json = get_node_or_null("%BtnSaveJson")
	btn_load_json = get_node_or_null("%BtnLoadJson")
	btn_export_script = get_node_or_null("%BtnExportScript")
	status_label = get_node_or_null("%StatusLabel")

	spin_quest_id = get_node_or_null("%SpinQuestId")
	edit_quest_title = get_node_or_null("%EditQuestTitle")
	opt_quest_category = get_node_or_null("%OptQuestCategory")
	spin_min_level = get_node_or_null("%SpinMinLevel")
	spin_prereq_id = get_node_or_null("%SpinPrereqId")
	chk_repeatable = get_node_or_null("%ChkRepeatable")
	edit_quest_desc = get_node_or_null("%EditQuestDesc")

	list_objectives = get_node_or_null("%ListObjectives")
	btn_add_step = get_node_or_null("%BtnAddStep")
	btn_remove_step = get_node_or_null("%BtnRemoveStep")
	btn_move_up_step = get_node_or_null("%BtnMoveUpStep")
	btn_move_down_step = get_node_or_null("%BtnMoveDownStep")
	btn_clear_steps = get_node_or_null("%BtnClearSteps")

	opt_step_type = get_node_or_null("%OptStepType")
	panel_step_talk = get_node_or_null("%PanelStepTalk")
	spin_talk_npc_id = get_node_or_null("%SpinTalkNpcId")
	edit_talk_npc_name = get_node_or_null("%EditTalkNpcName")
	spin_talk_id = get_node_or_null("%SpinTalkId")
	edit_talk_preview = get_node_or_null("%EditTalkPreview")
	btn_fetch_dialogue = get_node_or_null("%BtnFetchDialogue")

	panel_step_item = get_node_or_null("%PanelStepItem")
	spin_item_id = get_node_or_null("%SpinItemId")
	edit_item_name = get_node_or_null("%EditItemName")
	spin_item_count = get_node_or_null("%SpinItemCount")

	panel_step_monster = get_node_or_null("%PanelStepMonster")
	spin_monster_id = get_node_or_null("%SpinMonsterId")
	edit_monster_name = get_node_or_null("%EditMonsterName")
	spin_monster_count = get_node_or_null("%SpinMonsterCount")

	panel_step_area = get_node_or_null("%PanelStepArea")
	spin_area_map_id = get_node_or_null("%SpinAreaMapId")
	edit_area_map_name = get_node_or_null("%EditAreaMapName")
	spin_area_pos_x = get_node_or_null("%SpinAreaPosX")
	spin_area_pos_y = get_node_or_null("%SpinAreaPosY")
	spin_area_radius = get_node_or_null("%SpinAreaRadius")

	btn_commit_step = get_node_or_null("%BtnCommitStep")

	spin_reward_exp = get_node_or_null("%SpinRewardExp")
	spin_reward_gold = get_node_or_null("%SpinRewardGold")
	spin_reward_skill_id = get_node_or_null("%SpinRewardSkillId")
	lbl_reward_skill_name = get_node_or_null("%LblRewardSkillName")
	list_reward_items = get_node_or_null("%ListRewardItems")
	spin_add_item_id = get_node_or_null("%SpinAddItemId")
	edit_add_item_name = get_node_or_null("%EditAddItemName")
	spin_add_item_count = get_node_or_null("%SpinAddItemCount")
	btn_add_reward_item = get_node_or_null("%BtnAddRewardItem")
	btn_remove_reward_item = get_node_or_null("%BtnRemoveRewardItem")

	spin_preview_talk_id = get_node_or_null("%SpinPreviewTalkId")
	btn_preview_talk = get_node_or_null("%BtnPreviewTalk")
	lbl_preview_speaker = get_node_or_null("%LblPreviewSpeaker")
	lbl_preview_meta = get_node_or_null("%LblPreviewMeta")
	rich_preview_dialogue = get_node_or_null("%RichPreviewDialogue")
	edit_preview_raw = get_node_or_null("%EditPreviewRaw")
	list_preview_choices = get_node_or_null("%ListPreviewChoices")
	btn_follow_choice = get_node_or_null("%BtnFollowChoice")

func _init_ui_dropdowns() -> void:
	if opt_presets and opt_presets.item_count == 0:
		opt_presets.clear()
		for p_name in PRESETS.keys():
			opt_presets.add_item(p_name)
	
	if opt_quest_category and opt_quest_category.item_count == 0:
		opt_quest_category.clear()
		opt_quest_category.add_item("Main")
		opt_quest_category.add_item("Branch")
		opt_quest_category.add_item("Daily")
		opt_quest_category.add_item("Event")

	if opt_step_type and opt_step_type.item_count == 0:
		opt_step_type.clear()
		opt_step_type.add_item("TalkToNPC")
		opt_step_type.add_item("CollectItem")
		opt_step_type.add_item("DefeatMonster")
		opt_step_type.add_item("ReachArea")

func _connect_signals() -> void:
	if opt_presets:
		opt_presets.item_selected.connect(_on_preset_selected)
	if btn_new_quest:
		btn_new_quest.pressed.connect(_on_btn_new_quest_pressed)
	if btn_save_json:
		btn_save_json.pressed.connect(_on_btn_save_json_pressed)
	if btn_load_json:
		btn_load_json.pressed.connect(_on_btn_load_json_pressed)
	if btn_export_script:
		btn_export_script.pressed.connect(_on_btn_export_script_pressed)

	# Header controls binding
	if spin_quest_id:
		spin_quest_id.value_changed.connect(func(v: float): quest_id = int(v))
	if edit_quest_title:
		edit_quest_title.text_changed.connect(func(t: String): quest_title = t)
	if opt_quest_category:
		opt_quest_category.item_selected.connect(func(idx: int): quest_category = opt_quest_category.get_item_text(idx))
	if spin_min_level:
		spin_min_level.value_changed.connect(func(v: float): min_level = int(v))
	if spin_prereq_id:
		spin_prereq_id.value_changed.connect(func(v: float): prerequisite_quest_id = int(v))
	if chk_repeatable:
		chk_repeatable.toggled.connect(func(b: bool): is_repeatable = b)
	if edit_quest_desc:
		edit_quest_desc.text_changed.connect(func(): quest_description = edit_quest_desc.text)

	# Objective Sequencer controls
	if list_objectives:
		list_objectives.item_selected.connect(_on_objective_selected)
	if btn_add_step:
		btn_add_step.pressed.connect(_on_btn_add_step_pressed)
	if btn_remove_step:
		btn_remove_step.pressed.connect(_on_btn_remove_step_pressed)
	if btn_move_up_step:
		btn_move_up_step.pressed.connect(_on_btn_move_up_step_pressed)
	if btn_move_down_step:
		btn_move_down_step.pressed.connect(_on_btn_move_down_step_pressed)
	if btn_clear_steps:
		btn_clear_steps.pressed.connect(clear_objectives)
	if opt_step_type:
		opt_step_type.item_selected.connect(_on_step_type_selected)
	if btn_commit_step:
		btn_commit_step.pressed.connect(_on_btn_commit_step_pressed)
	if btn_fetch_dialogue:
		btn_fetch_dialogue.pressed.connect(_on_btn_fetch_dialogue_pressed)

	# Rewards controls
	if spin_reward_exp:
		spin_reward_exp.value_changed.connect(func(v: float): reward_exp = int(v))
	if spin_reward_gold:
		spin_reward_gold.value_changed.connect(func(v: float): reward_gold = int(v))
	if spin_reward_skill_id:
		spin_reward_skill_id.value_changed.connect(_on_reward_skill_changed)
	if btn_add_reward_item:
		btn_add_reward_item.pressed.connect(_on_btn_add_reward_item_pressed)
	if btn_remove_reward_item:
		btn_remove_reward_item.pressed.connect(_on_btn_remove_reward_item_pressed)
	if spin_add_item_id:
		spin_add_item_id.value_changed.connect(_on_add_item_id_changed)

	# Dialogue Previewer controls
	if btn_preview_talk:
		btn_preview_talk.pressed.connect(_on_btn_preview_talk_pressed)
	if spin_preview_talk_id:
		spin_preview_talk_id.value_changed.connect(func(v: float): preview_dialogue(int(v)))
	if btn_follow_choice:
		btn_follow_choice.pressed.connect(_on_btn_follow_choice_pressed)

# --- Token Parsing Engine ---

func _init_regexes() -> void:
	_sound_regex = RegEx.new()
	_sound_regex.compile("#[sS]([a-zA-Z0-9_-]+?)(?:/#[sS]|(?=[^a-zA-Z0-9_-]|$|#))")
	_face_regex = RegEx.new()
	_face_regex.compile("#[fF]([0-9]+)(?:/#[fF])?")
	_color_r_regex = RegEx.new()
	_color_r_regex.compile("#[Rr](.*?)(?:/?#[Rr]|#[Ww]|$)")
	_color_g_regex = RegEx.new()
	_color_g_regex.compile("#[Gg](.*?)(?:/?#[Gg]|#[Ww]|$)")
	_color_b_regex = RegEx.new()
	_color_b_regex.compile("#[Bb](.*?)(?:/?#[Bb]|#[Ww]|$)")
	_color_y_regex = RegEx.new()
	_color_y_regex.compile("#[Yy](.*?)(?:/?#[Yy]|#[Ww]|$)")
	_general_tag_regex = RegEx.new()
	_general_tag_regex.compile("#[a-zA-Z0-9_-]+(?:/#[a-zA-Z0-9_-]+)?")

## Formats authentic WLO tokens (#n, #s, #f, #R, #B, #G, #Y) into Godot BBCode.
func parse_tokens(text: String, player_name: String = "Adventurer") -> String:
	if text.is_empty():
		return ""
	if not _sound_regex:
		_init_regexes()
	
	var s: String = text
	# Replace player name #n/#n or #n
	s = s.replace("#n/#n", player_name).replace("#n", player_name)

	# Strip sound and face tokens for rich text display
	if _sound_regex:
		s = _sound_regex.sub(s, "", true)
	if _face_regex:
		s = _face_regex.sub(s, "", true)

	# Replace colors with BBCode
	if _color_r_regex:
		s = _color_r_regex.sub(s, "[color=red]$1[/color]", true)
	if _color_g_regex:
		s = _color_g_regex.sub(s, "[color=green]$1[/color]", true)
	if _color_b_regex:
		s = _color_b_regex.sub(s, "[color=deep_sky_blue]$1[/color]", true)
	if _color_y_regex:
		s = _color_y_regex.sub(s, "[color=yellow]$1[/color]", true)

	# Strip lingering formatting tags
	if _general_tag_regex:
		s = _general_tag_regex.sub(s, "", true)

	return s.strip_edges()

## Extracts metadata tokens such as sound effect and portrait face index from raw text.
func extract_tokens(text: String) -> Dictionary:
	var sound: String = ""
	var face_idx: int = -1
	if not _sound_regex:
		_init_regexes()
	
	if _sound_regex:
		var sm := _sound_regex.search(text)
		if sm:
			sound = sm.get_string(1)
	if _face_regex:
		var fm := _face_regex.search(text)
		if fm:
			face_idx = fm.get_string(1).to_int()
	
	return {
		"sound": sound,
		"face_index": face_idx
	}

func _strip_bbcode(bbcode: String) -> String:
	var clean := bbcode
	var tag_regex := RegEx.new()
	tag_regex.compile("\\[.*?\\]")
	return tag_regex.sub(clean, "", true).strip_edges()

# --- Dialogue Lookup & Previewer ---

## Queries GameDatabase or falls back to built-in knowledge to resolve Talk records.
func lookup_dialogue(talk_id: int) -> Dictionary:
	var gdb = _get_game_database()
	if gdb:
		var talk_dict: Dictionary = gdb.get_talk(talk_id)
		if not talk_dict.is_empty():
			var raw: String = str(talk_dict.get("raw_text", talk_dict.get("text", "")))
			var parsed_bbcode: String = parse_tokens(raw)
			var plain: String = str(talk_dict.get("plain_text", ""))
			if plain.is_empty():
				plain = _strip_bbcode(parsed_bbcode)
			var tokens: Dictionary = extract_tokens(raw)
			var choices: Array = talk_dict.get("choices", [])
			return {
				"talk_id": talk_id,
				"speaker": str(talk_dict.get("speaker", "NPC #" + str(talk_id))),
				"raw_text": raw,
				"text": parsed_bbcode,
				"plain_text": plain,
				"face_index": talk_dict.get("face_index", tokens.face_index),
				"sound_effect": talk_dict.get("sound_effect", tokens.sound),
				"choices": choices,
				"next_talk_id": talk_dict.get("next_talk_id", 0)
			}
	
	# Fallback database resolution for common authentic dialogue IDs
	var fb_speaker: String = "NPC #" + str(talk_id)
	var fb_raw: String = "Dialogue for Talk ID #" + str(talk_id)
	var fb_choices: Array = []
	var fb_next: int = 0

	match talk_id:
		14003, 10001:
			fb_speaker = "Captain Robinson"
			fb_raw = "#s1402#f8025Welcome aboard the ship! I am #RCaptain Robinson#W. We are setting sail for North Island soon."
			fb_choices = [{"text": "I am ready, Captain!", "next_talk_id": 0, "branch": 1}]
		14062, 10062, 20304:
			fb_speaker = "Kelang"
			fb_raw = "#f8038Greetings, #n! Welcome to #GNorth Island#W. Be careful outside the village gates."
			fb_choices = [
				{"text": "Thank you, elder.", "next_talk_id": 20305, "branch": 1},
				{"text": "Where can I gather food?", "next_talk_id": 20314, "branch": 2}
			]
		30160:
			fb_speaker = "Peter"
			fb_raw = "#s01#f8005Is that you? Did you inspect the lower cabin?"
			fb_choices = [{"text": "Yes, everything is safe.", "next_talk_id": 30161, "branch": 1}]
		_:
			fb_speaker = "NPC #" + str(talk_id)
			fb_raw = "#n, here is your next objective for Talk #B" + str(talk_id) + "#W."

	var tokens: Dictionary = extract_tokens(fb_raw)
	var formatted_bbcode: String = parse_tokens(fb_raw)
	return {
		"talk_id": talk_id,
		"speaker": fb_speaker,
		"raw_text": fb_raw,
		"text": formatted_bbcode,
		"plain_text": _strip_bbcode(formatted_bbcode),
		"face_index": tokens.face_index,
		"sound_effect": tokens.sound,
		"choices": fb_choices,
		"next_talk_id": fb_next
	}

## Previews dialogue text and displays parsed tokens in UI.
func preview_dialogue(talk_id: int) -> Dictionary:
	var info: Dictionary = lookup_dialogue(talk_id)
	
	if lbl_preview_speaker:
		lbl_preview_speaker.text = "Speaker: " + str(info.speaker)
	if lbl_preview_meta:
		var face_str = str(info.face_index) if info.face_index >= 0 else "None"
		var sfx_str = str(info.sound_effect) if not str(info.sound_effect).is_empty() else "None"
		lbl_preview_meta.text = "Portrait Face: %s | Sound SFX: %s | Talk ID: %d" % [face_str, sfx_str, talk_id]
	if rich_preview_dialogue:
		rich_preview_dialogue.text = str(info.text)
	if edit_preview_raw:
		edit_preview_raw.text = str(info.raw_text)
	
	if list_preview_choices:
		list_preview_choices.clear()
		var choices: Array = info.get("choices", [])
		for c in choices:
			var opt_text: String = str(c.get("text", "Choice"))
			var next_id: int = int(c.get("next_talk_id", 0))
			list_preview_choices.add_item("%s -> (Next Talk: %d)" % [opt_text, next_id])
	
	dialogue_previewed.emit(talk_id, str(info.plain_text))
	return info

# --- Multi-step Objective Sequencer Implementation ---

## Adds an objective to the sequence, returns its new index.
func add_objective(obj_type: String, data: Dictionary = {}) -> int:
	var new_index: int = objectives.size()
	var step: Dictionary = {
		"step_index": new_index,
		"type": obj_type
	}

	match obj_type:
		"TalkToNPC":
			step["npc_id"] = int(data.get("npc_id", 14003))
			step["npc_name"] = str(data.get("npc_name", "Captain Robinson"))
			step["talk_id"] = int(data.get("talk_id", 14003))
			step["dialogue_preview"] = str(data.get("dialogue_preview", "Welcome aboard the ship!"))
		"CollectItem":
			step["item_id"] = int(data.get("item_id", 32001))
			step["item_name"] = str(data.get("item_name", "Coconut"))
			step["count"] = maxi(1, int(data.get("count", 1)))
		"DefeatMonster":
			step["monster_id"] = int(data.get("monster_id", 1001))
			step["monster_name"] = str(data.get("monster_name", "Gel Monster"))
			step["count"] = maxi(1, int(data.get("count", 1)))
		"ReachArea":
			step["map_id"] = int(data.get("map_id", 10001))
			step["map_name"] = str(data.get("map_name", "Ship Deck"))
			step["target_pos"] = data.get("target_pos", Vector2(1720.0, 906.0))
			step["radius"] = float(data.get("radius", 64.0))
		_:
			push_error("Unsupported objective type: " + obj_type)
			return -1

	objectives.append(step)
	_reindex_objectives()
	_refresh_objectives_list()
	objective_added.emit(new_index, obj_type)
	return new_index

## Removes an objective at the given step index.
func remove_objective(index: int) -> bool:
	if index < 0 or index >= objectives.size():
		return false
	objectives.remove_at(index)
	_reindex_objectives()
	_refresh_objectives_list()
	if selected_objective_index >= objectives.size():
		selected_objective_index = objectives.size() - 1
	_sync_selected_objective_to_ui()
	objective_removed.emit(index)
	return true

## Updates an existing objective at index.
func update_objective(index: int, data: Dictionary) -> bool:
	if index < 0 or index >= objectives.size():
		return false
	var step: Dictionary = objectives[index]
	for k in data.keys():
		step[k] = data[k]
	step["step_index"] = index
	objectives[index] = step
	_refresh_objectives_list()
	objective_updated.emit(index)
	return true

## Moves an objective earlier in the sequence.
func move_objective_up(index: int) -> bool:
	if index <= 0 or index >= objectives.size():
		return false
	var temp = objectives[index]
	objectives[index] = objectives[index - 1]
	objectives[index - 1] = temp
	_reindex_objectives()
	_refresh_objectives_list()
	selected_objective_index = index - 1
	if list_objectives:
		list_objectives.select(selected_objective_index)
	return true

## Moves an objective later in the sequence.
func move_objective_down(index: int) -> bool:
	if index < 0 or index >= objectives.size() - 1:
		return false
	var temp = objectives[index]
	objectives[index] = objectives[index + 1]
	objectives[index + 1] = temp
	_reindex_objectives()
	_refresh_objectives_list()
	selected_objective_index = index + 1
	if list_objectives:
		list_objectives.select(selected_objective_index)
	return true

## Clears all objectives from the sequencer.
func clear_objectives() -> void:
	objectives.clear()
	selected_objective_index = -1
	_refresh_objectives_list()
	_sync_selected_objective_to_ui()

## Returns an objective dictionary by index.
func get_objective(index: int) -> Dictionary:
	if index >= 0 and index < objectives.size():
		return objectives[index].duplicate(true)
	return {}

## Returns a copy of all objectives.
func get_objectives() -> Array[Dictionary]:
	return objectives.duplicate(true)

func _reindex_objectives() -> void:
	for i in range(objectives.size()):
		objectives[i]["step_index"] = i

func _refresh_objectives_list() -> void:
	if not list_objectives:
		return
	list_objectives.clear()
	for i in range(objectives.size()):
		var step: Dictionary = objectives[i]
		var desc: String = _format_objective_description(step)
		list_objectives.add_item("Step %d: %s" % [i + 1, desc])

func _format_objective_description(step: Dictionary) -> String:
	var t: String = str(step.get("type", "Unknown"))
	match t:
		"TalkToNPC":
			var n: String = str(step.get("npc_name", "NPC"))
			var tid: int = int(step.get("talk_id", 0))
			return "[Talk] Speak with %s (Talk ID: %d)" % [n, tid]
		"CollectItem":
			var iname: String = str(step.get("item_name", "Item"))
			var c: int = int(step.get("count", 1))
			return "[Gather] Collect %s x%d" % [iname, c]
		"DefeatMonster":
			var mname: String = str(step.get("monster_name", "Monster"))
			var c: int = int(step.get("count", 1))
			return "[Hunt] Defeat %s x%d" % [mname, c]
		"ReachArea":
			var mname: String = str(step.get("map_name", "Area"))
			var mid: int = int(step.get("map_id", 0))
			var p = step.get("target_pos", Vector2.ZERO)
			return "[Travel] Reach %s (Map %d) at %s" % [mname, mid, str(p)]
	return "[Objective] " + t

func _on_objective_selected(index: int) -> void:
	selected_objective_index = index
	_sync_selected_objective_to_ui()

func _sync_selected_objective_to_ui() -> void:
	if selected_objective_index < 0 or selected_objective_index >= objectives.size():
		return
	var step: Dictionary = objectives[selected_objective_index]
	var t: String = str(step.get("type", "TalkToNPC"))
	
	if opt_step_type:
		for i in range(opt_step_type.item_count):
			if opt_step_type.get_item_text(i) == t:
				opt_step_type.selected = i
				break
	_update_step_panel_visibility(t)

	match t:
		"TalkToNPC":
			if spin_talk_npc_id:
				spin_talk_npc_id.value = step.get("npc_id", 14003)
			if edit_talk_npc_name:
				edit_talk_npc_name.text = step.get("npc_name", "Captain Robinson")
			if spin_talk_id:
				spin_talk_id.value = step.get("talk_id", 14003)
			if edit_talk_preview:
				edit_talk_preview.text = step.get("dialogue_preview", "")
		"CollectItem":
			if spin_item_id:
				spin_item_id.value = step.get("item_id", 32001)
			if edit_item_name:
				edit_item_name.text = step.get("item_name", "Coconut")
			if spin_item_count:
				spin_item_count.value = step.get("count", 1)
		"DefeatMonster":
			if spin_monster_id:
				spin_monster_id.value = step.get("monster_id", 1001)
			if edit_monster_name:
				edit_monster_name.text = step.get("monster_name", "Gel Monster")
			if spin_monster_count:
				spin_monster_count.value = step.get("count", 1)
		"ReachArea":
			if spin_area_map_id:
				spin_area_map_id.value = step.get("map_id", 10001)
			if edit_area_map_name:
				edit_area_map_name.text = step.get("map_name", "Ship Deck")
			var p = step.get("target_pos", Vector2.ZERO)
			if p is Dictionary:
				p = Vector2(p.get("x", 0.0), p.get("y", 0.0))
			if spin_area_pos_x:
				spin_area_pos_x.value = p.x
			if spin_area_pos_y:
				spin_area_pos_y.value = p.y
			if spin_area_radius:
				spin_area_radius.value = step.get("radius", 64.0)

func _update_step_panel_visibility(type_name: String) -> void:
	if panel_step_talk:
		panel_step_talk.visible = (type_name == "TalkToNPC")
	if panel_step_item:
		panel_step_item.visible = (type_name == "CollectItem")
	if panel_step_monster:
		panel_step_monster.visible = (type_name == "DefeatMonster")
	if panel_step_area:
		panel_step_area.visible = (type_name == "ReachArea")

func _on_step_type_selected(idx: int) -> void:
	if not opt_step_type:
		return
	var t: String = opt_step_type.get_item_text(idx)
	_update_step_panel_visibility(t)

func _on_btn_add_step_pressed() -> void:
	var t: String = "TalkToNPC"
	if opt_step_type:
		t = opt_step_type.get_item_text(opt_step_type.selected)
	var data: Dictionary = _collect_current_step_form_data(t)
	var new_idx: int = add_objective(t, data)
	selected_objective_index = new_idx
	if list_objectives:
		list_objectives.select(new_idx)
	_show_status("Added new %s objective." % t)

func _on_btn_remove_step_pressed() -> void:
	if selected_objective_index >= 0:
		remove_objective(selected_objective_index)
		_show_status("Removed objective.")

func _on_btn_move_up_step_pressed() -> void:
	if selected_objective_index > 0:
		move_objective_up(selected_objective_index)

func _on_btn_move_down_step_pressed() -> void:
	if selected_objective_index >= 0 and selected_objective_index < objectives.size() - 1:
		move_objective_down(selected_objective_index)

func _on_btn_commit_step_pressed() -> void:
	if selected_objective_index < 0 or selected_objective_index >= objectives.size():
		return
	var t: String = "TalkToNPC"
	if opt_step_type:
		t = opt_step_type.get_item_text(opt_step_type.selected)
	var data: Dictionary = _collect_current_step_form_data(t)
	data["type"] = t
	update_objective(selected_objective_index, data)
	_show_status("Updated objective step %d." % (selected_objective_index + 1))

func _collect_current_step_form_data(t: String) -> Dictionary:
	var data: Dictionary = {}
	match t:
		"TalkToNPC":
			data["npc_id"] = int(spin_talk_npc_id.value) if spin_talk_npc_id else 14003
			data["npc_name"] = edit_talk_npc_name.text if edit_talk_npc_name else "Captain Robinson"
			data["talk_id"] = int(spin_talk_id.value) if spin_talk_id else 14003
			data["dialogue_preview"] = edit_talk_preview.text if edit_talk_preview else ""
		"CollectItem":
			data["item_id"] = int(spin_item_id.value) if spin_item_id else 32001
			data["item_name"] = edit_item_name.text if edit_item_name else "Coconut"
			data["count"] = int(spin_item_count.value) if spin_item_count else 1
		"DefeatMonster":
			data["monster_id"] = int(spin_monster_id.value) if spin_monster_id else 1001
			data["monster_name"] = edit_monster_name.text if edit_monster_name else "Gel Monster"
			data["count"] = int(spin_monster_count.value) if spin_monster_count else 1
		"ReachArea":
			data["map_id"] = int(spin_area_map_id.value) if spin_area_map_id else 10001
			data["map_name"] = edit_area_map_name.text if edit_area_map_name else "Ship Deck"
			var px: float = spin_area_pos_x.value if spin_area_pos_x else 0.0
			var py: float = spin_area_pos_y.value if spin_area_pos_y else 0.0
			data["target_pos"] = Vector2(px, py)
			data["radius"] = spin_area_radius.value if spin_area_radius else 64.0
	return data

func _on_btn_fetch_dialogue_pressed() -> void:
	var tid: int = int(spin_talk_id.value) if spin_talk_id else 14003
	var info: Dictionary = preview_dialogue(tid)
	if edit_talk_preview:
		edit_talk_preview.text = str(info.plain_text)
	if edit_talk_npc_name and str(edit_talk_npc_name.text).is_empty():
		edit_talk_npc_name.text = str(info.speaker)
	_show_status("Fetched talk #%d for objective preview." % tid)

# --- Rewards Configuration Implementation ---

## Configures the quest reward payouts.
func set_rewards(exp: int, gold: int, items: Array[Dictionary], skill_id: int) -> void:
	reward_exp = exp
	reward_gold = gold
	reward_items = items.duplicate(true)
	reward_skill_id = skill_id
	_sync_rewards_to_ui()

## Adds a reward item to the payout roster.
func add_reward_item(item_id: int, item_name: String, count: int) -> void:
	reward_items.append({
		"item_id": item_id,
		"item_name": item_name,
		"count": maxi(1, count)
	})
	_refresh_reward_items_list()
	reward_item_added.emit(item_id, count)

## Removes a reward item at index.
func remove_reward_item(index: int) -> bool:
	if index < 0 or index >= reward_items.size():
		return false
	reward_items.remove_at(index)
	_refresh_reward_items_list()
	reward_item_removed.emit(index)
	return true

## Clears all reward items.
func clear_reward_items() -> void:
	reward_items.clear()
	_refresh_reward_items_list()

func _sync_rewards_to_ui() -> void:
	if spin_reward_exp:
		spin_reward_exp.value = reward_exp
	if spin_reward_gold:
		spin_reward_gold.value = reward_gold
	if spin_reward_skill_id:
		spin_reward_skill_id.value = reward_skill_id
		_on_reward_skill_changed(float(reward_skill_id))
	_refresh_reward_items_list()

func _refresh_reward_items_list() -> void:
	if not list_reward_items:
		return
	list_reward_items.clear()
	for i in range(reward_items.size()):
		var itm: Dictionary = reward_items[i]
		list_reward_items.add_item("%s (ID: %d) x%d" % [
			itm.get("item_name", "Item"),
			int(itm.get("item_id", 0)),
			int(itm.get("count", 1))
		])

func _on_reward_skill_changed(val: float) -> void:
	reward_skill_id = int(val)
	if not lbl_reward_skill_name:
		return
	if reward_skill_id <= 0:
		lbl_reward_skill_name.text = "(None)"
		return
	var gdb = _get_game_database()
	if gdb and gdb.skills:
		var rec = gdb.skills.get_skill(reward_skill_id)
		if rec:
			lbl_reward_skill_name.text = str(rec.name)
			return
	lbl_reward_skill_name.text = "Skill #%d" % reward_skill_id

func _on_add_item_id_changed(val: float) -> void:
	var itm_id: int = int(val)
	if not edit_add_item_name:
		return
	var gdb = _get_game_database()
	if gdb and gdb.items:
		var rec = gdb.items.get_item(itm_id)
		if rec:
			edit_add_item_name.text = str(rec.name)
			return
	if itm_id == 23001:
		edit_add_item_name.text = "Small Knife"
	elif itm_id == 32001:
		edit_add_item_name.text = "Coconut"

func _on_btn_add_reward_item_pressed() -> void:
	var itm_id: int = int(spin_add_item_id.value) if spin_add_item_id else 0
	var itm_name: String = edit_add_item_name.text if edit_add_item_name else "Item"
	var itm_cnt: int = int(spin_add_item_count.value) if spin_add_item_count else 1
	if itm_id <= 0:
		_show_status("Invalid Item ID for reward.")
		return
	add_reward_item(itm_id, itm_name, itm_cnt)
	_show_status("Added reward item: %s x%d" % [itm_name, itm_cnt])

func _on_btn_remove_reward_item_pressed() -> void:
	if not list_reward_items:
		return
	var sel = list_reward_items.get_selected_items()
	if sel.size() > 0:
		remove_reward_item(sel[0])
		_show_status("Removed reward item.")

# --- Presets Implementation ---

## Loads a built-in or custom quest preset.
func load_preset(preset_name: String) -> bool:
	if not PRESETS.has(preset_name):
		return false
	var p: Dictionary = PRESETS[preset_name]
	apply_quest_data(p)
	preset_loaded.emit(preset_name)
	_show_status("Loaded preset: " + preset_name)
	return true

## Returns all available preset names.
func get_preset_names() -> Array[String]:
	var names: Array[String] = []
	for k in PRESETS.keys():
		names.append(str(k))
	return names

func _on_preset_selected(idx: int) -> void:
	if not opt_presets:
		return
	var p_name: String = opt_presets.get_item_text(idx)
	load_preset(p_name)

# --- Serialization & Export / Import Engine ---

## Serializes current quest configuration into complete dictionary payload.
func create_quest_data() -> Dictionary:
	var clean_objectives: Array[Dictionary] = []
	for obj in objectives:
		var c = obj.duplicate(true)
		if c.has("target_pos") and c["target_pos"] is Vector2:
			c["target_pos"] = {"x": c["target_pos"].x, "y": c["target_pos"].y}
		clean_objectives.append(c)

	return {
		"quest_id": quest_id,
		"quest_title": quest_title,
		"quest_category": quest_category,
		"min_level": min_level,
		"prerequisite_quest_id": prerequisite_quest_id,
		"is_repeatable": is_repeatable,
		"quest_description": quest_description,
		"objectives": clean_objectives,
		"rewards": {
			"reward_exp": reward_exp,
			"reward_gold": reward_gold,
			"reward_items": reward_items.duplicate(true),
			"reward_skill_id": reward_skill_id
		},
		"format_version": "1.0",
		"created_at": Time.get_datetime_string_from_system()
	}

## Applies a loaded dictionary payload into editor state and UI.
func apply_quest_data(data: Dictionary) -> void:
	quest_id = int(data.get("quest_id", 1001))
	quest_title = str(data.get("quest_title", "Custom Quest"))
	quest_category = str(data.get("quest_category", "Main"))
	min_level = int(data.get("min_level", 1))
	prerequisite_quest_id = int(data.get("prerequisite_quest_id", 0))
	is_repeatable = bool(data.get("is_repeatable", false))
	quest_description = str(data.get("quest_description", ""))

	# Parse objectives
	objectives.clear()
	var raw_objs = data.get("objectives", [])
	for o in raw_objs:
		var item: Dictionary = o.duplicate(true)
		if item.has("target_pos"):
			var tp = item["target_pos"]
			if tp is Dictionary:
				item["target_pos"] = Vector2(float(tp.get("x", 0.0)), float(tp.get("y", 0.0)))
			elif tp is Array and tp.size() >= 2:
				item["target_pos"] = Vector2(float(tp[0]), float(tp[1]))
		objectives.append(item)
	_reindex_objectives()

	# Parse rewards
	var r = data.get("rewards", {})
	reward_exp = int(r.get("reward_exp", 0))
	reward_gold = int(r.get("reward_gold", 0))
	reward_skill_id = int(r.get("reward_skill_id", 0))
	reward_items.clear()
	var raw_items = r.get("reward_items", [])
	for itm in raw_items:
		reward_items.append(itm.duplicate(true))

	_sync_all_to_ui()

func _sync_all_to_ui() -> void:
	if spin_quest_id:
		spin_quest_id.value = quest_id
	if edit_quest_title:
		edit_quest_title.text = quest_title
	if opt_quest_category:
		for i in range(opt_quest_category.item_count):
			if opt_quest_category.get_item_text(i) == quest_category:
				opt_quest_category.selected = i
				break
	if spin_min_level:
		spin_min_level.value = min_level
	if spin_prereq_id:
		spin_prereq_id.value = prerequisite_quest_id
	if chk_repeatable:
		chk_repeatable.button_pressed = is_repeatable
	if edit_quest_desc:
		edit_quest_desc.text = quest_description

	_refresh_objectives_list()
	if objectives.size() > 0:
		selected_objective_index = 0
		if list_objectives:
			list_objectives.select(0)
		_sync_selected_objective_to_ui()
	else:
		selected_objective_index = -1

	_sync_rewards_to_ui()

## Exports quest data as JSON to file path (supports user:// and res://).
func save_quest(path: String = "") -> bool:
	if path.is_empty():
		path = CUSTOM_QUESTS_DIR + "quest_%d.json" % quest_id

	var base_dir: String = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(base_dir):
		DirAccess.make_dir_recursive_absolute(base_dir)

	var payload: Dictionary = create_quest_data()
	var json_str: String = JSON.stringify(payload, "\t")
	
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("Failed to open file for writing: " + path)
		return false
	file.store_string(json_str)
	file.close()

	quest_saved.emit(path)
	_show_status("Quest successfully saved to: " + path)
	return true

## Loads quest data from JSON file path.
func load_quest(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Quest file not found: " + path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Failed to read quest file: " + path)
		return {}
	var text: String = file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if not parsed or not (parsed is Dictionary):
		push_error("Invalid quest JSON content in: " + path)
		return {}

	apply_quest_data(parsed)
	quest_loaded.emit(quest_id)
	_show_status("Quest successfully loaded from: " + path)
	return parsed

## Exports a standalone GDScript quest file extending RefCounted.
func export_quest_script(path: String = "") -> String:
	if path.is_empty():
		path = CUSTOM_QUESTS_DIR + "quest_%d.gd" % quest_id

	var script_lines: Array[String] = []
	script_lines.append("class_name Quest_%d" % quest_id)
	script_lines.append("extends RefCounted")
	script_lines.append("")
	script_lines.append("## Autogenerated Quest Script: %s" % quest_title)
	script_lines.append("## Wonderland Online Quest Definition")
	script_lines.append("## Category: %s | Min Level: %d | Prereq: %d | Repeatable: %s" % [
		quest_category, min_level, prerequisite_quest_id, str(is_repeatable)
	])
	script_lines.append("")
	script_lines.append("const QUEST_ID: int = %d" % quest_id)
	script_lines.append("const QUEST_TITLE: String = \"%s\"" % quest_title.c_escape())
	script_lines.append("const QUEST_CATEGORY: String = \"%s\"" % quest_category)
	script_lines.append("const MIN_LEVEL: int = %d" % min_level)
	script_lines.append("const PREREQUISITE_QUEST_ID: int = %d" % prerequisite_quest_id)
	script_lines.append("const IS_REPEATABLE: bool = %s" % str(is_repeatable).to_lower())
	script_lines.append("const QUEST_DESCRIPTION: String = \"%s\"" % quest_description.c_escape())
	script_lines.append("")
	script_lines.append("enum QuestStatus { NOT_STARTED, IN_PROGRESS, READY_FOR_TURN_IN, COMPLETED }")
	script_lines.append("")
	script_lines.append("var status: QuestStatus = QuestStatus.NOT_STARTED")
	script_lines.append("var current_step_index: int = 0")
	script_lines.append("")
	script_lines.append("const OBJECTIVES: Array[Dictionary] = [")

	for i in range(objectives.size()):
		var obj: Dictionary = objectives[i]
		var t: String = str(obj.get("type", "TalkToNPC"))
		script_lines.append("\t{")
		script_lines.append("\t\t\"step_index\": %d," % i)
		script_lines.append("\t\t\"type\": \"%s\"," % t)
		match t:
			"TalkToNPC":
				script_lines.append("\t\t\"npc_id\": %d," % int(obj.get("npc_id", 0)))
				script_lines.append("\t\t\"npc_name\": \"%s\"," % str(obj.get("npc_name", "")).c_escape())
				script_lines.append("\t\t\"talk_id\": %d," % int(obj.get("talk_id", 0)))
				script_lines.append("\t\t\"dialogue_preview\": \"%s\"" % str(obj.get("dialogue_preview", "")).c_escape())
			"CollectItem":
				script_lines.append("\t\t\"item_id\": %d," % int(obj.get("item_id", 0)))
				script_lines.append("\t\t\"item_name\": \"%s\"," % str(obj.get("item_name", "")).c_escape())
				script_lines.append("\t\t\"count\": %d" % int(obj.get("count", 1)))
			"DefeatMonster":
				script_lines.append("\t\t\"monster_id\": %d," % int(obj.get("monster_id", 0)))
				script_lines.append("\t\t\"monster_name\": \"%s\"," % str(obj.get("monster_name", "")).c_escape())
				script_lines.append("\t\t\"count\": %d" % int(obj.get("count", 1)))
			"ReachArea":
				script_lines.append("\t\t\"map_id\": %d," % int(obj.get("map_id", 0)))
				script_lines.append("\t\t\"map_name\": \"%s\"," % str(obj.get("map_name", "")).c_escape())
				var pos = obj.get("target_pos", Vector2.ZERO)
				if pos is Dictionary:
					pos = Vector2(float(pos.get("x", 0.0)), float(pos.get("y", 0.0)))
				script_lines.append("\t\t\"target_pos\": Vector2(%f, %f)," % [pos.x, pos.y])
				script_lines.append("\t\t\"radius\": %f" % float(obj.get("radius", 64.0)))
		script_lines.append("\t}%s" % ("," if i < objectives.size() - 1 else ""))

	script_lines.append("]")
	script_lines.append("")
	script_lines.append("const REWARDS: Dictionary = {")
	script_lines.append("\t\"reward_exp\": %d," % reward_exp)
	script_lines.append("\t\"reward_gold\": %d," % reward_gold)
	script_lines.append("\t\"reward_skill_id\": %d," % reward_skill_id)
	script_lines.append("\t\"reward_items\": [")

	for j in range(reward_items.size()):
		var itm = reward_items[j]
		script_lines.append("\t\t{\"item_id\": %d, \"item_name\": \"%s\", \"count\": %d}%s" % [
			int(itm.get("item_id", 0)),
			str(itm.get("item_name", "")).c_escape(),
			int(itm.get("count", 1)),
			"," if j < reward_items.size() - 1 else ""
		])

	script_lines.append("\t]")
	script_lines.append("}")
	script_lines.append("")
	script_lines.append("func get_quest_id() -> int:")
	script_lines.append("\treturn QUEST_ID")
	script_lines.append("")
	script_lines.append("func get_title() -> String:")
	script_lines.append("\treturn QUEST_TITLE")
	script_lines.append("")
	script_lines.append("func get_objectives_count() -> int:")
	script_lines.append("\treturn OBJECTIVES.size()")
	script_lines.append("")
	script_lines.append("func get_current_objective() -> Dictionary:")
	script_lines.append("\tif current_step_index < OBJECTIVES.size():")
	script_lines.append("\t\treturn OBJECTIVES[current_step_index]")
	script_lines.append("\treturn {}")
	script_lines.append("")
	script_lines.append("func advance_step() -> bool:")
	script_lines.append("\tif current_step_index < OBJECTIVES.size() - 1:")
	script_lines.append("\t\tcurrent_step_index += 1")
	script_lines.append("\t\tstatus = QuestStatus.IN_PROGRESS")
	script_lines.append("\t\treturn true")
	script_lines.append("\tstatus = QuestStatus.READY_FOR_TURN_IN")
	script_lines.append("\treturn false")
	script_lines.append("")
	script_lines.append("func complete_quest() -> Dictionary:")
	script_lines.append("\tstatus = QuestStatus.COMPLETED")
	script_lines.append("\treturn REWARDS.duplicate(true)")
	script_lines.append("")
	script_lines.append("func reset_quest() -> void:")
	script_lines.append("\tif IS_REPEATABLE:")
	script_lines.append("\t\tstatus = QuestStatus.NOT_STARTED")
	script_lines.append("\t\tcurrent_step_index = 0")
	script_lines.append("")

	var code_output: String = "\n".join(script_lines)

	if not path.is_empty():
		var base_dir: String = path.get_base_dir()
		if not DirAccess.dir_exists_absolute(base_dir):
			DirAccess.make_dir_recursive_absolute(base_dir)
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file:
			file.store_string(code_output)
			file.close()
			quest_script_exported.emit(path)

	_show_status("Exported quest script: " + path)
	return code_output

# --- UI Button Handlers ---

func _on_btn_new_quest_pressed() -> void:
	quest_id = 2001
	quest_title = "New Quest"
	quest_category = "Main"
	min_level = 1
	prerequisite_quest_id = 0
	is_repeatable = false
	quest_description = ""
	clear_objectives()
	set_rewards(50, 25, [], 0)
	_sync_all_to_ui()
	_show_status("Created new blank quest template.")

func _on_btn_save_json_pressed() -> void:
	save_quest()

func _on_btn_load_json_pressed() -> void:
	load_quest(CUSTOM_QUESTS_DIR + "quest_%d.json" % quest_id)

func _on_btn_export_script_pressed() -> void:
	export_quest_script()

func _on_btn_preview_talk_pressed() -> void:
	var tid: int = int(spin_preview_talk_id.value) if spin_preview_talk_id else 14003
	preview_dialogue(tid)

func _on_btn_follow_choice_pressed() -> void:
	if not list_preview_choices:
		return
	var sel = list_preview_choices.get_selected_items()
	if sel.size() == 0:
		return
	var item_text: String = list_preview_choices.get_item_text(sel[0])
	var regex := RegEx.new()
	regex.compile("Next Talk: ([0-9]+)")
	var m = regex.search(item_text)
	if m:
		var target_talk_id: int = m.get_string(1).to_int()
		if target_talk_id > 0:
			if spin_preview_talk_id:
				spin_preview_talk_id.value = target_talk_id
			preview_dialogue(target_talk_id)
			_show_status("Traversed choice branch to Talk ID: %d" % target_talk_id)

func _show_status(msg: String) -> void:
	if status_label:
		status_label.text = msg
