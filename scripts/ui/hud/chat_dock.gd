class_name ChatDock
extends Control

## Authentic Wonderland Online Chat Dock.
## Supports responsive height resizing via drag handle and size button,
## sleek parchment scrollbar, authentic channel tabs (All, Current, Team, Guild, Whisper, System),
## auto-fitting input bar matching main_input_1 skin geometry, 31-emote popup grid,
## channel dropdown routing, and compact/framed mode toggling.

signal message_sent(channel: String, text: String)
signal tab_changed(tab_name: String)
signal overhead_bubble_emitted(code_or_text: String)
signal whisper_target_changed(target_name: String)

# UI Node References
@onready var chat_history_panel: PanelContainer = $ChatHistoryPanel if has_node("ChatHistoryPanel") else null
@onready var chat_history: RichTextLabel = $ChatHistoryPanel/ChatHistory if has_node("ChatHistoryPanel/ChatHistory") else null
@onready var chat_resize_handle: Control = $ChatHistoryPanel/ChatResizeHandle if has_node("ChatHistoryPanel/ChatResizeHandle") else null
@onready var chat_frame_nine_patch: NinePatchRect = $ChatHistoryPanel/ChatFrameNinePatch if has_node("ChatHistoryPanel/ChatFrameNinePatch") else null
@onready var panel_talk_form_left: TextureRect = $ChatHistoryPanel/PanelTalkFormLeft if has_node("ChatHistoryPanel/PanelTalkFormLeft") else null
@onready var btn_msg_lock: TextureButton = $ChatHistoryPanel/PanelTalkFormLeft/BtnMsgLock if has_node("ChatHistoryPanel/PanelTalkFormLeft/BtnMsgLock") else null
@onready var btn_chat_switch: TextureButton = $ChatHistoryPanel/PanelTalkFormLeft/BtnChatSwitch if has_node("ChatHistoryPanel/PanelTalkFormLeft/BtnChatSwitch") else null
@onready var btn_chat_size: TextureButton = $ChatHistoryPanel/BtnChatSize if has_node("ChatHistoryPanel/BtnChatSize") else null

@onready var channel_tabs: Control = $ChannelTabs if has_node("ChannelTabs") else null
@onready var btn_tab_all: Button = $ChannelTabs/BtnTabAll if has_node("ChannelTabs/BtnTabAll") else null
@onready var btn_tab_current: Button = $ChannelTabs/BtnTabCurrent if has_node("ChannelTabs/BtnTabCurrent") else null
@onready var btn_tab_team: Button = $ChannelTabs/BtnTabTeam if has_node("ChannelTabs/BtnTabTeam") else null
@onready var btn_tab_guild: Button = $ChannelTabs/BtnTabGuild if has_node("ChannelTabs/BtnTabGuild") else null
@onready var btn_tab_whisper: Button = $ChannelTabs/BtnTabWhisper if has_node("ChannelTabs/BtnTabWhisper") else null
@onready var btn_tab_system: Button = $ChannelTabs/BtnTabSystem if has_node("ChannelTabs/BtnTabSystem") else null

@onready var chat_input_bg: TextureRect = $ChatInputBackground if has_node("ChatInputBackground") else null
@onready var btn_mail: TextureButton = $BtnMail if has_node("BtnMail") else null
@onready var btn_channel: Button = $BtnChannel if has_node("BtnChannel") else null
@onready var whisper_target: LineEdit = $WhisperTarget if has_node("WhisperTarget") else null
@onready var chat_input: LineEdit = $ChatInput if has_node("ChatInput") else null
@onready var btn_emote: TextureButton = $BtnEmote if has_node("BtnEmote") else null
@onready var send_button: Button = $SendButton if has_node("SendButton") else null

@onready var channel_dropdown: Control = $ChannelDropdown if has_node("ChannelDropdown") else null
@onready var emote_popup: Control = $EmotePopup if has_node("EmotePopup") else null
@onready var emote_grid: GridContainer = $EmotePopup/EmoteGrid if has_node("EmotePopup/EmoteGrid") else null
@onready var emote_close_btn: Button = $EmotePopup/EmoteCloseBtn if has_node("EmotePopup/EmoteCloseBtn") else null

