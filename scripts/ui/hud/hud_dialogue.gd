class_name HUDDialogue
extends RefCounted

## Dedicated controller encapsulating the dual-form dialogue engine:
## FormTalk1 (NPC/Player dialogue, nameplate, typewriter text, animated portraits, blinking next icon)
## and FormTalk3 (branching choices), quest reward fanfare, and SFX playback.

const PillScript = preload("res://scripts/ui/hud/pill_button.gd")

var hud: Control = null

# FormTalk1 (768x169)
var dialogue_dock: Control = null
var dialogue_bg: TextureRect = null
var portrait_frame: Control = null
var portrait_rect: TextureRect = null
var speaker_label: Label = null
var dialogue_text: RichTextLabel = null
var next_icon: TextureRect = null

# FormTalk3 (324x168 Branching Choices)
var branching_dock: Control = null
var branching_bg: TextureRect = null
var choice_title: Label = null
var choices_container: VBoxContainer = null

# Dialogue State
var _dialogue_pages: Array[String] = []
var _dialogue_current_page: int = 0
var _current_choice_callback: Callable = Callable()
var _pending_choices: Array[String] = []

# Portrait Animation State
var _portrait_frames: Array[Texture2D] = []
var _portrait_frame_timer: float = 0.0
var _portrait_frame_index: int = 0

# Next-Page Icon Blinking (2 frames of 25x31)
var _next_icon_atlas: AtlasTexture = null
var _next_icon_timer: float = 0.0
var _next_icon_frame: int = 0

# SFX Player
var _sfx_player: AudioStreamPlayer = null

## Initializes and wires up the dialogue sub-controller with node references
func setup(p_hud: Control, nodes: Dictionary) -> void:
	hud = p_hud

	dialogue_dock = nodes.get("dialogue_dock", null) as Control
	dialogue_bg = nodes.get("dialogue_bg", null) as TextureRect
	portrait_frame = nodes.get("portrait_frame", null) as Control
	portrait_rect = nodes.get("portrait_rect", null) as TextureRect
	speaker_label = nodes.get("speaker_label", null) as Label
	dialogue_text = nodes.get("dialogue_text", null) as RichTextLabel
	next_icon = nodes.get("next_icon", null) as TextureRect

	branching_dock = nodes.get("branching_dock", null) as Control
	branching_bg = nodes.get("branching_bg", null) as TextureRect
	choice_title = nodes.get("choice_title", null) as Label
	choices_container = nodes.get("choices_container", null) as VBoxContainer

	_setup_audio_player()
	_setup_authentic_textures()
	_style_dialogue_text()
	_setup_click_handlers()

	if dialogue_dock:
		dialogue_dock.visible = false
	if branching_dock:
		branching_dock.visible = false

## Per-frame animation for next-page blinking icon and animated talking portrait
func process(delta: float) -> void:
	# Animate blinking next-page icon (2 frames of 25x31)
	if dialogue_dock and dialogue_dock.visible and _next_icon_atlas:
		_next_icon_timer += delta
		if _next_icon_timer >= 0.35:
			_next_icon_timer = 0.0
			_next_icon_frame = 1 - _next_icon_frame
			_next_icon_atlas.region = Rect2(0, _next_icon_frame * 31, 25, 31)

	# Animate talking/blinking portrait frames
	if dialogue_dock and dialogue_dock.visible and _portrait_frames.size() > 1 and portrait_rect:
		_portrait_frame_timer += delta
		if _portrait_frame_timer >= 0.25:
			_portrait_frame_timer = 0.0
			_portrait_frame_index = (_portrait_frame_index + 1) % _portrait_frames.size()
			portrait_rect.texture = _portrait_frames[_portrait_frame_index]

## Handles keyboard and mouse shortcuts for dialogue advancement and closing
func handle_unhandled_input(event: InputEvent) -> bool:
	# Mouse left-click anywhere on screen advances dialogue if active
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if dialogue_dock and dialogue_dock.visible and not (branching_dock and branching_dock.visible):
			advance_dialogue()
			return true

	if not (event is InputEventKey) or not event.pressed or event.echo:
		return false

	var key_event := event as InputEventKey

	# Dialogue advancement via Space or Enter (when chat input not active)
	if dialogue_dock and dialogue_dock.visible and not (branching_dock and branching_dock.visible):
		var chat_has_focus: bool = false
		if hud:
			var chat_in := hud.get_node_or_null("ChatDock/ChatInput") as LineEdit
			if chat_in and chat_in.has_focus():
				chat_has_focus = true

		if not chat_has_focus:
			if key_event.keycode == KEY_SPACE or key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
				advance_dialogue()
				return true

	# Escape key closes active dialogue or choices
	if key_event.keycode == KEY_ESCAPE:
		if branching_dock and branching_dock.visible:
			hide_choices()
			return true
		elif dialogue_dock and dialogue_dock.visible:
			hide_dialogue()
			return true

	return false

