class_name CombatMenu
extends Control

## Wonderland Online - Responsive Combat Command Menu.
## Renders the authentic 7 action buttons (Attack, Defend, Skill, Item, Catch, Escape, Auto).
## Supports dual-mode responsive layout:
## 1. DOCKED_BOTTOM_RIGHT: Classic bottom-right anchor matching WLO HUD specifications.
## 2. CONTEXTUAL_ANCHOR: Dynamically tracks acting player's isometric coordinate with screen bounds clamping.
## Features:
## - Keyboard shortcuts (A, D, S, I, C, E, U/Space).
## - Authentic audio feedback (wav0151.wav) on hover and click.
## - Rich tooltip hover cards displaying shortcut keys and mechanic descriptions.

# --- Signals ---
signal action_triggered(action_type: int)
signal anchor_mode_changed(is_contextual: bool)

# --- Layout Modes ---
enum AnchorMode {
	DOCKED_BOTTOM_RIGHT = 0,
	CONTEXTUAL_ANCHOR = 1
}

# --- Geometry Constants ---
const DEFAULT_MENU_SIZE: Vector2 = Vector2(220.0, 84.0)
const DOCKED_OFFSET_LEFT: float = -240.0
const DOCKED_OFFSET_TOP: float = -100.0
const DOCKED_OFFSET_RIGHT: float = -20.0
const DOCKED_OFFSET_BOTTOM: float = -16.0
const VIEWPORT_PADDING: float = 16.0

# --- Assets ---
const SKIN_DIR: String = "res://assets/menu/Skins/default/"
const SFX_PATH: String = "res://assets/sound/wav0151.wav"

const BUTTON_CONFIGS: Array[Dictionary] = [
	{
		"action": 0, # Attack
		"name": "Btn_Battle_1",
		"normal": SKIN_DIR + "Btn_Battle_1.bmp",
		"hover": SKIN_DIR + "Btn_Battle_1_1.bmp",
		"pressed": SKIN_DIR + "Btn_Battle_1_2.bmp",
		"shortcut": "A",
		"keycode": KEY_A,
		"alt_key": KEY_1,
		"title": "Attack",
		"description": "Execute normal physical strike against targeted foe."
	},
	{
		"action": 1, # Defend
		"name": "Btn_Battle_2",
		"normal": SKIN_DIR + "Btn_Battle_2.bmp",
		"hover": SKIN_DIR + "Btn_Battle_2_1.bmp",
		"pressed": SKIN_DIR + "Btn_Battle_2_2.bmp",
		"shortcut": "D",
		"keycode": KEY_D,
		"alt_key": KEY_2,
		"title": "Defend",
		"description": "Assume defensive stance to reduce incoming damage by 50%."
	},
	{
		"action": 2, # Skill
		"name": "Btn_Battle_3",
		"normal": SKIN_DIR + "Btn_Battle_3.bmp",
		"hover": SKIN_DIR + "Btn_Battle_3_1.bmp",
		"pressed": SKIN_DIR + "Btn_Battle_3_2.bmp",
		"shortcut": "S",
		"keycode": KEY_S,
		"alt_key": KEY_3,
		"title": "Skill",
		"description": "Open martial stunt and elemental magic selection menu."
	},
	{
		"action": 3, # Item
		"name": "Btn_Battle_4",
		"normal": SKIN_DIR + "Btn_Battle_4.bmp",
		"hover": SKIN_DIR + "Btn_Battle_4_1.bmp",
		"pressed": SKIN_DIR + "Btn_Battle_4_2.bmp",
		"shortcut": "I",
		"keycode": KEY_I,
		"alt_key": KEY_4,
		"title": "Item",
		"description": "Use consumable recovery herbs, potions, or combat scrolls."
	},
	{
		"action": 4, # Catch
		"name": "Btn_Battle_5",
		"normal": SKIN_DIR + "Btn_Battle_5.bmp",
		"hover": SKIN_DIR + "Btn_Battle_5_1.bmp",
		"pressed": SKIN_DIR + "Btn_Battle_5_2.bmp",
		"shortcut": "C",
		"keycode": KEY_C,
		"alt_key": KEY_5,
		"title": "Catch",
		"description": "Attempt to capture a weakened wild monster as a loyal pet."
	},
	{
		"action": 5, # Escape
		"name": "Btn_Battle_6",
		"normal": SKIN_DIR + "Btn_Battle_6.bmp",
		"hover": SKIN_DIR + "Btn_Battle_6_1.bmp",
		"pressed": SKIN_DIR + "Btn_Battle_6_2.bmp",
		"shortcut": "E",
		"keycode": KEY_E,
		"alt_key": KEY_6,
		"title": "Escape",
		"description": "Attempt to flee from battle based on relative SPD agility."
	},
	{
		"action": 6, # Auto
		"name": "Btn_Battle_7",
		"normal": SKIN_DIR + "Btn_Battle_7.bmp",
		"hover": SKIN_DIR + "Btn_Battle_7_1.bmp",
		"pressed": SKIN_DIR + "Btn_Battle_7_2.bmp",
		"shortcut": "U",
		"keycode": KEY_U,
		"alt_key": KEY_7,
		"title": "Auto",
		"description": "Toggle automatic tactical combat turn resolution."
	}
]