# State
var _chat_is_framed: bool = false
var _chat_is_locked: bool = false
var _chat_height_state: int = 0 # 0: -86, 1: -140, 2: -200
var _current_channel: String = "Local"
var _active_chat_tab: String = "All"
var _chat_is_resizing: bool = false
var _chat_resize_start_y: float = 0.0
var _chat_resize_start_top: float = -86.0
var _chat_messages: Array[Dictionary] = []
var _smooth_scroll_tween: Tween = null
var _dock_width: float = 524.0

# Tab StyleBox cache
var _style_tab_inactive: StyleBoxFlat = null
var _style_tab_hover: StyleBoxFlat = null
var _style_tab_active: StyleBoxFlat = null
var _style_empty: StyleBoxEmpty = null

const CHAT_HEIGHT_PRESETS: Array[float] = [-86.0, -140.0, -200.0]

func _ready() -> void:
	anchors_preset = Control.PRESET_BOTTOM_LEFT
	_init_tab_styles()
	_setup_components()
	_setup_custom_scrollbar()
	_setup_channel_tabs()
	_setup_input_fields_style()
	_setup_channel_dropdown_style()
	_setup_emotes()
	_update_chat_frame_style()
	_update_input_bar_layout()
	_update_channel_tabs_position()
	_apply_real_client_look()


## The original chat is bare text with a dark outline straight over the world (no panel, no tab row);
## the tabs stay in the tree for the channel filter API (docs/re/ui_windows.md).
func _apply_real_client_look() -> void:
	if channel_tabs:
		channel_tabs.visible = false
	if chat_history:
		chat_history.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.02, 1.0))
		chat_history.add_theme_constant_override("outline_size", 4)

func _input(event: InputEvent) -> void:
	if _chat_is_resizing:
		if event is InputEventMouseMotion and chat_history_panel:
			var dy: float = event.global_position.y - _chat_resize_start_y
			var new_top: float = clampf(_chat_resize_start_top + dy, -350.0, -60.0)
			chat_history_panel.offset_top = new_top
			_update_channel_tabs_position()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_chat_is_resizing = false

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

func _setup_components() -> void:
	if btn_msg_lock and not btn_msg_lock.pressed.is_connected(_on_btn_msg_lock_pressed):
		btn_msg_lock.pressed.connect(_on_btn_msg_lock_pressed)
	if btn_chat_switch and not btn_chat_switch.pressed.is_connected(_on_btn_chat_switch_pressed):
		btn_chat_switch.pressed.connect(_on_btn_chat_switch_pressed)
	if btn_chat_size and not btn_chat_size.pressed.is_connected(_on_btn_chat_size_pressed):
		btn_chat_size.pressed.connect(_on_btn_chat_size_pressed)
	if chat_resize_handle and not chat_resize_handle.gui_input.is_connected(_on_chat_resize_handle_gui_input):
		chat_resize_handle.gui_input.connect(_on_chat_resize_handle_gui_input)
	if btn_channel and not btn_channel.pressed.is_connected(_on_btn_channel_pressed):
		btn_channel.pressed.connect(_on_btn_channel_pressed)
	if btn_emote and not btn_emote.pressed.is_connected(_on_btn_emote_pressed):
		btn_emote.pressed.connect(_on_btn_emote_pressed)
	if emote_close_btn and not emote_close_btn.pressed.is_connected(_on_emote_close_pressed):
		emote_close_btn.pressed.connect(_on_emote_close_pressed)
	if chat_input and not chat_input.text_submitted.is_connected(_on_chat_submitted):
		chat_input.text_submitted.connect(_on_chat_submitted)
	if send_button and not send_button.pressed.is_connected(_on_send_button_pressed):
		send_button.pressed.connect(_on_send_button_pressed)
	if whisper_target and not whisper_target.text_changed.is_connected(_on_whisper_target_changed):
		whisper_target.text_changed.connect(_on_whisper_target_changed)
	if chat_history and not chat_history.meta_clicked.is_connected(_on_chat_meta_clicked):
		chat_history.meta_clicked.connect(_on_chat_meta_clicked)

	_setup_channel_dropdown()
	_load_textures()

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
		in_norm.bg_color = Color(0.02, 0.03, 0.05, 0.30)
		in_norm.corner_radius_top_left = 2
		in_norm.corner_radius_top_right = 2
		in_norm.corner_radius_bottom_left = 2
		in_norm.corner_radius_bottom_right = 2
		in_norm.content_margin_left = 6.0
		in_norm.content_margin_right = 6.0
		in_norm.content_margin_top = 2.0
		in_norm.content_margin_bottom = 2.0

		var in_focus := in_norm.duplicate() as StyleBoxFlat
		in_focus.bg_color = Color(0.03, 0.05, 0.08, 0.55)
		in_focus.border_width_left = 1
		in_focus.border_width_top = 1
		in_focus.border_width_right = 1
		in_focus.border_width_bottom = 1
		in_focus.border_color = Color(0.85, 0.72, 0.38, 0.60)

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

