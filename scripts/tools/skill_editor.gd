class_name SkillEditor
extends Control

## Wonderland Online Skill & Combat VFX Authoring Studio
## Strictly type-hinted visual editor for designing, configuring, testing,
## simulating formulas, timeline VFX binding, and exporting combat skills.

signal skill_changed(skill_id: int)
signal skill_saved(path: String)
signal skill_loaded(skill_id: int)
signal skill_exported(path: String)
signal formula_simulated(result: int, breakdown: String)
signal preset_loaded(preset_name: String)
signal database_skills_populated(count: int)

enum Element {
	NONE = 0,
	EARTH = 1,
	WATER = 2,
	FIRE = 3,
	WIND = 4
}

enum SkillType {
	PHYSICAL = 0,
	MAGIC = 1,
	ASSIST = 2,
	STATUS = 3,
	SPECIAL = 4
}

enum TargetScope {
	SINGLE = 0,
	ROW = 1,
	COLUMN = 2,
	CROSS = 3,
	ALL = 4
}

# --- Skill Identity ---
var skill_id: int = 15039
var skill_name: String = "Wine Flame"
var description: String = "Spits burning wine flame causing fiery physical damage."
var element: int = Element.FIRE
var skill_type: int = SkillType.PHYSICAL
var target_scope: int = TargetScope.SINGLE
var sp_cost: int = 20
var hp_cost: int = 0
var cooldown_turns: int = 0
var required_level: int = 1

# --- Combat Mechanics & Formula Preview ---
var base_damage: int = 85
var damage_multiplier_1: float = 1.2
var damage_multiplier_2: float = 0.0

# --- Motion Timeline & VFX Binding ---
var mbtm_motion_id: int = 60010
var cast_sfx_name: String = "wav9911.wav"
var hit_sfx_name: String = "wav9912.wav"
var vfx_animation_id: int = 60010

# --- Simulation Input State ---
var sim_user_atk: int = 100
var sim_user_matk: int = 80
var sim_target_def: int = 20
var sim_target_mdef: int = 20
var sim_user_elem: int = Element.FIRE
var sim_target_elem: int = Element.WIND
var last_sim_result: int = 0
var last_sim_breakdown: String = ""

# --- Timeline & Animation State ---
var is_playing: bool = false
var current_frame: int = 0
const TOTAL_FRAMES: int = 30
var fps: float = 15.0
var _anim_accumulator: float = 0.0
var _vfx_burst_radius: float = 0.0
var _vfx_particles: Array[Dictionary] = []
var _target_flash_time: float = 0.0

# --- Presets Definition ---
const PRESETS: Dictionary = {
	"Wine Flame": {
		"skill_id": 15039,
		"skill_name": "Wine Flame",
		"description": "Spits burning wine flame causing fiery physical damage.",
		"element": Element.FIRE,
		"skill_type": SkillType.PHYSICAL,
		"target_scope": TargetScope.SINGLE,
		"sp_cost": 20,
		"hp_cost": 0,
		"cooldown_turns": 0,
		"required_level": 1,
		"base_damage": 85,
		"damage_multiplier_1": 1.2,
		"damage_multiplier_2": 0.0,
		"mbtm_motion_id": 60010,
		"cast_sfx_name": "wav9911.wav",
		"hit_sfx_name": "wav9912.wav",
		"vfx_animation_id": 60010
	},
	"Leap": {
		"skill_id": 12036,
		"skill_name": "Leap",
		"description": "Leaps swift as the wind to strike the target.",
		"element": Element.WIND,
		"skill_type": SkillType.PHYSICAL,
		"target_scope": TargetScope.SINGLE,
		"sp_cost": 15,
		"hp_cost": 0,
		"cooldown_turns": 0,
		"required_level": 1,
		"base_damage": 70,
		"damage_multiplier_1": 1.1,
		"damage_multiplier_2": 0.0,
		"mbtm_motion_id": 60005,
		"cast_sfx_name": "wav9913.wav",
		"hit_sfx_name": "wav9914.wav",
		"vfx_animation_id": 60005
	},
	"Summon Dogs": {
		"skill_id": 11075,
		"skill_name": "Summon Dogs",
		"description": "Summons a pack of hounds to trample an entire row.",
		"element": Element.EARTH,
		"skill_type": SkillType.PHYSICAL,
		"target_scope": TargetScope.ROW,
		"sp_cost": 35,
		"hp_cost": 0,
		"cooldown_turns": 1,
		"required_level": 5,
		"base_damage": 110,
		"damage_multiplier_1": 1.25,
		"damage_multiplier_2": 0.0,
		"mbtm_motion_id": 60001,
		"cast_sfx_name": "wav9915.wav",
		"hit_sfx_name": "wav9916.wav",
		"vfx_animation_id": 60001
	},
	"Meteor Shower": {
		"skill_id": 15050,
		"skill_name": "Meteor Shower",
		"description": "Calls down fiery meteors raining damage upon all enemies.",
		"element": Element.FIRE,
		"skill_type": SkillType.MAGIC,
		"target_scope": TargetScope.ALL,
		"sp_cost": 65,
		"hp_cost": 0,
		"cooldown_turns": 2,
		"required_level": 20,
		"base_damage": 180,
		"damage_multiplier_1": 1.5,
		"damage_multiplier_2": 0.2,
		"mbtm_motion_id": 60050,
		"cast_sfx_name": "wav9920.wav",
		"hit_sfx_name": "wav9921.wav",
		"vfx_animation_id": 60050
	},
	"Cure": {
		"skill_id": 11077,
		"skill_name": "Cure",
		"description": "Restores HP to an ally using soothing water energy.",
		"element": Element.WATER,
		"skill_type": SkillType.ASSIST,
		"target_scope": TargetScope.SINGLE,
		"sp_cost": 25,
		"hp_cost": 0,
		"cooldown_turns": 0,
		"required_level": 1,
		"base_damage": -150,
		"damage_multiplier_1": 0.8,
		"damage_multiplier_2": 0.0,
		"mbtm_motion_id": 60003,
		"cast_sfx_name": "wav9930.wav",
		"hit_sfx_name": "wav9931.wav",
		"vfx_animation_id": 60003
	}
}

# --- UI Node References (Resolved safely via _ensure_node_refs) ---
var preset_option: OptionButton = null
var btn_load_preset: Button = null
var btn_new_skill: Button = null
var btn_lookup_db: Button = null
var btn_save_json: Button = null
var btn_load_json: Button = null
var btn_export_script: Button = null

var skill_id_spin: SpinBox = null
var skill_name_edit: LineEdit = null
var skill_desc_edit: TextEdit = null
var element_option: OptionButton = null
var skill_type_option: OptionButton = null
var target_scope_option: OptionButton = null
var sp_cost_spin: SpinBox = null
var hp_cost_spin: SpinBox = null
var cooldown_spin: SpinBox = null
var req_level_spin: SpinBox = null

var base_damage_spin: SpinBox = null
var multiplier1_spin: SpinBox = null
var multiplier2_spin: SpinBox = null

var sim_atk_spin: SpinBox = null
var sim_matk_spin: SpinBox = null
var sim_def_spin: SpinBox = null
var sim_mdef_spin: SpinBox = null
var sim_atk_elem_option: OptionButton = null
var sim_def_elem_option: OptionButton = null
var btn_sim_advantage: Button = null
var btn_sim_disadvantage: Button = null
var btn_sim_neutral: Button = null
var btn_simulate: Button = null
var lbl_raw_damage: Label = null
var lbl_elem_mod: Label = null
var lbl_final_damage: Label = null
var txt_formula_breakdown: TextEdit = null

