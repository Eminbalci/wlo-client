class_name CharacterCreate
extends Control

## Authentic 1:1 4-Step Character Creation Wizard for Wonderland Online.
## Reference: tests/char_create_ref.mp4 (800x600 screen, 740x352 window centered at X:30, Y:124).
## Every step sits on the skin whose baked artwork matches its content (Form_CreateRole_1..4.jpg):
## Step 1 "Name"             (skin 1): Role carousel, radar chart, standee, lore, name inputs over the baked black box
## Step 2 "Palette"          (skin 4, 536 px wide): Hair/Body/Eyes/Wear tabs, style, Default, R/G/B sliders over the baked bars
## Step 3 "Attributes"       (skin 3): Earth/Water/Fire/Wind, lore descriptions, element badge
## Step 4 "Role explication" (skin 2): radar + lore summary and the points / STR CON INT WIS AGI allocation

signal character_created(char_data: Dictionary)
signal cancelled()

const CharacterManager = preload("res://scripts/ui/auth/character_manager.gd")
const RadarChart = preload("res://scripts/ui/auth/radar_chart.gd")

const FORM_STEP1_PATH: String = "menu/Skins/white/Form_CreateRole_1.jpg"
const FORM_STEP2_PATH: String = "menu/Skins/white/Form_CreateRole_2.jpg"
const FORM_STEP3_PATH: String = "menu/Skins/white/Form_CreateRole_3.jpg"
const FORM_STEP4_PATH: String = "menu/Skins/white/Form_CreateRole_4.jpg"
const BACKGROUND_PIC_PATH: String = "res://assets/pic/LogPic1.jpg"

const BTN_NEXT_PATH: String = "menu/Skins/default/btn_next.bmp"
const BTN_PREV_PATH: String = "menu/Skins/default/Btn_Prev_1.bmp"
const BTN_OK_PATH: String = "menu/Skins/default/btn_ok_1.bmp"
const BTN_CANCEL_PATH: String = "menu/Skins/default/Btn_Cancel_1.bmp"
const BTN_ARROW_L_PATH: String = "assets/auth/btn_arrow_left_carousel.png"
const BTN_ARROW_R_PATH: String = "assets/auth/btn_arrow_right_carousel.png"

const SFX_CLICK_PATH: String = "res://assets/sound/wav0151.wav"
const SFX_ALERT_PATH: String = "res://assets/sound/SEB0024.WAV"

const ELEMENT_ICONS: Dictionary = {
	"Earth": "res://assets/hud/icon_element_1.png",
	"Water": "res://assets/hud/icon_element_2.png",
	"Fire": "res://assets/hud/icon_element_3.png",
	"Wind": "res://assets/hud/icon_element_4.png"
}

const ELEMENT_DESCRIPTIONS: Dictionary = {
	"Earth": "Earth (地) specializes in physical defense and steadfast durability.\nAffinities: CON +2, STR +1 | Solidifies defense and earth binds.",
	"Water": "Water (水) embodies restorative balance and arcane tranquility.\nAffinities: WIS +2, CON +1, INT +1 | Healing, restoration, and ice seals.",
	"Fire": "Fire (火) channels pure destructive might and blazing offense.\nAffinities: STR +2, AGI +1 | Searing physical and pyro bursts.",
	"Wind": "Wind (風) commands velocity, turn priority, and swift evasion.\nAffinities: AGI +2, STR +1 | Unmatched movement speed and evasion."
}

const ROLE_LORE: Dictionary = {
	1: {
		"title": "Nina (妮娜)",
		"trait": "Gender: Female | Specialty: Agility & Flame",
		"desc": "A cheerful traveling entertainer full of boundless curiosity. Quick-witted and light on her feet, she dazzles enemies with fiery acrobatics."
	},
	2: {
		"title": "Betty (貝蒂)",
		"trait": "Gender: Female | Specialty: Supreme Speed",
		"desc": "A spirited tomboy with untamed athletic instincts. Her sheer swiftness consistently secures initiative in battle before foes can react."
	},
	3: {
		"title": "Rocco (羅卡)",
		"trait": "Gender: Male | Specialty: Defense & Fortitude",
		"desc": "An earnest boy from a village of valiant warriors. Possesses remarkable endurance, unflinching loyalty, and stalwart physical defense."
	},
	4: {
		"title": "Vanessa (凡妮莎)",
		"trait": "Gender: Female | Specialty: Arcane Wisdom",
		"desc": "An aristocratic academy student well-versed in ancient sorcery. Calm and composed, she commands devastating aquatic and elemental spells."
	},
	5: {
		"title": "Lique (莉珂)",
		"trait": "Gender: Female | Specialty: High Agility",
		"desc": "A competitive racer who lives for the thrill of speed. Darting like a gale across the battlefield, she strikes with blistering momentum."
	},
	6: {
		"title": "Daniel (丹尼爾)",
		"trait": "Gender: Male | Specialty: Ferocious Attack",
		"desc": "A bold, passionate adventurer with a fierce sense of justice. Boasting supreme physical strength, he leads offensive charges fearlessly."
	},
	7: {
		"title": "Sid (席德)",
		"trait": "Gender: Male | Specialty: Balanced Combatant",
		"desc": "A street-smart fighter whose calm demeanor conceals lethal combo attacks. Extremely dependable in prolonged skirmishes."
	},
	8: {
		"title": "Jessica (潔西卡)",
		"trait": "Gender: Female | Specialty: Mystic Recovery",
		"desc": "A talented violinist who channels divine harmonies into life-saving enchantments. Master of team support, cleanses, and restorative melodies."
	},
	9: {
		"title": "Konnotsuroko (紺野鶴子)",
		"trait": "Gender: Female | Specialty: Graceful Discipline",
		"desc": "A serene traveler cloaked in classical martial elegance. Weaves disciplined strikes with harmonious elemental poise."
	},
	10: {
		"title": "Iris (艾莉絲)",
		"trait": "Gender: Female | Specialty: Versatile Sailor",
		"desc": "A seafaring adventurer hardened by tempestuous oceans. Resourceful, determined, and prepared for any unforeseen battle situation."
	},
	11: {
		"title": "Maria (瑪利亞)",
		"trait": "Gender: Female | Specialty: Supreme Healing",
		"desc": "A compassionate field medic dedicated to easing all suffering. Her unparalleled spiritual devotion restores fallen allies back to life."
	},
	12: {
		"title": "More (莫爾)",
		"trait": "Gender: Male | Specialty: Tactical Disruption",
		"desc": "A refined gentleman gifted with sharp wit and deceptive counter techniques. Turns opponents' brute force against themselves."
	},
	13: {
		"title": "Kurogane (鐵黑)",
		"trait": "Gender: Male | Specialty: Colossal Power",
		"desc": "A legendary artisan whose heavy blacksmith hammer shatters stone and steel alike. Unrivaled physical damage and rock-hard resilience."
	},
	14: {
		"title": "Karin (卡琳)",
		"trait": "Gender: Female | Specialty: Ki Martial Arts",
		"desc": "A dedicated martial disciple who channels fiery ki into explosive palm strikes. Lethally agile and destructive at close quarters."
	}
}