func _load_textures() -> void:
	if chat_input_bg:
		chat_input_bg.texture = null
	if btn_mail:
		var mail_norm := _load_texture_file("assets/hud/btn_mail_normal.png")
		var mail_hov := _load_texture_file("assets/hud/btn_mail_hover.png")
		var mail_press := _load_texture_file("assets/hud/btn_mail_pressed.png")
		if mail_norm: btn_mail.texture_normal = mail_norm
		if mail_hov: btn_mail.texture_hover = mail_hov
		if mail_press: btn_mail.texture_pressed = mail_press
	if btn_emote:
		var tex_norm := _load_texture_file("assets/hud/btn_expression_normal.png")
		var tex_hov := _load_texture_file("assets/hud/btn_expression_hover.png")
		var tex_press := _load_texture_file("assets/hud/btn_expression_pressed.png")
		if tex_norm: btn_emote.texture_normal = tex_norm
		if tex_hov: btn_emote.texture_hover = tex_hov
		if tex_press: btn_emote.texture_pressed = tex_press
	if btn_msg_lock:
		var l_norm := _load_texture_file("assets/hud/btn_msg_lock_normal.png")
		var l_hov := _load_texture_file("assets/hud/btn_msg_lock_hover.png")
		var l_press := _load_texture_file("assets/hud/btn_msg_lock_pressed.png")
		if l_norm: btn_msg_lock.texture_normal = l_norm
		if l_hov: btn_msg_lock.texture_hover = l_hov
		if l_press: btn_msg_lock.texture_pressed = l_press
	if btn_chat_switch:
		var s_tex := _load_texture_file("assets/hud/btn_chat_switch.png")
		if s_tex: btn_chat_switch.texture_normal = s_tex
	if btn_chat_size:
		btn_chat_size.texture_normal = null
	if panel_talk_form_left:
		panel_talk_form_left.texture = null
		panel_talk_form_left.mouse_filter = Control.MOUSE_FILTER_PASS

func _setup_channel_tabs() -> void:
	var tabs: Array[Dictionary] = [
		{"btn": btn_tab_all, "name": "All"},
		{"btn": btn_tab_current, "name": "Current"},
		{"btn": btn_tab_team, "name": "Team"},
		{"btn": btn_tab_guild, "name": "Guild"},
		{"btn": btn_tab_whisper, "name": "Whisper"},
		{"btn": btn_tab_system, "name": "System"},
	]
	for item in tabs:
		var btn: Button = item["btn"]
		if btn:
			var t_name: String = item["name"]
			if not btn.pressed.is_connected(select_chat_tab.bind(t_name)):
				btn.pressed.connect(select_chat_tab.bind(t_name))
	_update_tab_button_visuals()