var mbtm_motion_spin: SpinBox = null
var mbtm_preset_option: OptionButton = null
var cast_sfx_edit: LineEdit = null
var hit_sfx_edit: LineEdit = null
var vfx_anim_spin: SpinBox = null
var vfx_style_option: OptionButton = null

var vfx_canvas: Control = null
var btn_play_pause: Button = null
var btn_step_back: Button = null
var btn_step_forward: Button = null
var btn_reset: Button = null
var timeline_slider: HSlider = null
var lbl_frame_info: Label = null
var fps_spin: SpinBox = null
var status_label: Label = null

# --- Skill Browser Node References ---
var skill_search_edit: LineEdit = null
var skill_browser_option: OptionButton = null
var btn_select_skill: Button = null
var lbl_skill_count: Label = null

# --- Database Skill Cache ---
var _cached_db_skills: Array[Dictionary] = []
var _filtered_db_skill_ids: Array[int] = []

var code_dialog: AcceptDialog = null
var code_text_edit: TextEdit = null

var _game_database: Node = null
var _audio_player: AudioStreamPlayer = null

func _ready() -> void:
	custom_minimum_size = Vector2(800.0, 600.0)
	_ensure_node_refs()
	_init_database()
	_populate_dropdowns()
	_populate_skill_browser()
	_connect_signals()
	apply_skill_record(PRESETS["Wine Flame"])
	_run_formula_simulation()

func _init_database() -> void:
	if _game_database != null and "skills" in _game_database and _game_database.skills != null and _game_database.skills.get_all_skills().size() > 0:
		return

	if is_inside_tree() and has_node("/root/GameDatabase"):
		_game_database = get_node("/root/GameDatabase")

	if _game_database == null:
		var main_loop = Engine.get_main_loop()
		if main_loop and main_loop is SceneTree and main_loop.root and main_loop.root.has_node("GameDatabase"):
			_game_database = main_loop.root.get_node("GameDatabase")

	if _game_database == null:
		var gdb_script = load("res://scripts/database/game_database.gd")
		if gdb_script:
			_game_database = gdb_script.new()
			_game_database.name = "GameDatabase"
			var main_loop = Engine.get_main_loop()
			if main_loop and main_loop is SceneTree and main_loop.root:
				main_loop.root.add_child(_game_database)

	if _game_database != null and _game_database.has_method("load_all"):
		if not _game_database.is_loaded or (_game_database.skills and _game_database.skills.get_all_skills().is_empty()):
			_game_database.load_all()

func _ensure_node_refs() -> void:
	if preset_option != null:
		return
	
	preset_option = get_node_or_null("%PresetOption") as OptionButton
	btn_load_preset = get_node_or_null("%BtnLoadPreset") as Button
	btn_new_skill = get_node_or_null("%BtnNewSkill") as Button
	btn_lookup_db = get_node_or_null("%BtnLookupDB") as Button
	btn_save_json = get_node_or_null("%BtnSaveJson") as Button
	btn_load_json = get_node_or_null("%BtnLoadJson") as Button
	btn_export_script = get_node_or_null("%BtnExportScript") as Button

	skill_search_edit = get_node_or_null("%SkillSearchEdit") as LineEdit
	skill_browser_option = get_node_or_null("%SkillBrowserOption") as OptionButton
	btn_select_skill = get_node_or_null("%BtnSelectSkill") as Button
	lbl_skill_count = get_node_or_null("%LblSkillCount") as Label

	skill_id_spin = get_node_or_null("%SkillIdSpin") as SpinBox
	skill_name_edit = get_node_or_null("%SkillNameEdit") as LineEdit
	skill_desc_edit = get_node_or_null("%SkillDescEdit") as TextEdit
	element_option = get_node_or_null("%ElementOption") as OptionButton
	skill_type_option = get_node_or_null("%SkillTypeOption") as OptionButton
	target_scope_option = get_node_or_null("%TargetScopeOption") as OptionButton
	sp_cost_spin = get_node_or_null("%SpCostSpin") as SpinBox
	hp_cost_spin = get_node_or_null("%HpCostSpin") as SpinBox
	cooldown_spin = get_node_or_null("%CooldownSpin") as SpinBox
	req_level_spin = get_node_or_null("%ReqLevelSpin") as SpinBox

	base_damage_spin = get_node_or_null("%BaseDamageSpin") as SpinBox
	multiplier1_spin = get_node_or_null("%Multiplier1Spin") as SpinBox
	multiplier2_spin = get_node_or_null("%Multiplier2Spin") as SpinBox

	sim_atk_spin = get_node_or_null("%SimAtkSpin") as SpinBox
	sim_matk_spin = get_node_or_null("%SimMatkSpin") as SpinBox
	sim_def_spin = get_node_or_null("%SimDefSpin") as SpinBox
	sim_mdef_spin = get_node_or_null("%SimMdefSpin") as SpinBox
	sim_atk_elem_option = get_node_or_null("%SimAtkElemOption") as OptionButton
	sim_def_elem_option = get_node_or_null("%SimDefElemOption") as OptionButton
	btn_sim_advantage = get_node_or_null("%BtnSimAdvantage") as Button
	btn_sim_disadvantage = get_node_or_null("%BtnSimDisadvantage") as Button
	btn_sim_neutral = get_node_or_null("%BtnSimNeutral") as Button
	btn_simulate = get_node_or_null("%BtnSimulate") as Button
	lbl_raw_damage = get_node_or_null("%LblRawDamage") as Label
	lbl_elem_mod = get_node_or_null("%LblElemMod") as Label
	lbl_final_damage = get_node_or_null("%LblFinalDamage") as Label
	txt_formula_breakdown = get_node_or_null("%TxtFormulaBreakdown") as TextEdit

	mbtm_motion_spin = get_node_or_null("%MbtmMotionSpin") as SpinBox
	mbtm_preset_option = get_node_or_null("%MbtmPresetOption") as OptionButton
	cast_sfx_edit = get_node_or_null("%CastSfxEdit") as LineEdit
	hit_sfx_edit = get_node_or_null("%HitSfxEdit") as LineEdit
	vfx_anim_spin = get_node_or_null("%VfxAnimSpin") as SpinBox
	vfx_style_option = get_node_or_null("%VfxStyleOption") as OptionButton

	vfx_canvas = get_node_or_null("%VfxCanvas") as Control
	btn_play_pause = get_node_or_null("%BtnPlayPause") as Button
	btn_step_back = get_node_or_null("%BtnStepBack") as Button
	btn_step_forward = get_node_or_null("%BtnStepForward") as Button
	btn_reset = get_node_or_null("%BtnReset") as Button
	timeline_slider = get_node_or_null("%TimelineSlider") as HSlider
	lbl_frame_info = get_node_or_null("%LblFrameInfo") as Label
	fps_spin = get_node_or_null("%FpsSpin") as SpinBox
	status_label = get_node_or_null("%StatusLabel") as Label

	code_dialog = get_node_or_null("%CodeDialog") as AcceptDialog
	code_text_edit = get_node_or_null("%CodeTextEdit") as TextEdit

	if _audio_player == null:
		_audio_player = AudioStreamPlayer.new()
		add_child(_audio_player)

