class_name BattleView
extends Control

## Wonderland Online - Turn-Based Battle View.
## Modern responsive visual combat presentation layer rendering:
## - 2:1 axonometric battle arena with adaptive field centering across dynamic resolutions.
## - 8-slot player and 8-slot enemy troop standees with animated overhead HP/SP bars.
## - 7 authentic battle action buttons (Attack, Defend, Skill, Item, Catch, Escape, Auto)
##   with authentic SFX (wav0151.wav), keyboard shortcuts (A, D, S, I, C, E, U), and hover cards.
## - Responsive Command Menu supporting DOCKED_BOTTOM_RIGHT and CONTEXTUAL_ANCHOR modes.
## - Dynamic Turn Timeline / Initiative Order dock with descending SPD sorting & active actor highlight.
## - Screen-space Target Selection with isometric grid hover highlights & target reticle tracking.
## - Floating Combat Text (FCT) with crits, heals, misses, element advantage badges & smooth tweening.
## - Skill / Item selection modals and Victory / Defeat progression dialogs.

const BattleManager = preload("res://scripts/battle/battle_manager.gd")
const CombatEngine = preload("res://scripts/battle/combat_engine.gd")
const TurnTimelineDock = preload("res://scripts/battle/turn_timeline_dock.gd")
const FloatingCombatText = preload("res://scripts/battle/floating_combat_text.gd")

# --- Signals ---
signal battle_action_selected(action: Dictionary)
signal slot_clicked(is_enemy: bool, slot: int)
signal victory_confirmed
signal defeat_confirmed
signal escape_confirmed
signal view_closed
signal skill_vfx_completed(anim_id: int)
signal target_selected(is_enemy: bool, slot: int)

# --- Geometry Constants (2:1 Axonometric Projection) ---
const TOTAL_SLOTS: int = 8
const FRONT_ROW_COUNT: int = 4
const BACK_ROW_COUNT: int = 4

const CANVAS_SIZE: Vector2 = Vector2(800.0, 600.0)
const DIAMOND_HALF_WIDTH: float = 24.0
const DIAMOND_HALF_HEIGHT: float = 12.0 # Exact 2:1 ratio (48x24 px)

# Centered offsets for 800x600 resolution
const PLAYER_FRONT_START: Vector2 = Vector2(658.0, 425.0)
const PLAYER_BACK_START: Vector2 = Vector2(702.0, 385.0)
const PLAYER_STEP: Vector2 = Vector2(-66.0, -8.0)

const ENEMY_FRONT_START: Vector2 = Vector2(160.0, 415.0)
const ENEMY_BACK_START: Vector2 = Vector2(110.0, 375.0)
const ENEMY_STEP: Vector2 = Vector2(66.0, -8.0)

const NEUTRAL_DIVIDER_START: Vector2 = Vector2(385.0, 150.0)
const NEUTRAL_DIVIDER_END: Vector2 = Vector2(455.0, 370.0)

# --- Asset Paths ---
const SKIN_DIR: String = "res://assets/menu/Skins/default/"
const WHITE_SKIN_DIR: String = "res://assets/menu/Skins/white/"
const ACTION_SFX: String = "res://assets/sound/wav0151.wav"

## Real command ring: sheet number and offset from the acting fighter's feet, per action.
const RING_ART: Dictionary = {
	BattleManager.ActionType.DEFEND: 1,
	BattleManager.ActionType.CATCH: 2,
	BattleManager.ActionType.ESCAPE: 3,
	BattleManager.ActionType.ITEM: 4,
	BattleManager.ActionType.AUTO: 5,
	BattleManager.ActionType.ATTACK: 6,
	BattleManager.ActionType.SKILL: 7,
}
const RING_OFFSET: Dictionary = {
	BattleManager.ActionType.DEFEND: Vector2(2, -90),
	BattleManager.ActionType.CATCH: Vector2(47, -68),
	BattleManager.ActionType.ESCAPE: Vector2(57, -20),
	BattleManager.ActionType.ITEM: Vector2(29, 18),
	BattleManager.ActionType.AUTO: Vector2(-20, 18),
	BattleManager.ActionType.ATTACK: Vector2(-49, -20),
	BattleManager.ActionType.SKILL: Vector2(-41, -69),
}

const BTN_PATHS: Array[Dictionary] = [
	{
		"normal": SKIN_DIR + "Btn_Battle_1.bmp",
		"hover": SKIN_DIR + "Btn_Battle_1_1.bmp",
		"pressed": SKIN_DIR + "Btn_Battle_1_2.bmp",
		"action": BattleManager.ActionType.ATTACK,
		"tooltip": "Normal Physical Attack [A]",
		"shortcut": "A",
		"key": KEY_A,
		"alt_key": KEY_1,
		"description": "Execute normal physical strike against targeted foe."
	},
	{
		"normal": SKIN_DIR + "Btn_Battle_2.bmp",
		"hover": SKIN_DIR + "Btn_Battle_2_1.bmp",
		"pressed": SKIN_DIR + "Btn_Battle_2_2.bmp",
		"action": BattleManager.ActionType.DEFEND,
		"tooltip": "Defend (Halves incoming damage) [D]",
		"shortcut": "D",
		"key": KEY_D,
		"alt_key": KEY_2,
		"description": "Assume defensive stance to reduce incoming damage by 50%."
	},
	{
		"normal": SKIN_DIR + "Btn_Battle_3.bmp",
		"hover": SKIN_DIR + "Btn_Battle_3_1.bmp",
		"pressed": SKIN_DIR + "Btn_Battle_3_2.bmp",
		"action": BattleManager.ActionType.SKILL,
		"tooltip": "Cast Stunt or Magic Skill [S]",
		"shortcut": "S",
		"key": KEY_S,
		"alt_key": KEY_3,
		"description": "Open martial stunt and elemental magic selection menu."
	},
	{
		"normal": SKIN_DIR + "Btn_Battle_4.bmp",
		"hover": SKIN_DIR + "Btn_Battle_4_1.bmp",
		"pressed": SKIN_DIR + "Btn_Battle_4_2.bmp",
		"action": BattleManager.ActionType.ITEM,
		"tooltip": "Use Combat Consumable Item [I]",
		"shortcut": "I",
		"key": KEY_I,
		"alt_key": KEY_4,
		"description": "Use consumable recovery herbs, potions, or combat scrolls."
	},
	{
		"normal": SKIN_DIR + "Btn_Battle_5.bmp",
		"hover": SKIN_DIR + "Btn_Battle_5_1.bmp",
		"pressed": SKIN_DIR + "Btn_Battle_5_2.bmp",
		"action": BattleManager.ActionType.CATCH,
		"tooltip": "Capture Enemy as Pet [C]",
		"shortcut": "C",
		"key": KEY_C,
		"alt_key": KEY_5,
		"description": "Attempt to capture a weakened wild monster as a loyal pet."
	},
	{
		"normal": SKIN_DIR + "Btn_Battle_6.bmp",
		"hover": SKIN_DIR + "Btn_Battle_6_1.bmp",
		"pressed": SKIN_DIR + "Btn_Battle_6_2.bmp",
		"action": BattleManager.ActionType.ESCAPE,
		"tooltip": "Flee from Battle [E]",
		"shortcut": "E",
		"key": KEY_E,
		"alt_key": KEY_6,
		"description": "Attempt to flee from battle based on relative SPD agility."
	},
	{
		"normal": SKIN_DIR + "Btn_Battle_7.bmp",
		"hover": SKIN_DIR + "Btn_Battle_7_1.bmp",
		"pressed": SKIN_DIR + "Btn_Battle_7_2.bmp",
		"action": BattleManager.ActionType.AUTO,
		"tooltip": "Toggle Auto-Battle Mode [U]",
		"shortcut": "U",
		"key": KEY_U,
		"alt_key": KEY_7,
		"description": "Toggle automatic tactical combat turn resolution."
	}
]

# --- Element Badge Colors ---
const ELEMENT_COLORS: Array[Color] = [
	Color(0.7, 0.7, 0.7, 1.0),       # None
	Color(0.85, 0.65, 0.25, 1.0),    # Earth
	Color(0.25, 0.65, 0.95, 1.0),    # Water
	Color(0.95, 0.35, 0.25, 1.0),    # Fire
	Color(0.35, 0.95, 0.45, 1.0)     # Wind
]

# --- State ---
var battle_manager: BattleManager = null
var battle_speed_multiplier: float = 1.0
var current_player_slot: int = 0
var pending_action_type: int = BattleManager.ActionType.ATTACK
var pending_skill_data: Dictionary = {}
var pending_item_data: Dictionary = {}
var is_targeting: bool = false
var targeting_requires_enemy: bool = true

var hovered_is_enemy: bool = false
var hovered_slot: int = -1
var selected_target_is_enemy: bool = true
var selected_target_slot: int = 0

# Command menu positioning mode
var is_contextual_menu: bool = false

# --- Node References ---
var arena_canvas: Control = null
var actors_layer: Control = null
var floating_text_layer: Control = null
var vfx_layer: Control = null

var status_panel: PanelContainer = null
var timer_label: Label = null
var turn_label: Label = null
var actor_name_label: Label = null

var action_bar: Control = null
var action_buttons: Array[TextureButton] = []
var action_tooltip_card: PanelContainer = null
var action_tooltip_title: Label = null
var action_tooltip_shortcut: Label = null
var action_tooltip_desc: Label = null

var turn_timeline: TurnTimelineDock = null
var target_reticle: Control = null

var skill_dialog: PanelContainer = null
var skill_list: VBoxContainer = null

var item_dialog: PanelContainer = null
var item_list: VBoxContainer = null

var victory_dialog: PanelContainer = null
var victory_title_label: Label = null
var exp_reward_label: Label = null
var gold_reward_label: Label = null
var items_reward_label: Label = null
var victory_ok_button: Button = null

var log_label: Label = null
var _sfx_player: AudioStreamPlayer = null
var hover_info_label: Label = null
var _queued_action_icons: Dictionary = {}

# Map of actor UI widgets: key -> Dictionary { "sprite": Control, "hp_bar": ProgressBar, "sp_bar": ProgressBar, "name_label": Label, "root": Control }
var actor_widgets: Dictionary = {}

# --- Lifecycle Methods ---

func _init() -> void:
	custom_minimum_size = CANVAS_SIZE

func _ready() -> void:
	if size.x < CANVAS_SIZE.x or size.y < CANVAS_SIZE.y:
		size = Vector2(maxf(size.x, CANVAS_SIZE.x), maxf(size.y, CANVAS_SIZE.y))
	if not resized.is_connected(_on_view_resized):
		resized.connect(_on_view_resized)
	_build_ui()
	_update_layout()
	if not battle_manager:
		battle_manager = CombatEngine.new()
		add_child(battle_manager)
	_bind_battle_manager_signals()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_layout()