## Returns true if either dialogue window or branching choices dock is currently visible
func is_dialogue_active() -> bool:
	return (dialogue_dock != null and dialogue_dock.visible) or (branching_dock != null and branching_dock.visible)

## Starts a multi-page dialogue sequence in FormTalk1 with optional choices and SFX
func show_dialogue_sequence(
	speaker: String, pages: Array[String], portrait_id: int = 0,
	choices_text: Variant = "", choice_cb: Callable = Callable(), sfx_name: String = ""
) -> void:
	if not sfx_name.is_empty():
		play_sfx(sfx_name)

	_dialogue_pages = pages
	_dialogue_current_page = 0
	_current_choice_callback = choice_cb

	if speaker_label:
		speaker_label.text = speaker if not speaker.is_empty() else "NPC"

	_portrait_frames.clear()
	var target_tid: int = portrait_id
	if target_tid <= 0:
		var s_low := speaker.to_lower()
		if "captain" in s_low: target_tid = 8025
		elif "kelang" in s_low or "kelan" in s_low: target_tid = 8038
		elif "jack" in s_low: target_tid = 8004
		elif "ross" in s_low: target_tid = 8005
		elif "drunk" in s_low or "peter" in s_low or "john" in s_low: target_tid = 8017
		elif "natasha" in s_low: target_tid = 8083
		elif "breillat" in s_low: target_tid = 8092
		elif "chef" in s_low or "cook" in s_low: target_tid = 8021
		elif "crew" in s_low or "sailor" in s_low: target_tid = 8026
		elif "girl" in s_low: target_tid = 8003
		elif "visitor" in s_low: target_tid = 8013

	_update_portrait(target_tid)

	# Parse choices if passed as String or Array
	var parsed_choices: Array[String] = []
	if choices_text is String and not (choices_text as String).is_empty():
		var raw_str := choices_text as String
		var delimiter := "|" if "|" in raw_str else "\n"
		var parts := raw_str.split(delimiter, false)
		for p in parts:
			var trimmed := p.strip_edges()
			if not trimmed.is_empty():
				parsed_choices.append(trimmed)
	elif choices_text is Array:
		for item in choices_text:
			parsed_choices.append(str(item))

	_pending_choices = parsed_choices

	if _dialogue_pages.size() > 0:
		if dialogue_text:
			dialogue_text.text = _dialogue_pages[0]
		if dialogue_dock:
			dialogue_dock.visible = true
		if branching_dock:
			branching_dock.visible = false
	else:
		if dialogue_dock:
			dialogue_dock.visible = false

	if _pending_choices.size() > 0 and _dialogue_pages.size() <= 1:
		var choices_to_show := _pending_choices
		_pending_choices = []
		show_choices(choices_to_show, choice_cb)

