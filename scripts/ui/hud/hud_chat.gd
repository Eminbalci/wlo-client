class_name HUDChat
extends RefCounted

## Dedicated controller encapsulating the bottom-left chat dock, message history,
## channel routing, tabs, dropdowns, resizing, animated emoticons, and overhead speech bubbles.

const SkinButtonScript = preload("res://scripts/ui/hud/skin_button.gd")
const FRAME_ART_PATH: String = "res://assets/menu/Skins/default/Panel_TalkForm.bmp"
const STRIP_ART_PATH: String = "res://assets/menu/Skins/default/Panel_TalkForm2_1.bmp"
const CHAT_FACE_SIZE: int = 18
const CHAT_ROW_HEIGHT: int = 19
var hud: Control = null

# Chat UI Nodes
var chat_dock: Control = null
var chat_history_panel: PanelContainer = null
var chat_history: RichTextLabel = null
var chat_input_bg: TextureRect = null
var btn_mail: TextureButton = null
var btn_channel: Button = null
var chat_input: LineEdit = null
var send_button: Button = null
var chat_frame_nine_patch: NinePatchRect = null
var panel_talk_form_left: TextureRect = null
var btn_msg_lock: TextureButton = null
var btn_chat_switch: TextureButton = null
var btn_chat_size: TextureButton = null
var chat_resize_handle: Control = null
var whisper_target: LineEdit = null
var btn_emote: TextureButton = null
var channel_dropdown: Control = null
var emote_popup: Control = null
var emote_grid: GridContainer = null
var emote_close_btn: Button = null

# Channel Tabs Bar
var channel_tabs: Control = null
var btn_tab_all: Button = null
var btn_tab_current: Button = null
var btn_tab_team: Button = null
var btn_tab_guild: Button = null
var btn_tab_whisper: Button = null
var btn_tab_system: Button = null

# Chat State
var _chat_is_framed: bool = false
var _chat_is_locked: bool = false
var _chat_height_state: int = 0
var _current_channel: String = "Local"
var _chat_is_resizing: bool = false
var _chat_resize_start_y: float = 0.0
var _chat_resize_start_top: float = -86.0
var _active_chat_tab: String = "All"
var _chat_messages: Array[Dictionary] = []
var _chat_opacity_mode: int = 0
var _last_chat_msg: String = ""
var _last_chat_time: float = 0.0
var _dock_width: float = 524.0

# Tab StyleBox cache
var _style_tab_inactive: StyleBoxFlat = null
var _style_tab_hover: StyleBoxFlat = null
var _style_tab_active: StyleBoxFlat = null
var _style_empty: StyleBoxEmpty = null

## Initializes and wires up the chat dock sub-controller with node references
func setup(p_hud: Control, nodes: Dictionary) -> void:
	hud = p_hud

	chat_dock = nodes.get("chat_dock", null) as Control
	chat_history_panel = nodes.get("chat_history_panel", null) as PanelContainer
	chat_history = nodes.get("chat_history", null) as RichTextLabel
	chat_input_bg = nodes.get("chat_input_bg", null) as TextureRect
	btn_mail = nodes.get("btn_mail", null) as TextureButton
	btn_channel = nodes.get("btn_channel", null) as Button
	chat_input = nodes.get("chat_input", null) as LineEdit
	send_button = nodes.get("send_button", null) as Button
	chat_frame_nine_patch = nodes.get("chat_frame_nine_patch", null) as NinePatchRect
	panel_talk_form_left = nodes.get("panel_talk_form_left", null) as TextureRect
	btn_msg_lock = nodes.get("btn_msg_lock", null) as TextureButton
	btn_chat_switch = nodes.get("btn_chat_switch", null) as TextureButton
	btn_chat_size = nodes.get("btn_chat_size", null) as TextureButton
	chat_resize_handle = nodes.get("chat_resize_handle", null) as Control
	whisper_target = nodes.get("whisper_target", null) as LineEdit
	btn_emote = nodes.get("btn_emote", null) as TextureButton
	channel_dropdown = nodes.get("channel_dropdown", null) as Control
	emote_popup = nodes.get("emote_popup", null) as Control
	emote_grid = nodes.get("emote_grid", null) as GridContainer
	emote_close_btn = nodes.get("emote_close_btn", null) as Button

	channel_tabs = nodes.get("channel_tabs", null) as Control
	btn_tab_all = nodes.get("btn_tab_all", null) as Button
	btn_tab_current = nodes.get("btn_tab_current", null) as Button
	btn_tab_team = nodes.get("btn_tab_team", null) as Button
	btn_tab_guild = nodes.get("btn_tab_guild", null) as Button
	btn_tab_whisper = nodes.get("btn_tab_whisper", null) as Button
	btn_tab_system = nodes.get("btn_tab_system", null) as Button

	if channel_tabs:
		if not btn_tab_all: btn_tab_all = channel_tabs.get_node_or_null("BtnTabAll") as Button
		if not btn_tab_current: btn_tab_current = channel_tabs.get_node_or_null("BtnTabCurrent") as Button
		if not btn_tab_team: btn_tab_team = channel_tabs.get_node_or_null("BtnTabTeam") as Button
		if not btn_tab_guild: btn_tab_guild = channel_tabs.get_node_or_null("BtnTabGuild") as Button
		if not btn_tab_whisper: btn_tab_whisper = channel_tabs.get_node_or_null("BtnTabWhisper") as Button
		if not btn_tab_system: btn_tab_system = channel_tabs.get_node_or_null("BtnTabSystem") as Button

	_init_tab_styles()
	_setup_chat_dock_components()
	_setup_custom_scrollbar()
	_setup_channel_tabs()
	_setup_input_fields_style()
	_setup_channel_dropdown_style()
	_update_chat_frame_style()
	_update_input_bar_layout()
	_update_channel_tabs_position()

## Handles mouse input during active chat panel resize dragging
func handle_input(event: InputEvent) -> bool:
	if _chat_is_resizing:
		if event is InputEventMouseMotion and chat_history_panel:
			var dy: float = event.global_position.y - _chat_resize_start_y
			var new_top: float = clampf(_chat_resize_start_top + dy, -350.0, -60.0)
			chat_history_panel.offset_top = new_top
			_update_channel_tabs_position()
			return true
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_chat_is_resizing = false
			return true
	return false