func _setup_channel_dropdown() -> void:
	if not channel_dropdown:
		return
	var chan_list: Node = channel_dropdown.get_node_or_null("ChannelList")
	if not chan_list:
		return
	var map: Dictionary = {
		"BtnChanLocal": "Local",
		"BtnChanWorld": "World",
		"BtnChanTeam": "Team",
		"BtnChanGuild": "Guild",
		"BtnChanWhisper": "Whisper",
	}
	for node_name in map.keys():
		var btn = chan_list.get_node_or_null(node_name) as Button
		if btn and not btn.pressed.is_connected(_select_channel.bind(map[node_name])):
			btn.pressed.connect(_select_channel.bind(map[node_name]))

func _setup_emotes() -> void:
	if not emote_popup:
		return
	var bg = emote_popup.get_node_or_null("EmoteBackground") as TextureRect
	if bg and not bg.texture:
		bg.texture = _load_texture_file("assets/hud/panel_expression.png")
	if not emote_grid:
		return
	if emote_grid.get_child_count() > 0:
		return
	for i in range(1, 32):
		var btn := TextureButton.new()
		btn.custom_minimum_size = Vector2(20, 20)
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		var emote_code := "#%02d" % i
		btn.tooltip_text = emote_code

		var icon_tex := _load_texture_file("assets/hud/icon_expre_%d.png" % i)
		if icon_tex:
			btn.texture_normal = icon_tex

		btn.pressed.connect(_on_emote_selected.bind(emote_code))
		emote_grid.add_child(btn)

## Auto-fits input bar when whisper target is shown or hidden, or dock width changes
func _update_input_bar_layout() -> void:
	var is_whisper: bool = (_current_channel == "Whisper")
	if whisper_target:
		whisper_target.visible = is_whisper
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
		var in_x: float = 163.0 if is_whisper else 74.0
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
	sb_norm.bg_color = border_col.darkened(0.1) # the real channel button is filled with the channel colour
	sb_norm.border_width_left = 1
	sb_norm.border_width_top = 1
	sb_norm.border_width_right = 1
	sb_norm.border_width_bottom = 1
	sb_norm.border_color = border_col
	sb_norm.corner_radius_top_left = 2
	sb_norm.corner_radius_top_right = 2
	sb_norm.corner_radius_bottom_left = 2
	sb_norm.corner_radius_bottom_right = 2

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
	btn_channel.text = _current_channel
	for color_name in ["font_color", "font_hover_color", "font_pressed_color"]:
		btn_channel.add_theme_color_override(color_name, Color(1, 1, 1, 1))
	btn_channel.add_theme_color_override("font_outline_color", Color(0.05, 0.25, 0.05, 1.0))
	btn_channel.add_theme_constant_override("outline_size", 3)
	btn_channel.tooltip_text = "Chat Channel: %s" % _current_channel

## Sets responsive dock width
func set_dock_width(new_width: float) -> void:
	_dock_width = maxf(380.0, new_width)
	size.x = _dock_width
	if chat_history_panel:
		chat_history_panel.size.x = _dock_width
	if channel_tabs:
		channel_tabs.size.x = minf(320.0, _dock_width)
	_update_input_bar_layout()

## Updates the vertical position of channel tabs above history panel
func _update_channel_tabs_position() -> void:
	if channel_tabs and chat_history_panel:
		channel_tabs.offset_top = chat_history_panel.offset_top - 21.0
		channel_tabs.offset_bottom = chat_history_panel.offset_top
		channel_tabs.offset_left = 0.0

## Adds a formatted chat message to history
func add_chat_message(sender: String, message: String, channel: String = "Local") -> void:
	var line: String = _format_line(sender, message, channel)
	var msg_data := {
		"channel": channel,
		"message": message,
		"sender": sender,
		"line": line,
		"timestamp": Time.get_unix_time_from_system()
	}
	_chat_messages.append(msg_data)
	if _message_matches_tab(channel, _active_chat_tab):
		if chat_history:
			chat_history.append_text(line)
			if not _chat_is_locked:
				_smooth_scroll_to_bottom()