# --- State ---
var anchor_mode: int = AnchorMode.DOCKED_BOTTOM_RIGHT
var contextual_target_pos: Vector2 = Vector2.ZERO
var is_active_turn: bool = true

# --- Subnodes ---
var action_bar: HBoxContainer = null
var action_buttons: Array[TextureButton] = []
var tooltip_card: PanelContainer = null
var tooltip_title: Label = null
var tooltip_shortcut: Label = null
var tooltip_desc: Label = null
var sfx_player: AudioStreamPlayer = null
var _cached_sfx: AudioStream = null

func _init() -> void:
	custom_minimum_size = DEFAULT_MENU_SIZE

func _ready() -> void:
	_setup_audio()
	_build_ui()
	apply_docked_layout()

func _setup_audio() -> void:
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "MenuSfxPlayer"
	sfx_player.bus = "Master"
	add_child(sfx_player)
	
	if ResourceLoader.exists(SFX_PATH):
		_cached_sfx = load(SFX_PATH) as AudioStream
	elif FileAccess.file_exists(SFX_PATH):
		var file := FileAccess.open(SFX_PATH, FileAccess.READ)
		if file:
			var bytes := file.get_buffer(file.get_length())
			var wav := AudioStreamWAV.new()
			wav.data = bytes
			_cached_sfx = wav

func play_action_sfx() -> void:
	if _cached_sfx and sfx_player:
		sfx_player.stream = _cached_sfx
		sfx_player.play()

func _build_ui() -> void:
	mouse_filter = MOUSE_FILTER_PASS
	
	# ActionButtonsBar container
	action_bar = HBoxContainer.new()
	action_bar.name = "ActionButtonsBar"
	action_bar.set_anchors_preset(PRESET_FULL_RECT)
	action_bar.anchor_right = 1.0
	action_bar.anchor_bottom = 1.0
	action_bar.grow_horizontal = GROW_DIRECTION_BOTH
	action_bar.grow_vertical = GROW_DIRECTION_BOTH
	action_bar.add_theme_constant_override("separation", 4)
	add_child(action_bar)
	
	action_buttons.clear()
	for i in range(BUTTON_CONFIGS.size()):
		var cfg: Dictionary = BUTTON_CONFIGS[i]
		var btn := TextureButton.new()
		btn.name = cfg.get("name", "Btn_Battle_%d" % (i + 1))
		btn.custom_minimum_size = Vector2(28.0, 84.0)
		btn.ignore_texture_size = false
		btn.stretch_mode = TextureButton.STRETCH_KEEP
		
		var norm_path: String = cfg.get("normal", "")
		var hover_path: String = cfg.get("hover", "")
		var press_path: String = cfg.get("pressed", "")
		
		if ResourceLoader.exists(norm_path):
			btn.texture_normal = load(norm_path)
		if ResourceLoader.exists(hover_path):
			btn.texture_hover = load(hover_path)
		if ResourceLoader.exists(press_path):
			btn.texture_pressed = load(press_path)
			
		var action_type: int = int(cfg.get("action", 0))
		btn.pressed.connect(_on_button_pressed.bind(action_type, i))
		btn.mouse_entered.connect(_on_button_hovered.bind(i, btn))
		btn.mouse_exited.connect(_on_button_unhovered)
		
		action_bar.add_child(btn)
		action_buttons.append(btn)
		
	# Floating Tooltip Hover Card
	_build_tooltip_card()

func _build_tooltip_card() -> void:
	tooltip_card = PanelContainer.new()
	tooltip_card.name = "TooltipCard"
	tooltip_card.visible = false
	tooltip_card.mouse_filter = MOUSE_FILTER_IGNORE
	tooltip_card.z_index = 20
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.14, 0.96)
	style.border_color = Color(0.9, 0.75, 0.3, 0.95) # Gold border
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8.0
	style.content_margin_top = 6.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 6.0
	tooltip_card.add_theme_stylebox_override("panel", style)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	
	var hbox_header := HBoxContainer.new()
	hbox_header.add_theme_constant_override("separation", 6)
	
	tooltip_title = Label.new()
	tooltip_title.name = "TooltipTitle"
	tooltip_title.text = "Action"
	tooltip_title.add_theme_font_size_override("font_size", 12)
	tooltip_title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))
	hbox_header.add_child(tooltip_title)
	
	tooltip_shortcut = Label.new()
	tooltip_shortcut.name = "TooltipShortcut"
	tooltip_shortcut.text = "[A]"
	tooltip_shortcut.add_theme_font_size_override("font_size", 10)
	tooltip_shortcut.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0))
	hbox_header.add_child(tooltip_shortcut)
	vbox.add_child(hbox_header)
	
	tooltip_desc = Label.new()
	tooltip_desc.name = "TooltipDesc"
	tooltip_desc.text = "Action description text."
	tooltip_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip_desc.custom_minimum_size = Vector2(170.0, 0.0)
	tooltip_desc.add_theme_font_size_override("font_size", 10)
	tooltip_desc.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92, 1.0))
	vbox.add_child(tooltip_desc)
	
	tooltip_card.add_child(vbox)
	add_child(tooltip_card)