const STAT_KEYS: Array[String] = ["str", "con", "int", "wis", "agi"]
const TOTAL_BONUS_POINTS: int = 4
const ROLE_COUNT: int = 14

@export var target_slot: int = 0
@export var account_name: String = "default"

# Root Containers
@onready var background_rect: TextureRect = $Background
@onready var window_root: Control = $WindowRoot
@onready var audio_sfx: AudioStreamPlayer = $AudioSFX

# Step 1 Nodes
@onready var step1_container: Control = $WindowRoot/Step1
@onready var step1_bg: TextureRect = $WindowRoot/Step1/FormBg
@onready var step1_btn_arrow_l: TextureButton = $WindowRoot/Step1/LeftCard/BtnArrowLeft
@onready var step1_btn_arrow_r: TextureButton = $WindowRoot/Step1/LeftCard/BtnArrowRight
@onready var step1_role_name: Label = $WindowRoot/Step1/LeftCard/RoleNameLabel
@onready var step1_radar_chart: RadarChart = $WindowRoot/Step1/LeftCard/RadarChart
@onready var step1_role_standee: TextureRect = $WindowRoot/Step1/LeftCard/RoleStandee
@onready var step1_role_lore: Label = $WindowRoot/Step1/LeftCard/RoleLoreLabel

@onready var first_name_input: LineEdit = $WindowRoot/Step1/RightArea/NameContainer/FirstNameInput
@onready var family_name_input: LineEdit = $WindowRoot/Step1/RightArea/NameContainer/FamilyNameInput
@onready var preview_face_bust: TextureRect = $WindowRoot/Step1/RightArea/PreviewBox/FaceBust
@onready var btn_r: Button = $WindowRoot/Step1/RightArea/PreviewBox/BtnR
@onready var btn_h: Button = $WindowRoot/Step1/RightArea/PreviewBox/BtnH
@onready var walking_sprite: TextureRect = $WindowRoot/Step1/RightArea/PreviewBox/WalkingSprite
@onready var btn_turn_left: Button = $WindowRoot/Step1/RightArea/PreviewBox/BtnTurnLeft
@onready var btn_turn_right: Button = $WindowRoot/Step1/RightArea/PreviewBox/BtnTurnRight
@onready var step1_btn_return: TextureButton = $WindowRoot/Step1/BtnReturn
@onready var step1_btn_continue: TextureButton = $WindowRoot/Step1/BtnContinue

# Step 2 Nodes
@onready var step2_container: Control = $WindowRoot/Step2
@onready var step2_bg: TextureRect = $WindowRoot/Step2/FormBg
@onready var tab_hair: Button = $WindowRoot/Step2/LeftArea/TabsHBox/TabHair
@onready var tab_body: Button = $WindowRoot/Step2/LeftArea/TabsHBox/TabBody
@onready var tab_eyes: Button = $WindowRoot/Step2/LeftArea/TabsHBox/TabEyes
@onready var tab_wear: Button = $WindowRoot/Step2/LeftArea/TabsHBox/TabWear
@onready var style_val_label: Label = $WindowRoot/Step2/LeftArea/StyleArea/StyleValLabel
@onready var btn_style_prev: Button = $WindowRoot/Step2/LeftArea/StyleArea/BtnStylePrev
@onready var btn_style_next: Button = $WindowRoot/Step2/LeftArea/StyleArea/BtnStyleNext
@onready var btn_default_color: Button = $WindowRoot/Step2/LeftArea/BtnDefaultColor

@onready var slider_r: HSlider = $WindowRoot/Step2/LeftArea/SlidersArea/RedRow/SliderR
@onready var val_r: Label = $WindowRoot/Step2/LeftArea/SlidersArea/RedRow/ValR
@onready var btn_minus_r: Button = $WindowRoot/Step2/LeftArea/SlidersArea/RedRow/BtnMinusR
@onready var btn_plus_r: Button = $WindowRoot/Step2/LeftArea/SlidersArea/RedRow/BtnPlusR

@onready var slider_g: HSlider = $WindowRoot/Step2/LeftArea/SlidersArea/GreenRow/SliderG
@onready var val_g: Label = $WindowRoot/Step2/LeftArea/SlidersArea/GreenRow/ValG
@onready var btn_minus_g: Button = $WindowRoot/Step2/LeftArea/SlidersArea/GreenRow/BtnMinusG
@onready var btn_plus_g: Button = $WindowRoot/Step2/LeftArea/SlidersArea/GreenRow/BtnPlusG

@onready var slider_b: HSlider = $WindowRoot/Step2/LeftArea/SlidersArea/BlueRow/SliderB
@onready var val_b: Label = $WindowRoot/Step2/LeftArea/SlidersArea/BlueRow/ValB
@onready var btn_minus_b: Button = $WindowRoot/Step2/LeftArea/SlidersArea/BlueRow/BtnMinusB
@onready var btn_plus_b: Button = $WindowRoot/Step2/LeftArea/SlidersArea/BlueRow/BtnPlusB

@onready var step2_face_bust: TextureRect = $WindowRoot/Step2/RightArea/PreviewBox/FaceBust
@onready var step2_btn_r: Button = $WindowRoot/Step2/RightArea/PreviewBox/BtnR
@onready var step2_btn_h: Button = $WindowRoot/Step2/RightArea/PreviewBox/BtnH
@onready var step2_walking_sprite: TextureRect = $WindowRoot/Step2/RightArea/PreviewBox/WalkingSprite
@onready var step2_btn_turn_left: Button = $WindowRoot/Step2/RightArea/PreviewBox/BtnTurnLeft
@onready var step2_btn_turn_right: Button = $WindowRoot/Step2/RightArea/PreviewBox/BtnTurnRight
@onready var step2_full_name: Label = $WindowRoot/Step2/RightArea/FullNameLabel
@onready var step2_btn_return: TextureButton = $WindowRoot/Step2/BtnReturn
@onready var step2_btn_continue: TextureButton = $WindowRoot/Step2/BtnContinue