func _init_tab_styles() -> void:
	_style_empty = StyleBoxEmpty.new()

	_style_tab_inactive = StyleBoxFlat.new()
	_style_tab_inactive.bg_color = Color(0.04, 0.06, 0.09, 0.75)
	_style_tab_inactive.border_width_top = 1
	_style_tab_inactive.border_width_left = 1
	_style_tab_inactive.border_width_right = 1
	_style_tab_inactive.border_width_bottom = 0
	_style_tab_inactive.border_color = Color(0.50, 0.42, 0.28, 0.60)
	_style_tab_inactive.corner_radius_top_left = 3
	_style_tab_inactive.corner_radius_top_right = 3
	_style_tab_inactive.content_margin_left = 8.0
	_style_tab_inactive.content_margin_right = 8.0
	_style_tab_inactive.content_margin_top = 2.0
	_style_tab_inactive.content_margin_bottom = 2.0

	_style_tab_hover = StyleBoxFlat.new()
	_style_tab_hover.bg_color = Color(0.10, 0.14, 0.20, 0.88)
	_style_tab_hover.border_width_top = 1
	_style_tab_hover.border_width_left = 1
	_style_tab_hover.border_width_right = 1
	_style_tab_hover.border_width_bottom = 0
	_style_tab_hover.border_color = Color(0.80, 0.70, 0.45, 0.88)
	_style_tab_hover.corner_radius_top_left = 3
	_style_tab_hover.corner_radius_top_right = 3
	_style_tab_hover.content_margin_left = 8.0
	_style_tab_hover.content_margin_right = 8.0
	_style_tab_hover.content_margin_top = 2.0
	_style_tab_hover.content_margin_bottom = 2.0

	_style_tab_active = StyleBoxFlat.new()
	_style_tab_active.bg_color = Color(0.12, 0.16, 0.24, 0.94)
	_style_tab_active.border_width_top = 2
	_style_tab_active.border_width_left = 1
	_style_tab_active.border_width_right = 1
	_style_tab_active.border_width_bottom = 0
	_style_tab_active.border_color = Color(0.96, 0.84, 0.40, 0.98)
	_style_tab_active.corner_radius_top_left = 3
	_style_tab_active.corner_radius_top_right = 3
	_style_tab_active.content_margin_left = 8.0
	_style_tab_active.content_margin_right = 8.0
	_style_tab_active.content_margin_top = 1.0
	_style_tab_active.content_margin_bottom = 2.0

## Sets responsive dock width
func set_dock_width(new_width: float) -> void:
	_dock_width = maxf(380.0, new_width)
	if chat_dock:
		chat_dock.size.x = _dock_width
	if chat_history_panel:
		chat_history_panel.size.x = _dock_width
	if channel_tabs:
		channel_tabs.size.x = minf(320.0, _dock_width)
	_update_input_bar_layout()

## Updates input bar geometry and auto-fits WhisperTarget / ChatInput
func _update_input_bar_layout() -> void:
	var is_whisper := (_current_channel == "Whisper")
	if whisper_target:
		whisper_target.visible = true # the original always shows the recipient field beside the message field
		whisper_target.position = Vector2(74.0, 2.0)
		whisper_target.size = Vector2(86.0, 21.0)

	if btn_mail:
		btn_mail.position = Vector2(3.0, 2.0)
		btn_mail.size = Vector2(26.0, 21.0)

	if btn_channel:
		btn_channel.position = Vector2(30.0, 2.0)
		btn_channel.size = Vector2(42.0, 21.0)
		_update_channel_button_style()

	if chat_input:
		var in_x: float = 163.0
		var right_pad: float = 28.0
		var in_w: float = maxf(100.0, _dock_width - in_x - right_pad)
		chat_input.position = Vector2(in_x, 2.0)
		chat_input.size = Vector2(in_w, 21.0)

	if btn_emote:
		btn_emote.position = Vector2(_dock_width - 27.0, 1.0)
		btn_emote.size = Vector2(25.0, 23.0)

	if chat_input_bg:
		chat_input_bg.position = Vector2(0.0, 0.0)
		chat_input_bg.size = Vector2(_dock_width, 25.0)

	if channel_dropdown:
		channel_dropdown.position = Vector2(30.0, -118.0)
		channel_dropdown.size = Vector2(44.0, 114.0)

	if emote_popup:
		emote_popup.position = Vector2(_dock_width - 265.0, -75.0)
		emote_popup.size = Vector2(263.0, 71.0)

func _update_channel_button_style() -> void:
	if not btn_channel:
		return
	var ch_colors := {
		"Local": Color(0.24, 0.78, 0.35, 1.0),
		"Current": Color(0.24, 0.78, 0.35, 1.0),
		"Team": Color(0.29, 0.70, 1.0, 1.0),
		"Guild": Color(0.20, 0.88, 0.44, 1.0),
		"Whisper": Color(1.0, 0.40, 0.70, 1.0),
		"World": Color(1.0, 0.92, 0.20, 1.0),
		"System": Color(1.0, 0.75, 0.25, 1.0)
	}
	var border_col: Color = ch_colors.get(_current_channel, Color(0.24, 0.78, 0.35, 1.0))

	var sb_norm := StyleBoxFlat.new()
	sb_norm.bg_color = border_col.darkened(0.1)
	sb_norm.border_width_left = 1
	sb_norm.border_width_top = 1
	sb_norm.border_width_right = 1
	sb_norm.border_width_bottom = 1
	sb_norm.border_color = border_col
	sb_norm.corner_radius_top_left = 2
	sb_norm.corner_radius_top_right = 2
	sb_norm.corner_radius_bottom_right = 2
	sb_norm.corner_radius_bottom_left = 2

	var sb_hov := sb_norm.duplicate() as StyleBoxFlat
	sb_hov.bg_color = border_col.lightened(0.15)
	sb_hov.border_color = border_col.lightened(0.25)

	var sb_press := sb_norm.duplicate() as StyleBoxFlat
	sb_press.bg_color = border_col.darkened(0.35)
	sb_press.border_color = border_col.darkened(0.2)

	btn_channel.add_theme_stylebox_override("normal", sb_norm)
	btn_channel.add_theme_stylebox_override("hover", sb_hov)
	btn_channel.add_theme_stylebox_override("pressed", sb_press)
	btn_channel.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for color_name in ["font_color", "font_hover_color", "font_pressed_color"]:
		btn_channel.add_theme_color_override(color_name, Color(1, 1, 1, 1))
	btn_channel.add_theme_color_override("font_outline_color", Color(0.05, 0.25, 0.05, 1.0))
	btn_channel.add_theme_constant_override("outline_size", 3)
	btn_channel.text = _current_channel
	btn_channel.tooltip_text = "Chat Channel: %s" % _current_channel

