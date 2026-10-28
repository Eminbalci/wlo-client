class_name WloDialogueWindow
extends Control

## Authentic Wonderland Online NPC Dialogue Interface (Docs 08, 16, 69)
## Replaces basic floating popup with authentic WLO textured dialogue box:
## - Framed speaker portrait avatar on the left/top.
## - Golden speaker nameplate header.
## - Authentic NinePatch parchment message box with typewriter effect and click-to-complete.
## - Interactive parchment choice buttons (Options styling) or continue/OK button with flashing arrow.

signal dialogue_finished()
signal choice_selected(choice_index: int)

@export var typewriter_speed: float = 38.0 ## Characters per second

@onready var background: NinePatchRect = $Background
@onready var portrait_rect: TextureRect = $PortraitFrame/PortraitRect
@onready var speaker_label: Label = $SpeakerLabel
@onready var text_label: RichTextLabel = $TextLabel
@onready var next_icon: TextureRect = $NextIcon
@onready var choices_panel: Control = $ChoicesPanel
@onready var choices_container: VBoxContainer = $ChoicesPanel/ChoicesContainer
@onready var continue_btn: TextureButton = $ContinueBtn
@onready var close_btn: TextureButton = $CloseBtn

var current_choices: Array = []
var is_typing: bool = false
var full_text_content: String = ""
var typewriter_tween: Tween = null
var next_icon_tween: Tween = null

func _ready() -> void:
	visible = false

	# Setup continuous flashing animation for continue arrow
	if next_icon:
		next_icon_tween = create_tween().set_loops()
		next_icon_tween.tween_property(next_icon, "modulate:a", 0.25, 0.35)
		next_icon_tween.tween_property(next_icon, "modulate:a", 1.0, 0.35)

	if continue_btn:
		continue_btn.pressed.connect(_on_continue_pressed)

	if close_btn:
		close_btn.pressed.connect(_on_close_button_pressed)

	gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_typing:
			_skip_typewriter()
		elif current_choices.is_empty():
			_on_continue_pressed()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_accept"): # Space / Enter
		if is_typing:
			_skip_typewriter()
		elif current_choices.is_empty():
			_on_continue_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"): # Escape
		_on_close_button_pressed()
		get_viewport().set_input_as_handled()

## Displays authentic NPC dialogue with optional speaker portrait and branching choices.
func display_dialogue(speaker: String, text: String, choices: Array = [], custom_portrait: Texture2D = null) -> void:
	# 1. Resolve speaker title
	if speaker_label:
		speaker_label.text = speaker

	# 2. Resolve authentic NPC/Hero portrait
	if portrait_rect:
		if custom_portrait != null:
			portrait_rect.texture = custom_portrait
		else:
			portrait_rect.texture = _resolve_portrait(speaker)

	# 3. Format text body (replace authentic WLO tokens)
	full_text_content = _parse_wlo_tokens(text)
	if text_label:
		text_label.text = full_text_content
		text_label.visible_characters = 0

	# 4. Handle Branching Choices
	current_choices = choices
	_populate_choices(choices)

	# 5. Typewriter Animation
	_start_typewriter()

	visible = true

## Resolves an authentic speaker portrait from texture archives based on speaker name.
func _resolve_portrait(speaker: String) -> Texture2D:
	var lower_name: String = speaker.to_lower()
	var portrait_path: String = ""

	var player_name: String = "Daniel"
	var db = Engine.get_singleton("GameDatabase") if Engine.has_singleton("GameDatabase") else null
	if not db and get_tree() and get_tree().root.has_node("GameDatabase"):
		db = get_tree().root.get_node("GameDatabase")
	if db and "active_character" in db and db.active_character is Dictionary:
		player_name = db.active_character.get("name", "Daniel")

	if "captain" in lower_name:
		portrait_path = "res://assets/hud/portraits/captain_portrait.png"
	elif "crew" in lower_name or "sailor" in lower_name:
		portrait_path = "res://assets/hud/portraits/crew_portrait.png"
	elif "elder" in lower_name:
		portrait_path = "res://assets/hud/portraits/elder_portrait.png"
	elif lower_name == player_name.to_lower() or "daniel" in lower_name or "hero" in lower_name:
		portrait_path = "res://assets/hud/portraits/daniel_portrait.png"
	else:
		portrait_path = "res://assets/hud/portraits/default_portrait.png"

	if ResourceLoader.exists(portrait_path):
		return load(portrait_path)
	elif ResourceLoader.exists("res://assets/hud/role_pic_2.png"):
		return load("res://assets/hud/role_pic_2.png")
	return null