# Step 3 Nodes
@onready var step3_container: Control = $WindowRoot/Step3
@onready var step3_bg: TextureRect = $WindowRoot/Step3/FormBg
@onready var btn_elem_earth: TextureButton = $WindowRoot/Step3/LeftArea/ElementHBox/BtnElemEarth
@onready var btn_elem_water: TextureButton = $WindowRoot/Step3/LeftArea/ElementHBox/BtnElemWater
@onready var btn_elem_fire: TextureButton = $WindowRoot/Step3/LeftArea/ElementHBox/BtnElemFire
@onready var btn_elem_wind: TextureButton = $WindowRoot/Step3/LeftArea/ElementHBox/BtnElemWind
@onready var element_desc_label: Label = $WindowRoot/Step3/LeftArea/ElementDescLabel

@onready var step3_face_bust: TextureRect = $WindowRoot/Step3/RightArea/PreviewBox/FaceBust
@onready var step3_btn_r: Button = $WindowRoot/Step3/RightArea/PreviewBox/BtnR
@onready var step3_btn_h: Button = $WindowRoot/Step3/RightArea/PreviewBox/BtnH
@onready var step3_elem_coin: TextureRect = $WindowRoot/Step3/RightArea/PreviewBox/ElementCoinBadge
@onready var step3_walking_sprite: TextureRect = $WindowRoot/Step3/RightArea/PreviewBox/WalkingSprite
@onready var step3_btn_turn_left: Button = $WindowRoot/Step3/RightArea/PreviewBox/BtnTurnLeft
@onready var step3_btn_turn_right: Button = $WindowRoot/Step3/RightArea/PreviewBox/BtnTurnRight
@onready var step3_full_name: Label = $WindowRoot/Step3/RightArea/FullNameLabel
@onready var step3_btn_return: TextureButton = $WindowRoot/Step3/BtnReturn
@onready var step3_btn_finish: TextureButton = $WindowRoot/Step3/BtnFinish

# Step 4 Nodes (Role explication)
@onready var step4_container: Control = $WindowRoot/Step4
@onready var step4_bg: TextureRect = $WindowRoot/Step4/FormBg
@onready var step4_error_label: Label = $WindowRoot/Step4/ErrorLabel
@onready var step4_btn_prev: TextureButton = $WindowRoot/Step4/BtnPrev
@onready var step4_btn_ok: TextureButton = $WindowRoot/Step4/BtnOk
@onready var step4_role_name: Label = $WindowRoot/Step4/LeftCard/RoleNameLabel
@onready var step4_radar_chart: RadarChart = $WindowRoot/Step4/LeftCard/RadarChart
@onready var step4_role_lore: Label = $WindowRoot/Step4/LeftCard/RoleLoreLabel
@onready var step4_points_label: Label = $WindowRoot/Step4/StatsArea/ValPoints
@onready var step4_face_bust: TextureRect = $WindowRoot/Step4/RightArea/PreviewBox/FaceBust
@onready var step4_btn_r: Button = $WindowRoot/Step4/RightArea/PreviewBox/BtnR
@onready var step4_btn_h: Button = $WindowRoot/Step4/RightArea/PreviewBox/BtnH
@onready var step4_elem_coin: TextureRect = $WindowRoot/Step4/RightArea/PreviewBox/ElementCoinBadge
@onready var step4_walking_sprite: TextureRect = $WindowRoot/Step4/RightArea/PreviewBox/WalkingSprite
@onready var step4_btn_turn_left: Button = $WindowRoot/Step4/RightArea/PreviewBox/BtnTurnLeft
@onready var step4_btn_turn_right: Button = $WindowRoot/Step4/RightArea/PreviewBox/BtnTurnRight
@onready var step4_full_name: Label = $WindowRoot/Step4/RightArea/FullNameLabel

# Modal Popup Dialog
@onready var modal_error_popup: Control = $ModalErrorPopup
@onready var modal_message_label: Label = $ModalErrorPopup/DialogCard/MessageLabel
@onready var modal_btn_ok: Button = $ModalErrorPopup/DialogCard/BtnModalOk

# Backward Compatibility Aliases for test suites
@onready var step1_btn_next: TextureButton = step1_btn_continue
@onready var step1_btn_cancel: TextureButton = step1_btn_return
@onready var step2_btn_prev: TextureButton = step2_btn_return
@onready var step2_btn_next: TextureButton = step2_btn_continue
@onready var step3_btn_prev: TextureButton = step3_btn_return
@onready var step3_btn_next: TextureButton = step3_btn_finish
@onready var btn_finish: TextureButton = step4_btn_ok
@onready var btn_cancel: TextureButton = step1_btn_return

var name_input: LineEdit:
	get:
		return first_name_input

# State variables
var current_step: int = 1
var selected_role_id: int = 6 # Default to Daniel
var selected_element: String = "Fire"
var selected_hair_style: int = 1
var selected_hair_color: Color = Color(0.9, 0.9, 0.9, 1.0) # Silver/White
var selected_skin_tone: Color = Color(1.0, 1.0, 1.0, 1.0)
var selected_eye_color: Color = Color(0.2, 0.15, 0.1, 1.0)
var selected_wear_color: Color = Color(1.0, 1.0, 1.0, 1.0)
var _active_tab: int = 0 # 0=Hair, 1=Body, 2=Eyes, 3=Wear

const DEFAULT_HEADING: int = IsometricMath.Heading.SOUTH_WEST
const WALK_FPS: float = 8.0

var _current_direction: int = DEFAULT_HEADING # 0..7, IsometricMath.Heading
var _show_hat: bool = true
var _anim_timer: float = 0.0
var _walk_anim_timer: float = 0.0
var _avatar_frames: Array = []
var _cached_composite_frames: Array = []
var _standee_cache: Dictionary = {}

var base_stats: Dictionary = {"str": 10, "con": 10, "int": 10, "wis": 10, "agi": 10}
var bonus_points: Dictionary = {"str": 0, "con": 0, "int": 0, "wis": 0, "agi": 0}
var points_pool: int = TOTAL_BONUS_POINTS

func _ready() -> void:
	_load_art()
	_setup_signals()
	start_wizard(target_slot)

func _process(delta: float) -> void:
	_anim_timer += delta
	_walk_anim_timer += delta
	_update_blinking_avatar()
	_update_walking_sprite_frame()

func start_wizard(slot_index: int = 0) -> void:
	target_slot = slot_index
	selected_role_id = 6 # Daniel
	selected_element = "Fire"
	selected_hair_style = 1
	selected_hair_color = Color(0.9, 0.9, 0.9, 1.0)
	selected_skin_tone = Color(1.0, 1.0, 1.0, 1.0)
	selected_eye_color = Color(0.2, 0.15, 0.1, 1.0)
	selected_wear_color = Color(1.0, 1.0, 1.0, 1.0)
	_active_tab = 0
	_current_direction = DEFAULT_HEADING
	_show_hat = true
	points_pool = TOTAL_BONUS_POINTS
	bonus_points = {"str": 0, "con": 0, "int": 0, "wis": 0, "agi": 0}

	if first_name_input:
		first_name_input.text = ""
	if family_name_input:
		family_name_input.text = ""

	goto_step(1)