func _populate_dropdowns() -> void:
	if preset_option != null and preset_option.item_count == 0:
		for p_name in PRESETS.keys():
			preset_option.add_item(p_name)
	
	if element_option != null and element_option.item_count == 0:
		element_option.add_item("None (0)", Element.NONE)
		element_option.add_item("Earth (1)", Element.EARTH)
		element_option.add_item("Water (2)", Element.WATER)
		element_option.add_item("Fire (3)", Element.FIRE)
		element_option.add_item("Wind (4)", Element.WIND)
	
	if skill_type_option != null and skill_type_option.item_count == 0:
		skill_type_option.add_item("Physical (0)", SkillType.PHYSICAL)
		skill_type_option.add_item("Magic (1)", SkillType.MAGIC)
		skill_type_option.add_item("Assist (2)", SkillType.ASSIST)
		skill_type_option.add_item("Status (3)", SkillType.STATUS)
		skill_type_option.add_item("Special (4)", SkillType.SPECIAL)
	
	if target_scope_option != null and target_scope_option.item_count == 0:
		target_scope_option.add_item("Single (0)", TargetScope.SINGLE)
		target_scope_option.add_item("Row (1)", TargetScope.ROW)
		target_scope_option.add_item("Column (2)", TargetScope.COLUMN)
		target_scope_option.add_item("Cross (3)", TargetScope.CROSS)
		target_scope_option.add_item("All (4)", TargetScope.ALL)
	
	if sim_atk_elem_option != null and sim_atk_elem_option.item_count == 0:
		sim_atk_elem_option.add_item("None", Element.NONE)
		sim_atk_elem_option.add_item("Earth", Element.EARTH)
		sim_atk_elem_option.add_item("Water", Element.WATER)
		sim_atk_elem_option.add_item("Fire", Element.FIRE)
		sim_atk_elem_option.add_item("Wind", Element.WIND)
		sim_atk_elem_option.select(Element.FIRE)

	if sim_def_elem_option != null and sim_def_elem_option.item_count == 0:
		sim_def_elem_option.add_item("None", Element.NONE)
		sim_def_elem_option.add_item("Earth", Element.EARTH)
		sim_def_elem_option.add_item("Water", Element.WATER)
		sim_def_elem_option.add_item("Fire", Element.FIRE)
		sim_def_elem_option.add_item("Wind", Element.WIND)
		sim_def_elem_option.select(Element.WIND)

	if mbtm_preset_option != null and mbtm_preset_option.item_count == 0:
		mbtm_preset_option.add_item("60010 - Wine Flame / Overarm", 60010)
		mbtm_preset_option.add_item("60005 - Leap Wind Strike", 60005)
		mbtm_preset_option.add_item("60001 - Summon Dogs Wave", 60001)
		mbtm_preset_option.add_item("60050 - Meteor Shower Inferno", 60050)
		mbtm_preset_option.add_item("60003 - Cure Healing Aura", 60003)
		mbtm_preset_option.add_item("60022 - Basic Hand Attack", 60022)

	if vfx_style_option != null and vfx_style_option.item_count == 0:
		vfx_style_option.add_item("Fire Burst (Orange/Red)", 0)
		vfx_style_option.add_item("Water Splash (Cyan/Blue)", 1)
		vfx_style_option.add_item("Earth Quake (Brown/Amber)", 2)
		vfx_style_option.add_item("Wind Gale (Green/Yellow)", 3)
		vfx_style_option.add_item("Holy Radiance (White/Gold)", 4)

func _ensure_cached_db_skills() -> void:
	if not _cached_db_skills.is_empty():
		return
	if _game_database == null:
		_init_database()
	if _game_database == null or not ("skills" in _game_database) or _game_database.skills == null:
		return

	var all_skills: Dictionary = _game_database.skills.get_all_skills()
	if all_skills.is_empty():
		return

	var sorted_ids: Array = all_skills.keys()
	sorted_ids.sort()

	_cached_db_skills.clear()
	for sid in sorted_ids:
		var sk = all_skills[sid]
		var elem_name: String = sk.element_name if "element_name" in sk else get_element_name(int(sk.element))
		var type_name: String = sk.skill_type_name if "skill_type_name" in sk else get_skill_type_name(int(sk.skill_type))
		var label_str: String = "[%d] %s (%s, %s)" % [sid, sk.name, elem_name, type_name]
		_cached_db_skills.append({
			"id": sid,
			"name": sk.name,
			"element": int(sk.element),
			"element_name": elem_name,
			"type": int(sk.skill_type),
			"type_name": type_name,
			"label": label_str
		})

func _populate_skill_browser(filter_text: String = "") -> void:
	_ensure_cached_db_skills()
	
	if skill_browser_option == null:
		return

	skill_browser_option.clear()
	_filtered_db_skill_ids.clear()

	var q: String = filter_text.strip_edges().to_lower()
	var select_index: int = -1

	for entry in _cached_db_skills:
		var sid: int = entry["id"]
		var sname: String = entry["name"]
		var elem_str: String = entry["element_name"]
		var type_str: String = entry["type_name"]
		var item_label: String = entry["label"]

		var matches: bool = q.is_empty() or \
			str(sid).contains(q) or \
			sname.to_lower().contains(q) or \
			elem_str.to_lower().contains(q) or \
			type_str.to_lower().contains(q)

		if matches:
			var idx: int = skill_browser_option.item_count
			skill_browser_option.add_item(item_label, sid)
			_filtered_db_skill_ids.append(sid)
			if sid == skill_id:
				select_index = idx

	if skill_browser_option.item_count > 0:
		if select_index >= 0:
			skill_browser_option.selected = select_index
		else:
			skill_browser_option.selected = 0

	if lbl_skill_count:
		var total_cnt: int = _cached_db_skills.size()
		if q.is_empty():
			lbl_skill_count.text = "%d Skills" % total_cnt
		else:
			lbl_skill_count.text = "%d / %d" % [skill_browser_option.item_count, total_cnt]
	
	database_skills_populated.emit(skill_browser_option.item_count)