func _setup_custom_scrollbar() -> void:
	if not chat_history:
		return
	var v_scroll: VScrollBar = chat_history.get_v_scroll_bar()
	if not v_scroll:
		return
	v_scroll.custom_minimum_size.x = 6.0

	var sb_scroll := StyleBoxFlat.new()
	sb_scroll.bg_color = Color(0.02, 0.03, 0.05, 0.25)
	sb_scroll.corner_radius_top_left = 3
	sb_scroll.corner_radius_top_right = 3
	sb_scroll.corner_radius_bottom_left = 3
	sb_scroll.corner_radius_bottom_right = 3

	var sb_grabber := StyleBoxFlat.new()
	sb_grabber.bg_color = Color(0.68, 0.56, 0.34, 0.75)
	sb_grabber.border_width_left = 1
	sb_grabber.border_width_top = 1
	sb_grabber.border_width_right = 1
	sb_grabber.border_width_bottom = 1
	sb_grabber.border_color = Color(0.85, 0.72, 0.42, 0.85)
	sb_grabber.corner_radius_top_left = 3
	sb_grabber.corner_radius_top_right = 3
	sb_grabber.corner_radius_bottom_left = 3
	sb_grabber.corner_radius_bottom_right = 3

	var sb_grabber_hl := sb_grabber.duplicate() as StyleBoxFlat
	sb_grabber_hl.bg_color = Color(0.88, 0.76, 0.46, 0.95)
	sb_grabber_hl.border_color = Color(1.0, 0.88, 0.55, 1.0)

	var sb_grabber_press := sb_grabber.duplicate() as StyleBoxFlat
	sb_grabber_press.bg_color = Color(1.0, 0.88, 0.52, 1.0)
	sb_grabber_press.border_color = Color(1.0, 0.95, 0.70, 1.0)

	v_scroll.add_theme_stylebox_override("scroll", sb_scroll)
	v_scroll.add_theme_stylebox_override("scroll_focus", sb_scroll)
	v_scroll.add_theme_stylebox_override("grabber", sb_grabber)
	v_scroll.add_theme_stylebox_override("grabber_highlight", sb_grabber_hl)
	v_scroll.add_theme_stylebox_override("grabber_pressed", sb_grabber_press)

	var empty_tex := ImageTexture.create_from_image(Image.create(1, 1, false, Image.FORMAT_RGBA8))
	v_scroll.add_theme_icon_override("decrement", empty_tex)
	v_scroll.add_theme_icon_override("decrement_highlight", empty_tex)
	v_scroll.add_theme_icon_override("decrement_pressed", empty_tex)
	v_scroll.add_theme_icon_override("increment", empty_tex)
	v_scroll.add_theme_icon_override("increment_highlight", empty_tex)
	v_scroll.add_theme_icon_override("increment_pressed", empty_tex)

func _setup_input_fields_style() -> void:
	if chat_input:
		var in_norm := StyleBoxFlat.new()
		in_norm.bg_color = Color(0.04, 0.06, 0.09, 0.90)
		in_norm.border_width_left = 1
		in_norm.border_width_top = 1
		in_norm.border_width_right = 1
		in_norm.border_width_bottom = 1
		in_norm.border_color = Color(0.70, 0.58, 0.35, 0.85)
		in_norm.corner_radius_top_left = 2
		in_norm.corner_radius_top_right = 2
		in_norm.corner_radius_bottom_left = 2
		in_norm.corner_radius_bottom_right = 2
		in_norm.content_margin_left = 6.0
		in_norm.content_margin_right = 6.0
		in_norm.content_margin_top = 2.0
		in_norm.content_margin_bottom = 2.0

		var in_focus := in_norm.duplicate() as StyleBoxFlat
		in_focus.bg_color = Color(0.03, 0.05, 0.08, 0.98)
		in_focus.border_color = Color(0.95, 0.82, 0.42, 1.0)

		chat_input.add_theme_stylebox_override("normal", in_norm)
		chat_input.add_theme_stylebox_override("focus", in_focus)
		chat_input.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		chat_input.add_theme_color_override("font_placeholder_color", Color(0.70, 0.68, 0.60, 0.60))
		chat_input.add_theme_color_override("caret_color", Color(1.0, 0.88, 0.40, 1.0))
		chat_input.caret_blink = true

	if whisper_target:
		var wt_norm := StyleBoxFlat.new()
		wt_norm.bg_color = Color(0.04, 0.06, 0.09, 0.85)
		wt_norm.border_width_left = 1
		wt_norm.border_width_top = 1
		wt_norm.border_width_right = 1
		wt_norm.border_width_bottom = 1
		wt_norm.border_color = Color(0.70, 0.58, 0.35, 0.80)
		wt_norm.corner_radius_top_left = 2
		wt_norm.corner_radius_top_right = 2
		wt_norm.corner_radius_bottom_left = 2
		wt_norm.corner_radius_bottom_right = 2
		wt_norm.content_margin_left = 5.0
		wt_norm.content_margin_right = 5.0
		wt_norm.content_margin_top = 2.0
		wt_norm.content_margin_bottom = 2.0

		var wt_focus := wt_norm.duplicate() as StyleBoxFlat
		wt_focus.border_color = Color(1.0, 0.85, 0.45, 1.0)

		whisper_target.add_theme_stylebox_override("normal", wt_norm)
		whisper_target.add_theme_stylebox_override("focus", wt_focus)
		whisper_target.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		whisper_target.add_theme_color_override("font_placeholder_color", Color(0.68, 0.68, 0.64, 0.65))
		whisper_target.add_theme_color_override("caret_color", Color(1.0, 0.88, 0.40, 1.0))
		whisper_target.caret_blink = true