## Displays single-page dialogue with speaker, text, portrait texture or portrait_id, and choices
func show_dialogue(
	speaker: String, text: String, portrait_tex: Texture2D = null,
	choices: Array = [], portrait_id: int = 0,
	choice_cb: Callable = Callable(), portrait_frames: Array = []
) -> void:
	if speaker_label:
		speaker_label.text = speaker if not speaker.is_empty() else "NPC"
	if dialogue_text:
		dialogue_text.text = text
	_dialogue_pages = [text]
	_dialogue_current_page = 0
	_current_choice_callback = choice_cb
	_pending_choices = []

	_portrait_frames.clear()
	if not portrait_frames.is_empty():
		for f in portrait_frames:
			if f is Texture2D:
				_portrait_frames.append(f)
	elif portrait_tex:
		_portrait_frames.append(portrait_tex)
	else:
		var target_tid: int = portrait_id
		if target_tid <= 0:
			var s_low := speaker.to_lower()
			if "captain" in s_low: target_tid = 8025
			elif "kelang" in s_low or "kelan" in s_low: target_tid = 8038
			elif "jack" in s_low: target_tid = 8004
			elif "ross" in s_low: target_tid = 8005
			elif "drunk" in s_low or "peter" in s_low or "john" in s_low: target_tid = 8017
			elif "natasha" in s_low: target_tid = 8083
			elif "breillat" in s_low: target_tid = 8092
			elif "chef" in s_low or "cook" in s_low: target_tid = 8021
			elif "crew" in s_low or "sailor" in s_low: target_tid = 8026
			elif "girl" in s_low: target_tid = 8003
			elif "visitor" in s_low: target_tid = 8013
		if target_tid <= 0:
			target_tid = _talk_image_for_speaker(speaker)
		if target_tid > 0:
			_update_portrait(target_tid)

	if portrait_rect:
		if not _portrait_frames.is_empty():
			portrait_rect.texture = _portrait_frames[0]
			portrait_rect.visible = true
		elif portrait_tex:
			portrait_rect.texture = portrait_tex
			portrait_rect.visible = true

	var player_line := _is_player_speaker(speaker)
	var role: int = 6
	if hud and "character_status_ctrl" in hud and hud.character_status_ctrl:
		role = int(hud.character_status_ctrl.current_role_id)
	_apply_speaker_mode(player_line, role)
	if dialogue_dock:
		dialogue_dock.visible = true

	if choices.is_empty():
		if branching_dock:
			branching_dock.visible = false
	else:
		var str_choices: Array[String] = []
		for c in choices:
			str_choices.append(str(c))
		show_choices(str_choices, choice_cb)

## The frame is assembled like the original does: the two ends of Form_Talk_1 stay at native size and a slice cut from the
## middle is tiled to fill any width/height. The skin is already a 50% checker (every second pixel is chroma-key green),
## so every piece must land with the same pixel parity as in the source: the frame is an even width and an odd height.
const FRAME_SKIN: String = "res://assets/menu/Skins/white/Form_Talk_1.bmp"
const CAP_W: int = 200
const CAP_H: int = 45
var _frame_source: Image = null
var _frame_cache: Dictionary = {}


func _compose_frame(width: int, height: int) -> ImageTexture:
	var key := Vector2i(width, height)
	if _frame_cache.has(key):
		return _frame_cache[key]
	if _frame_source == null:
		var tex: Texture2D = load("res://scripts/ui/hud/skin_button.gd").keyed_texture(FRAME_SKIN)
		if tex == null:
			return null
		_frame_source = tex.get_image()
		_frame_source.convert(Image.FORMAT_RGBA8)
	var src := _frame_source
	var sw := src.get_width()
	var sh := src.get_height()
	var out := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var body := Rect2i(250, 60, 200, 50)
	for ty in range(0, height, body.size.y):
		for tx in range(0, width, body.size.x):
			out.blit_rect(src, body, Vector2i(tx, ty))
	var top_slice := Rect2i(250, 0, 200, CAP_H)
	var bottom_slice := Rect2i(250, sh - CAP_H, 200, CAP_H)
	for tx in range(CAP_W - 20, width - CAP_W + 20, top_slice.size.x):
		out.blit_rect(src, top_slice, Vector2i(tx, 0))
		out.blit_rect(src, bottom_slice, Vector2i(tx, height - CAP_H))
	var left_slice := Rect2i(0, 60, CAP_W, 50)
	var right_slice := Rect2i(sw - CAP_W, 60, CAP_W, 50)
	for ty in range(CAP_H - 5, height - CAP_H + 5, left_slice.size.y):
		out.blit_rect(src, left_slice, Vector2i(0, ty))
		out.blit_rect(src, right_slice, Vector2i(width - CAP_W, ty))
	out.blit_rect(src, Rect2i(0, 0, CAP_W, CAP_H), Vector2i(0, 0))
	out.blit_rect(src, Rect2i(sw - CAP_W, 0, CAP_W, CAP_H), Vector2i(width - CAP_W, 0))
	out.blit_rect(src, Rect2i(0, sh - CAP_H, CAP_W, CAP_H), Vector2i(0, height - CAP_H))
	out.blit_rect(src, Rect2i(sw - CAP_W, sh - CAP_H, CAP_W, CAP_H), Vector2i(width - CAP_W, height - CAP_H))
	var result := ImageTexture.create_from_image(out)
	_frame_cache[key] = result
	return result