func _on_view_resized() -> void:
	_update_layout()

func get_field_offset() -> Vector2:
	return Vector2(maxf(0.0, (size.x - CANVAS_SIZE.x) * 0.5), maxf(0.0, (size.y - CANVAS_SIZE.y) * 0.5))

func _update_layout() -> void:
	if countdown_label:
		countdown_label.offset_top = get_field_offset().y + 300.0
	if arena_canvas:
		arena_canvas.queue_redraw()
	for key in actor_widgets:
		var w: Dictionary = actor_widgets[key]
		var root_node: Control = w.get("root") as Control
		var is_enemy: bool = key.begins_with("enemy_")
		var parts: PackedStringArray = key.split("_")
		var slot: int = int(parts[1]) if parts.size() > 1 else 0
		if root_node and is_instance_valid(root_node):
			root_node.position = get_slot_screen_position(is_enemy, slot)
	
	_update_action_bar_position()
	_update_target_reticle_position()

func _process(_delta: float) -> void:
	if arena_canvas:
		arena_canvas.queue_redraw()

# --- Autoload Safe Lookup ---
func _get_archive_loader() -> Object:
	if Engine.has_singleton("ArchiveLoader"):
		return Engine.get_singleton("ArchiveLoader")
	if is_inside_tree() and get_tree() and get_tree().root and get_tree().root.has_node("ArchiveLoader"):
		return get_tree().root.get_node("ArchiveLoader")
	return null

# --- UI Construction ---

func _build_ui() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	
	# 1. Background
	var bg := ColorRect.new()
	bg.name = "ArenaBackground"
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.grow_horizontal = GROW_DIRECTION_BOTH
	bg.grow_vertical = GROW_DIRECTION_BOTH
	bg.color = Color(0.18, 0.38, 0.12, 1.0) # Authentic forest grass base
	add_child(bg)

	# Backdrop: authentic battle arena stage
	map_backdrop = TextureRect.new()
	map_backdrop.name = "MapBackdrop"
	map_backdrop.set_anchors_preset(PRESET_FULL_RECT)
	map_backdrop.anchor_right = 1.0
	map_backdrop.anchor_bottom = 1.0
	map_backdrop.grow_horizontal = GROW_DIRECTION_BOTH
	map_backdrop.grow_vertical = GROW_DIRECTION_BOTH
	map_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	map_backdrop.mouse_filter = MOUSE_FILTER_IGNORE
	if ResourceLoader.exists("res://assets/battle/forest_battle_bg.png"):
		map_backdrop.texture = load("res://assets/battle/forest_battle_bg.png") as Texture2D
		map_backdrop.visible = true
	else:
		map_backdrop.visible = false
	add_child(map_backdrop)
	
	# 2. Arena Custom Drawing Canvas
	arena_canvas = Control.new()
	arena_canvas.name = "ArenaCanvas"
	arena_canvas.set_anchors_preset(PRESET_FULL_RECT)
	arena_canvas.anchor_right = 1.0
	arena_canvas.anchor_bottom = 1.0
	arena_canvas.grow_horizontal = GROW_DIRECTION_BOTH
	arena_canvas.grow_vertical = GROW_DIRECTION_BOTH
	arena_canvas.mouse_filter = MOUSE_FILTER_IGNORE
	arena_canvas.draw.connect(_on_arena_canvas_draw)
	add_child(arena_canvas)
	
	# 3. Actors Layer
	actors_layer = Control.new()
	actors_layer.name = "ActorsLayer"
	actors_layer.set_anchors_preset(PRESET_FULL_RECT)
	actors_layer.anchor_right = 1.0
	actors_layer.anchor_bottom = 1.0
	actors_layer.grow_horizontal = GROW_DIRECTION_BOTH
	actors_layer.grow_vertical = GROW_DIRECTION_BOTH
	actors_layer.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(actors_layer)
	
	# 4. VFX Layer
	vfx_layer = Control.new()
	vfx_layer.name = "VFXLayer"
	vfx_layer.set_anchors_preset(PRESET_FULL_RECT)
	vfx_layer.anchor_right = 1.0
	vfx_layer.anchor_bottom = 1.0
	vfx_layer.grow_horizontal = GROW_DIRECTION_BOTH
	vfx_layer.grow_vertical = GROW_DIRECTION_BOTH
	vfx_layer.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(vfx_layer)
	
	# Target Reticle Indicator
	_build_target_reticle()
	
	# 5. Floating Text Layer
	floating_text_layer = Control.new()
	floating_text_layer.name = "FloatingTextLayer"
	floating_text_layer.set_anchors_preset(PRESET_FULL_RECT)
	floating_text_layer.anchor_right = 1.0
	floating_text_layer.anchor_bottom = 1.0
	floating_text_layer.grow_horizontal = GROW_DIRECTION_BOTH
	floating_text_layer.grow_vertical = GROW_DIRECTION_BOTH
	floating_text_layer.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(floating_text_layer)
	
	# 6. Combat Log Label at Top
	var log_panel := PanelContainer.new()
	log_panel.name = "LogPanel"
	log_panel.set_anchors_preset(PRESET_CENTER_TOP)
	log_panel.anchor_left = 0.5
	log_panel.anchor_top = 0.0
	log_panel.anchor_right = 0.5
	log_panel.anchor_bottom = 0.0
	log_panel.offset_left = -280.0
	log_panel.offset_top = 8.0
	log_panel.offset_right = 280.0
	log_panel.offset_bottom = 38.0
	log_panel.grow_horizontal = GROW_DIRECTION_BOTH
	var log_style := StyleBoxFlat.new()
	log_style.bg_color = Color(0.05, 0.07, 0.12, 0.85)
	log_style.border_color = Color(0.25, 0.35, 0.45, 0.7)
	log_style.set_border_width_all(1)
	log_style.set_corner_radius_all(4)
	log_panel.add_theme_stylebox_override("panel", log_style)
	
	log_label = Label.new()
	log_label.name = "LogLabel"
	log_label.text = "Wonderland Online Battle Arena Initialized."
	log_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	log_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	log_label.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95, 1.0))
	log_label.add_theme_font_size_override("font_size", 11)
	log_panel.add_child(log_label)
	add_child(log_panel)
	
	# Turn Timeline / Initiative Order Dock (Below LogPanel)
	_build_turn_timeline()
	
	# 7. Status Panel & 20s Countdown Timer (Bottom-Left)
	_build_status_panel()
	
	# 8. Action Buttons Bar (Bottom-Right, 7 Buttons)
	_build_action_buttons_bar()
	_apply_field_look()
	
	# 9. Skill Selection Dialog (Parchment Modal)
	_build_skill_dialog()
	
	# 10. Item Selection Dialog
	_build_item_dialog()
	
	# 11. Victory / Defeat Modal Screen
	_build_victory_dialog()

var countdown_label: Label = null

## The real fight has no banner, timeline or status panel: only the HUD, the fighters and a big cyan countdown.
func _apply_field_look() -> void:
	var log_panel := get_node_or_null("LogPanel") as Control
	if log_panel:
		log_panel.visible = false
	var bg := get_node_or_null("ArenaBackground") as ColorRect
	if bg:
		bg.color = Color(0.18, 0.38, 0.12, 1.0) # Authentic forest grass base
	if map_backdrop:
		map_backdrop.modulate = Color(1, 1, 1, 1)
		if map_backdrop.texture == null and ResourceLoader.exists("res://assets/battle/forest_battle_bg.png"):
			map_backdrop.texture = load("res://assets/battle/forest_battle_bg.png") as Texture2D
			map_backdrop.visible = true
	if countdown_label == null:
		countdown_label = Label.new()
		countdown_label.name = "CountdownLabel"
		countdown_label.set_anchors_preset(PRESET_CENTER_TOP)
		countdown_label.anchor_left = 0.5
		countdown_label.anchor_right = 0.5
		countdown_label.offset_left = -60.0
		countdown_label.offset_right = 60.0
		countdown_label.offset_top = get_field_offset().y + 240.0
		countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		countdown_label.mouse_filter = MOUSE_FILTER_IGNORE
		countdown_label.add_theme_font_size_override("font_size", 42)
		countdown_label.add_theme_color_override("font_color", Color(0.25, 0.92, 1.0, 1.0))
		countdown_label.add_theme_color_override("font_outline_color", Color(0.02, 0.2, 0.3, 1.0))
		countdown_label.add_theme_constant_override("outline_size", 4)
		add_child(countdown_label)
	_update_action_bar_position()
	if hover_info_label == null:
		hover_info_label = Label.new()
		hover_info_label.name = "HoverInfoLabel"
		hover_info_label.visible = false
		hover_info_label.z_index = 30
		hover_info_label.mouse_filter = MOUSE_FILTER_IGNORE
		hover_info_label.add_theme_font_size_override("font_size", 11)
		hover_info_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		hover_info_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
		hover_info_label.add_theme_constant_override("outline_size", 3)
		add_child(hover_info_label)
	_hide_old_panels()


func _hide_old_panels() -> void:
	var log_panel := get_node_or_null("LogPanel") as Control
	if log_panel:
		log_panel.visible = false
	if status_panel:
		status_panel.visible = false
	if turn_timeline:
		turn_timeline.visible = false


func _build_turn_timeline() -> void:
	turn_timeline = TurnTimelineDock.new()
	turn_timeline.name = "TurnTimelineDock"
	turn_timeline.set_anchors_preset(PRESET_CENTER_TOP)
	turn_timeline.anchor_left = 0.5
	turn_timeline.anchor_top = 0.0
	turn_timeline.anchor_right = 0.5
	turn_timeline.anchor_bottom = 0.0
	turn_timeline.offset_left = -280.0
	turn_timeline.offset_top = 44.0
	turn_timeline.offset_right = 280.0
	turn_timeline.offset_bottom = 90.0
	turn_timeline.grow_horizontal = GROW_DIRECTION_BOTH
	turn_timeline.combatant_card_clicked.connect(func(is_enemy: bool, slot: int):
		if is_targeting:
			_handle_slot_click(is_enemy, slot)
	)
	add_child(turn_timeline)

func _build_target_reticle() -> void:
	target_reticle = Control.new()
	target_reticle.name = "TargetReticle"
	target_reticle.mouse_filter = MOUSE_FILTER_IGNORE
	target_reticle.visible = false
	target_reticle.z_index = 10
	
	var arrow := Label.new()
	arrow.name = "ReticleArrow"
	arrow.text = "▼"
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow.add_theme_font_size_override("font_size", 20)
	arrow.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	arrow.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	arrow.add_theme_constant_override("shadow_offset_x", 1)
	arrow.add_theme_constant_override("shadow_offset_y", 1)
	arrow.position = Vector2(-12.0, -28.0)
	target_reticle.add_child(arrow)
	
	vfx_layer.add_child(target_reticle)