func _on_button_pressed(action_type: int, _idx: int) -> void:
	play_action_sfx()
	hide_tooltip()
	action_triggered.emit(action_type)

func _on_button_hovered(idx: int, btn: TextureButton) -> void:
	play_action_sfx()
	if idx < 0 or idx >= BUTTON_CONFIGS.size():
		return
	var cfg: Dictionary = BUTTON_CONFIGS[idx]
	tooltip_title.text = String(cfg.get("title", "Action"))
	tooltip_shortcut.text = "[%s]" % String(cfg.get("shortcut", ""))
	tooltip_desc.text = String(cfg.get("description", ""))
	
	# Position tooltip above the hovered button
	var btn_pos: Vector2 = btn.position
	var target_x: float = btn_pos.x - 40.0
	var target_y: float = -62.0
	
	# Clamp inside menu bounds
	target_x = clampf(target_x, -10.0, size.x - 160.0)
	tooltip_card.position = Vector2(target_x, target_y)
	tooltip_card.modulate.a = 0.0
	tooltip_card.visible = true
	
	var tween := create_tween()
	if tween:
		tween.tween_property(tooltip_card, "modulate:a", 1.0, 0.12)

func _on_button_unhovered() -> void:
	hide_tooltip()

func hide_tooltip() -> void:
	if tooltip_card:
		tooltip_card.visible = false

# --- Layout & Anchoring ---

func apply_docked_layout() -> void:
	anchor_mode = AnchorMode.DOCKED_BOTTOM_RIGHT
	set_anchors_preset(PRESET_BOTTOM_RIGHT)
	anchor_left = 1.0
	anchor_top = 1.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = DOCKED_OFFSET_LEFT
	offset_top = DOCKED_OFFSET_TOP
	offset_right = DOCKED_OFFSET_RIGHT
	offset_bottom = DOCKED_OFFSET_BOTTOM
	grow_horizontal = GROW_DIRECTION_BEGIN
	grow_vertical = GROW_DIRECTION_BEGIN
	anchor_mode_changed.emit(false)

func apply_contextual_layout(target_slot_pos: Vector2, parent_viewport_size: Vector2) -> void:
	anchor_mode = AnchorMode.CONTEXTUAL_ANCHOR
	contextual_target_pos = target_slot_pos
	
	# Clear preset anchors to manual positioning
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	
	# Desired position: slightly offset from player standee
	var desired_x: float = target_slot_pos.x + 24.0
	var desired_y: float = target_slot_pos.y - 70.0
	
	# Viewport bounds clamping so the menu never clips off-screen
	var max_x: float = parent_viewport_size.x - DEFAULT_MENU_SIZE.x - VIEWPORT_PADDING
	var max_y: float = parent_viewport_size.y - DEFAULT_MENU_SIZE.y - VIEWPORT_PADDING
	
	var final_x: float = clampf(desired_x, VIEWPORT_PADDING, max_x)
	var final_y: float = clampf(desired_y, VIEWPORT_PADDING, max_y)
	
	position = Vector2(final_x, final_y)
	size = DEFAULT_MENU_SIZE
	anchor_mode_changed.emit(true)

func toggle_anchor_mode(target_slot_pos: Vector2, parent_viewport_size: Vector2) -> void:
	if anchor_mode == AnchorMode.DOCKED_BOTTOM_RIGHT:
		apply_contextual_layout(target_slot_pos, parent_viewport_size)
	else:
		apply_docked_layout()

# --- Keyboard Shortcut Handling ---

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not is_active_turn:
		return
	if not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		return
		
	var key_event := event as InputEventKey
	var key: Key = key_event.keycode
	
	# Check shortcut matches
	for cfg in BUTTON_CONFIGS:
		if key == cfg.get("keycode") or key == cfg.get("alt_key"):
			var action_type: int = int(cfg.get("action", 0))
			play_action_sfx()
			_pulse_button(action_type)
			action_triggered.emit(action_type)
			get_viewport().set_input_as_handled()
			return

func _pulse_button(action_type: int) -> void:
	if action_type < 0 or action_type >= action_buttons.size():
		return
	var btn: TextureButton = action_buttons[action_type]
	if btn:
		var tween := create_tween()
		if tween:
			tween.tween_property(btn, "scale", Vector2(1.15, 1.15), 0.06).set_trans(Tween.TRANS_QUAD)
			tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.08).set_trans(Tween.TRANS_QUAD)