## Pixel-style bold text with a dark shadow like the original dialogue font.
func _style_dialogue_text() -> void:
	if dialogue_text == null:
		return
	var pixel_font := SystemFont.new()
	pixel_font.font_names = PackedStringArray(["NSimSun", "SimSun", "MingLiU", "Courier New"])
	pixel_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	pixel_font.hinting = TextServer.HINTING_LIGHT
	pixel_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	pixel_font.font_weight = 700
	var fallback := load("res://assets/fonts/NotoSansTC-Regular.ttf") as Font
	if fallback:
		pixel_font.fallbacks = [fallback]
	for slot in ["normal_font", "bold_font"]:
		dialogue_text.add_theme_font_override(slot, pixel_font)
	for slot in ["normal_font_size", "bold_font_size"]:
		dialogue_text.add_theme_font_size_override(slot, 13)
	dialogue_text.add_theme_color_override("default_color", Color(1.0, 0.95, 0.25, 1.0))
	dialogue_text.add_theme_color_override("font_outline_color", Color(0.12, 0.1, 0.05, 1.0))
	dialogue_text.add_theme_constant_override("outline_size", 2)


func _refresh_frame() -> void:
	if dialogue_bg == null or dialogue_dock == null:
		return
	var w := int(round(dialogue_dock.offset_right - dialogue_dock.offset_left))
	var h := int(round(dialogue_dock.offset_bottom - dialogue_dock.offset_top))
	w += w % 2          # even width keeps the right end on the source's checker phase
	h += 1 - (h % 2)    # odd height keeps the bottom end on the source's checker phase
	if w < 2 * CAP_W or h < 2 * CAP_H:
		return
	var tex := _compose_frame(w, h)
	if tex:
		dialogue_bg.texture = tex
		dialogue_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		dialogue_bg.stretch_mode = TextureRect.STRETCH_SCALE
		dialogue_bg.modulate = Color(1, 1, 1, 1)


## Real client: when the PLAYER speaks, the frame sits at the bottom of the view without a portrait box and the
## character's full-body illustration (Btn_RolePic_<role>, first of three frames) stands at the lower left.
const PLAYER_TOP: float = 48.0
const PLAYER_FRAME_TOP_FROM_BOTTOM: float = -190.0
var _player_body: TextureRect = null


func _is_player_speaker(speaker: String) -> bool:
	var name_now := speaker.strip_edges().to_lower()
	if name_now == "player" or name_now == "you":
		return true
	if hud:
		var status = hud.character_status_ctrl if "character_status_ctrl" in hud else null
		if status and name_now == str(status.current_name).strip_edges().to_lower() and not name_now.is_empty():
			return true
	return false


func _apply_speaker_mode(is_player: bool, role_id: int) -> void:
	if dialogue_dock == null:
		return
	if portrait_frame:
		portrait_frame.visible = not is_player
	if speaker_label:
		speaker_label.visible = not is_player
	if _player_body:
		_player_body.visible = is_player
	if is_player:
		dialogue_dock.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		dialogue_dock.anchor_left = 0.5
		dialogue_dock.anchor_right = 0.5
		dialogue_dock.anchor_top = 1.0
		dialogue_dock.anchor_bottom = 1.0
		dialogue_dock.offset_left = -293.5
		dialogue_dock.offset_right = 293.5
		dialogue_dock.offset_top = -190.0
		dialogue_dock.offset_bottom = -21.0
		dialogue_dock.grow_vertical = Control.GROW_DIRECTION_BEGIN
		_refresh_frame()
		if dialogue_text:
			dialogue_text.position = Vector2(60, 40)
			dialogue_text.size = Vector2(480, 70)
			dialogue_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if _player_body == null:
			_player_body = TextureRect.new()
			_player_body.name = "PlayerBody"
			_player_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_player_body.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			_player_body.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			dialogue_dock.get_parent().add_child(_player_body)
		var sheet: Texture2D = load("res://scripts/ui/hud/skin_button.gd").keyed_texture("res://assets/menu/Skins/default/Btn_RolePic_%d.bmp" % clampi(role_id, 1, 14))
		if sheet:
			var frame_h: float = floorf(sheet.get_height() / 3.0)
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(0, 0, sheet.get_width(), frame_h)
			_player_body.texture = atlas
			_player_body.size = Vector2(sheet.get_width(), frame_h)
			var view_h: float = hud.size.y if hud else 600.0
			_player_body.position = Vector2(40.0, view_h - frame_h - 10.0)
		_player_body.visible = true
		_player_body.move_to_front()
	else:
		dialogue_dock.set_anchors_preset(Control.PRESET_CENTER_TOP)
		dialogue_dock.anchor_left = 0.5
		dialogue_dock.anchor_right = 0.5
		dialogue_dock.anchor_top = 0.0
		dialogue_dock.anchor_bottom = 0.0
		dialogue_dock.offset_left = -293.5
		dialogue_dock.offset_right = 293.5
		dialogue_dock.offset_top = PLAYER_TOP
		dialogue_dock.offset_bottom = DIALOGUE_BOTTOM
		dialogue_dock.grow_vertical = Control.GROW_DIRECTION_END
		_refresh_frame()
		if dialogue_text:
			dialogue_text.position = Vector2(110, 32)
			dialogue_text.size = Vector2(310, 80)
			dialogue_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