func goto_step(step_idx: int) -> void:
	current_step = clampi(step_idx, 1, 4)

	if step1_container:
		step1_container.visible = (current_step == 1)
	if step2_container:
		step2_container.visible = (current_step == 2)
	if step3_container:
		step3_container.visible = (current_step == 3)
	if step4_container:
		step4_container.visible = (current_step == 4)

	match current_step:
		1:
			_update_step1_view()
		2:
			_update_step2_view()
		3:
			_update_step3_view()
		4:
			_update_step4_view()

# ==================== ART & TEXTURES ====================

func _load_art() -> void:
	if background_rect and not background_rect.texture:
		if ResourceLoader.exists(BACKGROUND_PIC_PATH):
			background_rect.texture = load(BACKGROUND_PIC_PATH)

	if step1_bg and not step1_bg.texture:
		step1_bg.texture = _load_texture(FORM_STEP1_PATH)
	if step2_bg and not step2_bg.texture:
		step2_bg.texture = _load_texture(FORM_STEP4_PATH)
	if step3_bg and not step3_bg.texture:
		step3_bg.texture = _load_texture(FORM_STEP3_PATH)
	if step4_bg and not step4_bg.texture:
		step4_bg.texture = _load_texture(FORM_STEP2_PATH)

	# Carousel navigation arrows
	_setup_button(step1_btn_arrow_l, BTN_ARROW_L_PATH)
	_setup_button(step1_btn_arrow_r, BTN_ARROW_R_PATH)

	# Step 1 Navigation buttons (Return / Continue)
	_setup_button(step1_btn_return, BTN_CANCEL_PATH)
	_setup_button(step1_btn_continue, BTN_NEXT_PATH)

	# Step 2 Navigation buttons (Return / Continue)
	_setup_button(step2_btn_return, BTN_PREV_PATH)
	_setup_button(step2_btn_continue, BTN_NEXT_PATH)

	# Step 3 Navigation buttons (Return / Continue)
	_setup_button(step3_btn_return, BTN_PREV_PATH)
	_setup_button(step3_btn_finish, BTN_NEXT_PATH)

	# Step 4 Navigation buttons (Return / Create)
	_setup_button(step4_btn_prev, BTN_PREV_PATH)
	_setup_button(step4_btn_ok, BTN_OK_PATH)

	# Element Buttons in Step 3
	_setup_element_button(btn_elem_earth, ELEMENT_ICONS["Earth"])
	_setup_element_button(btn_elem_water, ELEMENT_ICONS["Water"])
	_setup_element_button(btn_elem_fire, ELEMENT_ICONS["Fire"])
	_setup_element_button(btn_elem_wind, ELEMENT_ICONS["Wind"])

	_style_name_inputs()
	_style_palette_controls()
	_style_tabs()

func _load_texture(path: String) -> Texture2D:
	var loader = _get_archive_loader()
	if loader and loader.has_method("get_ui_texture"):
		var tex = loader.get_ui_texture(path)
		if tex:
			return tex

	var full_res_path := path if path.begins_with("res://") else ("res://assets/" + path)
	if ResourceLoader.exists(full_res_path):
		return load(full_res_path)
	return null

func _setup_button(btn: TextureButton, path: String) -> void:
	if not btn:
		return

	var base_name: String = path.get_file().get_basename()
	if base_name.begins_with("Btn_Cancel") or base_name == "btn_cancel":
		base_name = "btn_cancel"
	elif base_name.begins_with("btn_ok") or base_name == "btn_ok":
		base_name = "btn_ok"
	elif base_name.begins_with("Btn_Prev") or base_name == "btn_prev":
		base_name = "btn_prev_small"
	elif base_name.begins_with("btn_next"):
		base_name = "btn_next"
	elif base_name.begins_with("btn_arrow_left"):
		base_name = "btn_arrow_left"
	elif base_name.begins_with("btn_arrow_right"):
		base_name = "btn_arrow_right"

	var normal_p := "res://assets/auth/%s_normal.png" % base_name
	var hover_p := "res://assets/auth/%s_hover.png" % base_name
	var pressed_p := "res://assets/auth/%s_pressed.png" % base_name

	if ResourceLoader.exists(normal_p) and ResourceLoader.exists(hover_p) and ResourceLoader.exists(pressed_p):
		btn.texture_normal = load(normal_p)
		btn.texture_hover = load(hover_p)
		btn.texture_pressed = load(pressed_p)
		return

	# Fallback: Try single 3-state sheet
	var sheet := _load_texture(path)
	if sheet:
		var h: int = int(sheet.get_height() / 3.0)
		var w: int = sheet.get_width()
		if h > 0 and w > 0:
			var tex_normal := AtlasTexture.new()
			tex_normal.atlas = sheet
			tex_normal.region = Rect2(0, 0, w, h)
			btn.texture_normal = tex_normal

			var tex_hover := AtlasTexture.new()
			tex_hover.atlas = sheet
			tex_hover.region = Rect2(0, h, w, h)
			btn.texture_hover = tex_hover

			var tex_pressed := AtlasTexture.new()
			tex_pressed.atlas = sheet
			tex_pressed.region = Rect2(0, h * 2, w, h)
			btn.texture_pressed = tex_pressed
			return

	if ResourceLoader.exists(normal_p):
		btn.texture_normal = load(normal_p)
	if ResourceLoader.exists(hover_p):
		btn.texture_hover = load(hover_p)
	if ResourceLoader.exists(pressed_p):
		btn.texture_pressed = load(pressed_p)

func _setup_element_button(btn: TextureButton, path: String) -> void:
	if not btn or not ResourceLoader.exists(path):
		return
	var tex := load(path) as Texture2D
	btn.texture_normal = tex
	btn.texture_hover = tex
	btn.texture_pressed = tex

func _play_sfx(path: String) -> void:
	if not audio_sfx or not ResourceLoader.exists(path):
		return
	if not is_inside_tree():
		return
	var stream = load(path)
	if stream:
		audio_sfx.stream = stream
		audio_sfx.play()

func _get_archive_loader():
	if is_inside_tree():
		return get_node_or_null("/root/ArchiveLoader")
	if Engine.get_main_loop() is SceneTree:
		return (Engine.get_main_loop() as SceneTree).root.get_node_or_null("ArchiveLoader")
	return null