## Backward-compatible add_message alias
func add_message(sender_or_channel: String, message: String, channel_or_sender: String = "") -> void:
	if channel_or_sender != "" and (channel_or_sender in ["Local", "World", "Team", "Guild", "Whisper", "System"]):
		add_chat_message(sender_or_channel, message, channel_or_sender)
	elif sender_or_channel in ["Local", "World", "Team", "Guild", "Whisper", "System"]:
		add_chat_message(channel_or_sender if channel_or_sender != "" else "System", message, sender_or_channel)
	else:
		add_chat_message(sender_or_channel, message, channel_or_sender if channel_or_sender != "" else "Local")

## The original prints one line per message in the channel colour: "(World)Name:message".
func _format_line(sender: String, message: String, channel: String) -> String:
	var ch_lower := channel.to_lower()
	var snd_lower := sender.to_lower()
	if ch_lower == "system" or snd_lower == "system":
		return "[color=#ff3b30](System)%s[/color]\n" % [message]
	var colour := "#42d766"
	var label := channel
	match ch_lower:
		"local", "current":
			label = "Local"
			colour = "#e8e8b0"
		"whisper":
			colour = "#ff66b2"
		"team":
			colour = "#4ab3ff"
		"guild":
			colour = "#32e070"
		"world":
			colour = "#ffea33"
	var target_name := sender.substr(3).strip_edges() if (ch_lower == "whisper" and sender.begins_with("To ")) else sender
	return "[color=%s](%s)[url=whisper:%s]%s[/url]:%s[/color]\n" % [colour, label, target_name, sender, message]

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
	return ch == t

## Smoothly animates the vertical scroll bar to the bottom
func _smooth_scroll_to_bottom() -> void:
	if not chat_history or not is_inside_tree():
		return
	var v_scroll: VScrollBar = chat_history.get_v_scroll_bar()
	if not v_scroll:
		return
	var target_val: float = v_scroll.max_value
	if _smooth_scroll_tween and _smooth_scroll_tween.is_valid():
		_smooth_scroll_tween.kill()
	_smooth_scroll_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_smooth_scroll_tween.tween_property(v_scroll, "value", target_val, 0.15)

func select_chat_tab(tab_name: String) -> void:
	_active_chat_tab = tab_name
	_rebuild_history_for_tab()
	_update_tab_button_visuals()
	tab_changed.emit(tab_name)