func _setup_channel_dropdown_style() -> void:
	if not channel_dropdown:
		return
	var sb_dd := StyleBoxFlat.new()
	sb_dd.bg_color = Color(0.04, 0.06, 0.09, 0.94)
	sb_dd.border_width_left = 1
	sb_dd.border_width_top = 1
	sb_dd.border_width_right = 1
	sb_dd.border_width_bottom = 1
	sb_dd.border_color = Color(0.75, 0.62, 0.35, 0.90)
	sb_dd.corner_radius_top_left = 2
	sb_dd.corner_radius_top_right = 2
	sb_dd.corner_radius_bottom_left = 2
	sb_dd.corner_radius_bottom_right = 2
	sb_dd.content_margin_left = 2.0
	sb_dd.content_margin_right = 2.0
	sb_dd.content_margin_top = 3.0
	sb_dd.content_margin_bottom = 3.0
	channel_dropdown.add_theme_stylebox_override("panel", sb_dd)

## Channel tag colours (hex). The System window's colour pickers replace these through apply_chat_colors().
var _tag_colors: Dictionary = {
	"local": "42d766",
	"whisper": "ff66b2",
	"team": "4ab3ff",
	"guild": "32e070",
	"world": "ffea33",
}

## Applies the System window's chat colours ({"local": "#rrggbb", "whisper": ..., "party": ..., "guild": ..., "world": ...}).
func apply_chat_colors(colors: Dictionary) -> void:
	var key_map := {"local": "local", "whisper": "whisper", "party": "team", "guild": "guild", "world": "world"}
	for source_key in key_map.keys():
		if colors.has(source_key):
			_tag_colors[key_map[source_key]] = str(colors[source_key]).trim_prefix("#")

## Adds a formatted message to the chat history with channel color coding
## Role (1..14) whose face is shown next to a line: the player's own role, otherwise a stable pick from the name
## (the chat packet of this client does not carry the sender's role yet).
func _chat_role_for(sender: String, role_id: int = 0) -> int:
	if role_id >= 1 and role_id <= 14:
		return role_id # the packet / caller knows the sender's role
	var name_only := sender.substr(3).strip_edges() if sender.begins_with("To ") else sender
	var status = hud.character_status_ctrl if (hud and "character_status_ctrl" in hud) else null
	if status and name_only == str(status.current_name):
		return clampi(int(status.current_role_id), 1, 14)
	return int(absi(name_only.hash()) % 14) + 1


func add_chat_message(sender: String, message: String, channel: String = "Local", role_id: int = 0) -> void:
	if not chat_history:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if message == _last_chat_msg and (now - _last_chat_time) < 1.5:
		return
	_last_chat_msg = message
	_last_chat_time = now

	var line := ""
	var face_path := ""
	var ch_lower := channel.to_lower()
	var snd_lower := sender.to_lower()

	if ch_lower == "system" or snd_lower == "system":
		line = "[color=#ff3b30](System)%s[/color]" % [message]
	else:
		# The original prints "(Channel)Name:message" in the channel colour (docs/re/ui_windows.md).
		var label := channel
		var colour := "42d766"
		match ch_lower:
			"local", "current":
				label = "Local"
				colour = _tag_colors["local"]
			"whisper":
				colour = _tag_colors["whisper"]
			"team":
				colour = _tag_colors["team"]
			"guild":
				colour = _tag_colors["guild"]
			"world":
				colour = _tag_colors["world"]
		var target_name: String = sender.substr(3).strip_edges() if (ch_lower == "whisper" and sender.begins_with("To ")) else sender
		line = "[color=#%s](%s)[url=whisper:%s]%s[/url]:%s[/color]" % [colour, label, target_name, sender, message]
		# the original puts the sender's small face in front of every line (game art avatar_role_N_0)
		face_path = "res://assets/hud/avatar_role_%d_0.png" % _chat_role_for(sender, role_id)

	var entry := {
		"sender": sender,
		"message": message,
		"channel": channel,
		"line": line,
		"face": face_path,
	}
	_chat_messages.append(entry)

	if _message_matches_tab(channel, _active_chat_tab):
		_append_chat_entry(entry)

## Appends a formatted line cleanly to the chat history (with sender avatar face when present).
func _append_chat_entry(entry: Dictionary) -> void:
	if chat_history == null:
		return
	var face_path: String = str(entry.get("face", ""))
	var line_text: String = str(entry.get("line", ""))
	if line_text == "":
		return
	if face_path != "" and ResourceLoader.exists(face_path):
		var face_tex: Texture2D = load(face_path) as Texture2D
		if face_tex:
			chat_history.push_table(2)
			chat_history.set_table_column_expand(0, false)
			chat_history.set_table_column_expand(1, true)
			chat_history.push_cell()
			chat_history.add_image(face_tex, CHAT_FACE_SIZE, CHAT_ROW_HEIGHT)
			chat_history.pop()
			chat_history.push_cell()
			chat_history.append_text(line_text)
			chat_history.pop()
			chat_history.pop()
			return
	chat_history.append_text(line_text + "\n")


## Filters chat history by selected channel tab
func select_chat_tab(tab_name: String) -> void:
	_active_chat_tab = tab_name
	_update_tab_button_visuals()
	if chat_history:
		chat_history.clear()
		for msg in _chat_messages:
			if _message_matches_tab(msg["channel"], tab_name):
				_append_chat_entry(msg)
	if hud and hud.has_signal("chat_tab_changed"):
		hud.chat_tab_changed.emit(tab_name)

## Toggles between transparent background and authentic dark slate NinePatch box
func toggle_chat_opacity() -> void:
	_chat_is_framed = not _chat_is_framed
	_chat_opacity_mode = 2 if _chat_is_framed else 0
	_update_chat_frame_style()

## Sets up whisper targeting and focus
func whisper_to_player(target_name: String, initial_msg: String = "") -> void:
	if whisper_target:
		whisper_target.text = target_name
	_select_channel("Whisper")
	if not initial_msg.is_empty():
		var whisper_display := "To %s" % target_name
		add_chat_message(whisper_display, initial_msg, "Whisper")
		if hud and hud.has_signal("chat_message_sent"):
			hud.chat_message_sent.emit("Whisper", initial_msg)
	if chat_input:
		chat_input.grab_focus()