func _build_status_panel() -> void:
	status_panel = PanelContainer.new()
	status_panel.name = "StatusPanel"
	status_panel.set_anchors_preset(PRESET_BOTTOM_LEFT)
	status_panel.anchor_left = 0.0
	status_panel.anchor_top = 1.0
	status_panel.anchor_right = 0.0
	status_panel.anchor_bottom = 1.0
	status_panel.offset_left = 16.0
	status_panel.offset_top = -125.0
	status_panel.offset_right = 169.0
	status_panel.offset_bottom = -10.0
	status_panel.grow_vertical = GROW_DIRECTION_BEGIN
	
	var status_style := StyleBoxFlat.new()
	status_style.bg_color = Color(0.12, 0.14, 0.20, 0.95)
	status_style.border_color = Color(0.85, 0.70, 0.30, 0.9)
	status_style.set_border_width_all(2)
	status_style.set_corner_radius_all(6)
	
	var bg_tex: Texture2D = _chroma_keyed_texture(SKIN_DIR + "BattleStatus_1.bmp")
	if bg_tex:
		var tex_style := StyleBoxTexture.new()
		tex_style.texture = bg_tex
		status_panel.add_theme_stylebox_override("panel", tex_style)
	else:
		status_panel.add_theme_stylebox_override("panel", status_style)
		
	var vbox := VBoxContainer.new()
	vbox.name = "StatusVBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	actor_name_label = Label.new()
	actor_name_label.name = "ActorNameLabel"
	actor_name_label.text = "Player Turn"
	actor_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	actor_name_label.add_theme_font_size_override("font_size", 13)
	actor_name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4, 1.0))
	vbox.add_child(actor_name_label)
	
	turn_label = Label.new()
	turn_label.name = "TurnLabel"
	turn_label.text = "Turn 1"
	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_label.add_theme_font_size_override("font_size", 11)
	turn_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9, 1.0))
	vbox.add_child(turn_label)
	
	timer_label = Label.new()
	timer_label.name = "TimerLabel"
	timer_label.text = "20"
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 28)
	timer_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0)) # Bright Gold
	vbox.add_child(timer_label)
	
	status_panel.add_child(vbox)
	add_child(status_panel)

var map_backdrop: TextureRect = null

const ENVIRONMENT_BACKDROPS: Dictionary = {
	"forest": "res://assets/battle/forest_battle_bg.png",
	"beach": "res://assets/battle/beach_battle_bg.png",
	"cave": "res://assets/battle/cave_battle_bg.png",
	"deck": "res://assets/battle/deck_battle_bg.png",
}

const ENVIRONMENT_GROUND_COLORS: Dictionary = {
	"forest": Color(0.18, 0.38, 0.12, 1.0),
	"beach": Color(0.82, 0.76, 0.58, 1.0),
	"cave": Color(0.24, 0.22, 0.26, 1.0),
	"deck": Color(0.44, 0.30, 0.18, 1.0),
}

var current_environment: String = "forest"

## Shows `texture` (authentic battle stage) behind the arena.
func set_backdrop(texture: Texture2D) -> void:
	if map_backdrop == null:
		return
	if texture != null:
		map_backdrop.texture = texture
		map_backdrop.visible = true
	else:
		var def_path: String = String(ENVIRONMENT_BACKDROPS.get(current_environment, "res://assets/battle/forest_battle_bg.png"))
		if ResourceLoader.exists(def_path):
			map_backdrop.texture = load(def_path) as Texture2D
			map_backdrop.visible = true
		else:
			map_backdrop.visible = false

## Sets environment backdrop and matching arena ground tint.
func set_environment(env_type: String) -> void:
	var clean_type: String = env_type.to_lower().strip_edges()
	if not ENVIRONMENT_BACKDROPS.has(clean_type):
		clean_type = "forest"
	current_environment = clean_type
	var path: String = String(ENVIRONMENT_BACKDROPS.get(clean_type, ""))
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		if tex:
			set_backdrop(tex)
	var bg := get_node_or_null("ArenaBackground") as ColorRect
	if bg and ENVIRONMENT_GROUND_COLORS.has(clean_type):
		bg.color = ENVIRONMENT_GROUND_COLORS[clean_type]

static func resolve_environment_for_map(map_id: int, map_name: String = "") -> String:
	var lower_name: String = map_name.to_lower()
	if "forest" in lower_name or "wood" in lower_name or "tree" in lower_name or "grass" in lower_name or "plain" in lower_name or map_id in [10002, 10004]:
		return "forest"
	elif "cave" in lower_name or "cavern" in lower_name or "mine" in lower_name or "dungeon" in lower_name or map_id in [10003, 10005, 12001]:
		return "cave"
	elif "beach" in lower_name or "shore" in lower_name or "coast" in lower_name or map_id in [10001, 10011]:
		return "beach"
	elif "ship" in lower_name or "deck" in lower_name or "cabin" in lower_name or "boat" in lower_name or map_id in [10000, 10006]:
		return "deck"
	return "forest"

## Loads a skin bitmap and turns its pure green (0, 255, 0) chroma key transparent.
func _chroma_keyed_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var source := load(path) as Texture2D
	if source == null:
		return null
	var image := source.get_image()
	if image == null:
		return source
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.r < 0.02 and c.g > 0.98 and c.b < 0.02:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(image)

## Each Btn_Battle_N.bmp is a 28x84 sheet of three 28x28 frames: normal, highlighted, pressed.
func _battle_button_frame(path: String, frame: int) -> Texture2D:
	var sheet := _chroma_keyed_texture(path)
	if sheet == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(0.0, 28.0 * frame, 28.0, 28.0)
	return atlas

func _build_action_buttons_bar() -> void:
	action_bar = Control.new()
	action_bar.name = "ActionButtonsBar"
	action_bar.mouse_filter = MOUSE_FILTER_IGNORE
	# 7 buttons of 28px width + 4px spacing = 7 * 28 + 6 * 4 = 220px width, 84px height
	action_bar.set_anchors_preset(PRESET_BOTTOM_RIGHT)
	action_bar.anchor_left = 1.0
	action_bar.anchor_top = 1.0
	action_bar.anchor_right = 1.0
	action_bar.anchor_bottom = 1.0
	action_bar.offset_left = -240.0
	action_bar.offset_top = -44.0
	action_bar.offset_right = -20.0
	action_bar.offset_bottom = -16.0
	action_bar.grow_horizontal = GROW_DIRECTION_BEGIN
	action_bar.grow_vertical = GROW_DIRECTION_BEGIN
	action_bar.add_theme_constant_override("separation", 4)
	
	action_buttons.clear()
	for i in range(BTN_PATHS.size()):
		var info: Dictionary = BTN_PATHS[i]
		var btn := TextureButton.new()
		btn.name = "Btn_Battle_%d" % (i + 1)
		btn.tooltip_text = info.get("tooltip", "")
		btn.custom_minimum_size = Vector2(28.0, 28.0)
		btn.ignore_texture_size = false
		btn.stretch_mode = TextureButton.STRETCH_KEEP
		
		var ring_art: int = int(RING_ART.get(int(info.get("action", 0)), i + 1))
		var norm_path: String = SKIN_DIR + "Btn_Battle_%d.bmp" % ring_art
		var disabled_path: String = SKIN_DIR + "Btn_Battle_%d_2.bmp" % ring_art
		
		# Frames of the enabled sheet; the "_2" sheet is the greyed-out set used while it is not the player's turn.
		btn.texture_normal = _battle_button_frame(norm_path, 0)
		btn.texture_hover = _battle_button_frame(norm_path, 1)
		btn.texture_pressed = _battle_button_frame(norm_path, 2)
		btn.texture_disabled = _battle_button_frame(disabled_path, 0)
			
		var action_type: int = int(info.get("action", 0))
		btn.pressed.connect(_on_battle_button_pressed.bind(action_type, i))
		btn.mouse_entered.connect(_on_action_button_hovered.bind(i, btn))
		btn.mouse_exited.connect(_on_action_button_unhovered)
		
		action_bar.add_child(btn)
		action_buttons.append(btn)
		
	# Floating Tooltip Hover Card
	_build_action_tooltip_card()
	add_child(action_bar)

func _build_action_tooltip_card() -> void:
	action_tooltip_card = PanelContainer.new()
	action_tooltip_card.name = "ActionTooltipCard"
	action_tooltip_card.visible = false
	action_tooltip_card.mouse_filter = MOUSE_FILTER_IGNORE
	action_tooltip_card.z_index = 25
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.14, 0.96)
	style.border_color = Color(0.9, 0.75, 0.3, 0.95)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8.0
	style.content_margin_top = 4.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 4.0
	action_tooltip_card.add_theme_stylebox_override("panel", style)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	
	action_tooltip_title = Label.new()
	action_tooltip_title.text = "Attack"
	action_tooltip_title.add_theme_font_size_override("font_size", 11)
	action_tooltip_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3, 1.0))
	hbox.add_child(action_tooltip_title)
	
	action_tooltip_shortcut = Label.new()
	action_tooltip_shortcut.text = "[A]"
	action_tooltip_shortcut.add_theme_font_size_override("font_size", 10)
	action_tooltip_shortcut.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0))
	hbox.add_child(action_tooltip_shortcut)
	vbox.add_child(hbox)
	
	action_tooltip_desc = Label.new()
	action_tooltip_desc.text = "Action description."
	action_tooltip_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_tooltip_desc.custom_minimum_size = Vector2(160.0, 0.0)
	action_tooltip_desc.add_theme_font_size_override("font_size", 10)
	action_tooltip_desc.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92, 1.0))
	vbox.add_child(action_tooltip_desc)
	
	action_tooltip_card.add_child(vbox)
	add_child(action_tooltip_card)

func _on_action_button_hovered(idx: int, btn: TextureButton) -> void:
	play_sfx(ACTION_SFX)
	if idx < 0 or idx >= BTN_PATHS.size():
		return
	var info: Dictionary = BTN_PATHS[idx]
	action_tooltip_title.text = String(info.get("tooltip", "").split(" [")[0])
	action_tooltip_shortcut.text = "[%s]" % String(info.get("shortcut", ""))
	action_tooltip_desc.text = String(info.get("description", ""))
	
	var btn_global: Vector2 = btn.global_position
	var target_x: float = btn_global.x - 40.0
	var target_y: float = btn_global.y - 58.0
	
	target_x = clampf(target_x, 16.0, size.x - 180.0)
	action_tooltip_card.global_position = Vector2(target_x, target_y)
	action_tooltip_card.visible = true

func _on_action_button_unhovered() -> void:
	if action_tooltip_card:
		action_tooltip_card.visible = false

# --- Action Bar Responsive Position Update ---