## The real client shows the speaking NPC's own face (Npc.dat talk_image); when only the name is known, take the
## face of the NPC template with that exact name (first one that has a face).
func _talk_image_for_speaker(speaker: String) -> int:
	var db = _get_game_database()
	if db == null or not ("npcs" in db) or db.npcs == null or speaker.strip_edges().is_empty():
		return 0
	var wanted := speaker.strip_edges().to_lower()
	for rec in db.npcs.get_npcs_by_name(speaker.strip_edges()):
		if str(rec.name).strip_edges().to_lower() == wanted and int(rec.talk_image) >= 8000:
			return int(rec.talk_image)
	return 0


## Advances to the next dialogue page or opens choices if at the last page
## Scripted conversation (from an Eve.emg event): pages alternate between the NPC and the player. `pages` =
## [{"who": "npc"|"player", "text": String}], `npc_name` labels the NPC pages, `portrait_tid` is its Npc.dat talk_image.
var _script_pages: Array[Dictionary] = []
var _script_index: int = 0
var _script_npc: String = ""
var _script_tid: int = 0
var _script_done: Callable = Callable()
var _script_choices: Array = []
var _script_choice_cb: Callable = Callable()


func show_script(pages: Array[Dictionary], npc_name: String, portrait_tid: int = 0, on_done: Callable = Callable(), choices: Array = [], choice_cb: Callable = Callable()) -> void:
	if pages.is_empty():
		return
	_script_pages = pages
	_script_index = 0
	_script_npc = npc_name
	_script_tid = portrait_tid
	_script_done = on_done
	_script_choices = choices
	_script_choice_cb = choice_cb
	_show_script_page()


func is_script_active() -> bool:
	return not _script_pages.is_empty()


func _show_script_page() -> void:
	var page: Dictionary = _script_pages[_script_index]
	var is_player: bool = str(page.get("who", "npc")) == "player"
	var who: String = "Player" if is_player else _script_npc
	var last := _script_index >= _script_pages.size() - 1
	var line_choices: Array = _script_choices if (last and not _script_choices.is_empty()) else []
	show_dialogue(who, str(page.get("text", "")), null, line_choices, 0 if is_player else _script_tid, _script_choice_cb)


func _advance_script() -> bool:
	if _script_pages.is_empty():
		return false
	if _script_index < _script_pages.size() - 1:
		_script_index += 1
		_show_script_page()
		return true
	return false


func _finish_script() -> void:
	var done := _script_done
	_script_pages = []
	_script_choices = []
	_script_done = Callable()
	if done.is_valid():
		done.call()


func advance_dialogue() -> void:
	if _advance_script():
		return
	_dialogue_current_page += 1
	if _dialogue_current_page < _dialogue_pages.size():
		if dialogue_text:
			dialogue_text.text = _dialogue_pages[_dialogue_current_page]
	else:
		if not _pending_choices.is_empty():
			var choices_to_show := _pending_choices
			_pending_choices = []
			show_choices(choices_to_show, _current_choice_callback)
		elif choices_container and choices_container.get_child_count() > 0 and branching_dock and not branching_dock.visible:
			branching_dock.visible = true
		else:
			hide_dialogue()

## Closes both FormTalk1 and FormTalk3
func hide_dialogue() -> void:
	if not _script_pages.is_empty():
		_finish_script()
	if _player_body:
		_player_body.visible = false
	if dialogue_dock:
		dialogue_dock.visible = false
		dialogue_dock.offset_bottom = DIALOGUE_BOTTOM
		_refresh_frame()
	if branching_dock:
		branching_dock.visible = false
	_pending_choices = []
	_portrait_frames.clear()
	if hud and hud.has_signal("dialogue_closed"):
		hud.dialogue_closed.emit()