func _get_game_database():
	if is_inside_tree():
		return get_node_or_null("/root/GameDatabase")
	if Engine.get_main_loop() is SceneTree:
		return (Engine.get_main_loop() as SceneTree).root.get_node_or_null("GameDatabase")
	return null

# ==================== SIGNALS & HOOKS ====================

var _signals_connected: bool = false

func _setup_signals() -> void:
	if _signals_connected:
		return
	_signals_connected = true
	# Step 1 Role Carousel
	if step1_btn_arrow_l:
		step1_btn_arrow_l.pressed.connect(func(): select_prev_role())
	if step1_btn_arrow_r:
		step1_btn_arrow_r.pressed.connect(func(): select_next_role())

	# Step 1 Navigation
	if step1_btn_return:
		step1_btn_return.pressed.connect(func():
			_play_sfx(SFX_CLICK_PATH)
			cancelled.emit()
		)
	if step1_btn_continue:
		step1_btn_continue.pressed.connect(_on_step1_continue)

	# Preview controls (Step 1, 2, 3)
	for b in [btn_turn_left, step2_btn_turn_left, step3_btn_turn_left, step4_btn_turn_left]:
		if b:
			b.pressed.connect(func(): _turn_character(-1))
	for b in [btn_turn_right, step2_btn_turn_right, step3_btn_turn_right, step4_btn_turn_right]:
		if b:
			b.pressed.connect(func(): _turn_character(1))

	for b in [btn_r, step2_btn_r, step3_btn_r, step4_btn_r]:
		if b:
			b.pressed.connect(_cycle_appearance_preset)
	for b in [btn_h, step2_btn_h, step3_btn_h, step4_btn_h]:
		if b:
			b.pressed.connect(_toggle_hat)

	# Step 2 Tabs
	if tab_hair:
		tab_hair.pressed.connect(func(): _select_tab(0))
	if tab_body:
		tab_body.pressed.connect(func(): _select_tab(1))
	if tab_eyes:
		tab_eyes.pressed.connect(func(): _select_tab(2))
	if tab_wear:
		tab_wear.pressed.connect(func(): _select_tab(3))

	# Step 2 Style variant
	if btn_style_prev:
		btn_style_prev.pressed.connect(func(): _cycle_hair_style(-1))
	if btn_style_next:
		btn_style_next.pressed.connect(func(): _cycle_hair_style(1))
	if btn_default_color:
		btn_default_color.pressed.connect(_reset_active_tab_color)

	# Step 2 Sliders & +/- buttons
	if slider_r:
		slider_r.value_changed.connect(func(v): _on_slider_changed("r", v))
	if slider_g:
		slider_g.value_changed.connect(func(v): _on_slider_changed("g", v))
	if slider_b:
		slider_b.value_changed.connect(func(v): _on_slider_changed("b", v))

	if btn_minus_r:
		btn_minus_r.pressed.connect(func(): _nudge_slider(slider_r, -5))
	if btn_plus_r:
		btn_plus_r.pressed.connect(func(): _nudge_slider(slider_r, 5))
	if btn_minus_g:
		btn_minus_g.pressed.connect(func(): _nudge_slider(slider_g, -5))
	if btn_plus_g:
		btn_plus_g.pressed.connect(func(): _nudge_slider(slider_g, 5))
	if btn_minus_b:
		btn_minus_b.pressed.connect(func(): _nudge_slider(slider_b, -5))
	if btn_plus_b:
		btn_plus_b.pressed.connect(func(): _nudge_slider(slider_b, 5))

	# Step 2 Navigation
	if step2_btn_return:
		step2_btn_return.pressed.connect(func():
			_play_sfx(SFX_CLICK_PATH)
			goto_step(1)
		)
	if step2_btn_continue:
		step2_btn_continue.pressed.connect(func():
			_play_sfx(SFX_CLICK_PATH)
			goto_step(3)
		)

	# Step 3 Elements
	if btn_elem_earth:
		btn_elem_earth.pressed.connect(func(): select_element("Earth"))
	if btn_elem_water:
		btn_elem_water.pressed.connect(func(): select_element("Water"))
	if btn_elem_fire:
		btn_elem_fire.pressed.connect(func(): select_element("Fire"))
	if btn_elem_wind:
		btn_elem_wind.pressed.connect(func(): select_element("Wind"))

	# Step 3 Navigation
	if step3_btn_return:
		step3_btn_return.pressed.connect(func():
			_play_sfx(SFX_CLICK_PATH)
			goto_step(2)
		)
	if step3_btn_finish:
		step3_btn_finish.pressed.connect(func():
			_play_sfx(SFX_CLICK_PATH)
			goto_step(4)
		)

	# Step 4 Navigation and point allocation
	if step4_btn_prev:
		step4_btn_prev.pressed.connect(func():
			_play_sfx(SFX_CLICK_PATH)
			goto_step(3)
		)
	if step4_btn_ok:
		step4_btn_ok.pressed.connect(_on_confirm_create)
	for stat_key in STAT_KEYS:
		var upper: String = stat_key.to_upper()
		var minus_btn := get_node_or_null("WindowRoot/Step4/StatsArea/BtnMinus%s" % upper) as TextureButton
		var plus_btn := get_node_or_null("WindowRoot/Step4/StatsArea/BtnPlus%s" % upper) as TextureButton
		if minus_btn:
			minus_btn.pressed.connect(func(): _on_stat_button(stat_key, -1))
		if plus_btn:
			plus_btn.pressed.connect(func(): _on_stat_button(stat_key, 1))

	# Modal Dismiss Button
	if modal_btn_ok:
		modal_btn_ok.pressed.connect(_dismiss_modal_error)

	# Enter key submission on LineEdits
	if first_name_input:
		first_name_input.text_submitted.connect(func(_t): _on_step1_continue())
	if family_name_input:
		family_name_input.text_submitted.connect(func(_t): _on_step1_continue())

# ==================== STEP 1: ROLE & CHARACTER ====================

func select_next_role() -> void:
	_play_sfx(SFX_CLICK_PATH)
	var next_id := (selected_role_id % ROLE_COUNT) + 1
	select_role(next_id)

func select_prev_role() -> void:
	_play_sfx(SFX_CLICK_PATH)
	var prev_id := (selected_role_id - 2 + ROLE_COUNT) % ROLE_COUNT + 1
	select_role(prev_id)

func select_role(role_id: int) -> void:
	selected_role_id = clampi(role_id, 1, ROLE_COUNT)
	_cached_composite_frames.clear()
	_update_step1_view()
	_update_shared_preview()

