class_name EventsWindow
extends Control

## Events schedule / Activities window in Wonderland Online HUD.
## Displays scheduled daily activities and events with status, timing, and teleport options.
## Pure UI component without game logic.

signal teleport_pressed
signal leave_pressed
signal closed

const DEFAULT_SIZE: Vector2 = Vector2(520.0, 360.0)
const ROWS_PER_PAGE: int = 4
const COLUMNS: Array[String] = ["Event Name", "Start Time", "End Time", "Event Status"]

var title_label: Label = null
var day_label: Label = null
var pager_label: Label = null
var prev_button: Button = null
var next_button: Button = null
var teleport_button: Button = null
var leave_button: Button = null
var close_button: Button = null

var events: Array = []
var current_page: int = 1
var selected_row_index: int = -1

var _built: bool = false
var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO

var _row_containers: Array[PanelContainer] = []
var _row_labels: Array[Array] = []


func _init() -> void:
	name = "EventsWindow"
	custom_minimum_size = DEFAULT_SIZE
	size = DEFAULT_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


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

	# Root panel background with authentic WLO window frame styling
	var panel := PanelContainer.new()
	panel.name = "RootPanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.16, 0.24, 0.95)
	panel_style.border_color = Color(0.85, 0.72, 0.32, 1.0)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(4)
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	panel_style.shadow_size = 6
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var main_vbox := VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.offset_left = 10.0
	main_vbox.offset_top = 8.0
	main_vbox.offset_right = -10.0
	main_vbox.offset_bottom = -10.0
	main_vbox.add_theme_constant_override("separation", 8)
	add_child(main_vbox)

	# --- Title Bar ---
	var title_bar := HBoxContainer.new()
	title_bar.name = "TitleBar"
	title_bar.custom_minimum_size = Vector2(0.0, 24.0)
	title_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	title_bar.gui_input.connect(_on_title_bar_gui_input)

	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "Activities"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45, 1.0))
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	title_label.add_theme_constant_override("outline_size", 2)
	title_bar.add_child(title_label)

	close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "X"
	close_button.custom_minimum_size = Vector2(24.0, 22.0)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_button.pressed.connect(close)
	title_bar.add_child(close_button)

	main_vbox.add_child(title_bar)

	# --- Day Header Bar ---
	var day_bar := HBoxContainer.new()
	day_bar.name = "DayBar"
	day_bar.custom_minimum_size = Vector2(0.0, 20.0)

	day_label = Label.new()
	day_label.name = "DayLabel"
	day_label.text = ""
	day_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	day_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	day_label.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0, 1.0))
	day_label.add_theme_font_size_override("font_size", 12)
	day_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
	day_label.add_theme_constant_override("outline_size", 1)
	day_bar.add_child(day_label)

	main_vbox.add_child(day_bar)

	# --- Table Header ---
	var header_panel := PanelContainer.new()
	header_panel.name = "HeaderPanel"
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = Color(0.18, 0.23, 0.32, 0.9)
	header_style.border_color = Color(0.4, 0.5, 0.65, 0.7)
	header_style.set_border_width_all(1)
	header_style.set_corner_radius_all(2)
	header_panel.add_theme_stylebox_override("panel", header_style)

	var header_hbox := HBoxContainer.new()
	header_hbox.name = "HeaderHBox"
	header_hbox.custom_minimum_size = Vector2(0.0, 24.0)

	var col_widths: Array[float] = [170.0, 95.0, 95.0, 110.0]

	for i in range(COLUMNS.size()):
		var col_lbl := Label.new()
		col_lbl.name = "HeaderCol_%d" % i
		col_lbl.text = COLUMNS[i]
		col_lbl.custom_minimum_size = Vector2(col_widths[i], 0.0)
		col_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL if i == 0 else Control.SIZE_SHRINK_CENTER
		col_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if i == 0 else HORIZONTAL_ALIGNMENT_CENTER
		col_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		col_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5, 1.0))
		col_lbl.add_theme_font_size_override("font_size", 12)
		col_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
		col_lbl.add_theme_constant_override("outline_size", 1)
		header_hbox.add_child(col_lbl)

	header_panel.add_child(header_hbox)
	main_vbox.add_child(header_panel)

	# --- Table Rows Container ---
	var table_vbox := VBoxContainer.new()
	table_vbox.name = "TableRows"
	table_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table_vbox.add_theme_constant_override("separation", 4)

	_row_containers.clear()
	_row_labels.clear()

	for r in range(ROWS_PER_PAGE):
		var row_panel := PanelContainer.new()
		row_panel.name = "Row_%d" % r
		row_panel.custom_minimum_size = Vector2(0.0, 32.0)
		row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var row_style := StyleBoxFlat.new()
		row_style.bg_color = Color(0.15, 0.19, 0.28, 0.75) if r % 2 == 0 else Color(0.12, 0.16, 0.24, 0.75)
		row_style.border_color = Color(0.28, 0.35, 0.48, 0.6)
		row_style.set_border_width_all(1)
		row_style.set_corner_radius_all(2)
		row_panel.add_theme_stylebox_override("panel", row_style)

		var row_hbox := HBoxContainer.new()
		row_hbox.name = "RowHBox"
		row_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)

		var labels_for_row: Array[Label] = []
		for c in range(COLUMNS.size()):
			var cell_lbl := Label.new()
			cell_lbl.name = "Cell_%d_%d" % [r, c]
			cell_lbl.custom_minimum_size = Vector2(col_widths[c], 0.0)
			cell_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL if c == 0 else Control.SIZE_SHRINK_CENTER
			cell_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if c == 0 else HORIZONTAL_ALIGNMENT_CENTER
			cell_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			cell_lbl.clip_text = true
			cell_lbl.add_theme_font_size_override("font_size", 11)
			cell_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
			row_hbox.add_child(cell_lbl)
			labels_for_row.append(cell_lbl)

		row_panel.add_child(row_hbox)

		var row_idx := r
		row_panel.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_row_clicked(row_idx)
		)

		table_vbox.add_child(row_panel)
		_row_containers.append(row_panel)
		_row_labels.append(labels_for_row)

	main_vbox.add_child(table_vbox)

	# --- Pager Bar ---
	var pager_hbox := HBoxContainer.new()
	pager_hbox.name = "PagerBar"
	pager_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	pager_hbox.add_theme_constant_override("separation", 10)

	prev_button = Button.new()
	prev_button.name = "Previous"
	prev_button.text = "Previous"
	prev_button.custom_minimum_size = Vector2(70.0, 24.0)
	prev_button.focus_mode = Control.FOCUS_NONE
	prev_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	prev_button.pressed.connect(prev_page)
	pager_hbox.add_child(prev_button)

	pager_label = Label.new()
	pager_label.name = "PagerLabel"
	pager_label.text = "1/1"
	pager_label.custom_minimum_size = Vector2(50.0, 0.0)
	pager_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pager_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pager_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	pager_label.add_theme_font_size_override("font_size", 12)
	pager_hbox.add_child(pager_label)

	next_button = Button.new()
	next_button.name = "Next"
	next_button.text = "Next"
	next_button.custom_minimum_size = Vector2(70.0, 24.0)
	next_button.focus_mode = Control.FOCUS_NONE
	next_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	next_button.pressed.connect(next_page)
	pager_hbox.add_child(next_button)

	main_vbox.add_child(pager_hbox)

	# --- Bottom Action Buttons ---
	var bottom_hbox := HBoxContainer.new()
	bottom_hbox.name = "BottomBar"
	bottom_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_hbox.add_theme_constant_override("separation", 24)

	teleport_button = Button.new()
	teleport_button.name = "Teleport"
	teleport_button.text = "Teleport"
	teleport_button.custom_minimum_size = Vector2(90.0, 28.0)
	teleport_button.focus_mode = Control.FOCUS_NONE
	teleport_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	teleport_button.pressed.connect(_on_teleport_pressed)
	bottom_hbox.add_child(teleport_button)

	leave_button = Button.new()
	leave_button.name = "Leave"
	leave_button.text = "Leave"
	leave_button.custom_minimum_size = Vector2(90.0, 28.0)
	leave_button.focus_mode = Control.FOCUS_NONE
	leave_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	leave_button.pressed.connect(_on_leave_pressed)
	bottom_hbox.add_child(leave_button)

	main_vbox.add_child(bottom_hbox)

	_update_table()


