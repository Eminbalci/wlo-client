class_name DialogueBox
extends Control

## Wonderland Online Flexible & Responsive Dialogue Box
## Responsive bottom-center layout, dynamic left/right speaker avatars,
## BBCode typewriter RichTextLabel, paging, and interactive branching choices with SFX.

signal dialogue_started(speaker: String)
signal dialogue_finished()
signal page_changed(current_page: int, total_pages: int)
signal typewriter_completed()
signal choice_selected(choice_index: int, choice_text: String)

enum SpeakerSide {
	LEFT,
	RIGHT,
	NONE,
	BOTH
}

enum BoxPreset {
	BOTTOM_CENTER,
	TOP_CENTER,
	CENTER,
	CUSTOM
}

# --- Responsive Layout Settings ---
@export var box_preset: BoxPreset = BoxPreset.BOTTOM_CENTER
@export var bottom_margin: float = 20.0
@export var top_margin: float = 20.0
@export var box_width: float = 768.0
@export var box_height: float = 170.0
@export var auto_responsive: bool = true

# --- Typewriter & Paging Settings ---
@export var typewriter_speed: float = 38.0 ## Characters per second
@export var auto_advance_delay: float = 0.0 ## 0.0 = manual advance only

# --- Speaker & Avatar Settings ---
@export var speaker_side: SpeakerSide = SpeakerSide.LEFT

# --- Node References ---
var background_rect: TextureRect = null
var content_container: Control = null
var speaker_badge: PanelContainer = null
var speaker_label: Label = null
var text_label: RichTextLabel = null
var next_icon: TextureRect = null
var page_label: Label = null

var portrait_frame_left: Control = null
var portrait_rect_left: TextureRect = null
var portrait_frame_right: Control = null
var portrait_rect_right: TextureRect = null

var choices_panel: Control = null
var choices_container: Container = null

var sfx_player: AudioStreamPlayer = null

# Backward compatibility alias
var content_label: Object:
	get:
		return text_label

# --- State Variables ---
var _dialogue_pages: Array[String] = []
var _current_page_index: int = 0
var _current_choices: Array = []
var _is_typing: bool = false
var _typewriter_progress: float = 0.0
var _typewriter_total_chars: int = 0
var _typewriter_tween: Tween = null
var _next_icon_tween: Tween = null

# Portrait animation buffers (Frame 0: talk, Frame 1: blink)
var _portrait_frames_left: Array[Texture2D] = []
var _portrait_frames_right: Array[Texture2D] = []
var _portrait_anim_timer: float = 0.0
var _portrait_frame_index: int = 0

# SFX Streams
var _sfx_choice_click: AudioStream = null
var _sfx_reward: AudioStream = null

func _enter_tree() -> void:
	ensure_initialized()
	if auto_responsive and get_viewport():
		if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
			get_viewport().size_changed.connect(_on_viewport_size_changed)

func _exit_tree() -> void:
	if get_viewport() and get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.disconnect(_on_viewport_size_changed)

func _ready() -> void:
	ensure_initialized()
	visible = false

## Ensures all children, skins, and audio streams are resolved even if accessed before _ready
func ensure_initialized() -> void:
	if background_rect == null:
		_resolve_child_nodes()
		_load_authentic_skins()
		_load_sfx_streams()
		_setup_next_icon_animation()
		_apply_layout_preset()
		_apply_speaker_side()

