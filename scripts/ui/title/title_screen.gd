class_name TitleScreen
extends Control

const SINGLE_PLAYER_SCENE := "res://scenes/ui/single_player_slots.tscn"
const MULTIPLAYER_SCENE := "res://scenes/ui/login_screen.tscn"
const LOGO_PATH := "res://assets/ui/title/login_logo.png"

var single_player_button: Button
var multiplayer_button: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg_rect := TextureRect.new()
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray([Color("0b1d33"), Color("02060c")])

	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = gradient
	grad_tex.fill_from = Vector2(0.5, 0.0)
	grad_tex.fill_to = Vector2(0.5, 1.0)
	bg_rect.texture = grad_tex
	add_child(bg_rect)

	var center_container := CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	center_container.add_child(vbox)

	if ResourceLoader.exists(LOGO_PATH):
		var logo_tex := load(LOGO_PATH) as Texture2D
		if logo_tex:
			var logo_rect := TextureRect.new()
			logo_rect.texture = logo_tex
			logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			logo_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			vbox.add_child(logo_rect)

	var title_label := Label.new()
	title_label.text = "WONDERLAND ONLINE"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 40)
	title_label.add_theme_color_override("font_color", Color("f2e6b0"))
	title_label.add_theme_color_override("font_outline_color", Color("000000"))
	title_label.add_theme_constant_override("outline_size", 6)
	vbox.add_child(title_label)

	single_player_button = Button.new()
	single_player_button.text = "SINGLE PLAYER"
	single_player_button.custom_minimum_size = Vector2(320, 56)
	single_player_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	single_player_button.focus_mode = Control.FOCUS_ALL
	single_player_button.add_theme_font_size_override("font_size", 22)
	_apply_button_styles(single_player_button)
	single_player_button.pressed.connect(_on_single_player_pressed)
	vbox.add_child(single_player_button)

	multiplayer_button = Button.new()
	multiplayer_button.text = "MULTIPLAYER"
	multiplayer_button.custom_minimum_size = Vector2(320, 56)
	multiplayer_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	multiplayer_button.focus_mode = Control.FOCUS_ALL
	multiplayer_button.add_theme_font_size_override("font_size", 22)
	_apply_button_styles(multiplayer_button)
	multiplayer_button.pressed.connect(_on_multiplayer_pressed)
	vbox.add_child(multiplayer_button)

	var quit_button := Button.new()
	quit_button.text = "Quit"
	quit_button.custom_minimum_size = Vector2(160, 40)
	quit_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	quit_button.focus_mode = Control.FOCUS_ALL
	quit_button.add_theme_font_size_override("font_size", 16)
	_apply_button_styles(quit_button)
	quit_button.pressed.connect(_on_quit_pressed)
	vbox.add_child(quit_button)

	single_player_button.grab_focus()


func _apply_button_styles(button: Button) -> void:
	var normal_style := _create_style_box(Color("1e3a5f"))
	var hover_style := _create_style_box(Color("2a5083"))
	var pressed_style := _create_style_box(Color("14283f"))

	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", hover_style)

	button.add_theme_color_override("font_color", Color("ffffff"))
	button.add_theme_color_override("font_hover_color", Color("ffffff"))
	button.add_theme_color_override("font_pressed_color", Color("ffffff"))
	button.add_theme_color_override("font_focus_color", Color("ffffff"))


func _create_style_box(bg_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = Color("5aa0e6")
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	return style


func _on_single_player_pressed() -> void:
	_change_scene(SINGLE_PLAYER_SCENE)


func _on_multiplayer_pressed() -> void:
	_change_scene(MULTIPLAYER_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _change_scene(target: String) -> void:
	if not ResourceLoader.exists(target):
		push_warning("Scene missing: " + target)
		return
	get_tree().change_scene_to_file(target)
