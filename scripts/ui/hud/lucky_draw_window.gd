class_name LuckyDrawWindow
extends Control

## Lucky Draw / Chance window in Wonderland Online HUD.
## Opened from the top action bar Lucky Draw icon (icon 745).
## Layout measured from the live client (docs/reference/real_client/lucky_draw_click.png):
## title "chance", question-mark box, "Left N Draws" counter, Draw and Close buttons.
## Pure UI component without game logic; do not award anything.

signal draw_pressed
signal closed

const DEFAULT_WINDOW_SIZE: Vector2 = Vector2(190.0, 200.0)

var draws_left: int = 0
var title_label: Label = null
var question_box: Panel = null
var question_label: Label = null
var draws_left_label: Label = null
var draws_label: Label = null # Alias to draws_left_label
var draw_button: Button = null
var close_button: Button = null
var top_close_button: Button = null

var _built: bool = false
var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO


func _init() -> void:
	name = "LuckyDrawWindow"
	custom_minimum_size = DEFAULT_WINDOW_SIZE
	size = DEFAULT_WINDOW_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build()


func _ready() -> void:
	if not _built:
		_build()


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
		if get_viewport() != null:
			get_viewport().set_input_as_handled()


func _build() -> void:
	if _built:
		return
	_built = true

	# Root panel container with authentic WLO window frame styling
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
	main_vbox.add_theme_constant_override("separation", 8)
	add_child(main_vbox)

	# --- Title Bar ---
	var title_bar := HBoxContainer.new()
	title_bar.name = "TitleBar"
	title_bar.custom_minimum_size = Vector2(0.0, 22.0)
	title_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	title_bar.gui_input.connect(_on_title_bar_gui_input)

	title_label = Label.new()
	title_label.name = "chance"
	title_label.text = "chance"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45, 1.0))
	title_label.add_theme_font_size_override("font_size", 13)
	title_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	title_label.add_theme_constant_override("outline_size", 2)
	title_bar.add_child(title_label)

	top_close_button = Button.new()
	top_close_button.name = "TopCloseButton"
	top_close_button.text = "X"
	top_close_button.custom_minimum_size = Vector2(20.0, 20.0)
	top_close_button.focus_mode = Control.FOCUS_NONE
	top_close_button.pressed.connect(close)
	_apply_small_button_style(top_close_button)
	title_bar.add_child(top_close_button)

	main_vbox.add_child(title_bar)

	# --- Question Mark Box (Panel with centered '?' label) ---
	var box_center := CenterContainer.new()
	box_center.name = "BoxCenter"
	box_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box_center.size_flags_vertical = Control.SIZE_EXPAND_FILL

	question_box = Panel.new()
	question_box.name = "QuestionBox"
	question_box.custom_minimum_size = Vector2(120.0, 78.0)
	question_box.mouse_filter = Control.MOUSE_FILTER_PASS

	var q_style := StyleBoxFlat.new()
	q_style.bg_color = Color(0.08, 0.11, 0.17, 0.9)
	q_style.border_color = Color(0.55, 0.50, 0.35, 1.0)
	q_style.set_border_width_all(1)
	q_style.set_corner_radius_all(3)
	question_box.add_theme_stylebox_override("panel", q_style)

	question_label = Label.new()
	question_label.name = "QuestionLabel"
	question_label.text = "?"
	question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	question_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	question_label.add_theme_font_size_override("font_size", 34)
	question_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45, 1.0))
	question_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
	question_label.add_theme_constant_override("outline_size", 2)
	question_box.add_child(question_label)

	box_center.add_child(question_box)
	main_vbox.add_child(box_center)

	# --- "Left N Draws" Counter Label ---
	draws_left_label = Label.new()
	draws_left_label.name = "DrawsLeftLabel"
	draws_left_label.text = "Left %d Draws" % draws_left
	draws_left_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	draws_left_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	draws_left_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
	draws_left_label.add_theme_font_size_override("font_size", 12)
	draws_left_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
	draws_left_label.add_theme_constant_override("outline_size", 1)
	draws_label = draws_left_label
	main_vbox.add_child(draws_left_label)

	# --- Buttons (Draw and Close) ---
	var btn_hbox := HBoxContainer.new()
	btn_hbox.name = "ButtonHBox"
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 10)

	draw_button = Button.new()
	draw_button.name = "Draw"
	draw_button.text = "Draw"
	draw_button.custom_minimum_size = Vector2(74.0, 24.0)
	draw_button.focus_mode = Control.FOCUS_NONE
	draw_button.pressed.connect(_on_draw_pressed)
	_apply_action_button_style(draw_button)
	btn_hbox.add_child(draw_button)

	close_button = Button.new()
	close_button.name = "Close"
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(74.0, 24.0)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(close)
	_apply_action_button_style(close_button)
	btn_hbox.add_child(close_button)

	main_vbox.add_child(btn_hbox)


func _on_draw_pressed() -> void:
	draw_pressed.emit()


func _on_title_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_offset = get_global_mouse_position() - global_position
		else:
			_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		global_position = get_global_mouse_position() - _drag_offset


func _apply_small_button_style(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.18, 0.22, 0.32, 0.9)
	normal.border_color = Color(0.70, 0.60, 0.30, 0.8)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(2)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.28, 0.34, 0.48, 1.0)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.12, 0.15, 0.22, 1.0)
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_font_size_override("font_size", 10)
	btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.80, 1.0))


func _apply_action_button_style(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.16, 0.22, 0.32, 0.95)
	normal.border_color = Color(0.75, 0.65, 0.32, 1.0)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.24, 0.32, 0.46, 1.0)
	hover.border_color = Color(0.95, 0.82, 0.40, 1.0)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.10, 0.14, 0.22, 1.0)
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85, 1.0))
	btn.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
	btn.add_theme_constant_override("outline_size", 1)


## Sets the number of draws left and updates the counter label text.
func set_draws_left(n: int) -> void:
	draws_left = n
	if not _built:
		_build()
	if draws_left_label != null:
		draws_left_label.text = "Left %d Draws" % draws_left


## Returns the currently tracked number of draws left.
func get_draws_left() -> int:
	return draws_left


## Helper lookup for action buttons by name ("Draw" or "Close").
func get_action_button(action_name: String) -> Button:
	if action_name == "Draw":
		return draw_button
	elif action_name == "Close":
		return close_button
	return null


## Opens the window, ensuring it is built, visible, and focused on top.
func open() -> void:
	if not _built:
		_build()
	visible = true
	move_to_front()


## Closes the window, hiding it and emitting the closed signal.
func close() -> void:
	visible = false
	closed.emit()