func _resolve_child_nodes() -> void:
	background_rect = find_child("Background", true, false) as TextureRect
	if not background_rect:
		background_rect = find_child("TalkBackground", true, false) as TextureRect

	content_container = find_child("ContentContainer", true, false) as Control

	speaker_badge = find_child("SpeakerBadge", true, false) as PanelContainer
	speaker_label = find_child("SpeakerLabel", true, false) as Label
	if not speaker_label:
		speaker_label = find_child("SpeakerNameplate", true, false) as Label

	text_label = find_child("TextLabel", true, false) as RichTextLabel
	if not text_label:
		text_label = find_child("DialogueText", true, false) as RichTextLabel

	next_icon = find_child("NextIcon", true, false) as TextureRect
	page_label = find_child("PageLabel", true, false) as Label

	portrait_frame_left = find_child("PortraitFrameLeft", true, false) as Control
	if not portrait_frame_left:
		portrait_frame_left = find_child("PortraitFrame", true, false) as Control
	portrait_rect_left = find_child("PortraitLeft", true, false) as TextureRect
	if not portrait_rect_left and portrait_frame_left:
		portrait_rect_left = portrait_frame_left.find_child("PortraitTexture", true, false) as TextureRect
	if not portrait_rect_left and portrait_frame_left:
		portrait_rect_left = portrait_frame_left.find_child("PortraitRect", true, false) as TextureRect

	portrait_frame_right = find_child("PortraitFrameRight", true, false) as Control
	portrait_rect_right = find_child("PortraitRight", true, false) as TextureRect

	choices_panel = find_child("ChoicesPanel", true, false) as Control
	if not choices_panel:
		choices_panel = find_child("FormTalk3", true, false) as Control

	choices_container = find_child("ChoicesContainer", true, false) as Container
	if not choices_container and choices_panel:
		choices_container = choices_panel.find_child("ChoiceList", true, false) as Container

	sfx_player = find_child("SFXPlayer", true, false) as AudioStreamPlayer
	if not sfx_player:
		sfx_player = AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer"
		add_child(sfx_player)

func _process(delta: float) -> void:
	if not visible:
		return

	# Animate portraits when speaking
	if _portrait_frames_left.size() > 1 or _portrait_frames_right.size() > 1:
		_portrait_anim_timer += delta
		if _portrait_anim_timer >= 0.25:
			_portrait_anim_timer = 0.0
			_portrait_frame_index = (_portrait_frame_index + 1) % 2
			if _portrait_frames_left.size() > _portrait_frame_index and portrait_rect_left:
				portrait_rect_left.texture = _portrait_frames_left[_portrait_frame_index]
			if _portrait_frames_right.size() > _portrait_frame_index and portrait_rect_right:
				portrait_rect_right.texture = _portrait_frames_right[_portrait_frame_index]

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if auto_responsive and is_inside_tree():
			_apply_layout_preset()

func _on_viewport_size_changed() -> void:
	if auto_responsive and is_inside_tree():
		_apply_layout_preset()

# ==============================================================================
# Responsive Layout Engine
# ==============================================================================

## Sets and applies layout preset with responsive bottom-center anchoring
func set_box_preset(p_preset: BoxPreset) -> void:
	ensure_initialized()
	box_preset = p_preset
	_apply_layout_preset()

## Updates the dialogue box dimensions and screen anchoring
func set_box_dimensions(p_width: float, p_height: float, p_bottom_margin: float = 20.0) -> void:
	ensure_initialized()
	box_width = p_width
	box_height = p_height
	bottom_margin = p_bottom_margin
	_apply_layout_preset()

func _apply_layout_preset() -> void:
	var vp_size: Vector2 = get_viewport_rect().size if get_viewport() else Vector2(1280, 720)
	if vp_size.x <= 0 or vp_size.y <= 0:
		vp_size = Vector2(1280, 720)

	var target_w: float = minf(box_width, vp_size.x - 20.0)
	var target_h: float = box_height

	custom_minimum_size = Vector2(target_w, target_h)

	match box_preset:
		BoxPreset.BOTTOM_CENTER:
			set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
			anchor_left = 0.5
			anchor_right = 0.5
			anchor_top = 1.0
			anchor_bottom = 1.0
			offset_left = -target_w * 0.5
			offset_right = target_w * 0.5
			offset_bottom = -bottom_margin
			offset_top = -bottom_margin - target_h
			grow_horizontal = Control.GROW_DIRECTION_BOTH
			grow_vertical = Control.GROW_DIRECTION_BEGIN

		BoxPreset.TOP_CENTER:
			set_anchors_preset(Control.PRESET_CENTER_TOP)
			anchor_left = 0.5
			anchor_right = 0.5
			anchor_top = 0.0
			anchor_bottom = 0.0
			offset_left = -target_w * 0.5
			offset_right = target_w * 0.5
			offset_top = top_margin
			offset_bottom = top_margin + target_h
			grow_horizontal = Control.GROW_DIRECTION_BOTH
			grow_vertical = Control.GROW_DIRECTION_END

		BoxPreset.CENTER:
			set_anchors_preset(Control.PRESET_CENTER)
			anchor_left = 0.5
			anchor_right = 0.5
			anchor_top = 0.5
			anchor_bottom = 0.5
			offset_left = -target_w * 0.5
			offset_right = target_w * 0.5
			offset_top = -target_h * 0.5
			offset_bottom = target_h * 0.5
			grow_horizontal = Control.GROW_DIRECTION_BOTH
			grow_vertical = Control.GROW_DIRECTION_BOTH

		BoxPreset.CUSTOM:
			pass

	_reposition_internal_elements(target_w, target_h)