## Shows overhead comic bubble above the player character
func display_player_overhead_bubble(text_or_code: String, duration: float = 3.5) -> void:
	var player_node = hud.get("player") if hud else null
	if player_node and player_node.has_method("show_speech_bubble"):
		player_node.show_speech_bubble(text_or_code, duration)
	if hud and hud.has_signal("overhead_bubble_emitted"):
		hud.overhead_bubble_emitted.emit(text_or_code)

## Triggered when Send button is pressed
func on_send_pressed() -> void:
	if chat_input:
		on_chat_submitted(chat_input.text)

## Submits and routes chat input text
func on_chat_submitted(text: String) -> void:
	var clean := text.strip_edges()
	if clean.is_empty():
		if chat_input:
			chat_input.release_focus()
		return

	# Parse /target or /w or /whisper syntax
	if clean.begins_with("/target "):
		var remainder := clean.substr(8).strip_edges()
		var parts := remainder.split(" ", false, 1)
		if parts.size() >= 1:
			var target := parts[0]
			var msg := parts[1].strip_edges() if parts.size() > 1 else ""
			whisper_to_player(target, msg)
			if chat_input:
				chat_input.text = ""
				chat_input.release_focus()
			return
	elif clean.begins_with("/w ") or clean.begins_with("/whisper "):
		var prefix_len: int = 3 if clean.begins_with("/w ") else 9
		var remainder := clean.substr(prefix_len).strip_edges()
		var parts := remainder.split(" ", false, 1)
		if parts.size() >= 1:
			var target := parts[0]
			var msg := parts[1].strip_edges() if parts.size() > 1 else ""
			whisper_to_player(target, msg)
			if chat_input:
				chat_input.text = ""
				chat_input.release_focus()
			return
	elif clean.begins_with("/give ") or clean.begins_with("/item "):
		var prefix_len: int = 6 if clean.begins_with("/give ") else 6
		var args := clean.substr(prefix_len).strip_edges().split(" ", false)
		if not args.is_empty():
			var item_id: int = int(args[0])
			var count: int = int(args[1]) if args.size() > 1 else 1
			var item_name := "Item %d" % item_id
			var icon_id: int = 1000
			var db = (hud.get_node_or_null("/root/GameDatabase") if (hud and hud.is_inside_tree()) else null)
			if db and db.items:
				var rec = db.items.get_item(item_id)
				if rec:
					if not rec.name.is_empty(): item_name = rec.name
					if rec.icon_id > 0: icon_id = rec.icon_id
			if hud and hud.has_method("add_inventory_item"):
				var added: bool = hud.add_inventory_item(item_id, count, item_name, icon_id)
				var msg := ("Granted %s x%d (ID: %d)!" % [item_name, count, item_id]) if added else "Inventory is full!"
				add_chat_message("System", msg, "System")
		if chat_input:
			chat_input.text = ""
			if chat_input.is_inside_tree():
				chat_input.release_focus()
		return
	elif clean.begins_with("/gold "):
		var amt: int = int(clean.substr(6).strip_edges())
		if amt != 0 and hud and hud.has_method("add_gold"):
			hud.add_gold(amt)
			add_chat_message("System", "Added %d Gold to character!" % amt, "System")
		if chat_input:
			chat_input.text = ""
			if chat_input.is_inside_tree():
				chat_input.release_focus()
		return
	elif clean == "/clear":
		if hud and hud.has_method("clear_inventory"):
			hud.clear_inventory()
		elif hud and "inventory_ctrl" in hud and hud.inventory_ctrl and hud.inventory_ctrl.has_method("clear_inventory"):
			hud.inventory_ctrl.clear_inventory()
		add_chat_message("System", "Inventory cleared.", "System")
		if chat_input:
			chat_input.text = ""
			if chat_input.is_inside_tree():
				chat_input.release_focus()
		return

	display_player_overhead_bubble(clean)

	var sender_name := "Player"
	if hud:
		var name_lbl = hud.get_node_or_null("PlayerStatusDock/NameLabel") as Label
		if name_lbl and not name_lbl.text.is_empty():
			sender_name = name_lbl.text

	var channel := _current_channel
	var target := whisper_target.text.strip_edges() if whisper_target else ""
	if not target.is_empty() or channel == "Whisper":
		channel = "Whisper"
		var whisper_display := "To %s" % (target if not target.is_empty() else "Player")
		add_chat_message(whisper_display, clean, "Whisper")
		if hud and hud.has_signal("chat_message_sent"):
			hud.chat_message_sent.emit("Whisper", clean)
	else:
		add_chat_message(sender_name, clean, channel)
		if hud and hud.has_signal("chat_message_sent"):
			hud.chat_message_sent.emit(channel, clean)

	if chat_input:
		chat_input.text = ""
		chat_input.release_focus()

# ==============================================================================
# Internal Setup and Styling Helpers
# ==============================================================================