func _connect_signals() -> void:
	if preset_option:
		preset_option.item_selected.connect(func(idx: int):
			var p_name: String = preset_option.get_item_text(idx)
			load_preset(p_name)
		)
	if btn_load_preset:
		btn_load_preset.pressed.connect(func():
			if preset_option:
				var p_name: String = preset_option.get_item_text(preset_option.selected)
				load_preset(p_name)
		)
	if btn_new_skill:
		btn_new_skill.pressed.connect(_on_new_skill_pressed)
	if btn_lookup_db:
		btn_lookup_db.pressed.connect(_on_lookup_db_pressed)
	if btn_save_json:
		btn_save_json.pressed.connect(_on_save_json_pressed)
	if btn_load_json:
		btn_load_json.pressed.connect(_on_load_json_pressed)
	if btn_export_script:
		btn_export_script.pressed.connect(_on_export_script_pressed)

	if skill_browser_option:
		skill_browser_option.item_selected.connect(_on_skill_browser_item_selected)
	if skill_search_edit:
		skill_search_edit.text_changed.connect(_on_skill_search_text_changed)
		skill_search_edit.text_submitted.connect(_on_skill_search_text_submitted)
	if btn_select_skill:
		btn_select_skill.pressed.connect(_on_btn_select_skill_pressed)

	if skill_id_spin:
		skill_id_spin.value_changed.connect(func(v: float):
			skill_id = int(v)
			skill_changed.emit(skill_id)
		)
	if skill_name_edit:
		skill_name_edit.text_changed.connect(func(t: String):
			skill_name = t
		)
	if skill_desc_edit:
		skill_desc_edit.text_changed.connect(func():
			description = skill_desc_edit.text
		)
	if element_option:
		element_option.item_selected.connect(func(idx: int):
			element = element_option.get_item_id(idx)
			if sim_atk_elem_option:
				sim_atk_elem_option.select(element)
				sim_user_elem = element
			_update_vfx_style_from_element()
			_run_formula_simulation()
		)
	if skill_type_option:
		skill_type_option.item_selected.connect(func(idx: int):
			skill_type = skill_type_option.get_item_id(idx)
			_run_formula_simulation()
		)
	if target_scope_option:
		target_scope_option.item_selected.connect(func(idx: int):
			target_scope = target_scope_option.get_item_id(idx)
		)
	if sp_cost_spin:
		sp_cost_spin.value_changed.connect(func(v: float): sp_cost = int(v))
	if hp_cost_spin:
		hp_cost_spin.value_changed.connect(func(v: float): hp_cost = int(v))
	if cooldown_spin:
		cooldown_spin.value_changed.connect(func(v: float): cooldown_turns = int(v))
	if req_level_spin:
		req_level_spin.value_changed.connect(func(v: float): required_level = int(v))

	if base_damage_spin:
		base_damage_spin.value_changed.connect(func(v: float):
			base_damage = int(v)
			_run_formula_simulation()
		)
	if multiplier1_spin:
		multiplier1_spin.value_changed.connect(func(v: float):
			damage_multiplier_1 = float(v)
			_run_formula_simulation()
		)
	if multiplier2_spin:
		multiplier2_spin.value_changed.connect(func(v: float):
			damage_multiplier_2 = float(v)
			_run_formula_simulation()
		)

	if sim_atk_spin:
		sim_atk_spin.value_changed.connect(func(v: float):
			sim_user_atk = int(v)
			_run_formula_simulation()
		)
	if sim_matk_spin:
		sim_matk_spin.value_changed.connect(func(v: float):
			sim_user_matk = int(v)
			_run_formula_simulation()
		)
	if sim_def_spin:
		sim_def_spin.value_changed.connect(func(v: float):
			sim_target_def = int(v)
			_run_formula_simulation()
		)
	if sim_mdef_spin:
		sim_mdef_spin.value_changed.connect(func(v: float):
			sim_target_mdef = int(v)
			_run_formula_simulation()
		)
	if sim_atk_elem_option:
		sim_atk_elem_option.item_selected.connect(func(idx: int):
			sim_user_elem = sim_atk_elem_option.get_item_id(idx)
			_run_formula_simulation()
		)
	if sim_def_elem_option:
		sim_def_elem_option.item_selected.connect(func(idx: int):
			sim_target_elem = sim_def_elem_option.get_item_id(idx)
			_run_formula_simulation()
		)
	if btn_sim_advantage:
		btn_sim_advantage.pressed.connect(_on_sim_advantage_pressed)
	if btn_sim_disadvantage:
		btn_sim_disadvantage.pressed.connect(_on_sim_disadvantage_pressed)
	if btn_sim_neutral:
		btn_sim_neutral.pressed.connect(_on_sim_neutral_pressed)
	if btn_simulate:
		btn_simulate.pressed.connect(_run_formula_simulation)

	if mbtm_motion_spin:
		mbtm_motion_spin.value_changed.connect(func(v: float): mbtm_motion_id = int(v))
	if mbtm_preset_option:
		mbtm_preset_option.item_selected.connect(func(idx: int):
			var mid: int = mbtm_preset_option.get_item_id(idx)
			mbtm_motion_id = mid
			if mbtm_motion_spin:
				mbtm_motion_spin.value = mid
		)
	if cast_sfx_edit:
		cast_sfx_edit.text_changed.connect(func(t: String): cast_sfx_name = t)
	if hit_sfx_edit:
		hit_sfx_edit.text_changed.connect(func(t: String): hit_sfx_name = t)
	if vfx_anim_spin:
		vfx_anim_spin.value_changed.connect(func(v: float): vfx_animation_id = int(v))

	if btn_play_pause:
		btn_play_pause.pressed.connect(_toggle_playback)
	if btn_step_back:
		btn_step_back.pressed.connect(_step_back)
	if btn_step_forward:
		btn_step_forward.pressed.connect(_step_forward)
	if btn_reset:
		btn_reset.pressed.connect(_reset_timeline)
	if timeline_slider:
		timeline_slider.value_changed.connect(_on_slider_frame_changed)
	if fps_spin:
		fps_spin.value_changed.connect(func(v: float): fps = maxf(1.0, float(v)))

	if vfx_canvas:
		vfx_canvas.draw.connect(_on_vfx_canvas_draw)

func _process(delta: float) -> void:
	if is_playing:
		_anim_accumulator += delta
		var frame_dur: float = 1.0 / maxf(1.0, fps)
		if _anim_accumulator >= frame_dur:
			_anim_accumulator -= frame_dur
			var next_f: int = current_frame + 1
			if next_f > TOTAL_FRAMES:
				next_f = 0
			_set_current_frame(next_f)
	
	if _target_flash_time > 0.0:
		_target_flash_time = maxf(0.0, _target_flash_time - delta)
		if vfx_canvas:
			vfx_canvas.queue_redraw()

# --- Built-in Formula Simulator & Element Wheel ---

static func get_element_name(elem: int) -> String:
	match elem:
		Element.EARTH: return "Earth"
		Element.WATER: return "Water"
		Element.FIRE: return "Fire"
		Element.WIND: return "Wind"
		_: return "None"

static func get_skill_type_name(st: int) -> String:
	match st:
		SkillType.PHYSICAL: return "Physical"
		SkillType.MAGIC: return "Magic"
		SkillType.ASSIST: return "Assist"
		SkillType.STATUS: return "Status"
		SkillType.SPECIAL: return "Special"
		_: return "Physical"

static func get_target_scope_name(scope: int) -> String:
	match scope:
		TargetScope.SINGLE: return "Single"
		TargetScope.ROW: return "Row"
		TargetScope.COLUMN: return "Column"
		TargetScope.CROSS: return "Cross"
		TargetScope.ALL: return "All"
		_: return "Single"

static func get_element_multiplier(user_elem: int, target_elem: int) -> float:
	if user_elem == Element.NONE or target_elem == Element.NONE or user_elem == target_elem:
		return 1.0
	
	# Authentic WLO element wheel:
	# Earth beats Water (+25%)
	# Water beats Fire (+25%)
	# Fire beats Wind (+25%)
	# Wind beats Earth (+25%)
	if (user_elem == Element.EARTH and target_elem == Element.WATER) or \
	   (user_elem == Element.WATER and target_elem == Element.FIRE) or \
	   (user_elem == Element.FIRE and target_elem == Element.WIND) or \
	   (user_elem == Element.WIND and target_elem == Element.EARTH):
		return 1.25
	
	# Reverse counter (disadvantage, -25%)
	if (user_elem == Element.WATER and target_elem == Element.EARTH) or \
	   (user_elem == Element.FIRE and target_elem == Element.WATER) or \
	   (user_elem == Element.WIND and target_elem == Element.FIRE) or \
	   (user_elem == Element.EARTH and target_elem == Element.WIND):
		return 0.75
	
	return 1.0

func calculate_damage(user_atk: int, user_matk: int, target_def: int, target_mdef: int, user_elem: int, target_elem: int) -> int:
	var elem_mult: float = get_element_multiplier(user_elem, target_elem)
	
	# Assist / Healing skill: negative base_damage indicates healing
	if skill_type == SkillType.ASSIST and base_damage < 0:
		var heal_base: float = absf(float(base_damage))
		var matk_bonus: float = float(user_matk) * (damage_multiplier_1 if damage_multiplier_1 > 0.0 else 0.5)
		var total_heal: int = int(round(heal_base + matk_bonus))
		return -total_heal
	
	var atk_stat: float = float(user_matk) if skill_type == SkillType.MAGIC else float(user_atk)
	var def_stat: float = float(target_mdef) if skill_type == SkillType.MAGIC else float(target_def)
	var mult1: float = damage_multiplier_1 if damage_multiplier_1 > 0.0 else 1.0
	var mult2: float = damage_multiplier_2
	
	var raw: float = float(base_damage) + (atk_stat * mult1) - def_stat + (atk_stat * mult2)
	if raw < 1.0:
		raw = 1.0
	var final_dmg: int = int(round(raw * elem_mult))
	return maxi(1, final_dmg)