func _update_action_bar_position() -> void:
	if not action_bar:
		return
	# The ring is drawn around the fighter who is entering a command.
	action_bar.set_anchors_preset(PRESET_FULL_RECT)
	action_bar.offset_left = 0.0
	action_bar.offset_top = 0.0
	action_bar.offset_right = 0.0
	action_bar.offset_bottom = 0.0
	var feet: Vector2 = get_slot_screen_position(false, current_player_slot)
	for i in action_buttons.size():
		var action_type: int = int(BTN_PATHS[i].get("action", 0))
		var offset: Vector2 = RING_OFFSET.get(action_type, Vector2.ZERO)
		action_buttons[i].position = feet + offset - Vector2(14.0, 14.0)

func _update_action_bar_permissions() -> void:
	var is_pet: bool = (current_player_slot > 0)
	for i in range(action_buttons.size()):
		var btn: TextureButton = action_buttons[i]
		var act_type: int = int(BTN_PATHS[i].get("action", 0))
		if is_pet and (act_type == BattleManager.ActionType.CATCH or act_type == BattleManager.ActionType.ITEM):
			btn.disabled = true
			btn.mouse_filter = MOUSE_FILTER_IGNORE
		else:
			btn.disabled = false
			btn.mouse_filter = MOUSE_FILTER_STOP

func set_action_bar_contextual(enable: bool) -> void:
	is_contextual_menu = enable
	_update_action_bar_position()

func _build_skill_dialog() -> void:
	skill_dialog = PanelContainer.new()
	skill_dialog.name = "SkillSelectDialog"
	skill_dialog.set_anchors_preset(PRESET_CENTER)
	skill_dialog.anchor_left = 0.5
	skill_dialog.anchor_top = 0.5
	skill_dialog.anchor_right = 0.5
	skill_dialog.anchor_bottom = 0.5
	skill_dialog.offset_left = -140.0
	skill_dialog.offset_top = -160.0
	skill_dialog.offset_right = 140.0
	skill_dialog.offset_bottom = 160.0
	skill_dialog.grow_horizontal = GROW_DIRECTION_BOTH
	skill_dialog.grow_vertical = GROW_DIRECTION_BOTH
	skill_dialog.visible = false
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.12, 0.18, 0.98)
	style.border_color = Color(0.85, 0.70, 0.25, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	skill_dialog.add_theme_stylebox_override("panel", style)
	
	var vbox := VBoxContainer.new()
	var title := Label.new()
	title.text = "Select Combat Skill"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	vbox.add_child(title)
	
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(260.0, 240.0)
	skill_list = VBoxContainer.new()
	scroll.add_child(skill_list)
	vbox.add_child(scroll)
	
	var btn_close := Button.new()
	btn_close.text = "Cancel"
	btn_close.pressed.connect(func(): skill_dialog.visible = false)
	vbox.add_child(btn_close)
	
	skill_dialog.add_child(vbox)
	add_child(skill_dialog)

func _build_item_dialog() -> void:
	item_dialog = PanelContainer.new()
	item_dialog.name = "ItemSelectDialog"
	item_dialog.set_anchors_preset(PRESET_CENTER)
	item_dialog.anchor_left = 0.5
	item_dialog.anchor_top = 0.5
	item_dialog.anchor_right = 0.5
	item_dialog.anchor_bottom = 0.5
	item_dialog.offset_left = -140.0
	item_dialog.offset_top = -140.0
	item_dialog.offset_right = 140.0
	item_dialog.offset_bottom = 140.0
	item_dialog.grow_horizontal = GROW_DIRECTION_BOTH
	item_dialog.grow_vertical = GROW_DIRECTION_BOTH
	item_dialog.visible = false
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.12, 0.18, 0.98)
	style.border_color = Color(0.35, 0.75, 0.95, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	item_dialog.add_theme_stylebox_override("panel", style)
	
	var vbox := VBoxContainer.new()
	var title := Label.new()
	title.text = "Select Combat Consumable"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0, 1.0))
	vbox.add_child(title)
	
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(260.0, 200.0)
	item_list = VBoxContainer.new()
	scroll.add_child(item_list)
	vbox.add_child(scroll)
	
	var btn_close := Button.new()
	btn_close.text = "Cancel"
	btn_close.pressed.connect(func(): item_dialog.visible = false)
	vbox.add_child(btn_close)
	
	item_dialog.add_child(vbox)
	add_child(item_dialog)

func _build_victory_dialog() -> void:
	victory_dialog = PanelContainer.new()
	victory_dialog.name = "VictoryDialog"
	victory_dialog.set_anchors_preset(PRESET_CENTER)
	victory_dialog.anchor_left = 0.5
	victory_dialog.anchor_top = 0.5
	victory_dialog.anchor_right = 0.5
	victory_dialog.anchor_bottom = 0.5
	victory_dialog.offset_left = -150.0
	victory_dialog.offset_top = -130.0
	victory_dialog.offset_right = 150.0
	victory_dialog.offset_bottom = 130.0
	victory_dialog.grow_horizontal = GROW_DIRECTION_BOTH
	victory_dialog.grow_vertical = GROW_DIRECTION_BOTH
	victory_dialog.visible = false
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.16, 0.98)
	style.border_color = Color(1.0, 0.85, 0.3, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	victory_dialog.add_theme_stylebox_override("panel", style)
	
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	
	victory_title_label = Label.new()
	victory_title_label.name = "VictoryTitleLabel"
	victory_title_label.text = "VICTORY!"
	victory_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_title_label.add_theme_font_size_override("font_size", 22)
	victory_title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1.0))
	vbox.add_child(victory_title_label)
	
	exp_reward_label = Label.new()
	exp_reward_label.name = "ExpRewardLabel"
	exp_reward_label.text = "EXP Earned: +0"
	exp_reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exp_reward_label.add_theme_font_size_override("font_size", 14)
	exp_reward_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5, 1.0))
	vbox.add_child(exp_reward_label)
	
	gold_reward_label = Label.new()
	gold_reward_label.name = "GoldRewardLabel"
	gold_reward_label.text = "Gold Earned: +0"
	gold_reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_reward_label.add_theme_font_size_override("font_size", 14)
	gold_reward_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	vbox.add_child(gold_reward_label)
	
	items_reward_label = Label.new()
	items_reward_label.name = "ItemsRewardLabel"
	items_reward_label.text = "Items Dropped: None"
	items_reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	items_reward_label.add_theme_font_size_override("font_size", 12)
	items_reward_label.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0, 1.0))
	vbox.add_child(items_reward_label)
	
	victory_ok_button = Button.new()
	victory_ok_button.name = "VictoryOkButton"
	victory_ok_button.text = "OK"
	victory_ok_button.custom_minimum_size = Vector2(100.0, 34.0)
	victory_ok_button.pressed.connect(_on_victory_ok_pressed)
	vbox.add_child(victory_ok_button)
	
	victory_dialog.add_child(vbox)
	add_child(victory_dialog)

# --- Signal Binding with BattleManager ---

func _bind_battle_manager_signals() -> void:
	if not battle_manager:
		return
	battle_manager.battle_started.connect(_on_bm_battle_started)
	battle_manager.turn_started.connect(_on_bm_turn_started)
	battle_manager.round_execution_started.connect(_on_bm_round_execution_started)
	battle_manager.turn_timer_tick.connect(_on_bm_timer_tick)
	battle_manager.actor_damaged.connect(_on_bm_actor_damaged)
	battle_manager.actor_healed.connect(_on_bm_actor_healed)
	battle_manager.actor_defeated.connect(_on_bm_actor_defeated)
	battle_manager.action_executed.connect(_on_bm_action_executed)
	battle_manager.battle_won.connect(_on_bm_battle_won)
	battle_manager.battle_lost.connect(_on_bm_battle_lost)
	battle_manager.battle_escaped.connect(_on_bm_battle_escaped)

func set_battle_manager(bm: BattleManager) -> void:
	if battle_manager and battle_manager != bm and battle_manager.get_parent() == self:
		battle_manager.queue_free()
	battle_manager = bm
	if battle_manager.get_parent() != self:
		add_child(battle_manager)
	if battle_manager.has_method("set_battle_speed"):
		battle_manager.set_battle_speed(battle_speed_multiplier)
	_bind_battle_manager_signals()
	refresh_actor_widgets()
	refresh_turn_timeline()

func set_battle_speed(speed: float) -> void:
	battle_speed_multiplier = maxf(speed, 0.1)
	if battle_manager and battle_manager.has_method("set_battle_speed"):
		battle_manager.set_battle_speed(battle_speed_multiplier)

func refresh_turn_timeline() -> void:
	if not turn_timeline or not battle_manager:
		return
	var timeline: Array[Dictionary] = []
	if battle_manager is CombatEngine:
		timeline = (battle_manager as CombatEngine).get_initiative_timeline(current_player_slot, false)
	else:
		# Fallback timeline calculation
		for s in range(TOTAL_SLOTS):
			var p: Dictionary = battle_manager.get_participant(false, s)
			if not p.is_empty() and bool(p.get("is_alive", false)):
				timeline.append({
					"name": p.get("name", "Player"), "level": p.get("level", 1),
					"spd": p.get("spd", 10), "slot": s, "is_enemy": false,
					"element": p.get("element", 0), "is_active": (s == current_player_slot)
				})
			var e: Dictionary = battle_manager.get_participant(true, s)
			if not e.is_empty() and bool(e.get("is_alive", false)):
				timeline.append({
					"name": e.get("name", "Enemy"), "level": e.get("level", 1),
					"spd": e.get("spd", 10), "slot": s, "is_enemy": true,
					"element": e.get("element", 0), "is_active": false
				})
		timeline.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("spd", 10)) > int(b.get("spd", 10))
		)
	turn_timeline.update_timeline(timeline, battle_manager.current_turn)

# --- Grid Geometry & Coordinates ---

func get_slot_screen_position(is_enemy: bool, slot: int) -> Vector2:
	var base_pos: Vector2
	if not is_enemy:
		if slot < FRONT_ROW_COUNT:
			base_pos = PLAYER_FRONT_START + PLAYER_STEP * float(slot)
		else:
			base_pos = PLAYER_BACK_START + PLAYER_STEP * float(slot - FRONT_ROW_COUNT)
	else:
		if slot < FRONT_ROW_COUNT:
			base_pos = ENEMY_FRONT_START + ENEMY_STEP * float(slot)
		else:
			base_pos = ENEMY_BACK_START + ENEMY_STEP * float(slot - FRONT_ROW_COUNT)
	return base_pos + get_field_offset()

func get_slot_polygon(is_enemy: bool, slot: int) -> PackedVector2Array:
	var c: Vector2 = get_slot_screen_position(is_enemy, slot)
	var hw: float = DIAMOND_HALF_WIDTH
	var hh: float = DIAMOND_HALF_HEIGHT
	return PackedVector2Array([
		Vector2(c.x, c.y - hh),
		Vector2(c.x + hw, c.y),
		Vector2(c.x, c.y + hh),
		Vector2(c.x - hw, c.y)
	])