## Displays interactive decision choices in FormTalk3 (324x168)
func show_choices(choices: Array[String], callback: Callable = Callable()) -> void:
	_current_choice_callback = callback
	if not choices_container or not branching_dock:
		return

	for child in choices_container.get_children():
		child.queue_free()

	for i in range(choices.size()):
		var choice_text: String = choices[i]
		var choice_idx: int = i
		var btn := Button.new()
		btn.text = choice_text
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 12)
		btn.add_theme_color_override("font_color", Color(1.0, 0.96, 0.62, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.85, 0.2, 1.0))
		btn.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1, 0.95))
		btn.add_theme_constant_override("outline_size", 2)
		btn.flat = true
		btn.pressed.connect(_on_choice_clicked.bind(choice_idx, choice_text))
		choices_container.add_child(btn)

	_layout_choices_like_real_client()
	branching_dock.visible = true

const DIALOGUE_BOTTOM: float = 217.0
const DIALOGUE_BOTTOM_WITH_CHOICES: float = 292.0

## Real client: with choices the dialogue frame grows downwards and a light-blue bordered list ("Yes." / "No.")
## sits inside it, above a Close pill.
func _layout_choices_like_real_client() -> void:
	if dialogue_dock:
		dialogue_dock.offset_bottom = DIALOGUE_BOTTOM_WITH_CHOICES
		_refresh_frame()
	branching_dock.set_anchors_preset(Control.PRESET_CENTER_TOP)
	branching_dock.anchor_left = 0.5
	branching_dock.anchor_right = 0.5
	branching_dock.anchor_top = 0.0
	branching_dock.anchor_bottom = 0.0
	branching_dock.offset_left = -258.0
	branching_dock.offset_right = 258.0
	branching_dock.offset_top = 48.0 + 142.0
	branching_dock.offset_bottom = 48.0 + 222.0
	branching_dock.grow_vertical = Control.GROW_DIRECTION_END
	if branching_bg:
		branching_bg.visible = false
	if choice_title:
		choice_title.visible = false
	var box := branching_dock.get_node_or_null("ChoiceBox") as Panel
	if box == null:
		box = Panel.new()
		box.name = "ChoiceBox"
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.55, 0.70, 0.92, 0.30)
		style.border_color = Color(0.40, 0.62, 0.95, 1.0)
		style.set_border_width_all(2)
		box.add_theme_stylebox_override("panel", style)
		branching_dock.add_child(box)
		branching_dock.move_child(box, 0)
	box.position = Vector2(0, 0)
	box.size = Vector2(516, maxf(40.0, 12.0 + 18.0 * float(choices_container.get_child_count())))
	choices_container.position = Vector2(14, 4)
	choices_container.size = Vector2(490, box.size.y - 6)
	choices_container.add_theme_constant_override("separation", 0)
	var close_pill := branching_dock.get_node_or_null("ChoiceClose") as Button
	if close_pill == null:
		close_pill = PillScript.make("Close", Vector2(228, 0), Vector2(56, 18))
		close_pill.name = "ChoiceClose"
		close_pill.pressed.connect(hide_dialogue)
		branching_dock.add_child(close_pill)
	close_pill.position = Vector2(230, box.size.y + 8.0)


## Hides the branching choice menu
func hide_choices() -> void:
	if branching_dock:
		branching_dock.visible = false
	if dialogue_dock:
		dialogue_dock.offset_bottom = DIALOGUE_BOTTOM
		_refresh_frame()