func _run_formula_simulation() -> void:
	var elem_mult: float = get_element_multiplier(sim_user_elem, sim_target_elem)
	var result: int = calculate_damage(sim_user_atk, sim_user_matk, sim_target_def, sim_target_mdef, sim_user_elem, sim_target_elem)
	last_sim_result = result
	
	var raw_calc: float = 0.0
	var atk_name: String = "MATK" if skill_type == SkillType.MAGIC else "ATK"
	var def_name: String = "MDEF" if skill_type == SkillType.MAGIC else "DEF"
	var atk_val: int = sim_user_matk if skill_type == SkillType.MAGIC else sim_user_atk
	var def_val: int = sim_target_mdef if skill_type == SkillType.MAGIC else sim_target_def
	var mult1: float = damage_multiplier_1 if damage_multiplier_1 > 0.0 else 1.0
	var mult2: float = damage_multiplier_2
	
	if skill_type == SkillType.ASSIST and base_damage < 0:
		raw_calc = absf(float(base_damage)) + (float(sim_user_matk) * mult1)
		last_sim_breakdown = "CURE / HEAL: |Base| (%d) + (MATK %d * %.2f) = %d HP Restored" % [
			abs(base_damage), sim_user_matk, mult1, abs(result)
		]
	else:
		raw_calc = float(base_damage) + (float(atk_val) * mult1) - float(def_val) + (float(atk_val) * mult2)
		if raw_calc < 1.0:
			raw_calc = 1.0
		var mod_percent_str: String = "Neutral (0%%)"
		if elem_mult > 1.0:
			mod_percent_str = "Advantage (+25%%)"
		elif elem_mult < 1.0:
			mod_percent_str = "Disadvantage (-25%%)"
		
		last_sim_breakdown = "FORMULA: [Base (%d) + (%s %d * %.2f) - (%s %d) + (Sec %.2f)] * ElemMult (%.2f [%s])\n" % [
			base_damage, atk_name, atk_val, mult1, def_name, def_val, mult2, elem_mult, mod_percent_str
		]
		last_sim_breakdown += "Raw Base: %.1f -> Final Damage: %d" % [raw_calc, result]
	
	if lbl_raw_damage:
		lbl_raw_damage.text = "Raw Damage: %d" % int(round(raw_calc))
	if lbl_elem_mod:
		var pct_str: String = "+0%"
		if is_equal_approx(elem_mult, 1.25):
			pct_str = "+25% (Counter Win)"
		elif is_equal_approx(elem_mult, 0.75):
			pct_str = "-25% (Counter Loss)"
		else:
			pct_str = "1.00 (Neutral)"
		lbl_elem_mod.text = "Element Mod: %s" % pct_str
	if lbl_final_damage:
		if result < 0:
			lbl_final_damage.text = "HEAL: +%d HP" % abs(result)
			lbl_final_damage.modulate = Color(0.2, 0.9, 0.3, 1.0)
		else:
			lbl_final_damage.text = "DAMAGE: %d" % result
			lbl_final_damage.modulate = Color(1.0, 0.35, 0.2, 1.0)
	if txt_formula_breakdown:
		txt_formula_breakdown.text = last_sim_breakdown
	
	formula_simulated.emit(result, last_sim_breakdown)

func _on_sim_advantage_pressed() -> void:
	# Set target element so user has advantage
	match sim_user_elem:
		Element.EARTH: sim_target_elem = Element.WATER
		Element.WATER: sim_target_elem = Element.FIRE
		Element.FIRE: sim_target_elem = Element.WIND
		Element.WIND: sim_target_elem = Element.EARTH
		_:
			sim_user_elem = Element.FIRE
			sim_target_elem = Element.WIND
	if sim_atk_elem_option: sim_atk_elem_option.select(sim_user_elem)
	if sim_def_elem_option: sim_def_elem_option.select(sim_target_elem)
	_run_formula_simulation()

func _on_sim_disadvantage_pressed() -> void:
	# Set target element so user has disadvantage
	match sim_user_elem:
		Element.EARTH: sim_target_elem = Element.WIND
		Element.WATER: sim_target_elem = Element.EARTH
		Element.FIRE: sim_target_elem = Element.WATER
		Element.WIND: sim_target_elem = Element.FIRE
		_:
			sim_user_elem = Element.FIRE
			sim_target_elem = Element.WATER
	if sim_atk_elem_option: sim_atk_elem_option.select(sim_user_elem)
	if sim_def_elem_option: sim_def_elem_option.select(sim_target_elem)
	_run_formula_simulation()

func _on_sim_neutral_pressed() -> void:
	sim_target_elem = sim_user_elem
	if sim_def_elem_option: sim_def_elem_option.select(sim_target_elem)
	_run_formula_simulation()

# --- Motion Timeline & Visual Canvas Methods ---

func _toggle_playback() -> void:
	is_playing = not is_playing
	if btn_play_pause:
		btn_play_pause.text = "Pause" if is_playing else "Play"

func _step_forward() -> void:
	is_playing = false
	if btn_play_pause: btn_play_pause.text = "Play"
	var next_f: int = (current_frame + 1) % (TOTAL_FRAMES + 1)
	_set_current_frame(next_f)

func _step_back() -> void:
	is_playing = false
	if btn_play_pause: btn_play_pause.text = "Play"
	var prev_f: int = (current_frame - 1 + TOTAL_FRAMES + 1) % (TOTAL_FRAMES + 1)
	_set_current_frame(prev_f)

func _reset_timeline() -> void:
	is_playing = false
	if btn_play_pause: btn_play_pause.text = "Play"
	_set_current_frame(0)

func _on_slider_frame_changed(v: float) -> void:
	if int(v) != current_frame:
		_set_current_frame(int(v))

func _set_current_frame(f: int) -> void:
	current_frame = clampi(f, 0, TOTAL_FRAMES)
	if timeline_slider and int(timeline_slider.value) != current_frame:
		timeline_slider.value = current_frame
	if lbl_frame_info:
		lbl_frame_info.text = "Frame: %d / %d" % [current_frame, TOTAL_FRAMES]
	
	# Keyframe triggers
	if current_frame == 10:
		_trigger_cast_sfx()
	elif current_frame == 15:
		_trigger_hit_vfx()
	
	if vfx_canvas:
		vfx_canvas.queue_redraw()

func _trigger_cast_sfx() -> void:
	if _status_label_exists():
		status_label.text = "Cast SFX Triggered: %s (Motion ID: %d)" % [cast_sfx_name, mbtm_motion_id]
	_play_sound(cast_sfx_name)

func _trigger_hit_vfx() -> void:
	_target_flash_time = 0.25
	_vfx_burst_radius = 45.0
	_spawn_particles()
	if _status_label_exists():
		status_label.text = "Hit Impact Triggered: %s (VFX: %d) -> %s" % [
			hit_sfx_name, vfx_animation_id,
			"Damage: %d" % last_sim_result if last_sim_result > 0 else "Heal: %d" % abs(last_sim_result)
		]
	_play_sound(hit_sfx_name)

func _play_sound(sfx_name: String) -> void:
	if sfx_name.is_empty():
		return
	var sound_path: String = "res://assets/sound/" + sfx_name.replace("wav", "").strip_edges() + ".wav"
	if not FileAccess.file_exists(sound_path):
		sound_path = "res://assets/sound/" + sfx_name
	if FileAccess.file_exists(sound_path) and _audio_player:
		var stream = load(sound_path)
		if stream:
			_audio_player.stream = stream
			_audio_player.play()

func _spawn_particles() -> void:
	_vfx_particles.clear()
	var elem_color: Color = _get_element_color(element)
	for i in range(16):
		var angle: float = (TAU / 16.0) * float(i)
		var speed: float = randf_range(30.0, 90.0)
		_vfx_particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"color": elem_color,
			"size": randf_range(3.0, 7.0),
			"life": 1.0
		})