func _update_step1_view() -> void:
	var lore: Dictionary = ROLE_LORE.get(selected_role_id, {})
	var r_name: String = str(lore.get("title", "Role %d" % selected_role_id))
	var r_desc: String = str(lore.get("desc", ""))

	if step1_role_name:
		step1_role_name.text = r_name
	if step1_role_lore:
		step1_role_lore.text = r_desc

	# Standee
	if step1_role_standee:
		step1_role_standee.texture = _get_standee_texture(selected_role_id)

	# Calculate role base stats and update Radar Chart
	_calculate_base_stats()
	if step1_radar_chart:
		step1_radar_chart.set_stats(base_stats)

func _on_step1_continue() -> void:
	var first := first_name_input.text.strip_edges() if first_name_input else ""
	var last := family_name_input.text.strip_edges() if family_name_input else ""
	var combined := (first + " " + last).strip_edges()

	# If empty name -> trigger authentic alert sound & show modal error popup!
	if first.is_empty() or last.is_empty() or combined.is_empty():
		_show_modal_error("Please enter character name and family name!")
		return

	if combined.length() > 14:
		_show_modal_error("Character name cannot exceed 14 characters!")
		return

	_play_sfx(SFX_CLICK_PATH)
	goto_step(2)

func _show_modal_error(msg: String) -> void:
	_play_sfx(SFX_ALERT_PATH)
	if modal_message_label:
		modal_message_label.text = msg
	if modal_error_popup:
		modal_error_popup.visible = true
	if step4_error_label:
		step4_error_label.text = msg

func _dismiss_modal_error() -> void:
	_play_sfx(SFX_CLICK_PATH)
	if modal_error_popup:
		modal_error_popup.visible = false

	if not is_inside_tree():
		return
	if first_name_input and first_name_input.text.strip_edges().is_empty():
		first_name_input.grab_focus()
	elif family_name_input and family_name_input.text.strip_edges().is_empty():
		family_name_input.grab_focus()

# ==================== STEP 2: APPEARANCE ====================

func _select_tab(tab_idx: int) -> void:
	_play_sfx(SFX_CLICK_PATH)
	_active_tab = clampi(tab_idx, 0, 3)
	_update_tab_styling()
	_update_slider_values_from_active_color()

func _update_tab_styling() -> void:
	var tabs: Array[Button] = [tab_hair, tab_body, tab_eyes, tab_wear]
	for i in range(tabs.size()):
		var b := tabs[i]
		if b:
			if i == _active_tab:
				b.modulate = Color(1.3, 1.1, 0.4, 1.0) # Golden highlight
			else:
				b.modulate = Color(1.0, 1.0, 1.0, 0.85)

func _get_active_color() -> Color:
	match _active_tab:
		0: return selected_hair_color
		1: return selected_skin_tone
		2: return selected_eye_color
		3: return selected_wear_color
		_: return Color.WHITE

func _set_active_color(c: Color) -> void:
	match _active_tab:
		0: selected_hair_color = c
		1: selected_skin_tone = c
		2: selected_eye_color = c
		3: selected_wear_color = c
	_update_shared_preview()

func _update_slider_values_from_active_color() -> void:
	var c := _get_active_color()
	if slider_r:
		slider_r.set_value_no_signal(c.r * 255.0)
	if slider_g:
		slider_g.set_value_no_signal(c.g * 255.0)
	if slider_b:
		slider_b.set_value_no_signal(c.b * 255.0)

	if val_r: val_r.text = "%d" % int(c.r * 255.0)
	if val_g: val_g.text = "%d" % int(c.g * 255.0)
	if val_b: val_b.text = "%d" % int(c.b * 255.0)

func _on_slider_changed(channel: String, value: float) -> void:
	var c := _get_active_color()
	var norm_val: float = clampf(value / 255.0, 0.0, 1.0)
	match channel:
		"r":
			c.r = norm_val
			if val_r: val_r.text = "%d" % int(value)
		"g":
			c.g = norm_val
			if val_g: val_g.text = "%d" % int(value)
		"b":
			c.b = norm_val
			if val_b: val_b.text = "%d" % int(value)
	_set_active_color(c)

func _nudge_slider(slider: HSlider, delta_val: int) -> void:
	_play_sfx(SFX_CLICK_PATH)
	if slider:
		slider.value = clampf(slider.value + delta_val, 0.0, 255.0)

func _reset_active_tab_color() -> void:
	_play_sfx(SFX_CLICK_PATH)
	match _active_tab:
		0: selected_hair_color = Color(0.9, 0.9, 0.9, 1.0)
		1: selected_skin_tone = Color(1.0, 1.0, 1.0, 1.0)
		2: selected_eye_color = Color(0.2, 0.15, 0.1, 1.0)
		3: selected_wear_color = Color(1.0, 1.0, 1.0, 1.0)
	_update_slider_values_from_active_color()
	_update_shared_preview()

func _cycle_hair_style(delta_val: int) -> void:
	_play_sfx(SFX_CLICK_PATH)
	selected_hair_style = wrapi(selected_hair_style + delta_val, 1, 5)
	if style_val_label:
		style_val_label.text = "Style %d" % selected_hair_style
	_cached_composite_frames.clear()
	_update_shared_preview()

func select_hair_style(style_idx: int) -> void:
	selected_hair_style = clampi(style_idx, 1, 4)
	if style_val_label:
		style_val_label.text = "Style %d" % selected_hair_style
	_cached_composite_frames.clear()
	_update_shared_preview()

func set_hair_color(clr: Color) -> void:
	selected_hair_color = clr
	_update_slider_values_from_active_color()
	_update_shared_preview()

func _cycle_appearance_preset() -> void:
	_play_sfx(SFX_CLICK_PATH)
	var presets: Array[Color] = [
		Color(0.9, 0.9, 0.9),       # Silver
		Color(0.2, 0.15, 0.1),      # Deep Brown
		Color(0.08, 0.08, 0.08),    # Jet Black
		Color(0.95, 0.8, 0.4),      # Blonde
		Color(0.85, 0.25, 0.2),     # Crimson
		Color(0.25, 0.5, 0.9),      # Azure
		Color(0.3, 0.75, 0.4),      # Green
		Color(0.9, 0.5, 0.75)       # Pink
	]
	var cur_idx := 0
	for i in range(presets.size()):
		if presets[i].is_equal_approx(selected_hair_color):
			cur_idx = i
			break
	var next_clr = presets[(cur_idx + 1) % presets.size()]
	set_hair_color(next_clr)

func _toggle_hat() -> void:
	_play_sfx(SFX_CLICK_PATH)
	_show_hat = not _show_hat
	_cached_composite_frames.clear()
	_update_shared_preview()

func _update_step2_view() -> void:
	_update_tab_styling()
	_update_slider_values_from_active_color()
	if style_val_label:
		style_val_label.text = "Style %d" % selected_hair_style
	_update_shared_preview()

# ==================== STEP 3: ELEMENT & FINISH ====================

