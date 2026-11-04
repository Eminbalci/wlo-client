class_name GoldWindow
extends Control

## Gold / Money management window in Wonderland Online HUD.
## Opened from the top action bar Money icon (icon 668) or inventory gold click.
## Displays the player's current gold amount and provides actions:
## Discard, Trade Item, Trade Pet, Trade Equipment, Sell Item, Sell Pet, Sell Equipment, and Close.
## Emits action_pressed(action: String) when any action button is triggered.
## Pure UI component without game logic.

signal action_pressed(action: String)
signal closed

const BUTTON_ACTIONS: Array[String] = [
	"Discard",
	"Trade Item",
	"Trade Pet",
	"Trade Equipment",
	"Sell Item",
	"Sell Pet",
	"Sell Equipment",
	"Close",
]

const DEFAULT_WINDOW_SIZE: Vector2 = Vector2(260.0, 220.0)
const GOLD_ICON_PATH: String = "res://assets/menu/Skins/default/Icon_Gold_1.bmp"
const GOLD_WORD_PATH: String = "res://assets/hud/hud_word_gold.png"

var current_gold: int = 0
var title_label: Label = null
var gold_label: Label = null
var buttons: Dictionary = {} # String action -> Button
var button_list: Array[Button] = []

var _built: bool = false
var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO


func _init() -> void:
	name = "GoldWindow"
	custom_minimum_size = DEFAULT_WINDOW_SIZE
	size = DEFAULT_WINDOW_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func _ready() -> void:
	if not _built:
		_build()


func _build() -> void:
	if _built:
		return
	_built = true

	# Root panel background with authentic WLO window frame styling
	var panel := PanelContainer.new()
	panel.name = "RootPanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.16, 0.24, 0.95)
	panel_style.border_color = Color(0.85, 0.72, 0.32, 1.0) # Gold border
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(4)
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	panel_style.shadow_size = 6
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var main_vbox := VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.offset_left = 6.0
	main_vbox.offset_top = 4.0
	main_vbox.offset_right = -6.0
	main_vbox.offset_bottom = -6.0
	main_vbox.add_theme_constant_override("separation", 6)
	add_child(main_vbox)

	# --- Title Bar ---
	var title_bar := HBoxContainer.new()
	title_bar.name = "TitleBar"
	title_bar.custom_minimum_size = Vector2(0.0, 24.0)
	title_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	title_bar.gui_input.connect(_on_title_bar_gui_input)

	# Title label "gold"
	title_label = Label.new()
	title_label.name = "gold"
	title_label.text = "gold"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45, 1.0))
	title_label.add_theme_font_size_override("font_size", 13)
	title_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	title_label.add_theme_constant_override("outline_size", 2)
	title_bar.add_child(title_label)

	var top_close_btn := Button.new()
	top_close_btn.name = "TopCloseButton"
	top_close_btn.text = "X"
	top_close_btn.custom_minimum_size = Vector2(20.0, 20.0)
	top_close_btn.focus_mode = Control.FOCUS_NONE
	top_close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	top_close_btn.pressed.connect(close)
	title_bar.add_child(top_close_btn)

	main_vbox.add_child(title_bar)

	# --- Gold Display Box ---
	var gold_box := HBoxContainer.new()
	gold_box.name = "GoldDisplayBox"
	gold_box.custom_minimum_size = Vector2(0.0, 28.0)
	gold_box.alignment = BoxContainer.ALIGNMENT_CENTER
	gold_box.add_theme_constant_override("separation", 8)

	var icon_rect := TextureRect.new()
	icon_rect.name = "GoldIcon"
	icon_rect.custom_minimum_size = Vector2(24.0, 20.0)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gold_tex: Texture2D = null
	if ResourceLoader.exists(GOLD_ICON_PATH):
		gold_tex = load(GOLD_ICON_PATH) as Texture2D
	elif ResourceLoader.exists(GOLD_WORD_PATH):
		gold_tex = load(GOLD_WORD_PATH) as Texture2D
	if gold_tex != null:
		icon_rect.texture = gold_tex
	gold_box.add_child(icon_rect)

	gold_label = Label.new()
	gold_label.name = "GoldLabel"
	gold_label.text = "%d" % current_gold
	gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gold_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25, 1.0))
	gold_label.add_theme_font_size_override("font_size", 14)
	gold_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	gold_label.add_theme_constant_override("outline_size", 2)
	gold_box.add_child(gold_label)

	main_vbox.add_child(gold_box)

	# --- Buttons Grid (2 columns x 4 rows) ---
	var grid := GridContainer.new()
	grid.name = "ButtonGrid"
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)

	buttons.clear()
	button_list.clear()

	for action_name in BUTTON_ACTIONS:
		var btn := _create_action_button(action_name)
		grid.add_child(btn)
		buttons[action_name] = btn
		buttons[action_name.to_lower()] = btn
		buttons[action_name.to_lower().replace(" ", "_")] = btn
		button_list.append(btn)

	main_vbox.add_child(grid)