func _get_element_color(elem: int) -> Color:
	match elem:
		Element.EARTH: return Color(0.8, 0.55, 0.2, 1.0)
		Element.WATER: return Color(0.2, 0.65, 1.0, 1.0)
		Element.FIRE: return Color(1.0, 0.35, 0.1, 1.0)
		Element.WIND: return Color(0.3, 0.9, 0.45, 1.0)
		_: return Color(0.85, 0.85, 0.9, 1.0)

func _update_vfx_style_from_element() -> void:
	if vfx_style_option:
		match element:
			Element.FIRE: vfx_style_option.select(0)
			Element.WATER: vfx_style_option.select(1)
			Element.EARTH: vfx_style_option.select(2)
			Element.WIND: vfx_style_option.select(3)
			_: vfx_style_option.select(4)

func _on_vfx_canvas_draw() -> void:
	if not vfx_canvas:
		return
	var canvas_size: Vector2 = vfx_canvas.size
	var center_y: float = canvas_size.y * 0.55
	var caster_pos: Vector2 = Vector2(canvas_size.x * 0.22, center_y)
	var target_pos: Vector2 = Vector2(canvas_size.x * 0.78, center_y)
	
	# Draw Isometric Combat Arena Grid Ground
	var grid_color: Color = Color(0.12, 0.17, 0.24, 0.8)
	for i in range(-3, 4):
		var offset: float = float(i) * 28.0
		vfx_canvas.draw_line(
			Vector2(canvas_size.x * 0.5 + offset * 1.5, center_y - 45.0 + absf(offset) * 0.5),
			Vector2(canvas_size.x * 0.5 - offset * 1.5, center_y + 45.0 - absf(offset) * 0.5),
			grid_color, 1.0
		)
	
	# Draw Caster Entity (Attacker)
	var caster_bob: float = sin(float(current_frame) * 0.4) * 3.0
	var caster_draw_pos: Vector2 = caster_pos + Vector2(0.0, caster_bob)
	var caster_color: Color = _get_element_color(element)
	
	# Caster Shadow
	vfx_canvas.draw_circle(caster_pos + Vector2(0.0, 24.0), 18.0, Color(0.0, 0.0, 0.0, 0.35))
	# Caster Body
	vfx_canvas.draw_circle(caster_draw_pos, 16.0, Color(0.15, 0.25, 0.4, 1.0))
	# Caster Head / Cape
	vfx_canvas.draw_circle(caster_draw_pos + Vector2(0.0, -18.0), 10.0, caster_color)
	# Caster Stance / Weapon
	var cast_stretch: float = 0.0
	if current_frame >= 6 and current_frame <= 12:
		cast_stretch = 14.0 # thrust forward
	vfx_canvas.draw_line(
		caster_draw_pos,
		caster_draw_pos + Vector2(22.0 + cast_stretch, -4.0),
		Color(0.9, 0.85, 0.4, 1.0), 3.0
	)
	
	# Caster Casting Aura (frames 1..10)
	if current_frame > 0 and current_frame <= 12:
		var aura_pulse: float = 18.0 + sin(float(current_frame) * 0.8) * 6.0
		var aura_col: Color = caster_color
		aura_col.a = 0.45
		vfx_canvas.draw_arc(caster_draw_pos, aura_pulse, 0.0, TAU, 24, aura_col, 2.5)
	
	# Projectile / Motion Travel (frames 10..15)
	if current_frame >= 10 and current_frame <= 15:
		var t: float = float(current_frame - 10) / 5.0
		var proj_pos: Vector2 = caster_draw_pos.lerp(target_pos, t)
		var proj_col: Color = caster_color
		proj_col.a = 0.95
		vfx_canvas.draw_circle(proj_pos, 9.0, proj_col)
		vfx_canvas.draw_line(proj_pos - Vector2(18.0, 0.0), proj_pos, Color(1.0, 1.0, 1.0, 0.8), 3.0)
	
	# Draw Target Entity (Dummy / Defender)
	var target_recoil: float = 0.0
	if current_frame >= 15 and current_frame <= 20:
		target_recoil = sin(float(current_frame - 15) * 0.6) * 12.0
	var target_draw_pos: Vector2 = target_pos + Vector2(target_recoil, 0.0)
	var target_base_color: Color = _get_element_color(sim_target_elem)
	if _target_flash_time > 0.0:
		target_base_color = Color(1.0, 1.0, 1.0, 1.0) # White flash
	
	# Target Shadow
	vfx_canvas.draw_circle(target_pos + Vector2(0.0, 24.0), 18.0, Color(0.0, 0.0, 0.0, 0.35))
	# Target Body
	vfx_canvas.draw_circle(target_draw_pos, 16.0, target_base_color)
	# Target Head
	vfx_canvas.draw_circle(target_draw_pos + Vector2(0.0, -18.0), 10.0, Color(0.8, 0.2, 0.2, 1.0))
	
	# Hit Impact VFX Burst (frames 15..26)
	if current_frame >= 15 and current_frame <= 26:
		var hit_t: float = float(current_frame - 15) / 11.0
		var cur_radius: float = 12.0 + hit_t * 50.0
		var burst_col: Color = caster_color
		burst_col.a = 1.0 - hit_t
		vfx_canvas.draw_arc(target_draw_pos, cur_radius, 0.0, TAU, 32, burst_col, 3.5)
		vfx_canvas.draw_arc(target_draw_pos, cur_radius * 0.65, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, burst_col.a), 2.0)
		
		# Draw Particle Sparks
		for p in _vfx_particles:
			var p_offset: Vector2 = p["vel"] * hit_t * 0.4
			var p_col: Color = p["color"]
			p_col.a = 1.0 - hit_t
			vfx_canvas.draw_circle(target_draw_pos + p_offset, p["size"] * (1.0 - hit_t * 0.5), p_col)
	
	# Floating Damage / Heal Popup (frames 15..30)
	if current_frame >= 15:
		var num_t: float = float(current_frame - 15) / 15.0
		var float_y: float = target_draw_pos.y - 35.0 - (num_t * 30.0)
		var num_pos: Vector2 = Vector2(target_draw_pos.x - 25.0, float_y)
		var text_str: String = ""
		var text_col: Color = Color.WHITE
		if last_sim_result < 0:
			text_str = "+%d" % abs(last_sim_result)
			text_col = Color(0.25, 0.95, 0.4, 1.0 - num_t * 0.7)
		else:
			text_str = "-%d" % last_sim_result
			text_col = Color(1.0, 0.35, 0.15, 1.0 - num_t * 0.7)
		
		# Draw background pill and text
		vfx_canvas.draw_rect(Rect2(num_pos - Vector2(6.0, 14.0), Vector2(58.0, 20.0)), Color(0.05, 0.05, 0.08, 0.75 * (1.0 - num_t * 0.7)), true, 4.0)
		vfx_canvas.draw_string(
			ThemeDB.fallback_font,
			num_pos + Vector2(2.0, 0.0),
			text_str,
			HORIZONTAL_ALIGNMENT_CENTER,
			54.0,
			14,
			text_col
		)

# --- Presets & Data Management Methods ---

func get_available_presets() -> Array[String]:
	var list: Array[String] = []
	for k in PRESETS.keys():
		list.append(str(k))
	return list

func load_preset(p_name: String) -> void:
	if not PRESETS.has(p_name):
		push_warning("Skill preset not found: " + p_name)
		return
	apply_skill_record(PRESETS[p_name])
	preset_loaded.emit(p_name)
	if skill_browser_option:
		for i in range(skill_browser_option.item_count):
			if skill_browser_option.get_item_id(i) == skill_id:
				skill_browser_option.selected = i
				break
	if _status_label_exists():
		status_label.text = "Loaded Preset: %s (ID %d)" % [p_name, skill_id]