func set_day(text: String) -> void:
	if not _built:
		_build()
	if day_label != null:
		day_label.text = text


func set_events(rows: Array) -> void:
	if not _built:
		_build()
	events = rows.duplicate()
	current_page = 1
	selected_row_index = -1
	_update_table()


func get_total_pages() -> int:
	if events.is_empty():
		return 1
	return maxi(1, ceili(float(events.size()) / float(ROWS_PER_PAGE)))


func prev_page() -> void:
	if current_page > 1:
		current_page -= 1
		selected_row_index = -1
		_update_table()


func next_page() -> void:
	if current_page < get_total_pages():
		current_page += 1
		selected_row_index = -1
		_update_table()


func open() -> void:
	if not _built:
		_build()
	visible = true
	move_to_front()


func close() -> void:
	visible = false
	closed.emit()


func _on_teleport_pressed() -> void:
	teleport_pressed.emit()


func _on_leave_pressed() -> void:
	leave_pressed.emit()


func _on_row_clicked(visual_row_index: int) -> void:
	var global_idx := (current_page - 1) * ROWS_PER_PAGE + visual_row_index
	if global_idx >= 0 and global_idx < events.size():
		selected_row_index = global_idx
		_update_table()


func _set_row_highlight(panel: PanelContainer, is_selected: bool, row_index: int) -> void:
	var style := StyleBoxFlat.new()
	if is_selected:
		style.bg_color = Color(0.24, 0.38, 0.60, 0.95)
		style.border_color = Color(0.95, 0.85, 0.35, 1.0)
		style.set_border_width_all(2)
	else:
		style.bg_color = Color(0.15, 0.19, 0.28, 0.75) if row_index % 2 == 0 else Color(0.12, 0.16, 0.24, 0.75)
		style.border_color = Color(0.28, 0.35, 0.48, 0.6)
		style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	panel.add_theme_stylebox_override("panel", style)