func select_element(elem_name: String) -> void:
	if not ELEMENT_DESCRIPTIONS.has(elem_name):
		return
	_play_sfx(SFX_CLICK_PATH)
	selected_element = elem_name
	_update_step3_view()
	_calculate_base_stats()

func _update_step3_view() -> void:
	if element_desc_label and ELEMENT_DESCRIPTIONS.has(selected_element):
		element_desc_label.text = ELEMENT_DESCRIPTIONS[selected_element]

	var unselected_mod := Color(0.75, 0.75, 0.75, 0.8)
	var selected_mod := Color(1.3, 1.3, 1.3, 1.0)

	if btn_elem_earth:
		btn_elem_earth.modulate = selected_mod if selected_element == "Earth" else unselected_mod
	if btn_elem_water:
		btn_elem_water.modulate = selected_mod if selected_element == "Water" else unselected_mod
	if btn_elem_fire:
		btn_elem_fire.modulate = selected_mod if selected_element == "Fire" else unselected_mod
	if btn_elem_wind:
		btn_elem_wind.modulate = selected_mod if selected_element == "Wind" else unselected_mod

	if step3_elem_coin and ELEMENT_ICONS.has(selected_element):
		step3_elem_coin.texture = load(ELEMENT_ICONS[selected_element])

	_update_shared_preview()

# ==================== STEP 4 COMPATIBILITY ====================

func _update_step4_view() -> void:
	if step4_error_label:
		step4_error_label.text = ""
	var lore: Dictionary = ROLE_LORE.get(selected_role_id, {})
	if step4_role_name:
		step4_role_name.text = str(lore.get("title", "Role %d" % selected_role_id))
	if step4_role_lore:
		step4_role_lore.text = "%s\n%s" % [str(lore.get("trait", "")), str(lore.get("desc", ""))]
	if step4_elem_coin and ELEMENT_ICONS.has(selected_element):
		step4_elem_coin.texture = load(ELEMENT_ICONS[selected_element])
	_refresh_stat_display()
	_update_shared_preview()

func _on_stat_button(stat_key: String, delta_val: int) -> void:
	_play_sfx(SFX_CLICK_PATH)
	_modify_stat(stat_key, delta_val)
	_refresh_stat_display()

func get_final_stats() -> Dictionary:
	var result: Dictionary = {}
	for stat_key in STAT_KEYS:
		result[stat_key] = int(base_stats[stat_key]) + int(bonus_points[stat_key])
	return result

func _refresh_stat_display() -> void:
	_calculate_base_stats()
	var final_stats := get_final_stats()
	if step4_points_label:
		step4_points_label.text = str(points_pool)
	for stat_key in STAT_KEYS:
		var upper: String = stat_key.to_upper()
		var value_label := get_node_or_null("WindowRoot/Step4/StatsArea/Val%s" % upper) as Label
		if value_label:
			value_label.text = str(final_stats[stat_key])
		var minus_btn := get_node_or_null("WindowRoot/Step4/StatsArea/BtnMinus%s" % upper) as TextureButton
		var plus_btn := get_node_or_null("WindowRoot/Step4/StatsArea/BtnPlus%s" % upper) as TextureButton
		if minus_btn:
			minus_btn.disabled = int(bonus_points[stat_key]) <= 0
			minus_btn.modulate.a = 0.4 if minus_btn.disabled else 1.0
		if plus_btn:
			plus_btn.disabled = points_pool <= 0
			plus_btn.modulate.a = 0.4 if plus_btn.disabled else 1.0
	if step4_radar_chart:
		step4_radar_chart.set_stats(final_stats)

# ==================== STYLING OVER BAKED SKIN ART ====================

func _style_name_inputs() -> void:
	# The skin bakes a black 88x18 "Name:" box at (584, 74); the inputs sit on top of it.
	for input in [first_name_input, family_name_input]:
		if not input:
			continue
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0, 0, 0, 1)
		box.set_border_width_all(0)
		box.content_margin_left = 3.0
		box.content_margin_right = 3.0
		box.content_margin_top = 0.0
		box.content_margin_bottom = 0.0
		input.add_theme_stylebox_override("normal", box)
		input.add_theme_stylebox_override("focus", box)
		input.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		input.add_theme_color_override("caret_color", Color(1, 1, 1, 1))
		input.add_theme_color_override("font_placeholder_color", Color(0.55, 0.55, 0.55, 1))
		input.add_theme_font_size_override("font_size", 11)

func _style_palette_controls() -> void:
	# The skin bakes the R/G/B gradient bars and +/- arrows; the controls become transparent
	# overlays and each slider shows only a thin position marker.
	var clear := StyleBoxEmpty.new()
	var marker_image := Image.create(3, 12, false, Image.FORMAT_RGBA8)
	marker_image.fill(Color(0.1, 0.1, 0.15, 1))
	for y in 12:
		marker_image.set_pixel(1, y, Color(1, 1, 1, 1))
	var marker := ImageTexture.create_from_image(marker_image)
	for slider in [slider_r, slider_g, slider_b]:
		if not slider:
			continue
		slider.add_theme_stylebox_override("slider", clear)
		slider.add_theme_stylebox_override("grabber_area", clear)
		slider.add_theme_stylebox_override("grabber_area_highlight", clear)
		slider.add_theme_icon_override("grabber", marker)
		slider.add_theme_icon_override("grabber_highlight", marker)
		slider.add_theme_icon_override("grabber_disabled", marker)
	for btn in [btn_minus_r, btn_plus_r, btn_minus_g, btn_plus_g, btn_minus_b, btn_plus_b]:
		if not btn:
			continue
		btn.text = ""
		btn.flat = true
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			btn.add_theme_stylebox_override(state, clear)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _style_tabs() -> void:
	if not btn_r:
		return
	for tab in [tab_hair, tab_body, tab_eyes, tab_wear]:
		if not tab:
			continue
		for state in ["normal", "hover", "pressed"]:
			var box := btn_r.get_theme_stylebox(state)
			if box:
				tab.add_theme_stylebox_override(state, box)

# ==================== LIVE PREVIEW (BUST & SPRITE) ====================

func _turn_character(dir: int) -> void:
	_play_sfx(SFX_CLICK_PATH)
	_current_direction = (_current_direction + dir + 8) % 8
	_update_walking_sprite_frame()