func _create_action_button(action_name: String) -> Button:
	var btn := Button.new()
	btn.name = action_name
	btn.text = action_name
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(110.0, 26.0)
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# Authentic styling
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.18, 0.24, 0.36, 0.9)
	normal_style.border_color = Color(0.55, 0.65, 0.80, 0.8)
	normal_style.set_border_width_all(1)
	normal_style.set_corner_radius_all(3)
	normal_style.content_margin_left = 4.0
	normal_style.content_margin_right = 4.0
	normal_style.content_margin_top = 2.0
	normal_style.content_margin_bottom = 2.0
	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.28, 0.38, 0.55, 1.0)
	hover_style.border_color = Color(1.0, 0.88, 0.35, 1.0)
	hover_style.set_border_width_all(1)
	hover_style.set_corner_radius_all(3)
	hover_style.content_margin_left = 4.0
	hover_style.content_margin_right = 4.0
	hover_style.content_margin_top = 2.0
	hover_style.content_margin_bottom = 2.0
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.12, 0.16, 0.25, 1.0)
	pressed_style.border_color = Color(0.9, 0.75, 0.25, 1.0)
	pressed_style.set_border_width_all(1)
	pressed_style.set_corner_radius_all(3)
	pressed_style.content_margin_left = 4.0
	pressed_style.content_margin_right = 4.0
	pressed_style.content_margin_top = 2.0
	pressed_style.content_margin_bottom = 2.0
	btn.add_theme_stylebox_override("pressed", pressed_style)

	btn.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.5, 1.0))
	btn.add_theme_font_size_override("font_size", 12)

	btn.pressed.connect(func() -> void: _on_action_button_pressed(action_name))
	return btn


func _on_action_button_pressed(action_name: String) -> void:
	action_pressed.emit(action_name)
	if action_name == "Close":
		close()


func _on_title_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = true
				_drag_offset = get_global_mouse_position() - global_position
			else:
				_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		global_position = get_global_mouse_position() - _drag_offset


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()


# --- Public Interface ---

## Displays the specified gold amount.
func set_gold(amount: int) -> void:
	current_gold = amount
	if not _built:
		_build()
	if gold_label != null:
		gold_label.text = "%d" % amount


## Returns the currently tracked gold amount.
func get_gold() -> int:
	return current_gold


## Shows the gold window and brings it to front.
func open() -> void:
	if not _built:
		_build()
	visible = true
	move_to_front()


## Closes and hides the gold window, emitting closed signal.
func close() -> void:
	visible = false
	closed.emit()


## Retrieves a button reference by action name (e.g. "Discard", "Trade Item", or "discard").
func get_action_button(action_name: String) -> Button:
	if not _built:
		_build()
	return buttons.get(action_name, null) as Button