func _setup_chat_dock_components() -> void:
	if chat_history:
		chat_history.add_theme_font_size_override("normal_font_size", 12)
		chat_history.add_theme_constant_override("line_separation", 2)
		chat_history.add_theme_constant_override("table_h_separation", 2)
		chat_history.add_theme_constant_override("table_v_separation", 0)
		chat_history.add_theme_color_override("default_color", Color(1, 1, 1, 1))
		chat_history.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
		chat_history.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
		chat_history.add_theme_constant_override("shadow_offset_x", 1)
		chat_history.add_theme_constant_override("shadow_offset_y", 1)
		chat_history.add_theme_constant_override("shadow_outline_size", 1)
		chat_history.add_theme_constant_override("outline_size", 1)
		if not chat_history.meta_clicked.is_connected(_on_chat_meta_clicked):
			chat_history.meta_clicked.connect(_on_chat_meta_clicked)

	if chat_input and not chat_input.text_submitted.is_connected(on_chat_submitted):
		chat_input.text_submitted.connect(on_chat_submitted)

	if send_button and not send_button.pressed.is_connected(on_send_pressed):
		send_button.pressed.connect(on_send_pressed)

	# Mail button: clean 26x21 envelope icon textures
	if btn_mail:
		btn_mail.ignore_texture_size = true
		btn_mail.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		var mail_norm := _load_texture_file("assets/hud/btn_mail_normal.png")
		var mail_hov := _load_texture_file("assets/hud/btn_mail_hover.png")
		var mail_press := _load_texture_file("assets/hud/btn_mail_pressed.png")
		if mail_norm: btn_mail.texture_normal = mail_norm
		if mail_hov: btn_mail.texture_hover = mail_hov
		if mail_press: btn_mail.texture_pressed = mail_press
		if not btn_mail.pressed.is_connected(_on_mailbox_pressed):
			btn_mail.pressed.connect(_on_mailbox_pressed)

	# Channel button & dropdown
	if btn_channel:
		btn_channel.text = _current_channel
		if not btn_channel.pressed.is_connected(_on_channel_pressed):
			btn_channel.pressed.connect(_on_channel_pressed)
		_setup_channel_dropdown()
		_update_channel_button_style()

	# Whisper target input
	if whisper_target and not whisper_target.text_changed.is_connected(_on_whisper_target_changed):
		whisper_target.text_changed.connect(_on_whisper_target_changed)

	# Emote button & popup
	if btn_emote:
		btn_emote.ignore_texture_size = true
		btn_emote.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		var em_norm := _load_texture_file("assets/hud/btn_expression_normal.png")
		var em_hov := _load_texture_file("assets/hud/btn_expression_hover.png")
		var em_press := _load_texture_file("assets/hud/btn_expression_pressed.png")
		if em_norm: btn_emote.texture_normal = em_norm
		if em_hov: btn_emote.texture_hover = em_hov
		if em_press: btn_emote.texture_pressed = em_press
		if not btn_emote.pressed.is_connected(_on_emote_btn_pressed):
			btn_emote.pressed.connect(_on_emote_btn_pressed)
		_setup_emote_popup()

	# Left panel buttons
	if panel_talk_form_left:
		panel_talk_form_left.texture = null
		panel_talk_form_left.mouse_filter = Control.MOUSE_FILTER_PASS
	if btn_msg_lock:
		btn_msg_lock.texture_normal = _load_texture_file("assets/hud/btn_msg_lock_normal.png")
		btn_msg_lock.texture_hover = _load_texture_file("assets/hud/btn_msg_lock_hover.png")
		btn_msg_lock.texture_pressed = _load_texture_file("assets/hud/btn_msg_lock_pressed.png")
		if not btn_msg_lock.pressed.is_connected(_on_msg_lock_pressed):
			btn_msg_lock.pressed.connect(_on_msg_lock_pressed)

	if btn_chat_switch:
		btn_chat_switch.texture_normal = _load_texture_file("assets/hud/btn_chat_switch.png")
		if not btn_chat_switch.pressed.is_connected(_on_chat_switch_pressed):
			btn_chat_switch.pressed.connect(_on_chat_switch_pressed)

	if chat_frame_nine_patch:
		chat_frame_nine_patch.texture = null
		chat_frame_nine_patch.visible = false

	if btn_chat_size:
		btn_chat_size.texture_normal = null
		if not btn_chat_size.pressed.is_connected(_on_chat_size_pressed):
			btn_chat_size.pressed.connect(_on_chat_size_pressed)
		if not btn_chat_size.gui_input.is_connected(_on_chat_size_gui_input):
			btn_chat_size.gui_input.connect(_on_chat_size_gui_input)

	if chat_resize_handle and not chat_resize_handle.gui_input.is_connected(_on_chat_size_gui_input):
		chat_resize_handle.gui_input.connect(_on_chat_size_gui_input)

	if chat_input_bg:
		chat_input_bg.texture = null

func _setup_channel_tabs() -> void:
	_update_channel_tabs_position()
	var tab_buttons = [
		{"btn": btn_tab_all, "name": "All"},
		{"btn": btn_tab_current, "name": "Current"},
		{"btn": btn_tab_team, "name": "Team"},
		{"btn": btn_tab_guild, "name": "Guild"},
		{"btn": btn_tab_whisper, "name": "Whisper"},
		{"btn": btn_tab_system, "name": "System"},
	]
	for item in tab_buttons:
		var btn: Button = item["btn"]
		var tname: String = item["name"]
		if btn and not btn.pressed.is_connected(select_chat_tab.bind(tname)):
			btn.pressed.connect(select_chat_tab.bind(tname))
	_update_tab_button_visuals()

## The original chat is bare outlined text over the world with no tab row; the tabs stay in the tree
## for the channel filter API.
func _apply_real_client_look() -> void:
	# While the input field has focus the real chat shows its translucent framed panel behind the log.
	if chat_input and not chat_input.focus_entered.is_connected(_on_chat_input_focus_changed.bind(true)):
		chat_input.focus_entered.connect(_on_chat_input_focus_changed.bind(true))
		chat_input.focus_exited.connect(_on_chat_input_focus_changed.bind(false))
	if channel_tabs:
		channel_tabs.visible = false
	_refresh_lock_button()
	if btn_chat_switch:
		btn_chat_switch.tooltip_text = "Chat Box Switch"
	if btn_channel:
		btn_channel.tooltip_text = "Switch Channel"
	if btn_emote:
		btn_emote.tooltip_text = "Chat Emotes"
	_style_channel_list_like_real()
	if chat_history:
		# The original draws chat in a fixed-width pixel font (SimSun / MingLiU style) with a 1 px dark shadow.
		var pixel_font := SystemFont.new()
		pixel_font.font_names = PackedStringArray(["NSimSun", "SimSun", "MingLiU", "Courier New"])
		pixel_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		pixel_font.hinting = TextServer.HINTING_LIGHT
		pixel_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		var fallback := load("res://assets/fonts/NotoSansTC-Regular.ttf") as Font
		if fallback:
			pixel_font.fallbacks = [fallback]
		for font_slot in ["normal_font", "bold_font", "italics_font", "bold_italics_font", "mono_font"]:
			chat_history.add_theme_font_override(font_slot, pixel_font)
		for size_slot in ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size", "mono_font_size"]:
			chat_history.add_theme_font_size_override(size_slot, 12)
		chat_history.add_theme_color_override("font_outline_color", Color(0.10, 0.07, 0.02, 1.0))
		chat_history.add_theme_constant_override("outline_size", 2)
		chat_history.add_theme_constant_override("line_separation", 2)
		chat_history.add_theme_constant_override("table_h_separation", 2)
		chat_history.add_theme_constant_override("table_v_separation", 0)