func _update_tab_button_visuals() -> void:
	if not _style_tab_active:
		_init_tab_styles()
	var tab_buttons := [
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

func _rebuild_history_for_tab() -> void:
	if not chat_history:
		return
	chat_history.clear()
	for msg in _chat_messages:
		var ch: String = msg.get("channel", "Local")
		if _message_matches_tab(ch, _active_chat_tab):
			chat_history.append_text(msg.get("line", ""))
	if not _chat_is_locked:
		chat_history.scroll_to_line(chat_history.get_line_count())

func _select_channel(channel: String) -> void:
	_current_channel = channel
	if btn_channel:
		btn_channel.text = channel
		btn_channel.tooltip_text = "Chat Channel: %s" % channel
	if channel_dropdown:
		channel_dropdown.visible = false
	_update_input_bar_layout()
	if channel == "Whisper" and whisper_target:
		whisper_target.grab_focus()

func _on_btn_channel_pressed() -> void:
	if channel_dropdown:
		channel_dropdown.visible = not channel_dropdown.visible

func _on_btn_emote_pressed() -> void:
	if emote_popup:
		emote_popup.visible = not emote_popup.visible

func _on_emote_close_pressed() -> void:
	if emote_popup:
		emote_popup.visible = false

func _on_emote_selected(emote_code: String) -> void:
	if chat_input:
		chat_input.text += emote_code
		chat_input.grab_focus()
		chat_input.caret_column = chat_input.text.length()
	overhead_bubble_emitted.emit(emote_code)
	if emote_popup:
		emote_popup.visible = false

func _on_btn_msg_lock_pressed() -> void:
	_chat_is_locked = not _chat_is_locked
	if chat_history:
		chat_history.scroll_following = not _chat_is_locked

func _on_btn_chat_switch_pressed() -> void:
	_chat_is_framed = not _chat_is_framed
	_update_chat_frame_style()

func _update_chat_frame_style() -> void:
	if chat_frame_nine_patch:
		chat_frame_nine_patch.visible = false
	if chat_history_panel:
		var chat_bg := StyleBoxFlat.new()
		if _chat_is_framed:
			chat_bg.bg_color = Color(0.04, 0.06, 0.10, 0.88)
			chat_bg.border_width_left = 1
			chat_bg.border_width_top = 1
			chat_bg.border_width_right = 1
			chat_bg.border_width_bottom = 1
			chat_bg.border_color = Color(0.35, 0.50, 0.65, 0.80)
			chat_bg.corner_radius_top_left = 3
			chat_bg.corner_radius_top_right = 3
		else:
			chat_bg.bg_color = Color(0, 0, 0, 0)
			chat_bg.border_width_left = 0
			chat_bg.border_width_top = 0
			chat_bg.border_width_right = 0
			chat_bg.border_width_bottom = 0
			chat_bg.border_color = Color(0, 0, 0, 0)
		chat_bg.content_margin_left = 12.0
		chat_bg.content_margin_top = 4.0
		chat_bg.content_margin_right = 12.0
		chat_bg.content_margin_bottom = 4.0
		chat_history_panel.add_theme_stylebox_override("panel", chat_bg)

func _on_btn_chat_size_pressed() -> void:
	_chat_height_state = (_chat_height_state + 1) % CHAT_HEIGHT_PRESETS.size()
	set_chat_height(CHAT_HEIGHT_PRESETS[_chat_height_state])

## Sets chat history panel height offset
func set_chat_height(new_offset_top: float) -> void:
	if chat_history_panel:
		chat_history_panel.offset_top = new_offset_top
		_update_channel_tabs_position()

func _on_chat_resize_handle_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_chat_is_resizing = true
			_chat_resize_start_y = event.global_position.y
			_chat_resize_start_top = chat_history_panel.offset_top if chat_history_panel else -86.0
		else:
			_chat_is_resizing = false

func _on_whisper_target_changed(new_target: String) -> void:
	if not new_target.is_empty() and _current_channel != "Whisper":
		_select_channel("Whisper")
	whisper_target_changed.emit(new_target)

func _on_chat_submitted(text: String) -> void:
	var clean_text := text.strip_edges()
	if clean_text.is_empty():
		return
	if chat_input:
		chat_input.clear()

	# Check /target syntax
	if clean_text.begins_with("/"):
		var parts := clean_text.split(" ", false, 2)
		var cmd := parts[0].trim_prefix("/").to_lower()
		if cmd == "target" or cmd == "w" or cmd == "whisper":
			if parts.size() >= 2:
				var t_name := parts[1]
				set_whisper_target(t_name)
				if parts.size() >= 3:
					clean_text = parts[2]
				else:
					return

	var target := whisper_target.text.strip_edges() if whisper_target else ""
	var channel := _current_channel
	if channel == "Whisper" and target != "":
		clean_text = "@%s %s" % [target, clean_text]

	message_sent.emit(channel, clean_text)
	add_chat_message("You", clean_text, channel)

func _on_send_button_pressed() -> void:
	if chat_input:
		_on_chat_submitted(chat_input.text)

func _on_chat_meta_clicked(meta: Variant) -> void:
	var meta_str := str(meta)
	if meta_str.begins_with("whisper:"):
		var target := meta_str.substr(8).strip_edges()
		set_whisper_target(target)
	else:
		set_whisper_target(meta_str)

## Configures whisper target and routes to Whisper channel
func set_whisper_target(target_name: String) -> void:
	if whisper_target:
		whisper_target.text = target_name
	_select_channel("Whisper")
	if chat_input:
		chat_input.grab_focus()

func _load_texture_file(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var abs_path := ProjectSettings.globalize_path("res://" + path.trim_prefix("res://"))
	if FileAccess.file_exists(abs_path):
		var img := Image.new()
		if img.load(abs_path) == OK:
			return ImageTexture.create_from_image(img)
	return null