func _update_table() -> void:
	var total_pages := get_total_pages()
	current_page = clamp(current_page, 1, total_pages)

	if pager_label != null:
		pager_label.text = "%d/%d" % [current_page, total_pages]

	if prev_button != null:
		prev_button.disabled = (current_page <= 1)
	if next_button != null:
		next_button.disabled = (current_page >= total_pages)

	var start_idx := (current_page - 1) * ROWS_PER_PAGE

	for r in range(ROWS_PER_PAGE):
		var event_idx := start_idx + r
		var labels: Array = _row_labels[r] if r < _row_labels.size() else []
		var container: PanelContainer = _row_containers[r] if r < _row_containers.size() else null

		if event_idx < events.size():
			var item: Dictionary = events[event_idx] if events[event_idx] is Dictionary else {}
			if labels.size() >= 4:
				labels[0].text = str(item.get("name", ""))
				labels[1].text = str(item.get("start", ""))
				labels[2].text = str(item.get("end", ""))
				labels[3].text = str(item.get("status", ""))
			if container != null:
				_set_row_highlight(container, event_idx == selected_row_index, r)
		else:
			if labels.size() >= 4:
				labels[0].text = ""
				labels[1].text = ""
				labels[2].text = ""
				labels[3].text = ""
			if container != null:
				_set_row_highlight(container, false, r)


func _on_title_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_offset = get_global_mouse_position() - global_position
		else:
			_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		global_position = get_global_mouse_position() - _drag_offset
