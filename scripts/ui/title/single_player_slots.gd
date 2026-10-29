class_name SinglePlayerSlots
extends Control

var selected_slot: int = -1
var is_new_game: bool = false
var slot_buttons: Dictionary = {}

var _slots_vbox: VBoxContainer
var _btn_normal: StyleBoxFlat
var _btn_hover: StyleBoxFlat
var _btn_pressed: StyleBoxFlat
var _row_panel_style: StyleBoxFlat


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_init_styles()

	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color("#0b1d33"), Color("#02060c")])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)

	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.texture = tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 18)
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(main_vbox)

	var title := Label.new()
	title.text = "SELECT SAVE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color("#f2e6b0"))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 6)
	main_vbox.add_child(title)

	_slots_vbox = VBoxContainer.new()
	_slots_vbox.add_theme_constant_override("separation", 10)
	main_vbox.add_child(_slots_vbox)

	var back_btn := Button.new()
	back_btn.text = "Back"
	_style_button(back_btn, Vector2(200, 44))
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.pressed.connect(_on_back_pressed)
	main_vbox.add_child(back_btn)

	_build_rows()


func _init_styles() -> void:
	_row_panel_style = StyleBoxFlat.new()
	_row_panel_style.bg_color = Color("#13294a")
	_row_panel_style.border_color = Color("#5aa0e6")
	_row_panel_style.set_border_width_all(2)
	_row_panel_style.set_corner_radius_all(10)

	_btn_normal = StyleBoxFlat.new()
	_btn_normal.bg_color = Color("#1e3a5f")
	_btn_normal.border_color = Color("#5aa0e6")
	_btn_normal.set_border_width_all(2)
	_btn_normal.set_corner_radius_all(8)

	_btn_hover = _btn_normal.duplicate()
	_btn_hover.bg_color = Color("#2a5083")

	_btn_pressed = _btn_normal.duplicate()
	_btn_pressed.bg_color = Color("#14283f")


func _style_button(btn: Button, min_size: Vector2) -> void:
	btn.custom_minimum_size = min_size
	btn.focus_mode = Control.FOCUS_ALL
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_stylebox_override("normal", _btn_normal)
	btn.add_theme_stylebox_override("hover", _btn_hover)
	btn.add_theme_stylebox_override("pressed", _btn_pressed)
	btn.add_theme_stylebox_override("focus", _btn_hover)


func _build_rows() -> void:
	slot_buttons.clear()
	for child in _slots_vbox.get_children():
		child.queue_free()

	var first_button: Button = null

	for i in range(SaveGame.SLOT_COUNT):
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(520, 84)
		panel.add_theme_stylebox_override("panel", _row_panel_style)
		_slots_vbox.add_child(panel)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 16)
		margin.add_theme_constant_override("margin_right", 16)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_bottom", 10)
		panel.add_child(margin)

		var row_hbox := HBoxContainer.new()
		row_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		margin.add_child(row_hbox)

		var info_vbox := VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		row_hbox.add_child(info_vbox)

		var name_label := Label.new()
		name_label.text = "Slot %d" % (i + 1)
		name_label.add_theme_font_size_override("font_size", 18)
		info_vbox.add_child(name_label)

		var details_label := Label.new()
		details_label.add_theme_font_size_override("font_size", 14)
		details_label.add_theme_color_override("font_color", Color("#9fc3ea"))
		info_vbox.add_child(details_label)

		var btn_hbox := HBoxContainer.new()
		btn_hbox.add_theme_constant_override("separation", 8)
		btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		row_hbox.add_child(btn_hbox)

		var slot_entry := {"new": null, "continue": null, "delete": null}

		if not SaveGame.has_slot(i):
			details_label.text = "Empty"
			var new_btn := Button.new()
			new_btn.text = "New Game"
			_style_button(new_btn, Vector2(140, 40))
			new_btn.pressed.connect(_on_new_game_pressed.bind(i))
			btn_hbox.add_child(new_btn)
			slot_entry["new"] = new_btn
			if first_button == null:
				first_button = new_btn
		else:
			var summary: Dictionary = SaveGame.slot_summary(i)
			var char_name: String = summary.get("name", "Unknown")
			var level: int = int(summary.get("level", 1))
			var saved_at: int = int(summary.get("saved_at", 0))
			var date_str := ""
			if saved_at > 0:
				date_str = Time.get_datetime_string_from_unix_time(saved_at, true).replace("T", " ").substr(0, 16)
			else:
				date_str = "Unknown"
			details_label.text = "%s  Lv %d  -  %s" % [char_name, level, date_str]

			var cont_btn := Button.new()
			cont_btn.text = "Continue"
			_style_button(cont_btn, Vector2(140, 40))
			cont_btn.pressed.connect(_on_continue_pressed.bind(i))
			btn_hbox.add_child(cont_btn)
			slot_entry["continue"] = cont_btn

			var del_btn := Button.new()
			del_btn.text = "Delete"
			_style_button(del_btn, Vector2(100, 40))
			del_btn.pressed.connect(_on_delete_pressed.bind(i))
			btn_hbox.add_child(del_btn)
			slot_entry["delete"] = del_btn

			if first_button == null:
				first_button = cont_btn

		slot_buttons[i] = slot_entry

	if first_button != null:
		first_button.call_deferred("grab_focus")


func _on_new_game_pressed(slot: int) -> void:
	selected_slot = slot
	is_new_game = true
	_enter_world()


func _on_continue_pressed(slot: int) -> void:
	selected_slot = slot
	is_new_game = false
	_enter_world()


func _on_delete_pressed(slot: int) -> void:
	SaveGame.delete_slot(slot)
	_build_rows()


func _on_back_pressed() -> void:
	var title_path := "res://scenes/ui/title_screen.tscn"
	if ResourceLoader.exists(title_path):
		get_tree().change_scene_to_file(title_path)


func _enter_world() -> void:
	var gdb: Node = get_tree().root.get_node_or_null("GameDatabase")
	if is_new_game:
		var char_dict: Dictionary = CharacterManager.create_default_character(selected_slot, 6, "Daniel")
		char_dict["map_id"] = 10002
		char_dict["gold"] = 500
		char_dict["save_slot"] = selected_slot
		SaveGame.write_slot(selected_slot, char_dict)
		if gdb != null and "active_character" in gdb:
			gdb.active_character = char_dict.duplicate(true)
	else:
		var snap: Dictionary = SaveGame.read_slot(selected_slot)
		if snap.is_empty():
			push_warning("Failed to load save data for slot %d." % selected_slot)
			return
		snap["save_slot"] = selected_slot
		if gdb != null and "active_character" in gdb:
			gdb.active_character = snap.duplicate(true)

	var world_path: String = "res://scenes/world/map_view.tscn"
	var loading_screen: Node = get_tree().root.get_node_or_null("LoadingScreen")
	if loading_screen != null and loading_screen.has_method("go_to"):
		loading_screen.go_to(get_tree(), world_path)
	elif ResourceLoader.exists(world_path):
		get_tree().change_scene_to_file(world_path)