## The real channel popup is a stack of bright green buttons (Guild, Team, Whisper ...) without any panel behind them.
func _style_channel_list_like_real() -> void:
	if channel_dropdown == null:
		return
	channel_dropdown.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var list := channel_dropdown.get_node_or_null("ChannelList")
	if list == null:
		return
	for child in list.get_children():
		var btn := child as Button
		if btn == null:
			continue
		for state in ["normal", "hover", "pressed", "focus"]:
			var box := StyleBoxFlat.new()
			box.bg_color = Color(0.30, 0.76, 0.18, 1.0) if state != "hover" else Color(0.45, 0.88, 0.30, 1.0)
			box.border_color = Color(0.78, 0.94, 0.45, 1.0)
			box.set_border_width_all(1)
			box.set_corner_radius_all(2)
			btn.add_theme_stylebox_override(state, box)
		for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			btn.add_theme_color_override(color_name, Color(1, 1, 1, 1))
		btn.add_theme_color_override("font_outline_color", Color(0.05, 0.25, 0.05, 1.0))
		btn.add_theme_constant_override("outline_size", 3)


func _update_channel_tabs_position() -> void:
	_apply_real_client_look()
	if channel_tabs and chat_history_panel:
		channel_tabs.offset_top = chat_history_panel.offset_top - 21.0
		channel_tabs.offset_bottom = chat_history_panel.offset_top
		channel_tabs.offset_left = 0.0

func _update_tab_button_visuals() -> void:
	if not _style_tab_active:
		_init_tab_styles()
	var tab_buttons = [
		{"btn": btn_tab_all, "name": "All"},
		{"btn": btn_tab_current, "name": "Current"},
		{"btn": btn_tab_team, "name": "Team"},
		{"btn": btn_tab_guild, "name": "Guild"},
		{"btn": btn_tab_whisper, "name": "Whisper"},
		{"btn": btn_tab_system, "name": "System"},
	]
	for item in tab_buttons:
		var btn: Button = item["btn"]
		if not btn:
			continue
		var is_active: bool = (item["name"] == _active_chat_tab)
		btn.add_theme_stylebox_override("normal", _style_tab_active if is_active else _style_tab_inactive)
		btn.add_theme_stylebox_override("hover", _style_tab_hover)
		btn.add_theme_stylebox_override("pressed", _style_tab_active)
		btn.add_theme_stylebox_override("focus", _style_empty)
		if is_active:
			btn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.35, 1.0))
			btn.add_theme_color_override("font_outline_color", Color(0.12, 0.06, 0.0, 1.0))
			btn.add_theme_constant_override("outline_size", 2)
		else:
			btn.add_theme_color_override("font_color", Color(0.82, 0.82, 0.80, 0.85))
			btn.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.04, 0.95))
			btn.add_theme_constant_override("outline_size", 1)

func _on_chat_input_focus_changed(focused: bool) -> void:
	_chat_is_framed = focused
	_update_chat_frame_style()


var _drag_handle: Control = null


func _ensure_chat_art() -> void:
	if _drag_handle != null or chat_history_panel == null:
		return
	var dock := chat_history_panel.get_parent()
	if dock == null:
		return
	# Corner drag handle for resizing chat height
	_drag_handle = Control.new()
	_drag_handle.name = "ChatDragHandle"
	_drag_handle.size = Vector2(30, 30)
	_drag_handle.mouse_filter = Control.MOUSE_FILTER_STOP
	_drag_handle.mouse_default_cursor_shape = Control.CURSOR_VSIZE
	_drag_handle.tooltip_text = "Drag to resize the chat"
	_drag_handle.gui_input.connect(_on_chat_size_gui_input)
	dock.add_child(_drag_handle)
	if not chat_history_panel.resized.is_connected(_sync_chat_art):
		chat_history_panel.resized.connect(_sync_chat_art)
		chat_history_panel.item_rect_changed.connect(_sync_chat_art)


func _sync_chat_art() -> void:
	if chat_history_panel == null:
		return
	var rect := Rect2(chat_history_panel.position, chat_history_panel.size)
	if _drag_handle:
		_drag_handle.position = Vector2(rect.end.x - 30.0, rect.position.y)
		_drag_handle.visible = not _chat_box_collapsed


func _update_chat_frame_style() -> void:
	if not chat_history_panel:
		return
	_ensure_chat_art()
	var chat_bg := StyleBoxFlat.new()
	if _chat_is_framed:
		chat_bg.bg_color = Color(0.04, 0.06, 0.10, 0.88)
		chat_bg.border_color = Color(0.35, 0.50, 0.65, 0.80)
		chat_bg.set_border_width_all(1)
		chat_bg.set_corner_radius_all(3)
	else:
		chat_bg.bg_color = Color(0, 0, 0, 0)
		chat_bg.border_color = Color(0, 0, 0, 0)
		chat_bg.set_border_width_all(0)
	chat_bg.content_margin_left = 12.0
	chat_bg.content_margin_top = 4.0
	chat_bg.content_margin_right = 12.0
	chat_bg.content_margin_bottom = 4.0
	chat_history_panel.add_theme_stylebox_override("panel", chat_bg)
	_sync_chat_art()
	if chat_frame_nine_patch:
		chat_frame_nine_patch.visible = false

func _setup_channel_dropdown() -> void:
	if not channel_dropdown:
		return
	channel_dropdown.visible = false
	var list = channel_dropdown.get_node_or_null("ChannelList")
	if not list:
		return
	var chans = ["Guild", "Team", "Whisper", "World", "Local"]
	for cname in chans:
		var btn = list.get_node_or_null("BtnChan" + cname) as Button
		if btn and not btn.pressed.is_connected(_select_channel.bind(cname)):
			btn.pressed.connect(_select_channel.bind(cname))

func _select_channel(cname: String) -> void:
	_current_channel = cname
	if btn_channel:
		btn_channel.text = cname
		btn_channel.tooltip_text = "Chat Channel: " + cname
		_update_channel_button_style()
	if channel_dropdown:
		channel_dropdown.visible = false
	_update_input_bar_layout()
	if cname == "Whisper" and whisper_target:
		whisper_target.grab_focus()