func _update_blinking_avatar() -> void:
	if _avatar_frames.is_empty():
		var loader = _get_archive_loader()
		if loader and loader.has_method("get_avatar_frames"):
			_avatar_frames = loader.get_avatar_frames(selected_role_id)
		else:
			_avatar_frames = _load_fallback_avatar_frames(selected_role_id)

	if not _avatar_frames.is_empty():
		var f_idx: int = 1 if (_anim_timer >= 3.5 and _anim_timer < 3.68) else 0
		if _anim_timer >= 3.68:
			_anim_timer = 0.0
		var tex = _avatar_frames[f_idx]
		for bust in [preview_face_bust, step2_face_bust, step3_face_bust, step4_face_bust]:
			if bust and bust.is_visible_in_tree():
				bust.texture = tex
				bust.modulate = selected_hair_color

func _update_walking_sprite_frame() -> void:
	var comp_frames := _get_player_composite_frames()
	var sub_idx: int = int(_walk_anim_timer * WALK_FPS) % 4
	var frame_idx: int = _current_direction * 4 + sub_idx

	var target_tex: Texture2D = null
	if not comp_frames.is_empty():
		if frame_idx < comp_frames.size():
			target_tex = comp_frames[frame_idx]
		else:
			target_tex = comp_frames[frame_idx % comp_frames.size()]
	else:
		target_tex = _get_standee_texture(selected_role_id)

	for spr in [walking_sprite, step2_walking_sprite, step3_walking_sprite, step4_walking_sprite]:
		if spr and spr.is_visible_in_tree():
			spr.texture = target_tex
			spr.modulate = selected_hair_color

func _get_player_composite_frames() -> Array:
	if not _cached_composite_frames.is_empty():
		return _cached_composite_frames

	var loader = _get_archive_loader()
	if loader and loader.has_method("get_player_composite_frames"):
		var equip_layers: Dictionary = {}
		if _show_hat:
			var db = _get_game_database()
			if db and db.has_method("get_role"):
				var r_data: Dictionary = db.get_role(selected_role_id)
				var head_id: int = int(r_data.get("default_head_item_id", 0))
				if head_id > 0:
					equip_layers["head"] = head_id

		_cached_composite_frames = loader.get_player_composite_frames(selected_role_id, equip_layers)
		return _cached_composite_frames

	return []

func _update_shared_preview() -> void:
	var full_name := ""
	if first_name_input and family_name_input:
		full_name = (first_name_input.text.strip_edges() + " " + family_name_input.text.strip_edges()).strip_edges()

	if step2_full_name:
		step2_full_name.text = full_name
	if step3_full_name:
		step3_full_name.text = full_name
	if step4_full_name:
		step4_full_name.text = full_name

	_update_blinking_avatar()
	_update_walking_sprite_frame()

func _get_standee_texture(role_id: int) -> Texture2D:
	if _standee_cache.has(role_id):
		return _standee_cache[role_id]

	var png_path := "res://assets/auth/standees/standee_role_%d.png" % role_id
	if ResourceLoader.exists(png_path):
		var tex := load(png_path) as Texture2D
		if tex:
			_standee_cache[role_id] = tex
			return tex
	return null

func _load_fallback_avatar_frames(role_id: int) -> Array:
	var frames: Array = []
	for f_idx in [0, 1]:
		var p := "res://assets/hud/avatar_role_%d_%d.png" % [role_id, f_idx]
		if ResourceLoader.exists(p):
			frames.append(load(p))
	if frames.is_empty():
		var default_p := "res://assets/hud/portraits/default_portrait.png"
		if ResourceLoader.exists(default_p):
			frames.append(load(default_p))
	return frames

# ==================== STATS ALLOCATION & BASE STATS ====================

func _calculate_base_stats() -> void:
	var r_data: Dictionary = {}
	var db = _get_game_database()
	if db and db.has_method("get_role"):
		r_data = db.get_role(selected_role_id)
	if r_data.is_empty():
		var GameDb = load("res://scripts/database/game_database.gd")
		if GameDb and "ROLES" in GameDb:
			r_data = GameDb.ROLES.get(selected_role_id, {})

	base_stats = {"str": 8, "con": 8, "int": 8, "wis": 8, "agi": 8}
	if not r_data.is_empty():
		base_stats["str"] = int(r_data.get("str", 8))
		base_stats["con"] = int(r_data.get("con", 8))
		base_stats["int"] = int(r_data.get("int", 8))
		base_stats["wis"] = int(r_data.get("wis", 8))
		base_stats["agi"] = int(r_data.get("agi", 8))

	if current_step >= 3 and not selected_element.is_empty():
		match selected_element:
			"Earth":
				base_stats["con"] += 2
				base_stats["str"] += 1
			"Water":
				base_stats["wis"] += 2
				base_stats["con"] += 1
				base_stats["int"] += 1
			"Fire":
				base_stats["str"] += 2
				base_stats["agi"] += 1
			"Wind":
				base_stats["agi"] += 2
				base_stats["str"] += 1

func _modify_stat(stat_key: String, delta_val: int) -> void:
	if delta_val > 0:
		var to_add: int = mini(delta_val, points_pool)
		bonus_points[stat_key] += to_add
		points_pool -= to_add
	elif delta_val < 0:
		var to_sub: int = mini(-delta_val, bonus_points[stat_key])
		bonus_points[stat_key] -= to_sub
		points_pool += to_sub

# ==================== FINAL CREATION ====================

func _on_confirm_create() -> void:
	var first := first_name_input.text.strip_edges() if first_name_input else ""
	var last := family_name_input.text.strip_edges() if family_name_input else ""
	var cname := (first + " " + last).strip_edges()

	if cname.is_empty() and name_input:
		cname = name_input.text.strip_edges()

	if cname.is_empty():
		_show_modal_error("Please enter character name!")
		return

	if cname.length() > 14:
		_show_modal_error("Character name cannot exceed 14 characters!")
		return

	_calculate_base_stats()
	var final_str: int = int(base_stats["str"]) + int(bonus_points["str"])
	var final_con: int = int(base_stats["con"]) + int(bonus_points["con"])
	var final_int: int = int(base_stats["int"]) + int(bonus_points["int"])
	var final_wis: int = int(base_stats["wis"]) + int(bonus_points["wis"])
	var final_agi: int = int(base_stats["agi"]) + int(bonus_points["agi"])

	var char_data := CharacterManager.create_default_character(
		target_slot,
		selected_role_id,
		cname,
		selected_element,
		final_str,
		final_con,
		final_int,
		final_wis,
		final_agi
	)

	char_data["hair_style"] = selected_hair_style
	char_data["hair_color"] = [selected_hair_color.r, selected_hair_color.g, selected_hair_color.b]
	char_data["skin_tone"] = [selected_skin_tone.r, selected_skin_tone.g, selected_skin_tone.b]
	char_data["first_name"] = first
	char_data["family_name"] = last

	CharacterManager.save_character(target_slot, char_data, account_name)
	_play_sfx(SFX_CLICK_PATH)
	character_created.emit(char_data)