func _reposition_internal_elements(target_w: float, target_h: float) -> void:
	if background_rect:
		background_rect.offset_left = 0.0
		background_rect.offset_top = 0.0
		background_rect.offset_right = target_w
		background_rect.offset_bottom = target_h

	_apply_speaker_side()

# ==============================================================================
# Dynamic Avatar Placement Engine (Left / Right / Both / None)
# ==============================================================================

## Configures active speaker side and dynamically shifts text layout
func set_speaker_side(p_side: SpeakerSide) -> void:
	ensure_initialized()
	speaker_side = p_side
	_apply_speaker_side()

func _apply_speaker_side() -> void:
	var total_w: float = size.x if size.x > 0 else box_width
	var total_h: float = size.y if size.y > 0 else box_height

	var portrait_size: Vector2 = Vector2(96.0, 96.0)
	var left_pad: float = 35.0
	var right_pad: float = 35.0

	# Left Portrait
	if portrait_frame_left:
		portrait_frame_left.custom_minimum_size = portrait_size
		portrait_frame_left.offset_left = 32.0
		portrait_frame_left.offset_top = (total_h - portrait_size.y) * 0.5
		portrait_frame_left.offset_right = portrait_frame_left.offset_left + portrait_size.x
		portrait_frame_left.offset_bottom = portrait_frame_left.offset_top + portrait_size.y

	# Right Portrait
	if portrait_frame_right:
		portrait_frame_right.custom_minimum_size = portrait_size
		portrait_frame_right.offset_right = total_w - 32.0
		portrait_frame_right.offset_left = portrait_frame_right.offset_right - portrait_size.x
		portrait_frame_right.offset_top = (total_h - portrait_size.y) * 0.5
		portrait_frame_right.offset_bottom = portrait_frame_right.offset_top + portrait_size.y

	match speaker_side:
		SpeakerSide.LEFT:
			if portrait_frame_left: portrait_frame_left.visible = true
			if portrait_frame_right: portrait_frame_right.visible = false
			left_pad = 148.0
			right_pad = 40.0

		SpeakerSide.RIGHT:
			if portrait_frame_left: portrait_frame_left.visible = false
			if portrait_frame_right: portrait_frame_right.visible = true
			left_pad = 40.0
			right_pad = 148.0

		SpeakerSide.BOTH:
			if portrait_frame_left: portrait_frame_left.visible = true
			if portrait_frame_right: portrait_frame_right.visible = true
			left_pad = 148.0
			right_pad = 148.0

		SpeakerSide.NONE:
			if portrait_frame_left: portrait_frame_left.visible = false
			if portrait_frame_right: portrait_frame_right.visible = false
			left_pad = 40.0
			right_pad = 40.0

	# Adjust Content Container bounds
	if content_container:
		content_container.offset_left = left_pad
		content_container.offset_top = 18.0
		content_container.offset_right = total_w - right_pad
		content_container.offset_bottom = total_h - 18.0

	# Adjust NextIcon position
	if next_icon:
		next_icon.offset_right = total_w - (right_pad if speaker_side == SpeakerSide.RIGHT or speaker_side == SpeakerSide.BOTH else 28.0)
		next_icon.offset_left = next_icon.offset_right - 25.0
		next_icon.offset_bottom = total_h - 18.0
		next_icon.offset_top = next_icon.offset_bottom - 31.0

# ==============================================================================
# Skin & SFX Asset Loaders
# ==============================================================================