func _on_channel_pressed() -> void:
	if channel_dropdown:
		channel_dropdown.visible = !channel_dropdown.visible
	else:
		add_chat_message("System", "Current Chat Channel: %s" % _current_channel, "System")

func _on_whisper_target_changed(new_text: String) -> void:
	if not new_text.is_empty() and _current_channel != "Whisper":
		_select_channel("Whisper")

func _setup_emote_popup() -> void:
	if not emote_popup:
		return
	emote_popup.visible = false
	var bg = emote_popup.get_node_or_null("EmoteBackground") as TextureRect
	if bg:
		bg.texture = _load_texture_file("assets/hud/panel_expression.png")
	if emote_close_btn and not emote_close_btn.pressed.is_connected(func(): emote_popup.visible = false):
		emote_close_btn.pressed.connect(func(): emote_popup.visible = false)

	if emote_grid and emote_grid.get_child_count() == 0:
		for i in range(1, 32):
			var tb := TextureButton.new()
			tb.custom_minimum_size = Vector2(20, 20)
			tb.ignore_texture_size = true
			tb.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			var tex := _load_texture_file("assets/hud/icon_expre_%d.png" % i)
			if tex:
				tb.texture_normal = tex
			var code := "#%02d" % i
			tb.tooltip_text = code
			tb.pressed.connect(func():
				if chat_input:
					chat_input.text += code
					chat_input.grab_focus()
				display_player_overhead_bubble(code)
				emote_popup.visible = false
			)
			emote_grid.add_child(tb)

func _on_emote_btn_pressed() -> void:
	if emote_popup:
		emote_popup.visible = !emote_popup.visible

## "Chat Box Switch": hides the whole log and leaves only the input bar (and this one button); pressing again restores it.
var _chat_box_collapsed: bool = false

func _on_chat_switch_pressed() -> void:
	_chat_box_collapsed = !_chat_box_collapsed
	_apply_chat_box_collapsed()

func _apply_chat_box_collapsed() -> void:
	if chat_history:
		chat_history.visible = not _chat_box_collapsed
	for strip_button in [btn_msg_lock, btn_chat_size]:
		if strip_button:
			strip_button.visible = not _chat_box_collapsed
	if btn_chat_switch:
		# the strip art already paints the purple switch; only the collapsed state needs its own sprite
		btn_chat_switch.texture_normal = _load_texture_file("assets/hud/btn_chat_switch.png") if _chat_box_collapsed else null
		btn_chat_switch.position = Vector2(2, 62) if _chat_box_collapsed else Vector2(18, 62)
	_sync_chat_art()
	if chat_history_panel:
		chat_history_panel.visible = true # the switch button lives inside the panel
		chat_history_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE if _chat_box_collapsed else Control.MOUSE_FILTER_STOP

func is_chat_box_collapsed() -> bool:
	return _chat_box_collapsed

## "Chatbox: Locked / Unlocked": a locked box stops following new messages and shows the lock in gold.
func _on_msg_lock_pressed() -> void:
	_chat_is_locked = !_chat_is_locked
	if chat_history:
		chat_history.scroll_following = !_chat_is_locked
	_refresh_lock_button()

func _refresh_lock_button() -> void:
	if btn_msg_lock == null:
		return
	btn_msg_lock.tooltip_text = "Chatbox: Locked" if _chat_is_locked else "Chatbox: Unlocked"
	var normal_tex := _load_texture_file("assets/hud/btn_msg_lock_normal.png")
	var pressed_tex := _load_texture_file("assets/hud/btn_msg_lock_pressed.png")
	btn_msg_lock.texture_normal = pressed_tex if (_chat_is_locked and pressed_tex) else normal_tex

func _on_chat_size_pressed() -> void:
	if not chat_history_panel:
		return
	_chat_height_state = (_chat_height_state + 1) % 3
	var heights := [-86.0, -140.0, -200.0]
	chat_history_panel.offset_top = heights[_chat_height_state]
	_update_channel_tabs_position()

func _on_chat_size_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_chat_is_resizing = true
			_chat_resize_start_y = event.global_position.y
			if chat_history_panel:
				_chat_resize_start_top = chat_history_panel.offset_top
		else:
			_chat_is_resizing = false
	elif event is InputEventMouseMotion and _chat_is_resizing and chat_history_panel:
		var dy: float = event.global_position.y - _chat_resize_start_y
		var new_top: float = clampf(_chat_resize_start_top + dy, -350.0, -60.0)
		chat_history_panel.offset_top = new_top
		_chat_height_state = 0
		_update_channel_tabs_position()
		_sync_chat_art()

func _on_chat_meta_clicked(meta: Variant) -> void:
	var meta_str := str(meta)
	if meta_str.begins_with("whisper:"):
		var target := meta_str.substr(8).strip_edges()
		whisper_to_player(target)
	else:
		whisper_to_player(meta_str)

func _on_mailbox_pressed() -> void:
	add_chat_message("System", "Mailbox opened. You have 0 unread messages.", "System")
	if hud and hud.has_signal("banner_emitted"):
		hud.banner_emitted.emit("Mailbox: 0 unread messages")

func _message_matches_tab(channel: String, tab_name: String) -> bool:
	if tab_name == "All":
		return true
	var ch := channel.to_lower()
	var t := tab_name.to_lower()
	if t == "current" or t == "local":
		return ch == "current" or ch == "local" or ch == "general"
	elif t == "team":
		return ch == "team"
	elif t == "guild":
		return ch == "guild"
	elif t == "whisper":
		return ch == "whisper"
	elif t == "system":
		return ch == "system"
	return false

func _load_texture_file(rel_path: String) -> Texture2D:
	var res_path: String = rel_path if rel_path.begins_with("res://") else ("res://" + rel_path)
	if ResourceLoader.exists(res_path):
		var res = load(res_path)
		if res is Texture2D:
			return res
	var abs_path: String = "D:/Godot/WonderlandOnline/wonderland-online-client/" + rel_path if not rel_path.begins_with("res://") else ProjectSettings.globalize_path(res_path)
	if not FileAccess.file_exists(abs_path):
		return null
	var img := Image.new()
	var err := img.load(abs_path)
	if err == OK:
		return ImageTexture.create_from_image(img)
	return null