## Parses authentic WLO Talk tokens (#R, #B, #G, #Y colors, #n player name).
func _parse_wlo_tokens(raw_text: String) -> String:
	var parsed: String = raw_text

	# Replace player name token #n
	var p_name: String = "Traveler"
	var db = Engine.get_singleton("GameDatabase") if Engine.has_singleton("GameDatabase") else null
	if not db and get_tree() and get_tree().root.has_node("GameDatabase"):
		db = get_tree().root.get_node("GameDatabase")
	if db and "active_character" in db and db.active_character is Dictionary:
		p_name = db.active_character.get("name", "Traveler")
	parsed = parsed.replace("#n", p_name)

	# Convert authentic WLO color tags to Godot BBCode (slash optional: #R...#R or #R.../#R)
	# Red: #R...#R or #R.../#R
	var regex_r: RegEx = RegEx.new()
	regex_r.compile("#[Rr](.*?)/?#[Rr]")
	parsed = regex_r.sub(parsed, "[color=#FF5555]$1[/color]", true)

	# Blue/Cyan: #B...#B or #B.../#B
	var regex_b: RegEx = RegEx.new()
	regex_b.compile("#[Bb](.*?)/?#[Bb]")
	parsed = regex_b.sub(parsed, "[color=#66CCFF]$1[/color]", true)

	# Green: #G...#G or #G.../#G
	var regex_g: RegEx = RegEx.new()
	regex_g.compile("#[Gg](.*?)/?#[Gg]")
	parsed = regex_g.sub(parsed, "[color=#55FF55]$1[/color]", true)

	# Yellow/Gold: #Y...#Y or #Y.../#Y
	var regex_y: RegEx = RegEx.new()
	regex_y.compile("#[Yy](.*?)/?#[Yy]")
	parsed = regex_y.sub(parsed, "[color=#FFDD44]$1[/color]", true)

	# Strip leftover unrecognized tags e.g. #f01/#f or #s01/#s
	var regex_tags: RegEx = RegEx.new()
	regex_tags.compile("#[a-zA-Z0-9_-]+/?#[a-zA-Z0-9_-]+")
	parsed = regex_tags.sub(parsed, "", true)

	return parsed

## Starts the typewriter text reveal effect.
func _start_typewriter() -> void:
	if not text_label:
		return

	if typewriter_tween and typewriter_tween.is_valid():
		typewriter_tween.kill()

	var plain_len: int = text_label.get_parsed_text().length()
	if plain_len <= 0:
		text_label.visible_characters = -1
		is_typing = false
		_on_typewriter_finished()
		return

	is_typing = true
	if next_icon:
		next_icon.visible = false

	var duration: float = clampf(float(plain_len) / typewriter_speed, 0.25, 2.5)
	typewriter_tween = create_tween()
	typewriter_tween.tween_property(text_label, "visible_characters", plain_len, duration)
	typewriter_tween.finished.connect(_on_typewriter_finished)

## Instantly reveals the full text.
func _skip_typewriter() -> void:
	if not is_typing:
		return

	if typewriter_tween and typewriter_tween.is_valid():
		typewriter_tween.kill()

	if text_label:
		text_label.visible_characters = -1

	_on_typewriter_finished()

func _on_typewriter_finished() -> void:
	is_typing = false
	if current_choices.is_empty():
		if next_icon:
			next_icon.visible = true
		if continue_btn:
			continue_btn.visible = true
	else:
		if choices_panel:
			choices_panel.visible = true

## Populates interactive branching choices styled as authentic WLO parchment option buttons.
func _populate_choices(choices: Array) -> void:
	if not choices_container:
		return

	for child in choices_container.get_children():
		child.queue_free()

	if choices.is_empty():
		if choices_panel:
			choices_panel.visible = false
		if continue_btn:
			continue_btn.visible = true
		if next_icon:
			next_icon.visible = true
		return

	if choices_panel:
		choices_panel.visible = true
	if continue_btn:
		continue_btn.visible = false
	if next_icon:
		next_icon.visible = false

	# Build authentic Option buttons
	for i in range(choices.size()):
		var choice_data: Dictionary = choices[i]
		var btn: Button = Button.new()
		btn.text = choice_data.get("text", "Option %d" % (i + 1))
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(260, 26)

		# Style the button using authentic parchment texture
		_apply_choice_button_style(btn)

		var act: Callable = choice_data.get("action", Callable())
		var idx: int = i
		btn.pressed.connect(func():
			if act.is_valid():
				act.call()
			choice_selected.emit(idx)
			visible = false
			dialogue_finished.emit()
		)
		choices_container.add_child(btn)

## Applies authentic WLO parchment theme styling to choice buttons.
func _apply_choice_button_style(btn: Button) -> void:
	btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.85, 0.6, 1.0))
	btn.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.0, 1.0))
	btn.add_theme_constant_override("outline_size", 2)
	btn.add_theme_font_size_override("font_size", 11)

	# Textures for Options buttons
	if ResourceLoader.exists("res://assets/hud/dialogue_choice_btn.png"):
		var norm_tex: Texture2D = load("res://assets/hud/dialogue_choice_btn.png")
		var s_norm: StyleBoxTexture = StyleBoxTexture.new()
		s_norm.texture = norm_tex
		s_norm.texture_margin_left = 10
		s_norm.texture_margin_right = 10
		s_norm.texture_margin_top = 8
		s_norm.texture_margin_bottom = 8
		btn.add_theme_stylebox_override("normal", s_norm)

	if ResourceLoader.exists("res://assets/hud/dialogue_choice_hover.png"):
		var hov_tex: Texture2D = load("res://assets/hud/dialogue_choice_hover.png")
		var s_hov: StyleBoxTexture = StyleBoxTexture.new()
		s_hov.texture = hov_tex
		s_hov.texture_margin_left = 10
		s_hov.texture_margin_right = 10
		s_hov.texture_margin_top = 8
		s_hov.texture_margin_bottom = 8
		btn.add_theme_stylebox_override("hover", s_hov)
		btn.add_theme_stylebox_override("pressed", s_hov)
		btn.add_theme_stylebox_override("focus", s_hov)

func _on_continue_pressed() -> void:
	visible = false
	dialogue_finished.emit()

func _on_close_button_pressed() -> void:
	visible = false
	dialogue_finished.emit()