func _load_authentic_skins() -> void:
	var loader := _get_archive_loader()

	# 1. Main Background Parchment (Form_Talk_2.bmp / TalkForm1.bmp / Panel_TalkForm.bmp)
	if background_rect:
		var bg_tex: Texture2D = null
		if loader and loader.has_method("get_ui_texture"):
			bg_tex = loader.get_ui_texture("menu/Skins/white/Form_Talk_2.bmp")
			if not bg_tex:
				bg_tex = loader.get_ui_texture("menu/Skins/white/TalkForm1.bmp")
			if not bg_tex:
				bg_tex = loader.get_ui_texture("menu/Skins/default/Panel_TalkForm.bmp")

		if not bg_tex:
			var candidates: Array[String] = [
				"res://assets/menu/Skins/white/Form_Talk_2.bmp",
				"res://assets/menu/Skins/white/TalkForm1.bmp",
				"res://assets/menu/Skins/default/Panel_TalkForm.bmp",
				"res://assets/hud/Panel_TalkForm.bmp",
				"res://assets/hud/dialogue_box_bg.png"
			]
			for p in candidates:
				if ResourceLoader.exists(p):
					bg_tex = load(p)
					break

		if bg_tex:
			background_rect.texture = bg_tex
			background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			background_rect.stretch_mode = TextureRect.STRETCH_SCALE

	# 2. Next Page Indicator Icon (Icon_Nextone_1.bmp or dialogue_arrow_next.png)
	if next_icon and not next_icon.texture:
		var icon_tex: Texture2D = null
		if loader and loader.has_method("get_ui_texture"):
			var sheet = loader.get_ui_texture("menu/Skins/default/Icon_Nextone_1.bmp")
			if sheet:
				var atlas := AtlasTexture.new()
				atlas.atlas = sheet
				atlas.region = Rect2(0, 0, 25, 31)
				icon_tex = atlas

		if not icon_tex and ResourceLoader.exists("res://assets/hud/dialogue_arrow_next.png"):
			icon_tex = load("res://assets/hud/dialogue_arrow_next.png")

		if icon_tex:
			next_icon.texture = icon_tex
			next_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			next_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# 3. Choice Box Panel Background (Form_Talk_3.bmp)
	if choices_panel:
		var choice_bg = choices_panel.find_child("ChoiceBackground", true, false) as TextureRect
		if choice_bg and not choice_bg.texture:
			var c_tex: Texture2D = null
			if loader and loader.has_method("get_ui_texture"):
				c_tex = loader.get_ui_texture("menu/Skins/white/Form_Talk_3.bmp")
			if not c_tex and ResourceLoader.exists("res://assets/menu/Skins/white/Form_Talk_3.bmp"):
				c_tex = load("res://assets/menu/Skins/white/Form_Talk_3.bmp")
			if c_tex:
				choice_bg.texture = c_tex
				choice_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				choice_bg.stretch_mode = TextureRect.STRETCH_SCALE

func _load_sfx_streams() -> void:
	var sfx_paths: Array[String] = [
		"res://assets/sound/wav0151.wav",
		"res://assets/sound/wav0151.WAV",
		"res://assets/sound/0151.wav"
	]
	for p in sfx_paths:
		if ResourceLoader.exists(p):
			_sfx_choice_click = load(p)
			break

	var reward_paths: Array[String] = [
		"res://assets/sound/wav9911.wav",
		"res://assets/sound/9911.wav"
	]
	for p in reward_paths:
		if ResourceLoader.exists(p):
			_sfx_reward = load(p)
			break

func _setup_next_icon_animation() -> void:
	if not next_icon:
		return
	if _next_icon_tween and _next_icon_tween.is_valid():
		_next_icon_tween.kill()

	_next_icon_tween = create_tween().set_loops()
	_next_icon_tween.tween_property(next_icon, "modulate:a", 0.25, 0.35)
	_next_icon_tween.tween_property(next_icon, "modulate:a", 1.0, 0.35)

# ==============================================================================
# Public Dialogue Display API
# ==============================================================================

## Displays single-page or multi-page dialogue sequence with choices and speaker positioning
func show_dialogue(
	speaker: String,
	text: String,
	choices: Array = [],
	portrait_tex: Texture2D = null,
	portrait_id: int = 0,
	p_speaker_side: SpeakerSide = SpeakerSide.LEFT,
	portrait_frames: Array = []
) -> void:
	show_dialogue_sequence(
		speaker,
		[text],
		choices,
		portrait_tex,
		portrait_id,
		p_speaker_side,
		portrait_frames
	)

## Starts a multi-page dialogue sequence
func show_dialogue_sequence(
	speaker: String,
	pages: Array,
	choices: Array = [],
	portrait_tex: Texture2D = null,
	portrait_id: int = 0,
	p_speaker_side: SpeakerSide = SpeakerSide.LEFT,
	portrait_frames: Array = []
) -> void:
	ensure_initialized()

	_dialogue_pages.clear()
	for p in pages:
		_dialogue_pages.append(str(p))

	if _dialogue_pages.is_empty():
		_dialogue_pages.append("")

	_current_page_index = 0
	_current_choices = choices

	# Speaker Badge
	set_speaker_name(speaker)

	# Speaker Side
	set_speaker_side(p_speaker_side)

	# Portrait setup
	_setup_portrait(portrait_tex, portrait_id, portrait_frames, p_speaker_side)

	# Display first page
	_display_current_page()

	visible = true
	dialogue_started.emit(speaker)