func find_slot_at_point(point: Vector2) -> Dictionary:
	var hw: float = DIAMOND_HALF_WIDTH
	var hh: float = DIAMOND_HALF_HEIGHT
	
	# Check Enemy Slots first (render order)
	for slot in range(TOTAL_SLOTS):
		var center: Vector2 = get_slot_screen_position(true, slot)
		var dx: float = absf(point.x - center.x) / hw
		var dy: float = absf(point.y - center.y) / hh
		if (dx + dy) <= 1.08:
			return {"found": true, "is_enemy": true, "slot": slot}
			
	# Check Player Slots
	for slot in range(TOTAL_SLOTS):
		var center: Vector2 = get_slot_screen_position(false, slot)
		var dx: float = absf(point.x - center.x) / hw
		var dy: float = absf(point.y - center.y) / hh
		if (dx + dy) <= 1.08:
			return {"found": true, "is_enemy": false, "slot": slot}
			
	return {"found": false, "is_enemy": false, "slot": -1}

# --- Drawing Pipeline (2:1 Axonometric Grid) ---

func _on_arena_canvas_draw() -> void:
	if not arena_canvas:
		return
		
	# 1. Neutral Divider Line
	var f_offset: Vector2 = get_field_offset()
	
	# 2. Draw 8 Player Slots
	for s in range(TOTAL_SLOTS):
		_draw_diamond_slot(false, s)
		
	# 3. Draw 8 Enemy Slots
	for s in range(TOTAL_SLOTS):
		_draw_diamond_slot(true, s)

func _draw_diamond_slot(is_enemy: bool, slot: int) -> void:
	var poly: PackedVector2Array = get_slot_polygon(is_enemy, slot)
	var is_hovered: bool = (hovered_is_enemy == is_enemy and hovered_slot == slot)
	var is_target_selected: bool = (selected_target_is_enemy == is_enemy and selected_target_slot == slot and is_targeting)
	if not is_hovered and not is_target_selected:
		return # the real field shows no grid
	
	var actor: Dictionary = battle_manager.get_participant(is_enemy, slot) if battle_manager else {}
	var occupied: bool = not actor.is_empty() and bool(actor.get("is_alive", false))
	var elem: int = int(actor.get("element", 0)) if occupied else 0
	var elem_color: Color = ELEMENT_COLORS[elem]
	
	# Fill Color
	var fill_color: Color
	if is_target_selected:
		fill_color = Color(1.0, 0.3, 0.2, 0.45) # Red target highlight
	elif is_hovered:
		fill_color = Color(0.3, 0.8, 1.0, 0.4)  # Cyan hover
	elif occupied:
		fill_color = Color(elem_color.r, elem_color.g, elem_color.b, 0.25)
	else:
		fill_color = Color(0.12, 0.15, 0.22, 0.20) # Empty slot
		
	arena_canvas.draw_colored_polygon(poly, fill_color)
	
	# Border Color & Width
	var border_color: Color
	var border_width: float = 1.0
	if is_target_selected:
		border_color = Color(1.0, 0.85, 0.2, 1.0) # Gold
		border_width = 2.5
	elif is_hovered:
		border_color = Color(0.4, 0.9, 1.0, 0.95)
		border_width = 2.0
	elif occupied:
		border_color = elem_color
		border_width = 1.2
	else:
		border_color = Color(0.25, 0.35, 0.45, 0.4)
		
	var closed_poly: PackedVector2Array = poly.duplicate()
	closed_poly.append(poly[0])
	arena_canvas.draw_polyline(closed_poly, border_color, border_width)

# --- Actor Widget Management ---

func refresh_actor_widgets() -> void:
	for child in actors_layer.get_children():
		child.queue_free()
	actor_widgets.clear()
	
	if not battle_manager:
		return
		
	for s in range(TOTAL_SLOTS):
		var p: Dictionary = battle_manager.get_participant(false, s)
		if not p.is_empty() and bool(p.get("is_alive", false)):
			_create_actor_widget(false, s, p)
			
	for s in range(TOTAL_SLOTS):
		var e: Dictionary = battle_manager.get_participant(true, s)
		if not e.is_empty() and bool(e.get("is_alive", false)):
			_create_actor_widget(true, s, e)

## Keywords of the original battle presets mapped to the real monster that looks closest, used
## when a participant has no Npc.dat template id of its own.
const MONSTER_NAME_ALIASES: Dictionary = {
	"jelly": "Jellyfish",
	"bat": "Bat",
	"pirate": "Pirate",
}

## Looks up the Npc.dat monster template for a battle participant: explicit template id, then the
## exact name, then a keyword alias. Returns null when nothing matches.
func _find_monster_template(data: Dictionary):
	var game_db := get_node_or_null("/root/GameDatabase")
	if game_db == null or not ("npcs" in game_db):
		return null
	var npc_db = game_db.npcs
	var template_id: int = int(data.get("template_id", 0))
	if template_id > 0:
		var by_id = npc_db.get_npc(template_id)
		if by_id != null and bool(by_id.is_monster):
			return by_id
	var wanted: String = str(data.get("name", data.get("monster_name", ""))).strip_edges()
	if wanted.is_empty():
		return null
	var queries: Array[String] = [wanted]
	for keyword in MONSTER_NAME_ALIASES.keys():
		if wanted.to_lower().contains(keyword):
			queries.append(MONSTER_NAME_ALIASES[keyword])
	for query in queries:
		var exact_or_partial: Array = npc_db.get_npcs_by_name(query)
		var best = null
		for rec in exact_or_partial:
			if not bool(rec.is_monster) or int(rec.sprite_id) <= 0:
				continue
			if best == null or absi(int(rec.level) - int(data.get("level", 1))) < absi(int(best.level) - int(data.get("level", 1))):
				best = rec
		if best != null:
			return best
	return null

func _create_actor_widget(is_enemy: bool, slot: int, data: Dictionary) -> void:
	var pos: Vector2 = get_slot_screen_position(is_enemy, slot)
	var key: String = "%s_%d" % ["enemy" if is_enemy else "player", slot]
	
	var root := Control.new()
	root.name = "Actor_" + key
	root.position = pos
	root.mouse_filter = MOUSE_FILTER_IGNORE
	
	# 1. Actor Standee / Sprite
	var standee: Control = null
	var sprite_tex: Texture2D = null
	var al: Object = _get_archive_loader()

	if not is_enemy:
		var role_id: int = int(data.get("role_id", data.get("id", 1)))
		if role_id <= 0 or role_id > 14:
			role_id = 1
		var equip_layers: Dictionary = data.get("equip_layers", {})
		var comp_frames: Array[ImageTexture] = []
		if al != null and al.has_method("get_player_composite_frames"):
			comp_frames = al.get_player_composite_frames(role_id, equip_layers)
		if not comp_frames.is_empty():
			var f_idx: int = 36 if comp_frames.size() > 36 else 0
			sprite_tex = comp_frames[f_idx]
	else:
		var role_id: int = int(data.get("role_id", 0))
		if role_id > 0 and role_id <= 14:
			var comp_frames: Array[ImageTexture] = []
			if al != null and al.has_method("get_player_composite_frames"):
				comp_frames = al.get_player_composite_frames(role_id)
			if not comp_frames.is_empty():
				var f_idx: int = 52 if comp_frames.size() > 52 else 0
				sprite_tex = comp_frames[f_idx]
		else:
			# Real monster template (Npc.dat) first: its sprite id gives the authentic standee, drawn
			# facing the player party (down-left).
			var template = _find_monster_template(data)
			if template != null and al != null and al.has_method("get_npc_texture"):
				sprite_tex = al.get_npc_texture(int(template.sprite_id), IsometricMath.Heading.SOUTH_WEST)
		if sprite_tex == null and is_enemy and int(data.get("role_id", 0)) <= 0:
			var candidates: Array[String] = []
			var jmp_name: String = str(data.get("jmp_name", ""))
			if not jmp_name.is_empty() and jmp_name.to_lower().ends_with(".jmp"):
				candidates.append(jmp_name)
			var m_id: int = int(data.get("id", data.get("monster_id", 1000)))
			if m_id >= 1000 and m_id <= 1703:
				candidates.append("%d.jmp" % m_id)
			elif m_id > 0 and m_id < 1000:
				candidates.append("%d.jmp" % (1000 + (m_id % 700)))
			candidates.append("1000.jmp")
			for cand in candidates:
				if al != null and al.has_method("get_jma_frame_128"):
					sprite_tex = al.get_jma_frame_128("001.jma", cand, 0)
					if sprite_tex != null:
						break

	var overhead_y: float = -78.0
	if sprite_tex:
		var tex_rect := TextureRect.new()
		tex_rect.name = "Standee"
		tex_rect.texture = sprite_tex
		tex_rect.mouse_filter = MOUSE_FILTER_IGNORE
		tex_rect.size = Vector2(128.0, 128.0)
		tex_rect.position = Vector2(-64.0, -108.0)
		standee = tex_rect
		overhead_y = -118.0
	else:
		var rect := ColorRect.new()
		rect.name = "Standee"
		rect.size = Vector2(24.0, 36.0)
		rect.position = Vector2(-12.0, -38.0)
		var elem: int = int(data.get("element", 0))
		var base_col: Color = ELEMENT_COLORS[elem]
		if is_enemy:
			rect.color = Color(base_col.r * 0.9, base_col.g * 0.6, base_col.b * 0.6, 1.0)
		else:
			rect.color = Color(base_col.r * 0.7, base_col.g * 0.9, base_col.b * 1.0, 1.0)
		standee = rect

	root.add_child(standee)
	
	# 2. Overhead HUD Container
	var overhead := VBoxContainer.new()
	overhead.name = "OverheadHUD"
	overhead.position = Vector2(-40.0, overhead_y)
	overhead.size = Vector2(80.0, 36.0)
	overhead.add_theme_constant_override("separation", 2)
	
	var name_lbl := Label.new()
	name_lbl.name = "NameLabel"
	# Real client: plain name above the head (own character yellow, others cyan) and a thin red HP line.
	name_lbl.text = str(data.get("name", "Actor"))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 11)
	var own_name := (not is_enemy and slot == current_player_slot)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.25, 1.0) if own_name else Color(0.25, 0.9, 1.0, 1.0))
	name_lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.12, 0.2, 1.0))
	name_lbl.add_theme_constant_override("outline_size", 3)
	overhead.add_child(name_lbl)
	
	var hp_bar := ProgressBar.new()
	hp_bar.name = "HPBar"
	hp_bar.custom_minimum_size = Vector2(36.0, 2.0)
	hp_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hp_bar.max_value = float(data.get("max_hp", 100))
	hp_bar.value = float(data.get("hp", 100))
	hp_bar.show_percentage = false
	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.9, 0.08, 0.08, 1.0)
	hp_fill.set_corner_radius_all(1)
	hp_bar.add_theme_stylebox_override("fill", hp_fill)
	var hp_back := StyleBoxFlat.new()
	hp_back.bg_color = Color(0.12, 0.12, 0.12, 0.8)
	hp_bar.add_theme_stylebox_override("background", hp_back)
	overhead.add_child(hp_bar)
	
	var sp_bar := ProgressBar.new()
	sp_bar.name = "SPBar"
	sp_bar.custom_minimum_size = Vector2(80.0, 4.0)
	sp_bar.visible = false # the real fighters show only the red HP line
	sp_bar.max_value = float(data.get("max_sp", 50))
	sp_bar.value = float(data.get("sp", 50))
	sp_bar.show_percentage = false
	var sp_fill := StyleBoxFlat.new()
	sp_fill.bg_color = Color(0.2, 0.5, 0.95, 1.0)
	sp_fill.set_corner_radius_all(2)
	sp_bar.add_theme_stylebox_override("fill", sp_fill)
	overhead.add_child(sp_bar)
	
	root.add_child(overhead)
	actors_layer.add_child(root)
	
	actor_widgets[key] = {
		"root": root,
		"standee": standee,
		"hp_bar": hp_bar,
		"sp_bar": sp_bar,
		"name_lbl": name_lbl
	}