## Displays authentic animated quest reward fanfare, floating text, and chat announcement
func show_quest_reward(reward_name: String = "", count: int = 1, gold: int = 0, exp: int = 0) -> void:
	# 1. Authentic Quest Completion Fanfare SFX (wav9911)
	play_sfx("wav9911")

	# 2. System Announcement
	var msg := "Quest Updated!"
	if not reward_name.is_empty():
		msg += " Received %s x%d." % [reward_name, count]
	if gold > 0:
		msg += " +%d Gold." % gold
	if exp > 0:
		msg += " +%d EXP." % exp

	if hud and hud.has_method("add_chat_message"):
		hud.add_chat_message("System", msg, "System")

	# 3. Reward banner: a small translucent frame with gold bars in the middle of the view, "Obtain N pcs <item>"
	if hud:
		var frame := NinePatchRect.new()
		frame.name = "RewardBanner"
		frame.texture = load("res://scripts/ui/hud/skin_button.gd").keyed_texture("res://assets/menu/Skins/white/Form_Talk_1.bmp")
		frame.patch_margin_left = 30
		frame.patch_margin_right = 30
		frame.patch_margin_top = 14
		frame.patch_margin_bottom = 14
		frame.modulate = Color(1, 1, 1, 0.9)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.size = Vector2(190, 58)
		var view := hud.size if hud.size.x > 0 else Vector2(800, 600)
		frame.position = Vector2((view.x - 190.0) * 0.5, view.y * 0.5 - 40.0)
		frame.z_index = 50
		var line := Label.new()
		var banner_text := ""
		if not reward_name.is_empty():
			banner_text = "Obtain %d pcs %s" % [count, reward_name]
		elif gold > 0:
			banner_text = "Obtain %d Gold" % gold
		elif exp > 0:
			banner_text = "Obtain %d EXP" % exp
		else:
			banner_text = msg
		line.text = banner_text
		line.set_anchors_preset(Control.PRESET_FULL_RECT)
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		line.add_theme_font_size_override("font_size", 11)
		line.add_theme_color_override("font_color", Color(1.0, 0.95, 0.25, 1.0))
		line.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.2, 1.0))
		line.add_theme_constant_override("outline_size", 2)
		frame.add_child(line)
		hud.add_child(frame)
		var tw := hud.create_tween()
		tw.tween_interval(1.6)
		tw.tween_property(frame, "modulate:a", 0.0, 0.6)
		tw.finished.connect(frame.queue_free)

## Plays authentic SFX from res://assets/sound/
func play_sfx(sfx_name: String) -> void:
	if sfx_name.is_empty():
		return
	if not _sfx_player:
		_setup_audio_player()
	if not _sfx_player:
		return

	var clean_name: String = sfx_name.replace(".wav", "").replace(".WAV", "")
	var paths: Array[String] = [
		"res://assets/sound/%s.wav" % clean_name,
		"res://assets/sound/%s.WAV" % clean_name,
		"res://assets/sound/%s.wav" % clean_name.to_lower(),
		"res://assets/sound/%s.WAV" % clean_name.to_upper()
	]
	var stream: AudioStream = null
	for p in paths:
		if ResourceLoader.exists(p):
			stream = load(p)
			break
	if stream:
		_sfx_player.stream = stream
		if _sfx_player.is_inside_tree():
			_sfx_player.play()

# ==============================================================================
# Internal Helpers
# ==============================================================================

func _setup_audio_player() -> void:
	if _sfx_player:
		return
	if hud:
		var existing := hud.get_node_or_null("HudSFXPlayer") as AudioStreamPlayer
		if existing:
			_sfx_player = existing
		else:
			_sfx_player = AudioStreamPlayer.new()
			_sfx_player.name = "HudSFXPlayer"
			hud.add_child(_sfx_player)

func _setup_authentic_textures() -> void:
	var loader = _get_archive_loader()
	if not loader:
		return

	# FormTalk1 background (authentic white parchment Form_Talk_2.bmp with fallback to Form_Talk_1.bmp)
	if dialogue_bg:
		# The real client shows the blue Form_Talk_1 (gold bars) translucent, stretched to the dock, at the TOP of the view.
		var t1_tex: Texture2D = load("res://scripts/ui/hud/skin_button.gd").keyed_texture("res://assets/menu/Skins/white/Form_Talk_1.bmp")
		if t1_tex == null:
			t1_tex = loader.get_ui_texture("menu/Skins/white/Form_Talk_2.bmp")
		if t1_tex:
			dialogue_bg.texture = t1_tex
			dialogue_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			dialogue_bg.stretch_mode = TextureRect.STRETCH_SCALE
			dialogue_bg.modulate = Color(1, 1, 1, 1)
			_refresh_frame()

	# FormTalk3 background
	if branching_bg:
		var t3_tex: ImageTexture = loader.get_ui_texture("menu/Skins/white/Form_Talk_3.bmp")
		if t3_tex:
			branching_bg.texture = t3_tex

	# Next-page blinking icon (25x62 -> 2 frames of 25x31)
	if next_icon:
		var next_icon_sheet: ImageTexture = loader.get_ui_texture("menu/Skins/default/Icon_Nextone_1.bmp")
		if next_icon_sheet:
			_next_icon_atlas = AtlasTexture.new()
			_next_icon_atlas.atlas = next_icon_sheet
			_next_icon_atlas.region = Rect2(0, 0, 25, 31)
			next_icon.texture = _next_icon_atlas

	# NPC Portrait fallback
	if portrait_rect and not portrait_rect.texture:
		var role_pic_sheet: ImageTexture = loader.get_ui_texture("menu/Skins/default/Btn_RolePic_1.bmp")
		if role_pic_sheet:
			var portrait_atlas := AtlasTexture.new()
			portrait_atlas.atlas = role_pic_sheet
			portrait_atlas.region = Rect2(0, 0, 94, 92)
			portrait_rect.texture = portrait_atlas