## Sets speaker name in badge
func set_speaker_name(speaker: String) -> void:
	ensure_initialized()
	if speaker_label:
		speaker_label.text = speaker if not speaker.is_empty() else "NPC"
	if speaker_badge:
		speaker_badge.visible = not speaker.is_empty()

## Hides dialogue and choices cleanly
func hide_dialogue() -> void:
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()
	_is_typing = false
	visible = false
	if choices_panel:
		choices_panel.visible = false
	dialogue_finished.emit()

## Advances to next dialogue page or reveals options
func advance_dialogue() -> void:
	ensure_initialized()
	if not visible:
		return

	# If currently typing, skip typewriter effect first
	if _is_typing:
		_skip_typewriter()
		return

	# If choices are presented, don't advance past choices
	if choices_panel and choices_panel.visible:
		return

	_current_page_index += 1
	if _current_page_index < _dialogue_pages.size():
		_display_current_page()
	else:
		# Final page reached: show choices if pending, else finish
		if not _current_choices.is_empty():
			_show_choices(_current_choices)
		else:
			hide_dialogue()

# ==============================================================================
# Typewriter & Text Formatting Engine
# ==============================================================================

func _display_current_page() -> void:
	if _current_page_index < 0 or _current_page_index >= _dialogue_pages.size():
		return

	var raw_page: String = _dialogue_pages[_current_page_index]
	var formatted_text: String = parse_wlo_tokens(raw_page)

	if text_label:
		text_label.text = formatted_text
		text_label.visible_characters = 0

	# Update page counter indicator
	if page_label:
		if _dialogue_pages.size() > 1:
			page_label.text = "%d / %d" % [_current_page_index + 1, _dialogue_pages.size()]
			page_label.visible = true
		else:
			page_label.visible = false

	if next_icon:
		next_icon.visible = false

	if choices_panel:
		choices_panel.visible = false

	# Notify page change
	page_changed.emit(_current_page_index, _dialogue_pages.size())

	# Start Typewriter
	_start_typewriter()

func _start_typewriter() -> void:
	if not text_label:
		_on_typewriter_finished()
		return

	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()

	var plain_length: int = text_label.get_parsed_text().length()
	_typewriter_total_chars = plain_length

	if plain_length <= 0 or typewriter_speed <= 0.0:
		text_label.visible_characters = -1
		_on_typewriter_finished()
		return

	_is_typing = true
	var duration: float = clampf(float(plain_length) / typewriter_speed, 0.2, 3.5)

	_typewriter_tween = create_tween()
	_typewriter_tween.tween_property(text_label, "visible_characters", plain_length, duration)
	_typewriter_tween.finished.connect(_on_typewriter_finished)

func _skip_typewriter() -> void:
	if not _is_typing:
		return
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()
	if text_label:
		text_label.visible_characters = -1
	_on_typewriter_finished()

func _on_typewriter_finished() -> void:
	_is_typing = false
	typewriter_completed.emit()

	var is_final_page: bool = (_current_page_index >= _dialogue_pages.size() - 1)

	if is_final_page and not _current_choices.is_empty():
		_show_choices(_current_choices)
		if next_icon:
			next_icon.visible = false
	else:
		if next_icon:
			next_icon.visible = true