func get_actor_widget(is_enemy: bool, slot: int) -> Dictionary:
	var key: String = "%s_%d" % ["enemy" if is_enemy else "player", slot]
	return actor_widgets.get(key, {})

# --- Target Selection & Reticle Tracking ---

func _update_target_reticle_position() -> void:
	if not target_reticle:
		return
	if not is_targeting:
		target_reticle.visible = false
		return
		
	var target_pos: Vector2 = get_slot_screen_position(selected_target_is_enemy, selected_target_slot)
	target_reticle.position = target_pos + Vector2(0.0, -85.0)
	target_reticle.visible = true
	
	var arrow: Label = target_reticle.get_node_or_null("ReticleArrow") as Label
	if arrow:
		if selected_target_is_enemy:
			arrow.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2, 1.0))
		else:
			arrow.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0, 1.0))

func cycle_target(forward: bool = true) -> void:
	if not is_targeting or not battle_manager:
		return
		
	var pool: Array[Dictionary] = []
	if battle_manager is CombatEngine:
		pool = (battle_manager as CombatEngine).get_valid_targets(false, pending_action_type, pending_skill_data)
	else:
		pool = battle_manager.get_living_participants(targeting_requires_enemy)
		
	if pool.is_empty():
		return
		
	var cur_idx: int = 0
	for i in range(pool.size()):
		var cand: Dictionary = pool[i]
		if bool(cand.get("is_enemy", false)) == selected_target_is_enemy and int(cand.get("slot", 0)) == selected_target_slot:
			cur_idx = i
			break
			
	var next_idx: int = (cur_idx + (1 if forward else -1)) % pool.size()
	if next_idx < 0:
		next_idx = pool.size() - 1
		
	var next_target: Dictionary = pool[next_idx]
	selected_target_is_enemy = bool(next_target.get("is_enemy", false))
	selected_target_slot = int(next_target.get("slot", 0))
	_update_target_reticle_position()
	play_sfx(ACTION_SFX)

# --- Mouse & Interaction Handling ---

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var hit: Dictionary = find_slot_at_point(event.position)
		if hit.get("found", false):
			hovered_is_enemy = bool(hit.get("is_enemy", false))
			hovered_slot = int(hit.get("slot", -1))
		else:
			hovered_slot = -1
		_update_battle_cursor()
		_update_hover_info_card()
			
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var hit: Dictionary = find_slot_at_point(event.position)
		if hit.get("found", false):
			var clicked_enemy: bool = bool(hit.get("is_enemy", false))
			var clicked_slot: int = int(hit.get("slot", -1))
			_handle_slot_click(clicked_enemy, clicked_slot)

## Sword + red arrow over a valid target while aiming, plain pointer otherwise.
func _update_battle_cursor() -> void:
	var cursor_manager := get_node_or_null("/root/CursorManager")
	if cursor_manager == null or not cursor_manager.has_method("set_cursor_by_name"):
		return
	var valid_target: bool = is_targeting and hovered_slot >= 0 and (hovered_is_enemy == targeting_requires_enemy)
	cursor_manager.set_cursor_by_name("target" if valid_target else "normal")

## Authentic white text card displaying Name, Element, LV, and HP/MaxHP left of the hovered combatant.
func _update_hover_info_card() -> void:
	if not hover_info_label:
		return
	if hovered_slot < 0 or battle_manager == null:
		hover_info_label.visible = false
		return
	var actor: Dictionary = battle_manager.get_participant(hovered_is_enemy, hovered_slot)
	if actor.is_empty() or not bool(actor.get("is_alive", false)):
		hover_info_label.visible = false
		return
	var elem_idx: int = int(actor.get("element", 0))
	var elem_str: String = BattleManager.ELEMENT_NAMES[elem_idx] if elem_idx < BattleManager.ELEMENT_NAMES.size() else "None"
	hover_info_label.text = "%s\n%s\nLV: %d\nHP: %d/%d" % [
		actor.get("name", "Actor"),
		elem_str,
		int(actor.get("level", 1)),
		int(actor.get("hp", 100)),
		int(actor.get("max_hp", 100))
	]
	var fpos: Vector2 = get_slot_screen_position(hovered_is_enemy, hovered_slot)
	hover_info_label.position = fpos + Vector2(-110.0, -80.0)
	hover_info_label.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		return
		
	var key_event := event as InputEventKey
	var key: Key = key_event.keycode
	
	# If currently selecting target
	if is_targeting:
		if key == KEY_LEFT or key == KEY_A:
			cycle_target(false)
			get_viewport().set_input_as_handled()
			return
		elif key == KEY_RIGHT or key == KEY_D or key == KEY_TAB:
			cycle_target(true)
			get_viewport().set_input_as_handled()
			return
		elif key == KEY_ENTER or key == KEY_SPACE:
			_commit_pending_action()
			get_viewport().set_input_as_handled()
			return
		elif key == KEY_ESCAPE:
			is_targeting = false
			_update_target_reticle_position()
			_log("Targeting cancelled.")
			get_viewport().set_input_as_handled()
			return
			
	# If waiting for action command input
	if battle_manager and battle_manager.current_state == BattleManager.BattleState.INPUT_WAIT:
		for i in range(BTN_PATHS.size()):
			var cfg: Dictionary = BTN_PATHS[i]
			if key == cfg.get("key") or key == cfg.get("alt_key"):
				click_battle_button(i + 1)
				get_viewport().set_input_as_handled()
				return

func _handle_slot_click(is_enemy: bool, slot: int) -> void:
	slot_clicked.emit(is_enemy, slot)
	
	if is_targeting:
		if targeting_requires_enemy and not is_enemy:
			_log("Target must be an enemy!")
			return
		if not targeting_requires_enemy and is_enemy:
			_log("Target must be a friendly party member!")
			return
			
		selected_target_is_enemy = is_enemy
		selected_target_slot = slot
		is_targeting = false
		_update_target_reticle_position()
		target_selected.emit(is_enemy, slot)
		_commit_pending_action()

func click_slot(is_enemy: bool, slot: int) -> void:
	_handle_slot_click(is_enemy, slot)

# --- Battle Action Button Triggers ---

func _on_battle_button_pressed(_action_type: int, button_index: int) -> void:
	click_battle_button(button_index + 1)

func click_battle_button(button_number: int) -> void:
	if not battle_manager or battle_manager.current_state != BattleManager.BattleState.INPUT_WAIT:
		return
		
	play_sfx(ACTION_SFX)
	
	# Pulse animation on corresponding button
	var btn_idx: int = button_number - 1
	if btn_idx >= 0 and btn_idx < action_buttons.size():
		var btn: TextureButton = action_buttons[btn_idx]
		var tween := create_tween()
		if tween:
			tween.tween_property(btn, "scale", Vector2(1.15, 1.15), 0.06).set_trans(Tween.TRANS_QUAD)
			tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.08).set_trans(Tween.TRANS_QUAD)
			
	match button_number:
		1: # Attack
			pending_action_type = BattleManager.ActionType.ATTACK
			targeting_requires_enemy = true
			is_targeting = true
			_log("Select an enemy target to attack. [Left/Right: Cycle, Enter: Confirm, Esc: Cancel]")
			var enemies: Array[Dictionary] = battle_manager.get_living_participants(true)
			if not enemies.is_empty():
				selected_target_is_enemy = true
				selected_target_slot = int(enemies[0].get("slot", 0))
			_update_target_reticle_position()
				
		2: # Defend
			pending_action_type = BattleManager.ActionType.DEFEND
			is_targeting = false
			_update_target_reticle_position()
			_commit_pending_action()
			
		3: # Skill
			_open_skill_dialog()
			
		4: # Item
			_open_item_dialog()
			
		5: # Catch
			pending_action_type = BattleManager.ActionType.CATCH
			targeting_requires_enemy = true
			is_targeting = true
			_log("Select an enemy to capture.")
			var enemies: Array[Dictionary] = battle_manager.get_living_participants(true)
			if not enemies.is_empty():
				selected_target_is_enemy = true
				selected_target_slot = int(enemies[0].get("slot", 0))
			_update_target_reticle_position()
				
		6: # Escape
			pending_action_type = BattleManager.ActionType.ESCAPE
			is_targeting = false
			_update_target_reticle_position()
			_commit_pending_action()
			
		7: # Auto
			var new_auto: bool = not battle_manager.is_auto_battle
			battle_manager.set_auto_battle(new_auto)
			_log("Auto-Battle %s." % ["Enabled" if new_auto else "Disabled"])

func _open_skill_dialog() -> void:
	for child in skill_list.get_children():
		child.queue_free()
		
	var active_player: Dictionary = battle_manager.get_participant(false, current_player_slot)
	if active_player.is_empty():
		return
		
	var skills: Array = active_player.get("skills", [])
	for s in skills:
		var btn := Button.new()
		var sp_cost: int = int(s.get("sp_cost", 0))
		var elem: int = int(s.get("element", 0))
		var elem_name: String = BattleManager.ELEMENT_NAMES[elem] if elem < BattleManager.ELEMENT_NAMES.size() else "None"
		btn.text = "%s (%s | %d SP)" % [s.get("name", "Skill"), elem_name, sp_cost]
		btn.custom_minimum_size = Vector2(250.0, 30.0)
		btn.pressed.connect(_on_skill_item_selected.bind(s))
		skill_list.add_child(btn)
		
	skill_dialog.visible = true