func _setup_click_handlers() -> void:
	var on_dialogue_clicked = func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			advance_dialogue()
			if hud and hud.get_viewport():
				hud.get_viewport().set_input_as_handled()

	if next_icon:
		next_icon.mouse_filter = Control.MOUSE_FILTER_STOP
		if not next_icon.gui_input.is_connected(on_dialogue_clicked):
			next_icon.gui_input.connect(on_dialogue_clicked)
	if dialogue_dock:
		dialogue_dock.mouse_filter = Control.MOUSE_FILTER_STOP
		if not dialogue_dock.gui_input.is_connected(on_dialogue_clicked):
			dialogue_dock.gui_input.connect(on_dialogue_clicked)
	if dialogue_bg:
		dialogue_bg.mouse_filter = Control.MOUSE_FILTER_STOP
		if not dialogue_bg.gui_input.is_connected(on_dialogue_clicked):
			dialogue_bg.gui_input.connect(on_dialogue_clicked)
	if dialogue_text:
		dialogue_text.mouse_filter = Control.MOUSE_FILTER_STOP
		if not dialogue_text.gui_input.is_connected(on_dialogue_clicked):
			dialogue_text.gui_input.connect(on_dialogue_clicked)

func _on_choice_clicked(choice_idx: int, choice_txt: String) -> void:
	# Close first: the callback may open the follow-up conversation (next question, answer lines) and must stay visible.
	var callback := _current_choice_callback
	hide_dialogue()
	if hud and hud.has_signal("dialogue_choice_selected"):
		hud.dialogue_choice_selected.emit(choice_idx, choice_txt)
	if callback.is_valid():
		callback.call(choice_idx, choice_txt)

func _update_portrait(portrait_index: int) -> void:
	var loader = _get_archive_loader()
	if not loader:
		return

	# 1. If portrait_index is an authentic TID (>= 8000), decode bust directly from 008.jma
	if portrait_index >= 8000 and loader.has_method("get_avatar_frames"):
		var jma_frames = loader.get_avatar_frames(portrait_index)
		if not jma_frames.is_empty():
			_portrait_frames.clear()
			for f in jma_frames:
				_portrait_frames.append(f)
			if portrait_rect:
				portrait_rect.texture = _portrait_frames[0]
				portrait_rect.visible = true
			return

	# 2. If portrait_index is an NPC ID, resolve talk_image TID from NpcDatabase
	var db = _get_game_database()
	if db and "npcs" in db and db.npcs and loader.has_method("get_avatar_frames"):
		var nrec = db.npcs.get_npc(portrait_index)
		if nrec and nrec.talk_image >= 8000:
			var jma_frames = loader.get_avatar_frames(nrec.talk_image)
			if not jma_frames.is_empty():
				_portrait_frames.clear()
				for f in jma_frames:
					_portrait_frames.append(f)
				if portrait_rect:
					portrait_rect.texture = _portrait_frames[0]
					portrait_rect.visible = true
				return

	# 3. Fallback to default role/NPC bitmap sheet
	var sheet: ImageTexture = loader.get_ui_texture("menu/Skins/default/Btn_RolePic_1.bmp")
	if sheet and portrait_rect:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		var y_offset: int = (portrait_index % 8) * 92
		atlas.region = Rect2(0, y_offset, 94, 92)
		portrait_rect.texture = atlas
		portrait_rect.visible = true

func _get_archive_loader() -> Node:
	if hud and hud.is_inside_tree():
		return hud.get_node_or_null("/root/ArchiveLoader")
	var loop = Engine.get_main_loop()
	if loop is SceneTree and loop.root:
		return loop.root.get_node_or_null("ArchiveLoader")
	return null

func _get_game_database() -> Node:
	if hud and hud.is_inside_tree():
		return hud.get_node_or_null("/root/GameDatabase")
	var loop = Engine.get_main_loop()
	if loop is SceneTree and loop.root:
		return loop.root.get_node_or_null("GameDatabase")
	return null