## Parses authentic Wonderland Online token format to Godot BBCode
static func parse_wlo_tokens(raw_text: String, player_name: String = "") -> String:
	var parsed: String = raw_text

	# Player name token #n or #n/#n
	if player_name.is_empty():
		var loop = Engine.get_main_loop()
		if loop is SceneTree and loop.root and loop.root.has_node("GameDatabase"):
			var db = loop.root.get_node("GameDatabase")
			if "active_character" in db and db.active_character is Dictionary:
				player_name = str(db.active_character.get("name", "Daniel"))
		if player_name.is_empty():
			player_name = "Daniel"

	parsed = parsed.replace("#n/#n", player_name).replace("#n", player_name)

	# Colors: #R (Red), #B (Blue/Cyan), #G (Green), #Y (Gold/Yellow)
	# Supports authentic #R...#R, #R...#W, and bracketed #[Rr]...#[Rr]
	var reg_r := RegEx.new()
	reg_r.compile("#\\[?[Rr]\\]?(.*?)(?:/?#\\[?[Rr]\\]?|#[Ww]|$)")
	parsed = reg_r.sub(parsed, "[color=red]$1[/color]", true)

	var reg_b := RegEx.new()
	reg_b.compile("#\\[?[Bb]\\]?(.*?)(?:/?#\\[?[Bb]\\]?|#[Ww]|$)")
	parsed = reg_b.sub(parsed, "[color=deep_sky_blue]$1[/color]", true)

	var reg_g := RegEx.new()
	reg_g.compile("#\\[?[Gg]\\]?(.*?)(?:/?#\\[?[Gg]\\]?|#[Ww]|$)")
	parsed = reg_g.sub(parsed, "[color=green]$1[/color]", true)

	var reg_y := RegEx.new()
	reg_y.compile("#\\[?[Yy]\\]?(.*?)(?:/?#\\[?[Yy]\\]?|#[Ww]|$)")
	parsed = reg_y.sub(parsed, "[color=yellow]$1[/color]", true)

	# Strip sound and face tags (#s402, #f3, #s01/#s, #f01/#f)
	var reg_sound := RegEx.new()
	reg_sound.compile("#[sS]([0-9]+)(?:/#[sS]|\\b)")
	parsed = reg_sound.sub(parsed, "", true)

	var reg_face := RegEx.new()
	reg_face.compile("#[fF]([0-9]+)(?:/#[fF]|\\b)")
	parsed = reg_face.sub(parsed, "", true)

	# Strip leftover unknown control tags e.g. #abc/#abc
	var reg_clean := RegEx.new()
	reg_clean.compile("#[a-zA-Z0-9_-]+(?:/#[a-zA-Z0-9_-]+)?")
	parsed = reg_clean.sub(parsed, "", true)

	return parsed.strip_edges()

# ==============================================================================
# Choice & Branching Option Engine
# ==============================================================================

func _show_choices(choices: Array) -> void:
	if not choices_panel or not choices_container:
		return

	for child in choices_container.get_children():
		choices_container.remove_child(child)
		child.queue_free()

	if choices.is_empty():
		choices_panel.visible = false
		return

	# Support flexible Grid vs Vertical list layout
	if choices_container is GridContainer:
		var grid := choices_container as GridContainer
		grid.columns = 2 if choices.size() > 4 else 1

	for i in range(choices.size()):
		var choice_entry = choices[i]
		var choice_text: String = ""
		var choice_action: Callable = Callable()

		if choice_entry is Dictionary:
			choice_text = str(choice_entry.get("text", "Option %d" % (i + 1)))
			choice_action = choice_entry.get("action", Callable())
		else:
			choice_text = str(choice_entry)

		var btn := Button.new()
		btn.name = "ChoiceBtn_%d" % i
		btn.text = "%d. %s" % [i + 1, choice_text]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(240.0, 26.0)
		btn.focus_mode = Control.FOCUS_ALL

		_apply_choice_button_styling(btn)

		var idx: int = i
		var txt: String = choice_text
		var act: Callable = choice_action

		btn.pressed.connect(func():
			_play_sfx(_sfx_choice_click)
			if act.is_valid():
				act.call()
			choice_selected.emit(idx, txt)
			hide_dialogue()
		)

		choices_container.add_child(btn)

	choices_panel.visible = true

	# Focus first button for immediate keyboard accessibility
	if choices_container.get_child_count() > 0:
		var first_btn = choices_container.get_child(0) as Button
		if first_btn and first_btn.is_inside_tree():
			first_btn.grab_focus()