func _on_skill_item_selected(skill_data: Dictionary) -> void:
	skill_dialog.visible = false
	pending_action_type = BattleManager.ActionType.SKILL
	pending_skill_data = skill_data
	
	var is_heal: bool = int(skill_data.get("skill_type", 0)) == BattleManager.SkillMechanism.ASSIST and int(skill_data.get("base_damage", 0)) < 0
	targeting_requires_enemy = not is_heal
	is_targeting = true
	_log("Selected skill '%s'. Choose target." % skill_data.get("name", "Skill"))
	
	if targeting_requires_enemy:
		var enemies: Array[Dictionary] = battle_manager.get_living_participants(true)
		if not enemies.is_empty():
			selected_target_is_enemy = true
			selected_target_slot = int(enemies[0].get("slot", 0))
	else:
		selected_target_is_enemy = false
		selected_target_slot = current_player_slot
		
	_update_target_reticle_position()

func _open_item_dialog() -> void:
	for child in item_list.get_children():
		child.queue_free()
		
	var sample_items: Array[Dictionary] = [
		{"id": 1001, "name": "Healing Herb", "heal_hp": 80, "heal_sp": 0},
		{"id": 1002, "name": "Mana Dew", "heal_hp": 0, "heal_sp": 40},
		{"id": 1003, "name": "Elixir of Life", "heal_hp": 250, "heal_sp": 100}
	]
	
	for it in sample_items:
		var btn := Button.new()
		btn.text = "%s (+%d HP, +%d SP)" % [it.get("name"), it.get("heal_hp"), it.get("heal_sp")]
		btn.custom_minimum_size = Vector2(250.0, 30.0)
		btn.pressed.connect(_on_item_selected.bind(it))
		item_list.add_child(btn)
		
	item_dialog.visible = true

func _on_item_selected(item_data: Dictionary) -> void:
	item_dialog.visible = false
	pending_action_type = BattleManager.ActionType.ITEM
	pending_item_data = item_data
	targeting_requires_enemy = false
	is_targeting = true
	selected_target_is_enemy = false
	selected_target_slot = current_player_slot
	_log("Using '%s'. Select target." % item_data.get("name"))
	_update_target_reticle_position()

func _commit_pending_action() -> void:
	is_targeting = false
	_update_target_reticle_position()
	
	var committed_slot: int = current_player_slot
	var action: Dictionary = {
		"type": pending_action_type,
		"slot": committed_slot,
		"is_enemy": false,
		"target_slot": selected_target_slot,
		"target_is_enemy": selected_target_is_enemy
	}
	if pending_action_type == BattleManager.ActionType.SKILL:
		action["skill"] = pending_skill_data
	elif pending_action_type == BattleManager.ActionType.ITEM:
		action["item"] = pending_item_data
		
	battle_action_selected.emit(action)
	if battle_manager:
		battle_manager.register_player_action(committed_slot, action)

	# Show floating icon of the committed action over this actor's head
	_show_floating_action_icon(committed_slot, pending_action_type)

	# Sequence to next party member (e.g. Companion / Pet) if they need to enter a command
	var next_slot: int = -1
	if battle_manager:
		for s in range(TOTAL_SLOTS):
			var p: Dictionary = battle_manager.get_participant(false, s)
			var key: String = "p_%d" % s
			if not p.is_empty() and bool(p.get("is_alive", false)) and not battle_manager.queued_actions.has(key):
				next_slot = s
				break

	if next_slot != -1:
		current_player_slot = next_slot
		action_bar.visible = true
		_update_action_bar_position()
		_update_action_bar_permissions()
		var p_name: String = str(battle_manager.get_participant(false, next_slot).get("name", "Companion"))
		_log("%s's command phase." % p_name)
	else:
		action_bar.visible = false
		if countdown_label:
			countdown_label.visible = false

func _show_floating_action_icon(slot: int, action_type: int) -> void:
	var ring_art: int = int(RING_ART.get(action_type, 1))
	var norm_path: String = SKIN_DIR + "Btn_Battle_%d.bmp" % ring_art
	var tex: Texture2D = _battle_button_frame(norm_path, 0)
	if tex == null:
		return
	if _queued_action_icons.has(slot) and is_instance_valid(_queued_action_icons[slot]):
		_queued_action_icons[slot].queue_free()
	var rect := TextureRect.new()
	rect.texture = tex
	rect.custom_minimum_size = Vector2(28.0, 28.0)
	rect.size = Vector2(28.0, 28.0)
	rect.mouse_filter = MOUSE_FILTER_IGNORE
	rect.z_index = 20
	var fpos: Vector2 = get_slot_screen_position(false, slot)
	rect.position = fpos + Vector2(-14.0, -85.0)
	if actors_layer:
		actors_layer.add_child(rect)
	else:
		add_child(rect)
	_queued_action_icons[slot] = rect

func _clear_floating_action_icons() -> void:
	for slot in _queued_action_icons.keys():
		var rect = _queued_action_icons[slot]
		if is_instance_valid(rect):
			rect.queue_free()
	_queued_action_icons.clear()

# Programmatic API for testing
func select_action(action_type: int, target_is_enemy: bool = true, target_slot: int = 0, skill_data: Dictionary = {}) -> void:
	pending_action_type = action_type
	selected_target_is_enemy = target_is_enemy
	selected_target_slot = target_slot
	pending_skill_data = skill_data
	_commit_pending_action()

# --- Visual Effects & Floating Numbers ---

## Enhanced Floating Combat Text popup with crits, heals, misses and element badges.
func spawn_combat_popup(pos: Vector2, text: String, type: int, badge_text: String = "") -> FloatingCombatText:
	return FloatingCombatText.spawn(floating_text_layer, pos, text, type, badge_text)

## Backward-compatible floating text method returning a Label.
func spawn_floating_text(pos: Vector2, text: String, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = pos + Vector2(-30.0, -10.0)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	floating_text_layer.add_child(lbl)
	
	var tween := create_tween()
	if tween:
		tween.set_speed_scale(battle_speed_multiplier)
		tween.tween_property(lbl, "position", lbl.position + Vector2(0.0, -32.0), 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(lbl, "modulate:a", 0.0, 0.75)
		tween.tween_callback(lbl.queue_free)
	else:
		lbl.queue_free()
	return lbl

func play_hit_impact(is_enemy: bool, slot: int, is_critical: bool) -> void:
	var widget: Dictionary = get_actor_widget(is_enemy, slot)
	var standee: Control = widget.get("standee") as Control
	if not standee:
		return
		
	var tween := create_tween()
	if tween:
		tween.set_speed_scale(battle_speed_multiplier)
		if standee is ColorRect:
			var orig_col: Color = (standee as ColorRect).color
			var flash_col: Color = Color(1.0, 0.2, 0.2, 1.0) if is_critical else Color(1.0, 1.0, 1.0, 1.0)
			tween.tween_property(standee, "color", flash_col, 0.08)
			tween.tween_property(standee, "color", orig_col, 0.12)
		else:
			var flash_mod: Color = Color(1.0, 0.2, 0.2, 1.0) if is_critical else Color(1.8, 1.8, 1.8, 1.0)
			tween.tween_property(standee, "modulate", flash_mod, 0.08)
			tween.tween_property(standee, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
		var orig_pos: Vector2 = standee.position
		tween.tween_property(standee, "position", orig_pos + Vector2(4.0, 0.0), 0.05)
		tween.tween_property(standee, "position", orig_pos - Vector2(4.0, 0.0), 0.05)
		tween.tween_property(standee, "position", orig_pos, 0.05)

# --- BattleManager Signal Handlers ---

func _on_bm_battle_started() -> void:
	refresh_actor_widgets()
	refresh_turn_timeline()
	action_bar.visible = true
	_hide_old_panels()
	_log("Turn-based combat encounter started!")

func _on_bm_turn_started(turn: int) -> void:
	turn_label.text = "Turn %d" % turn
	var initial_secs: int = int(battle_manager.turn_time_limit if (battle_manager and "turn_time_limit" in battle_manager) else 20)
	timer_label.text = str(initial_secs)
	if countdown_label:
		countdown_label.text = str(initial_secs)
		countdown_label.visible = true
		countdown_label.add_theme_color_override("font_color", Color(0.25, 0.92, 1.0, 1.0))
		countdown_label.add_theme_color_override("font_outline_color", Color(0.02, 0.2, 0.3, 1.0))
	timer_label.remove_theme_color_override("font_color")
	timer_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	
	# Reset active player command turn to first living member (player leader)
	current_player_slot = 0
	if battle_manager:
		for s in range(TOTAL_SLOTS):
			var p: Dictionary = battle_manager.get_participant(false, s)
			if not p.is_empty() and bool(p.get("is_alive", false)):
				current_player_slot = s
				break

	action_bar.visible = true
	_update_action_bar_position()
	_update_action_bar_permissions()
	_clear_floating_action_icons()
	is_targeting = false
	_update_target_reticle_position()
	refresh_actor_widgets()
	refresh_turn_timeline()

func _on_bm_round_execution_started(_queue: Array[Dictionary]) -> void:
	action_bar.visible = false
	if countdown_label:
		countdown_label.visible = false
	_clear_floating_action_icons()

func _on_bm_timer_tick(time_remaining: float) -> void:
	var secs: int = int(ceilf(time_remaining))
	timer_label.text = str(secs)
	if countdown_label:
		countdown_label.text = str(secs)
		if secs <= 5:
			countdown_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25, 1.0))
			countdown_label.add_theme_color_override("font_outline_color", Color(0.4, 0.05, 0.05, 1.0))
		else:
			countdown_label.add_theme_color_override("font_color", Color(0.25, 0.92, 1.0, 1.0))
			countdown_label.add_theme_color_override("font_outline_color", Color(0.02, 0.2, 0.3, 1.0))
	if secs <= 5:
		timer_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0))

func _on_bm_actor_damaged(is_enemy: bool, slot: int, damage: int, is_crit: bool, cur_hp: int) -> void:
	var widget: Dictionary = get_actor_widget(is_enemy, slot)
	var hp_bar: ProgressBar = widget.get("hp_bar") as ProgressBar
	if hp_bar:
		hp_bar.value = float(cur_hp)
		
	var pos: Vector2 = get_slot_screen_position(is_enemy, slot) + Vector2(0.0, -40.0)
	var txt: String = "-%d" % damage
	if is_crit:
		txt = "CRIT! -" + str(damage)
	var col: Color = Color(1.0, 0.9, 0.2, 1.0) if is_crit else Color(1.0, 0.3, 0.2, 1.0)
	
	spawn_floating_text(pos, txt, col)
	play_hit_impact(is_enemy, slot, is_crit)
	refresh_turn_timeline()

func _on_bm_actor_healed(is_enemy: bool, slot: int, amount: int, cur_hp: int) -> void:
	var widget: Dictionary = get_actor_widget(is_enemy, slot)
	var hp_bar: ProgressBar = widget.get("hp_bar") as ProgressBar
	if hp_bar:
		hp_bar.value = float(cur_hp)
		
	var pos: Vector2 = get_slot_screen_position(is_enemy, slot) + Vector2(0.0, -40.0)
	spawn_floating_text(pos, "+%d" % amount, Color(0.2, 1.0, 0.3, 1.0))
	refresh_turn_timeline()