func create_skill_record() -> Dictionary:
	return {
		"skill_id": skill_id,
		"skill_name": skill_name,
		"description": description,
		"element": element,
		"element_name": get_element_name(element),
		"skill_type": skill_type,
		"skill_type_name": get_skill_type_name(skill_type),
		"target_scope": target_scope,
		"target_scope_name": get_target_scope_name(target_scope),
		"sp_cost": sp_cost,
		"hp_cost": hp_cost,
		"cooldown_turns": cooldown_turns,
		"required_level": required_level,
		"base_damage": base_damage,
		"damage_multiplier_1": damage_multiplier_1,
		"damage_multiplier_2": damage_multiplier_2,
		"mbtm_motion_id": mbtm_motion_id,
		"cast_sfx_name": cast_sfx_name,
		"hit_sfx_name": hit_sfx_name,
		"vfx_animation_id": vfx_animation_id
	}

func apply_skill_record(record: Dictionary) -> void:
	skill_id = int(record.get("skill_id", 0))
	skill_name = str(record.get("skill_name", ""))
	description = str(record.get("description", ""))
	element = int(record.get("element", Element.NONE))
	skill_type = int(record.get("skill_type", SkillType.PHYSICAL))
	target_scope = int(record.get("target_scope", TargetScope.SINGLE))
	sp_cost = int(record.get("sp_cost", 0))
	hp_cost = int(record.get("hp_cost", 0))
	cooldown_turns = int(record.get("cooldown_turns", 0))
	required_level = int(record.get("required_level", 1))
	base_damage = int(record.get("base_damage", 0))
	damage_multiplier_1 = float(record.get("damage_multiplier_1", 1.0))
	damage_multiplier_2 = float(record.get("damage_multiplier_2", 0.0))
	mbtm_motion_id = int(record.get("mbtm_motion_id", 0))
	cast_sfx_name = str(record.get("cast_sfx_name", ""))
	hit_sfx_name = str(record.get("hit_sfx_name", ""))
	vfx_animation_id = int(record.get("vfx_animation_id", 0))
	
	_update_ui_from_state()
	_update_vfx_style_from_element()
	_run_formula_simulation()
	skill_changed.emit(skill_id)

func _update_ui_from_state() -> void:
	if skill_id_spin: skill_id_spin.value = skill_id
	if skill_name_edit: skill_name_edit.text = skill_name
	if skill_desc_edit: skill_desc_edit.text = description
	if element_option: element_option.select(element)
	if skill_type_option: skill_type_option.select(skill_type)
	if target_scope_option: target_scope_option.select(target_scope)
	if sp_cost_spin: sp_cost_spin.value = sp_cost
	if hp_cost_spin: hp_cost_spin.value = hp_cost
	if cooldown_spin: cooldown_spin.value = cooldown_turns
	if req_level_spin: req_level_spin.value = required_level
	if base_damage_spin: base_damage_spin.value = base_damage
	if multiplier1_spin: multiplier1_spin.value = damage_multiplier_1
	if multiplier2_spin: multiplier2_spin.value = damage_multiplier_2
	if mbtm_motion_spin: mbtm_motion_spin.value = mbtm_motion_id
	if cast_sfx_edit: cast_sfx_edit.text = cast_sfx_name
	if hit_sfx_edit: hit_sfx_edit.text = hit_sfx_name
	if vfx_anim_spin: vfx_anim_spin.value = vfx_animation_id
	if sim_atk_elem_option: sim_atk_elem_option.select(element)
	sim_user_elem = element