func _apply_choice_button_styling(btn: Button) -> void:
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.9, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.88, 0.2, 1.0))
	btn.add_theme_color_override("font_focus_color", Color(1.0, 0.92, 0.35, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.85, 0.75, 0.15, 1.0))
	btn.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.0, 1.0))
	btn.add_theme_constant_override("outline_size", 2)

	# Apply authentic parchment button textures if available
	if ResourceLoader.exists("res://assets/hud/dialogue_choice_btn.png"):
		var norm_tex: Texture2D = load("res://assets/hud/dialogue_choice_btn.png")
		var s_norm := StyleBoxTexture.new()
		s_norm.texture = norm_tex
		s_norm.texture_margin_left = 10
		s_norm.texture_margin_right = 10
		s_norm.texture_margin_top = 6
		s_norm.texture_margin_bottom = 6
		btn.add_theme_stylebox_override("normal", s_norm)

	if ResourceLoader.exists("res://assets/hud/dialogue_choice_hover.png"):
		var hov_tex: Texture2D = load("res://assets/hud/dialogue_choice_hover.png")
		var s_hov := StyleBoxTexture.new()
		s_hov.texture = hov_tex
		s_hov.texture_margin_left = 10
		s_hov.texture_margin_right = 10
		s_hov.texture_margin_top = 6
		s_hov.texture_margin_bottom = 6
		btn.add_theme_stylebox_override("hover", s_hov)
		btn.add_theme_stylebox_override("focus", s_hov)
		btn.add_theme_stylebox_override("pressed", s_hov)
	else:
		btn.flat = true

# ==============================================================================
# Keyboard & Mouse Input Handling
# ==============================================================================

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		advance_dialogue()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	# Mouse Left Click advances dialogue when choices are not showing
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not (choices_panel and choices_panel.visible):
			advance_dialogue()
			if get_viewport():
				get_viewport().set_input_as_handled()
			return

	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	var key_event := event as InputEventKey

	# Number keys 1..9 for instant choice selection
	if choices_panel and choices_panel.visible and choices_container:
		var key_code: int = key_event.keycode
		var choice_idx: int = -1
		if key_code >= KEY_1 and key_code <= KEY_9:
			choice_idx = key_code - KEY_1
		elif key_code >= KEY_KP_1 and key_code <= KEY_KP_9:
			choice_idx = key_code - KEY_KP_1

		if choice_idx >= 0 and choice_idx < choices_container.get_child_count():
			var target_btn = choices_container.get_child(choice_idx) as Button
			if target_btn and target_btn.visible:
				target_btn.emit_signal("pressed")
				if get_viewport():
					get_viewport().set_input_as_handled()
				return

	# Space / Enter advances dialogue
	if key_event.keycode == KEY_SPACE or key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
		if not (choices_panel and choices_panel.visible):
			advance_dialogue()
			if get_viewport():
				get_viewport().set_input_as_handled()
			return

	# Escape closes dialogue
	if key_event.keycode == KEY_ESCAPE:
		hide_dialogue()
		if get_viewport():
			get_viewport().set_input_as_handled()
		return

# ==============================================================================
# Internal Helpers
# ==============================================================================

func _setup_portrait(
	custom_tex: Texture2D,
	portrait_id: int,
	portrait_frames: Array,
	side: SpeakerSide
) -> void:
	_portrait_frames_left.clear()
	_portrait_frames_right.clear()

	var frames: Array[Texture2D] = []
	if not portrait_frames.is_empty():
		for f in portrait_frames:
			if f is Texture2D:
				frames.append(f)
	elif custom_tex:
		frames.append(custom_tex)
	elif portrait_id > 0:
		var loader := _get_archive_loader()
		if loader and loader.has_method("get_avatar_frames"):
			var jma_frames = loader.get_avatar_frames(portrait_id)
			for f in jma_frames:
				frames.append(f)

	if frames.is_empty():
		# Fallback default portrait
		if ResourceLoader.exists("res://assets/hud/portraits/default_portrait.png"):
			frames.append(load("res://assets/hud/portraits/default_portrait.png"))

	if side == SpeakerSide.RIGHT:
		_portrait_frames_right = frames
		if portrait_rect_right and not frames.is_empty():
			portrait_rect_right.texture = frames[0]
	else:
		_portrait_frames_left = frames
		if portrait_rect_left and not frames.is_empty():
			portrait_rect_left.texture = frames[0]

func _play_sfx(stream: AudioStream) -> void:
	if not stream:
		return
	if not is_inside_tree():
		return
	if not sfx_player:
		sfx_player = AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer"
		add_child(sfx_player)
	sfx_player.stream = stream
	sfx_player.play()

func _get_archive_loader() -> Node:
	if is_inside_tree() and get_tree().root:
		return get_tree().root.get_node_or_null("ArchiveLoader")
	var loop = Engine.get_main_loop()
	if loop is SceneTree and loop.root:
		return loop.root.get_node_or_null("ArchiveLoader")
	return null