func _on_bm_actor_defeated(is_enemy: bool, slot: int) -> void:
	var widget: Dictionary = get_actor_widget(is_enemy, slot)
	var root: Control = widget.get("root") as Control
	var standee: Control = widget.get("standee") as Control
	if root:
		var tween := create_tween()
		if tween:
			tween.set_speed_scale(battle_speed_multiplier)
			if standee:
				var orig_y: float = standee.position.y
				tween.tween_property(standee, "scale", Vector2(1.2, 0.2), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tween.parallel().tween_property(standee, "position:y", orig_y + 24.0, 0.22)
			tween.parallel().tween_property(root, "modulate:a", 0.0, 0.35)
			tween.tween_callback(root.queue_free)
		else:
			root.queue_free()
	refresh_turn_timeline()

func play_sfx(sfx_name: String) -> void:
	if sfx_name.is_empty():
		return
	if not _sfx_player:
		_sfx_player = AudioStreamPlayer.new()
		_sfx_player.name = "BattleSfxPlayer"
		_sfx_player.bus = "Master"
		add_child(_sfx_player)

	var clean_name: String = sfx_name.strip_edges()
	var candidates: Array[String] = [
		"res://assets/sound/" + clean_name,
		"D:/GitHub/WLRI/sound/" + clean_name,
		clean_name
	]
	if not clean_name.to_lower().ends_with(".wav"):
		candidates.append("res://assets/sound/" + clean_name + ".wav")
		candidates.append("D:/GitHub/WLRI/sound/" + clean_name + ".wav")
		if clean_name.begins_with("wav"):
			var num_part := clean_name.substr(3)
			candidates.append("res://assets/sound/" + num_part + ".wav")
			candidates.append("D:/GitHub/WLRI/sound/" + num_part + ".wav")

	var stream: AudioStream = null
	for path in candidates:
		if path.begins_with("res://") and ResourceLoader.exists(path):
			stream = load(path) as AudioStream
			if stream:
				break
		elif FileAccess.file_exists(path):
			var file := FileAccess.open(path, FileAccess.READ)
			if file:
				var bytes := file.get_buffer(file.get_length())
				if bytes.size() >= 44:
					var wav := AudioStreamWAV.new()
					wav.data = bytes
					stream = wav
					break
	if stream:
		_sfx_player.stream = stream
		_sfx_player.play()

## Spawns and plays authentic skill VFX animation on vfx_layer at target_pos.
func play_skill_vfx(anim_id: int, target_pos: Vector2, sfx_name: String = "", fps: float = 15.0) -> void:
	if not vfx_layer:
		return

	var frames: Array[ImageTexture] = []
	var al: Object = _get_archive_loader()
	if al != null and al.has_method("get_skill_vfx_frames"):
		frames = al.get_skill_vfx_frames(anim_id)

	var vfx_node := TextureRect.new()
	vfx_node.name = "SkillVFX_%d" % anim_id
	vfx_node.mouse_filter = MOUSE_FILTER_IGNORE
	vfx_node.set_meta("anim_id", anim_id)

	if frames.is_empty():
		vfx_layer.add_child(vfx_node)
		var tween := create_tween()
		if tween:
			tween.tween_interval(0.1)
			tween.tween_callback(func():
				skill_vfx_completed.emit(anim_id)
				if is_instance_valid(vfx_node):
					vfx_node.queue_free()
			)
		else:
			skill_vfx_completed.emit(anim_id)
			vfx_node.queue_free()
		return

	var frame_sz: Vector2 = frames[0].get_size()
	vfx_node.texture = frames[0]
	vfx_node.size = frame_sz
	vfx_node.position = target_pos - (frame_sz * 0.5)
	vfx_layer.add_child(vfx_node)

	if not sfx_name.is_empty():
		play_sfx(sfx_name)

	var frame_dur: float = 1.0 / maxf(1.0, fps)
	var tween := create_tween()
	if tween:
		for i in range(1, frames.size()):
			tween.tween_interval(frame_dur)
			tween.tween_callback(func():
				if is_instance_valid(vfx_node):
					vfx_node.texture = frames[i]
			)
		tween.tween_interval(frame_dur)
		tween.tween_callback(func():
			skill_vfx_completed.emit(anim_id)
			if is_instance_valid(vfx_node):
				vfx_node.queue_free()
		)
	else:
		skill_vfx_completed.emit(anim_id)
		vfx_node.queue_free()

## Dynamic camera zoom focused on action impact point
func play_camera_attack_zoom(focus_point: Vector2) -> void:
	if not actors_layer:
		return
	actors_layer.pivot_offset = focus_point
	var zoom_tween := create_tween()
	if zoom_tween:
		zoom_tween.set_speed_scale(battle_speed_multiplier)
		zoom_tween.tween_property(actors_layer, "scale", Vector2(1.06, 1.06), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		zoom_tween.tween_property(actors_layer, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _on_bm_action_executed(result: Dictionary) -> void:
	var msg: String = String(result.get("message", ""))
	if not msg.is_empty():
		_log(msg)

	var action_type: int = int(result.get("action_type", 0))
	var user_is_enemy: bool = bool(result.get("user_is_enemy", false))
	var user_slot: int = int(result.get("user_slot", 0))
	var target_is_enemy: bool = bool(result.get("target_is_enemy", not user_is_enemy))
	var target_slot: int = int(result.get("target_slot", -1))
	if target_slot < 0:
		target_slot = 0

	# 1. Play caster attack motion
	var caster_widget: Dictionary = get_actor_widget(user_is_enemy, user_slot)
	var caster_standee: Control = caster_widget.get("standee") as Control
	if caster_standee:
		var orig_pos: Vector2 = caster_standee.position
		var lunge_offset: Vector2 = Vector2(-40.0, -8.0) if not user_is_enemy else Vector2(40.0, 8.0)
		var c_tween := create_tween()
		if c_tween:
			c_tween.set_speed_scale(battle_speed_multiplier)
			c_tween.tween_property(caster_standee, "position", orig_pos + lunge_offset, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			c_tween.tween_property(caster_standee, "position", orig_pos, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Dynamic combat camera zoom
	if action_type == BattleManager.ActionType.ATTACK or action_type == BattleManager.ActionType.SKILL:
		var target_fpos: Vector2 = get_slot_screen_position(target_is_enemy, target_slot)
		play_camera_attack_zoom(target_fpos)

	# 2. Extract skill or animation_id
	var anim_id: int = int(result.get("animation_id", 0))
	var skill: Dictionary = result.get("skill", {})
	if anim_id == 0 and not skill.is_empty():
		anim_id = int(skill.get("animation_id", 0))
	
	if anim_id == 0:
		if action_type == BattleManager.ActionType.ATTACK:
			anim_id = 60022
		elif action_type == BattleManager.ActionType.SKILL:
			anim_id = 60005

	# 3. Target screen position & SFX
	var target_pos: Vector2 = get_slot_screen_position(target_is_enemy, target_slot)
	var sfx_name: String = str(skill.get("cast_sfx_name", skill.get("sfx", "")))
	if sfx_name.is_empty():
		sfx_name = "9911.wav"

	# 4. Call play_skill_vfx(anim_id, target_slot_screen_position, sfx)
	if anim_id > 0:
		play_skill_vfx(anim_id, target_pos, sfx_name)

	# 5. Trigger target hurt / hit impact upon VFX impact
	if is_inside_tree() and get_tree():
		var impact_timer := get_tree().create_timer(0.12)
		impact_timer.timeout.connect(func():
			play_hit_impact(target_is_enemy, target_slot, bool(result.get("is_critical", false)))
		)
	else:
		play_hit_impact(target_is_enemy, target_slot, bool(result.get("is_critical", false)))
		
	refresh_turn_timeline()

func _on_bm_battle_won(p_rewards: Dictionary) -> void:
	action_bar.visible = false
	status_panel.visible = false
	if countdown_label:
		countdown_label.visible = false
	_clear_floating_action_icons()
	if turn_timeline:
		turn_timeline.visible = false
	
	victory_title_label.text = "VICTORY!"
	victory_title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1.0))
	exp_reward_label.text = "EXP Earned: +%d" % int(p_rewards.get("exp", 0))
	gold_reward_label.text = "Gold Earned: +%d" % int(p_rewards.get("gold", 0))
	
	var items: Array = p_rewards.get("items", [])
	if items.is_empty():
		items_reward_label.text = "Items Dropped: None"
	else:
		var names: Array[String] = []
		for it in items:
			names.append("%s x%d" % [it.get("item_name", "Item"), it.get("quantity", 1)])
		items_reward_label.text = "Items Dropped: " + ", ".join(names)
		
	victory_dialog.visible = true

func _on_bm_battle_lost() -> void:
	action_bar.visible = false
	status_panel.visible = false
	if countdown_label:
		countdown_label.visible = false
	_clear_floating_action_icons()
	if turn_timeline:
		turn_timeline.visible = false
	
	victory_title_label.text = "DEFEAT..."
	victory_title_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 1.0))
	exp_reward_label.text = "EXP Earned: 0"
	gold_reward_label.text = "Gold Earned: 0"
	items_reward_label.text = "Your party was wiped out."
	victory_dialog.visible = true

func _on_bm_battle_escaped() -> void:
	action_bar.visible = false
	status_panel.visible = false
	if countdown_label:
		countdown_label.visible = false
	_clear_floating_action_icons()
	if turn_timeline:
		turn_timeline.visible = false
	escape_confirmed.emit()
	view_closed.emit()

func _on_victory_ok_pressed() -> void:
	victory_dialog.visible = false
	if battle_manager and battle_manager.current_state == BattleManager.BattleState.VICTORY:
		victory_confirmed.emit()
	else:
		defeat_confirmed.emit()
	view_closed.emit()

# --- Logging & Helpers ---

func _log(msg: String) -> void:
	if log_label:
		log_label.text = msg

func is_action_buttons_visible() -> bool:
	return action_bar.visible

func is_victory_dialog_visible() -> bool:
	return victory_dialog.visible

func get_timer_value() -> float:
	return battle_manager.turn_timer if battle_manager else 0.0

func cleanup() -> void:
	if battle_manager:
		battle_manager.reset()
	for child in actors_layer.get_children():
		child.queue_free()
	actor_widgets.clear()
	action_bar.visible = false
	if countdown_label:
		countdown_label.visible = false
	_clear_floating_action_icons()
	victory_dialog.visible = false
	skill_dialog.visible = false
	item_dialog.visible = false
	if turn_timeline:
		turn_timeline.visible = false
	if target_reticle:
		target_reticle.visible = false