func save_skill_json(path: String) -> bool:
	var record: Dictionary = create_skill_record()
	var json_str: String = JSON.stringify(record, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("Failed to write skill JSON to: " + path)
		return false
	file.store_string(json_str)
	file.close()
	skill_saved.emit(path)
	if _status_label_exists():
		status_label.text = "Saved skill JSON: %s" % path
	return true

func load_skill_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Skill JSON file not found: " + path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var json_str: String = file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var err: Error = json.parse(json_str)
	if err != OK:
		push_error("Failed to parse skill JSON: " + json.get_error_message())
		return {}
	if json.data is Dictionary:
		var record: Dictionary = json.data
		apply_skill_record(record)
		skill_loaded.emit(skill_id)
		if _status_label_exists():
			status_label.text = "Loaded skill JSON: %s (ID %d)" % [path, skill_id]
		return record
	return {}

func export_skill_script(path: String = "") -> String:
	var record: Dictionary = create_skill_record()
	var script_content: String = """class_name Skill_%d
extends RefCounted

## Auto-generated Skill Definition from WLO Skill & Combat VFX Studio
## Skill Name: %s (ID: %d)
## Description: %s

const SKILL_ID: int = %d
const SKILL_NAME: String = "%s"
const DESCRIPTION: String = "%s"
const ELEMENT: int = %d # %s
const SKILL_TYPE: int = %d # %s
const TARGET_SCOPE: int = %d # %s

const SP_COST: int = %d
const HP_COST: int = %d
const COOLDOWN_TURNS: int = %d
const REQUIRED_LEVEL: int = %d

const BASE_DAMAGE: int = %d
const DAMAGE_MULTIPLIER_1: float = %f
const DAMAGE_MULTIPLIER_2: float = %f

const MBTM_MOTION_ID: int = %d
const CAST_SFX: String = "%s"
const HIT_SFX: String = "%s"
const VFX_ANIMATION_ID: int = %d

static func get_element_multiplier(user_elem: int, target_elem: int) -> float:
	if user_elem == 0 or target_elem == 0 or user_elem == target_elem:
		return 1.0
	# Earth(1) -> Water(2) -> Fire(3) -> Wind(4) -> Earth(1)
	if (user_elem == 1 and target_elem == 2) or \\
	   (user_elem == 2 and target_elem == 3) or \\
	   (user_elem == 3 and target_elem == 4) or \\
	   (user_elem == 4 and target_elem == 1):
		return 1.25
	if (user_elem == 2 and target_elem == 1) or \\
	   (user_elem == 3 and target_elem == 2) or \\
	   (user_elem == 4 and target_elem == 3) or \\
	   (user_elem == 1 and target_elem == 4):
		return 0.75
	return 1.0

static func calculate_damage(user_atk: int, user_matk: int, target_def: int, target_mdef: int, user_elem: int, target_elem: int) -> int:
	var elem_mult: float = get_element_multiplier(user_elem, target_elem)
	if SKILL_TYPE == 2 and BASE_DAMAGE < 0:
		var heal_base: float = absf(float(BASE_DAMAGE))
		var matk_bonus: float = float(user_matk) * (DAMAGE_MULTIPLIER_1 if DAMAGE_MULTIPLIER_1 > 0.0 else 0.5)
		return -int(round(heal_base + matk_bonus))
	
	var atk_stat: float = float(user_matk) if SKILL_TYPE == 1 else float(user_atk)
	var def_stat: float = float(target_mdef) if SKILL_TYPE == 1 else float(target_def)
	var mult1: float = DAMAGE_MULTIPLIER_1 if DAMAGE_MULTIPLIER_1 > 0.0 else 1.0
	var raw: float = float(BASE_DAMAGE) + (atk_stat * mult1) - def_stat + (atk_stat * DAMAGE_MULTIPLIER_2)
	if raw < 1.0:
		raw = 1.0
	return maxi(1, int(round(raw * elem_mult)))
""" % [
		record["skill_id"],
		record["skill_name"], record["skill_id"],
		record["description"],
		record["skill_id"],
		record["skill_name"],
		record["description"].c_escape(),
		record["element"], record["element_name"],
		record["skill_type"], record["skill_type_name"],
		record["target_scope"], record["target_scope_name"],
		record["sp_cost"],
		record["hp_cost"],
		record["cooldown_turns"],
		record["required_level"],
		record["base_damage"],
		record["damage_multiplier_1"],
		record["damage_multiplier_2"],
		record["mbtm_motion_id"],
		record["cast_sfx_name"],
		record["hit_sfx_name"],
		record["vfx_animation_id"]
	]
	
	if not path.is_empty():
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file:
			file.store_string(script_content)
			file.close()
			skill_exported.emit(path)
			if _status_label_exists():
				status_label.text = "Exported skill GDScript: %s" % path
	return script_content

func get_mbtm_motion_count() -> int:
	if _game_database == null:
		_init_database()
	if _game_database != null and "skills" in _game_database and _game_database.skills != null:
		if _game_database.skills.has_method("get_mbtm_count"):
			var cnt: int = _game_database.skills.get_mbtm_count()
			if cnt > 0:
				return cnt
	return 1829

func lookup_from_game_database(target_id: int) -> bool:
	if _game_database == null:
		_init_database()
	if _game_database == null or not ("skills" in _game_database) or _game_database.skills == null:
		push_warning("GameDatabase.skills not initialized")
		return false
	
	var sk_db = _game_database.skills
	if not sk_db.has_method("has_skill") or not sk_db.has_skill(target_id):
		push_warning("Skill ID %d not found in GameDatabase" % target_id)
		return false
	
	var rec = sk_db.get_skill(target_id)
	if rec == null:
		return false
	
	skill_id = rec.id
	skill_name = rec.name
	description = rec.description
	element = int(rec.element)
	skill_type = int(rec.skill_type)
	target_scope = int(rec.target_scope)
	sp_cost = rec.sp_cost
	hp_cost = 0
	cooldown_turns = 0
	required_level = maxi(1, rec.rank) if "rank" in rec and rec.rank > 0 else 1
	base_damage = rec.base_damage
	damage_multiplier_1 = rec.damage_rate_1 if rec.damage_rate_1 > 0.0 else 1.0
	damage_multiplier_2 = rec.damage_rate_2
	mbtm_motion_id = rec.animation_id if rec.animation_id > 0 else target_id
	vfx_animation_id = mbtm_motion_id
	
	match element:
		Element.FIRE:
			cast_sfx_name = "wav9911.wav"
			hit_sfx_name = "wav9912.wav"
		Element.WIND:
			cast_sfx_name = "wav9913.wav"
			hit_sfx_name = "wav9914.wav"
		Element.EARTH:
			cast_sfx_name = "wav9915.wav"
			hit_sfx_name = "wav9916.wav"
		Element.WATER:
			cast_sfx_name = "wav9930.wav"
			hit_sfx_name = "wav9931.wav"
		_:
			cast_sfx_name = "wav9911.wav"
			hit_sfx_name = "wav9912.wav"

	_update_ui_from_state()
	_update_vfx_style_from_element()
	_run_formula_simulation()
	
	if skill_browser_option:
		var found_in_browser: bool = false
		for i in range(skill_browser_option.item_count):
			if skill_browser_option.get_item_id(i) == target_id:
				skill_browser_option.selected = i
				found_in_browser = true
				break
		if not found_in_browser:
			if skill_search_edit and not skill_search_edit.text.is_empty():
				skill_search_edit.text = ""
			_populate_skill_browser("")
			for i in range(skill_browser_option.item_count):
				if skill_browser_option.get_item_id(i) == target_id:
					skill_browser_option.selected = i
					break
	
	skill_loaded.emit(skill_id)
	skill_changed.emit(skill_id)
	
	if _status_label_exists():
		status_label.text = "Loaded Skill %d ('%s') from GameDatabase" % [target_id, skill_name]
	return true

func load_skill_from_database(target_id: int) -> bool:
	return lookup_from_game_database(target_id)

func get_database_skills_count() -> int:
	if _game_database == null:
		_init_database()
	if _game_database != null and "skills" in _game_database and _game_database.skills != null:
		return _game_database.skills.get_all_skills().size()
	return 0

func get_database_skills() -> Dictionary:
	if _game_database == null:
		_init_database()
	if _game_database != null and "skills" in _game_database and _game_database.skills != null:
		return _game_database.skills.get_all_skills()
	return {}

func search_database_skills(query: String) -> Array[Dictionary]:
	_ensure_cached_db_skills()
	var q := query.strip_edges().to_lower()
	var results: Array[Dictionary] = []
	for entry in _cached_db_skills:
		if q.is_empty() or str(entry["id"]).contains(q) or entry["name"].to_lower().contains(q) or entry["element_name"].to_lower().contains(q) or entry["type_name"].to_lower().contains(q):
			results.append(entry)
	return results

func refresh_database_skills() -> void:
	_cached_db_skills.clear()
	_init_database()
	_populate_skill_browser(skill_search_edit.text if skill_search_edit else "")

func set_game_database(db: Node) -> void:
	_game_database = db
	refresh_database_skills()

# --- Skill Browser Event Callbacks ---

func _on_skill_browser_item_selected(idx: int) -> void:
	if skill_browser_option == null or idx < 0 or idx >= skill_browser_option.item_count:
		return
	var sid: int = skill_browser_option.get_item_id(idx)
	lookup_from_game_database(sid)

func _on_skill_search_text_changed(new_text: String) -> void:
	_populate_skill_browser(new_text)

func _on_skill_search_text_submitted(text: String) -> void:
	var trimmed: String = text.strip_edges()
	if trimmed.is_valid_int():
		var sid: int = trimmed.to_int()
		if lookup_from_game_database(sid):
			return
	if skill_browser_option and skill_browser_option.item_count > 0:
		var target_idx: int = skill_browser_option.selected if skill_browser_option.selected >= 0 else 0
		var sid: int = skill_browser_option.get_item_id(target_idx)
		lookup_from_game_database(sid)

func _on_btn_select_skill_pressed() -> void:
	if skill_browser_option and skill_browser_option.item_count > 0:
		var target_idx: int = skill_browser_option.selected if skill_browser_option.selected >= 0 else 0
		var sid: int = skill_browser_option.get_item_id(target_idx)
		lookup_from_game_database(sid)

# --- Button Handlers ---

func _on_new_skill_pressed() -> void:
	skill_id = 19999
	skill_name = "Custom Strike"
	description = "Author a brand new custom skill."
	element = Element.NONE
	skill_type = SkillType.PHYSICAL
	target_scope = TargetScope.SINGLE
	sp_cost = 10
	hp_cost = 0
	cooldown_turns = 0
	required_level = 1
	base_damage = 50
	damage_multiplier_1 = 1.0
	damage_multiplier_2 = 0.0
	mbtm_motion_id = 60022
	cast_sfx_name = "wav9911.wav"
	hit_sfx_name = "wav9912.wav"
	vfx_animation_id = 60022
	_update_ui_from_state()
	_run_formula_simulation()
	if _status_label_exists():
		status_label.text = "Initialized new custom skill template."

func _on_lookup_db_pressed() -> void:
	var id_to_find: int = int(skill_id_spin.value) if skill_id_spin else skill_id
	lookup_from_game_database(id_to_find)

func _on_save_json_pressed() -> void:
	var path: String = "user://skill_%d.json" % skill_id
	save_skill_json(path)

func _on_load_json_pressed() -> void:
	var path: String = "user://skill_%d.json" % skill_id
	if FileAccess.file_exists(path):
		load_skill_json(path)
	elif _status_label_exists():
		status_label.text = "File not found: %s" % path

func _on_export_script_pressed() -> void:
	var path: String = "user://skill_%d.gd" % skill_id
	var code: String = export_skill_script(path)
	if code_dialog and code_text_edit:
		code_text_edit.text = code
		code_dialog.popup_centered(Vector2(650, 500))

func _status_label_exists() -> bool:
	return status_label != null

