class_name SystemWindow
extends Control

const AuthAudioScript = preload("res://scripts/ui/auth/auth_audio.gd")
const PillScript = preload("res://scripts/ui/hud/pill_button.gd")
const SkinButtonScript = preload("res://scripts/ui/hud/skin_button.gd")

## Sub-controller and view for Wonderland Online System Settings Window (Form_System_2).
## Manages BGM and SFX volume sliders, mute toggles, Fullscreen/Windowed display mode,
## Resume, Character Select (Logout), and Exit Game actions.
## Persists configuration automatically to user://system_settings.json.

signal settings_changed(settings: Dictionary)
signal logout_requested
signal window_closed

const SETTINGS_FILE_PATH: String = "user://system_settings.json"
const DEFAULT_BGM_VOLUME: int = 80
const DEFAULT_SFX_VOLUME: int = 80
const WINDOW_WIDTH: float = 388.0
const WINDOW_HEIGHT: float = 451.0

## Caption top y of each baked row in Form_System_2 (card-local pixels).
const OPTION_ROWS: Dictionary = {
	"pvp_pk": 62.0,
	"join_battle": 87.0,
	"trading": 112.0,
	"chat_channels": 138.0,
	"info_visibility": 163.0,
	"zoom_mode": 188.0,
	"party_invites": 214.0,
}
const COLOR_ROWS: Dictionary = {
	"local": 270.0,
	"whisper": 300.0,
	"party": 330.0,
	"guild": 359.0,
	"world": 388.0,
}
const DEFAULT_OPTIONS: Dictionary = {
	"pvp_pk": false,
	"join_battle": true,
	"trading": true,
	"chat_channels": true,
	"info_visibility": true,
	"zoom_mode": false,
	"party_invites": true,
}
const DEFAULT_CHAT_COLORS: Dictionary = {
	"local": Color(0.26, 0.84, 0.40, 1.0),
	"whisper": Color(1.0, 0.40, 0.70, 1.0),
	"party": Color(0.29, 0.70, 1.0, 1.0),
	"guild": Color(0.20, 0.88, 0.44, 1.0),
	"world": Color(1.0, 0.92, 0.20, 1.0),
}

var _bgm_volume: int = DEFAULT_BGM_VOLUME
var _bgm_muted: bool = false
var _sfx_volume: int = DEFAULT_SFX_VOLUME
var _sfx_muted: bool = false
var _fullscreen: bool = false
var _options: Dictionary = DEFAULT_OPTIONS.duplicate()
var _chat_colors: Dictionary = DEFAULT_CHAT_COLORS.duplicate()
var _suppress_option_events: bool = false

var _is_building: bool = false
var _hud: Control = null

# Node references
var background: TextureRect = null
var title_label: Label = null
var close_button: Button = null

var bgm_label: Label = null
var bgm_slider: HSlider = null
var bgm_mute_check: CheckBox = null

var sfx_label: Label = null
var sfx_slider: HSlider = null
var sfx_mute_check: CheckBox = null

var fullscreen_check: CheckBox = null
var display_info_label: Label = null

var btn_resume: Button = null
var btn_logout: Button = null
var btn_exit: Button = null

func _init() -> void:
	size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)
	custom_minimum_size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)

func _ready() -> void:
	ensure_audio_buses()
	_build_ui_if_needed()
	load_settings()

func setup(hud: Control = null) -> void:
	_hud = hud
	ensure_audio_buses()
	_build_ui_if_needed()
	load_settings()

## Ensures BGM and SFX audio buses exist on AudioServer
static func ensure_audio_buses() -> void:
	if AudioServer.get_bus_index("BGM") == -1:
		var idx: int = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, "BGM")
		AudioServer.set_bus_send(idx, "Master")
	if AudioServer.get_bus_index("SFX") == -1:
		var idx: int = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, "SFX")
		AudioServer.set_bus_send(idx, "Master")

static func get_bgm_bus() -> int:
	ensure_audio_buses()
	var idx := AudioServer.get_bus_index("BGM")
	return idx if idx != -1 else AudioServer.get_bus_index("Master")

static func get_sfx_bus() -> int:
	ensure_audio_buses()
	var idx := AudioServer.get_bus_index("SFX")
	return idx if idx != -1 else AudioServer.get_bus_index("Master")

## Converts a 0..100 integer volume percentage to decibels
static func linear_to_bus_db(percentage: int) -> float:
	if percentage <= 0:
		return -80.0
	var linear: float = clampf(float(percentage) / 100.0, 0.0001, 1.0)
	return linear_to_db(linear)

## Converts decibels to a 0..100 integer volume percentage
static func bus_db_to_linear(db: float) -> int:
	if db <= -79.0:
		return 0
	var linear: float = db_to_linear(db)
	return clampi(roundi(linear * 100.0), 0, 100)

## Builds or binds all UI elements inside SystemWindow
func _build_ui_if_needed() -> void:
	if _is_building:
		return
	_is_building = true

	size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)
	custom_minimum_size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)

	# 1. Background TextureRect
	background = get_node_or_null("Background") as TextureRect
	if not background:
		background = TextureRect.new()
		background.name = "Background"
		add_child(background)
	background.position = Vector2.ZERO
	background.size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)
	background.mouse_filter = Control.MOUSE_FILTER_PASS

	if not background.texture:
		if ResourceLoader.exists("res://assets/hud/form_system_2.png"):
			background.texture = load("res://assets/hud/form_system_2.png")
		elif ResourceLoader.exists("res://assets/menu/Skins/white/Form_System_2.bmp"):
			var st := Engine.get_main_loop() as SceneTree
			var loader: Node = st.root.get_node_or_null("ArchiveLoader") if (st and st.root) else null
			if loader and loader.has_method("get_ui_texture"):
				var tex: ImageTexture = loader.get_ui_texture("menu/Skins/white/Form_System_2.bmp")
				if tex:
					background.texture = tex

	# 2. Title Label (Hidden by default, matching authentic Delphi skin)
	title_label = get_node_or_null("TitleLabel") as Label
	if not title_label:
		title_label = Label.new()
		title_label.name = "TitleLabel"
		add_child(title_label)
	title_label.position = Vector2(20, 8)
	title_label.size = Vector2(160, 20)
	title_label.visible = false
	title_label.text = "System Settings"

	# 3. Authentic 18x18 Close Button
	close_button = get_node_or_null("CloseButton") as Button
	if not close_button:
		close_button = Button.new()
		close_button.name = "CloseButton"
		add_child(close_button)
	WindowCloseButton.apply(close_button, WINDOW_WIDTH) # sits on the baked x sphere

	_apply_close_button_textures(close_button)

	for conn in close_button.pressed.get_connections():
		close_button.pressed.disconnect(conn.callable)
	close_button.pressed.connect(close_window)

	# 4. The skin (Form_System_2) bakes every caption: PVP and PK ... World Color on the left,
	#    Sound Options / BG Music / SFX / Blacklist on the right. The legacy caption labels stay
	#    hidden and every control sits on its baked row.
	for legacy_name in ["AudioSectionLabel", "DisplaySectionLabel"]:
		var legacy := get_node_or_null(legacy_name) as Label
		if legacy:
			legacy.visible = false

	var marker := _make_slider_marker()
	var clear := StyleBoxEmpty.new()

	# BG Music: baked bar at (256, 120)-(332, 127), baked arrows either side
	bgm_label = _ensure_percent_label("BgmLabel", Vector2(300, 90))
	bgm_slider = _ensure_overlay_slider("BgmSlider", Vector2(256, 116), marker, clear)
	bgm_slider.value = float(_bgm_volume)
	for conn in bgm_slider.value_changed.get_connections():
		bgm_slider.value_changed.disconnect(conn.callable)
	bgm_slider.value_changed.connect(func(val: float) -> void:
		set_bgm_volume(int(val), true)
	)
	_ensure_arrow_overlay("BgmDownBtn", Vector2(237, 115), func() -> void: set_bgm_volume(_bgm_volume - 10, true))
	_ensure_arrow_overlay("BgmUpBtn", Vector2(334, 115), func() -> void: set_bgm_volume(_bgm_volume + 10, true))
	bgm_mute_check = _ensure_mute_check("BgmMuteCheck", Vector2(214, 132), _bgm_muted)
	for conn in bgm_mute_check.toggled.get_connections():
		bgm_mute_check.toggled.disconnect(conn.callable)
	bgm_mute_check.toggled.connect(func(pressed: bool) -> void:
		set_bgm_muted(pressed, true)
	)

	# SFX: baked bar at (256, 190)-(332, 197)
	sfx_label = _ensure_percent_label("SfxLabel", Vector2(300, 160))
	sfx_slider = _ensure_overlay_slider("SfxSlider", Vector2(256, 186), marker, clear)
	sfx_slider.value = float(_sfx_volume)
	for conn in sfx_slider.value_changed.get_connections():
		sfx_slider.value_changed.disconnect(conn.callable)
	sfx_slider.value_changed.connect(func(val: float) -> void:
		set_sfx_volume(int(val), true)
	)
	_ensure_arrow_overlay("SfxDownBtn", Vector2(237, 185), func() -> void: set_sfx_volume(_sfx_volume - 10, true))
	_ensure_arrow_overlay("SfxUpBtn", Vector2(334, 185), func() -> void: set_sfx_volume(_sfx_volume + 10, true))
	sfx_mute_check = _ensure_mute_check("SfxMuteCheck", Vector2(214, 202), _sfx_muted)
	for conn in sfx_mute_check.toggled.get_connections():
		sfx_mute_check.toggled.disconnect(conn.callable)
	sfx_mute_check.toggled.connect(func(pressed: bool) -> void:
		set_sfx_muted(pressed, true)
	)

	# 5. Left column: one control per baked caption row (caption top y from the skin art)
	_suppress_option_events = true
	for key in OPTION_ROWS.keys():
		_build_option_row(key, OPTION_ROWS[key])
	_build_title_input()
	for key in COLOR_ROWS.keys():
		_build_color_row(key, COLOR_ROWS[key])
	_suppress_option_events = false

	# Right column below the baked "Blacklist" caption
	var blacklist := get_node_or_null("BlacklistLabel") as Label
	if not blacklist:
		blacklist = Label.new()
		blacklist.name = "BlacklistLabel"
		add_child(blacklist)
	blacklist.position = Vector2(214, 264)
	blacklist.size = Vector2(156, 18)
	blacklist.text = "No blocked players"
	blacklist.add_theme_font_size_override("font_size", 10)
	blacklist.add_theme_color_override("font_color", Color(0.42, 0.46, 0.60, 1.0))

	fullscreen_check = get_node_or_null("FullscreenCheck") as CheckBox
	if not fullscreen_check:
		fullscreen_check = CheckBox.new()
		fullscreen_check.name = "FullscreenCheck"
		add_child(fullscreen_check)
	fullscreen_check.position = Vector2(214, 292)
	fullscreen_check.size = Vector2(156, 20)
	fullscreen_check.text = "Fullscreen"
	fullscreen_check.button_pressed = _fullscreen
	fullscreen_check.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	fullscreen_check.add_theme_font_size_override("font_size", 11)
	fullscreen_check.add_theme_color_override("font_color", Color(0.20, 0.26, 0.44, 1.0))
	_apply_checkbox_icons(fullscreen_check)
	_apply_checkbox_text_colors(fullscreen_check)
	for conn in fullscreen_check.toggled.get_connections():
		fullscreen_check.toggled.disconnect(conn.callable)
	fullscreen_check.toggled.connect(func(pressed: bool) -> void:
		set_fullscreen(pressed, true)
	)

	display_info_label = get_node_or_null("DisplayInfoLabel") as Label
	if not display_info_label:
		display_info_label = Label.new()
		display_info_label.name = "DisplayInfoLabel"
		add_child(display_info_label)
	display_info_label.position = Vector2(214, 314)
	display_info_label.size = Vector2(156, 28)
	display_info_label.text = "Resolution: 1280x720\nResponsive HUD layout"
	display_info_label.add_theme_font_size_override("font_size", 9)
	display_info_label.add_theme_color_override("font_color", Color(0.42, 0.46, 0.60, 1.0))

	# 6. Action buttons stacked in the free area of the right column
	btn_resume = get_node_or_null("BtnResume") as Button
	if not btn_resume:
		btn_resume = _create_styled_button("Resume", Vector2(214, 350), Vector2(156, 24))
		btn_resume.name = "BtnResume"
		add_child(btn_resume)
	btn_resume.position = Vector2(214, 350)
	btn_resume.size = Vector2(156, 24)
	btn_resume.tooltip_text = "Return to Game [Esc]"
	for conn in btn_resume.pressed.get_connections():
		btn_resume.pressed.disconnect(conn.callable)
	btn_resume.pressed.connect(on_resume_pressed)

	btn_logout = get_node_or_null("BtnLogout") as Button
	if not btn_logout:
		btn_logout = _create_styled_button("Character Select", Vector2(214, 378), Vector2(156, 24))
		btn_logout.name = "BtnLogout"
		add_child(btn_logout)
	btn_logout.position = Vector2(214, 378)
	btn_logout.size = Vector2(156, 24)
	btn_logout.tooltip_text = "Return to Character Selection Screen"
	for conn in btn_logout.pressed.get_connections():
		btn_logout.pressed.disconnect(conn.callable)
	btn_logout.pressed.connect(on_logout_pressed)

	btn_exit = get_node_or_null("BtnExit") as Button
	if not btn_exit:
		btn_exit = _create_styled_button("Exit Game", Vector2(214, 406), Vector2(156, 24))
		btn_exit.name = "BtnExit"
		add_child(btn_exit)
	btn_exit.position = Vector2(214, 406)
	btn_exit.size = Vector2(156, 24)
	btn_exit.tooltip_text = "Quit Wonderland Online"
	for conn in btn_exit.pressed.get_connections():
		btn_exit.pressed.disconnect(conn.callable)
	btn_exit.pressed.connect(on_exit_pressed)

	_build_real_client_controls()
	_is_building = false

# ==================== REAL CLIENT CONTROLS ====================
# Positions measured from a live capture of the original window (docs/re/ui_windows.md): On/Off pills,
# Setup pills, colour pickers with arrows, the two-column button grid and the bottom Close button.

const TOGGLE_ROWS: Array[String] = ["pvp_pk", "join_battle", "trading", "zoom_mode", "party_invites"]
const SETUP_ROWS: Dictionary = {"chat_channels": "Chat Channels", "info_visibility": "Info Visibility"}
const COLOR_LABELS: Dictionary = {"local": "Local", "whisper": "Whisper", "party": "Team", "guild": "Guild", "world": "World"}
const COLOR_PALETTE: Array[Color] = [
	Color(1.0, 1.0, 1.0), Color(1.0, 0.92, 0.2), Color(1.0, 0.6, 0.2), Color(1.0, 0.4, 0.7),
	Color(0.26, 0.84, 0.4), Color(0.3, 0.85, 0.95), Color(0.29, 0.7, 1.0), Color(1.0, 0.35, 0.35),
]
const GRID_BUTTONS: Array = [
	["Official Site", "Change Password"], ["Readme", "Spawn Point"], ["Chat Box", "Balance Inquiry"],
	["Redeem Code", "VIP"], ["Redeem MyCard", "Log Out"], ["Buy IM Points", "Exit"],
]

var option_pills: Dictionary = {}
var color_labels: Dictionary = {}
var grid_buttons: Dictionary = {}
var bgm_toggle_pill: Button = null
var sfx_toggle_pill: Button = null
var bottom_close_button: Button = null
var title_setup_pill: Button = null


func _notify(text: String) -> void:
	if _hud != null and _hud.has_method("add_chat_message"):
		_hud.add_chat_message("System", text, "System")


func _build_real_client_controls() -> void:
	if not option_pills.is_empty():
		return
	# Legacy controls stay in the tree (the settings API drives them) but the real window has no such widgets.
	for legacy in ["BgmLabel", "SfxLabel", "BgmMuteCheck", "SfxMuteCheck", "BlacklistLabel", "FullscreenCheck",
			"DisplayInfoLabel", "BtnResume", "BtnLogout", "BtnExit"]:
		var node := get_node_or_null(legacy) as Control
		if node:
			node.visible = false
	for key in OPTION_ROWS.keys():
		var check := get_node_or_null("Opt_%s" % key) as Control
		if check:
			check.visible = false
	for key in COLOR_ROWS.keys():
		var picker := get_node_or_null("Color_%s" % key) as Control
		if picker:
			picker.visible = false

	for key in TOGGLE_ROWS:
		var pill := PillScript.make("On", Vector2(138, OPTION_ROWS[key] - 8.0), Vector2(39, 18))
		pill.name = "Pill_%s" % key
		var opt_key: String = key
		pill.pressed.connect(func() -> void:
			AuthAudioScript.play_click()
			set_option(opt_key, not bool(get_option(opt_key)))
			_sync_real_controls())
		add_child(pill)
		option_pills[key] = pill
	for key in SETUP_ROWS.keys():
		var setup := PillScript.make("Setup", Vector2(138, OPTION_ROWS[key] - 8.0), Vector2(36, 18))
		setup.name = "Setup_%s" % key
		var row_name: String = SETUP_ROWS[key]
		setup.pressed.connect(func() -> void:
			AuthAudioScript.play_click()
			_notify("%s setup is not available in this client yet." % row_name))
		add_child(setup)
	_build_title_setup()

	for key in COLOR_ROWS.keys():
		var center_y: float = COLOR_ROWS[key]
		var label := Label.new()
		label.name = "ColorName_%s" % key
		label.position = Vector2(134, center_y - 9.0)
		label.size = Vector2(62, 18)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.text = COLOR_LABELS[key]
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_outline_color", Color(0.1, 0.12, 0.3, 1.0))
		label.add_theme_constant_override("outline_size", 3)
		add_child(label)
		color_labels[key] = label
		var color_key: String = key
		var prev := SkinButtonScript.make("ArrowL_4", Vector2(118, center_y - 8.0), "ColorPrev_%s" % key)
		prev.pressed.connect(func() -> void: _step_chat_color(color_key, -1))
		add_child(prev)
		var next := SkinButtonScript.make("ArrowR_4", Vector2(182, center_y - 8.0), "ColorNext_%s" % key)
		next.pressed.connect(func() -> void: _step_chat_color(color_key, 1))
		add_child(next)

	bgm_toggle_pill = PillScript.make("On", Vector2(286, 79), Vector2(38, 18))
	bgm_toggle_pill.name = "BgmTogglePill"
	bgm_toggle_pill.pressed.connect(func() -> void:
		AuthAudioScript.play_click()
		set_bgm_muted(not _bgm_muted, true)
		_sync_real_controls())
	add_child(bgm_toggle_pill)
	sfx_toggle_pill = PillScript.make("On", Vector2(246, 149), Vector2(38, 18))
	sfx_toggle_pill.name = "SfxTogglePill"
	sfx_toggle_pill.pressed.connect(func() -> void:
		AuthAudioScript.play_click()
		set_sfx_muted(not _sfx_muted, true)
		_sync_real_controls())
	add_child(sfx_toggle_pill)

	var blacklist_setup := PillScript.make("Setup", Vector2(292, 238), Vector2(36, 18))
	blacklist_setup.name = "Setup_blacklist"
	blacklist_setup.pressed.connect(func() -> void: _notify("The blacklist is not available in this client yet."))
	add_child(blacklist_setup)
	var security := PillScript.make("Security Lock", Vector2(214, 203), Vector2(69, 18), 9)
	security.name = "Btn_SecurityLock"
	security.pressed.connect(func() -> void: _notify("Security Lock is not available in this client yet."))
	add_child(security)
	var change_login := PillScript.make("Change Login", Vector2(294, 203), Vector2(69, 18), 9)
	change_login.name = "Btn_ChangeLogin"
	change_login.pressed.connect(on_logout_pressed)
	add_child(change_login)

	for row in GRID_BUTTONS.size():
		for col in 2:
			var caption: String = GRID_BUTTONS[row][col]
			var btn := PillScript.make(caption, Vector2(207 + col * 82, 261 + row * 25), Vector2(76 if col == 0 else 74, 17), 9)
			btn.name = "Btn_%s" % caption.replace(" ", "")
			btn.pressed.connect(func() -> void: _on_grid_button(caption))
			add_child(btn)
			grid_buttons[caption] = btn

	bottom_close_button = PillScript.make("Close", Vector2(161, 408), Vector2(56, 18))
	bottom_close_button.name = "BtnBottomClose"
	bottom_close_button.pressed.connect(close_window)
	add_child(bottom_close_button)
	_sync_real_controls()


func _build_title_setup() -> void:
	var edit := get_node_or_null("Opt_own_title") as LineEdit
	title_setup_pill = PillScript.make("Setup", Vector2(138, 238), Vector2(36, 18))
	title_setup_pill.name = "Setup_own_title"
	title_setup_pill.pressed.connect(func() -> void:
		if edit:
			title_setup_pill.visible = false
			edit.visible = true
			edit.grab_focus())
	add_child(title_setup_pill)
	if edit:
		edit.visible = false
		edit.focus_exited.connect(func() -> void:
			edit.visible = false
			title_setup_pill.visible = true)


func _on_grid_button(caption: String) -> void:
	AuthAudioScript.play_click()
	match caption:
		"Log Out":
			on_logout_pressed()
		"Exit":
			on_exit_pressed()
		_:
			_notify("%s is not available in this client yet." % caption)


func _step_chat_color(key: String, step: int) -> void:
	AuthAudioScript.play_click()
	var current: Color = get_chat_color(key)
	var best := 0
	var best_dist := INF
	for i in COLOR_PALETTE.size():
		var c: Color = COLOR_PALETTE[i]
		var dist: float = absf(c.r - current.r) + absf(c.g - current.g) + absf(c.b - current.b)
		if dist < best_dist:
			best_dist = dist
			best = i
	set_chat_color(key, COLOR_PALETTE[(best + step + COLOR_PALETTE.size()) % COLOR_PALETTE.size()])
	_sync_real_controls()


## Brings pills and colour names in line with the stored settings.
func _sync_real_controls() -> void:
	for key in option_pills.keys():
		PillScript.style_toggle(option_pills[key], bool(_options.get(key, DEFAULT_OPTIONS[key])))
	if bgm_toggle_pill:
		PillScript.style_toggle(bgm_toggle_pill, not _bgm_muted)
	if sfx_toggle_pill:
		PillScript.style_toggle(sfx_toggle_pill, not _sfx_muted)
	for key in color_labels.keys():
		(color_labels[key] as Label).add_theme_color_override("font_color", get_chat_color(key))

# ==================== LAYOUT HELPERS (controls over baked skin art) ====================

func _make_slider_marker() -> ImageTexture:
	var marker_image := Image.create(3, 13, false, Image.FORMAT_RGBA8)
	marker_image.fill(Color(0.95, 0.97, 1.0, 1))
	for y in 13:
		marker_image.set_pixel(0, y, Color(0.1, 0.12, 0.25, 1))
		marker_image.set_pixel(2, y, Color(0.1, 0.12, 0.25, 1))
	return ImageTexture.create_from_image(marker_image)

func _ensure_overlay_slider(node_name: String, pos: Vector2, marker: Texture2D, clear: StyleBox) -> HSlider:
	var slider := get_node_or_null(node_name) as HSlider
	if not slider:
		slider = HSlider.new()
		slider.name = node_name
		add_child(slider)
	slider.position = pos
	slider.size = Vector2(76, 15)
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	slider.add_theme_stylebox_override("slider", clear)
	slider.add_theme_stylebox_override("grabber_area", clear)
	slider.add_theme_stylebox_override("grabber_area_highlight", clear)
	slider.add_theme_icon_override("grabber", marker)
	slider.add_theme_icon_override("grabber_highlight", marker)
	slider.add_theme_icon_override("grabber_disabled", marker)
	return slider

func _ensure_arrow_overlay(node_name: String, pos: Vector2, action: Callable) -> Button:
	var btn := get_node_or_null(node_name) as Button
	if not btn:
		btn = Button.new()
		btn.name = node_name
		add_child(btn)
		var clear := StyleBoxEmpty.new()
		btn.flat = true
		btn.text = ""
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			btn.add_theme_stylebox_override(state, clear)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.pressed.connect(func() -> void:
			AuthAudioScript.play_click()
			action.call()
		)
	btn.position = pos
	btn.size = Vector2(18, 17)
	return btn

func _ensure_percent_label(node_name: String, pos: Vector2) -> Label:
	var label := get_node_or_null(node_name) as Label
	if not label:
		label = Label.new()
		label.name = node_name
		add_child(label)
	label.position = pos
	label.size = Vector2(66, 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.20, 0.26, 0.44, 1.0))
	return label

func _ensure_mute_check(node_name: String, pos: Vector2, pressed: bool) -> CheckBox:
	var check := get_node_or_null(node_name) as CheckBox
	if not check:
		check = CheckBox.new()
		check.name = node_name
		add_child(check)
	check.position = pos
	check.size = Vector2(70, 18)
	check.text = "Mute"
	check.button_pressed = pressed
	check.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	check.add_theme_font_size_override("font_size", 10)
	check.add_theme_color_override("font_color", Color(0.20, 0.26, 0.44, 1.0))
	_apply_checkbox_icons(check)
	_apply_checkbox_text_colors(check)
	return check

func _build_option_row(key: String, caption_top: float) -> void:
	var check := get_node_or_null("Opt_%s" % key) as CheckBox
	if not check:
		check = CheckBox.new()
		check.name = "Opt_%s" % key
		add_child(check)
		check.text = "On"
		check.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		check.add_theme_font_size_override("font_size", 10)
		check.add_theme_color_override("font_color", Color(0.20, 0.26, 0.44, 1.0))
		_apply_checkbox_icons(check)
		_apply_checkbox_text_colors(check)
		check.toggled.connect(func(pressed: bool) -> void:
			set_option(key, pressed)
		)
	check.position = Vector2(126, caption_top - 5.0)
	check.size = Vector2(70, 18)
	check.button_pressed = bool(_options.get(key, DEFAULT_OPTIONS[key]))

func _build_title_input() -> void:
	var edit := get_node_or_null("Opt_own_title") as LineEdit
	if not edit:
		edit = LineEdit.new()
		edit.name = "Opt_own_title"
		add_child(edit)
		edit.placeholder_text = "title"
		edit.max_length = 12
		edit.add_theme_font_size_override("font_size", 10)
		edit.add_theme_color_override("font_color", Color(0.15, 0.2, 0.38, 1.0))
		edit.text_submitted.connect(func(t: String) -> void:
			set_option("own_title", t.strip_edges())
		)
		edit.focus_exited.connect(func() -> void:
			set_option("own_title", edit.text.strip_edges())
		)
	edit.position = Vector2(126, 239.0)
	edit.size = Vector2(80, 18)
	edit.text = str(_options.get("own_title", ""))

func _build_color_row(key: String, caption_top: float) -> void:
	var picker := get_node_or_null("Color_%s" % key) as ColorPickerButton
	if not picker:
		picker = ColorPickerButton.new()
		picker.name = "Color_%s" % key
		add_child(picker)
		picker.edit_alpha = false
		picker.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		picker.color_changed.connect(func(c: Color) -> void:
			set_chat_color(key, c)
		)
	picker.position = Vector2(126, caption_top - 3.0)
	picker.size = Vector2(44, 16)
	picker.color = get_chat_color(key)


func _apply_close_button_textures(btn: Button) -> void:
	# The close button is a transparent hit area over the x sphere baked into the skin (WindowCloseButton).
	pass

func _apply_checkbox_text_colors(cb: CheckBox) -> void:
	var ink := Color(0.20, 0.26, 0.44, 1.0)
	for color_name in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color", "font_focus_color"]:
		cb.add_theme_color_override(color_name, ink)

func _apply_checkbox_icons(cb: CheckBox) -> void:
	if not cb:
		return
	if ResourceLoader.exists("res://assets/hud/btn_checkbox_checked.png"):
		cb.add_theme_icon_override("checked", load("res://assets/hud/btn_checkbox_checked.png"))
	if ResourceLoader.exists("res://assets/hud/btn_checkbox_unchecked.png"):
		cb.add_theme_icon_override("unchecked", load("res://assets/hud/btn_checkbox_unchecked.png"))

func _create_styled_button(btn_text: String, pos: Vector2, sz: Vector2) -> Button:
	var btn := Button.new()
	btn.text = btn_text
	btn.position = pos
	btn.size = sz
	btn.custom_minimum_size = sz
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var norm := StyleBoxFlat.new()
	norm.bg_color = Color(0.92, 0.90, 0.86, 1.0)
	norm.border_color = Color(0.50, 0.42, 0.32, 1.0)
	norm.set_border_width_all(1)
	norm.set_corner_radius_all(3)

	var hov := StyleBoxFlat.new()
	hov.bg_color = Color(1.0, 0.96, 0.88, 1.0)
	hov.border_color = Color(0.70, 0.55, 0.35, 1.0)
	hov.set_border_width_all(1)
	hov.set_corner_radius_all(3)

	var prs := StyleBoxFlat.new()
	prs.bg_color = Color(0.78, 0.74, 0.68, 1.0)
	prs.border_color = Color(0.35, 0.28, 0.20, 1.0)
	prs.set_border_width_all(1)
	prs.set_corner_radius_all(3)

	btn.add_theme_stylebox_override("normal", norm)
	btn.add_theme_stylebox_override("hover", hov)
	btn.add_theme_stylebox_override("pressed", prs)
	btn.add_theme_stylebox_override("focus", norm)
	btn.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(0.05, 0.05, 0.05, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.1, 0.08, 0.05, 1.0))
	btn.add_theme_font_size_override("font_size", 11)
	return btn

# ==================== SETTINGS CONTROL APIS ====================

func set_bgm_volume(val: int, save: bool = true) -> void:
	_bgm_volume = clampi(val, 0, 100)
	var bus := get_bgm_bus()
	AudioServer.set_bus_volume_db(bus, linear_to_bus_db(_bgm_volume))
	if bgm_slider and int(bgm_slider.value) != _bgm_volume:
		bgm_slider.value = float(_bgm_volume)
	if bgm_label:
		bgm_label.text = "%d%%" % _bgm_volume
	if save:
		save_settings()

func get_bgm_volume() -> int:
	return _bgm_volume

func set_bgm_muted(muted: bool, save: bool = true) -> void:
	_bgm_muted = muted
	var bus := get_bgm_bus()
	AudioServer.set_bus_mute(bus, _bgm_muted)
	if bgm_mute_check and bgm_mute_check.button_pressed != _bgm_muted:
		bgm_mute_check.button_pressed = _bgm_muted
	if save:
		save_settings()

func is_bgm_muted() -> bool:
	return _bgm_muted

func set_sfx_volume(val: int, save: bool = true) -> void:
	_sfx_volume = clampi(val, 0, 100)
	var bus := get_sfx_bus()
	AudioServer.set_bus_volume_db(bus, linear_to_bus_db(_sfx_volume))
	if sfx_slider and int(sfx_slider.value) != _sfx_volume:
		sfx_slider.value = float(_sfx_volume)
	if sfx_label:
		sfx_label.text = "%d%%" % _sfx_volume
	if save:
		save_settings()

func get_sfx_volume() -> int:
	return _sfx_volume

func set_sfx_muted(muted: bool, save: bool = true) -> void:
	_sfx_muted = muted
	var bus := get_sfx_bus()
	AudioServer.set_bus_mute(bus, _sfx_muted)
	if sfx_mute_check and sfx_mute_check.button_pressed != _sfx_muted:
		sfx_mute_check.button_pressed = _sfx_muted
	if save:
		save_settings()

func is_sfx_muted() -> bool:
	return _sfx_muted

func set_fullscreen(enabled: bool, save: bool = true) -> void:
	_fullscreen = enabled
	if _fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	if fullscreen_check and fullscreen_check.button_pressed != _fullscreen:
		fullscreen_check.button_pressed = _fullscreen
	if save:
		save_settings()

func is_fullscreen() -> bool:
	return _fullscreen

func toggle_fullscreen() -> void:
	set_fullscreen(not _fullscreen, true)

func set_option(key: String, value: Variant, save: bool = true) -> void:
	if _suppress_option_events:
		return
	_options[key] = value
	if save:
		save_settings()

func get_option(key: String) -> Variant:
	return _options.get(key, DEFAULT_OPTIONS.get(key, ""))

func set_chat_color(key: String, color: Color, save: bool = true) -> void:
	if _suppress_option_events:
		return
	_chat_colors[key] = color
	if save:
		save_settings()

func get_chat_color(key: String) -> Color:
	return _chat_colors.get(key, DEFAULT_CHAT_COLORS.get(key, Color.WHITE))

func get_settings_data() -> Dictionary:
	return {
		"bgm_volume": _bgm_volume,
		"bgm_muted": _bgm_muted,
		"sfx_volume": _sfx_volume,
		"sfx_muted": _sfx_muted,
		"fullscreen": _fullscreen,
		"options": _options.duplicate(),
		"chat_colors": _serialize_chat_colors()
	}

func _serialize_chat_colors() -> Dictionary:
	var result := {}
	for key in _chat_colors.keys():
		result[key] = "#" + (_chat_colors[key] as Color).to_html(false)
	return result

func save_settings() -> void:
	var existing_data := {}
	if FileAccess.file_exists(SETTINGS_FILE_PATH):
		var r_file := FileAccess.open(SETTINGS_FILE_PATH, FileAccess.READ)
		if r_file:
			var txt := r_file.get_as_text()
			r_file.close()
			var parsed = JSON.parse_string(txt)
			if parsed is Dictionary:
				existing_data = parsed

	var data := get_settings_data()
	for k in data.keys():
		existing_data[k] = data[k]

	var file := FileAccess.open(SETTINGS_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(existing_data, "\t"))
		file.close()
	settings_changed.emit(existing_data)

func load_settings() -> void:
	ensure_audio_buses()
	var data := {}
	if FileAccess.file_exists(SETTINGS_FILE_PATH):
		var file := FileAccess.open(SETTINGS_FILE_PATH, FileAccess.READ)
		if file:
			var txt := file.get_as_text()
			file.close()
			var parsed = JSON.parse_string(txt)
			if parsed is Dictionary:
				data = parsed

	_bgm_volume = int(data.get("bgm_volume", DEFAULT_BGM_VOLUME))
	_bgm_muted = bool(data.get("bgm_muted", false))
	_sfx_volume = int(data.get("sfx_volume", DEFAULT_SFX_VOLUME))
	_sfx_muted = bool(data.get("sfx_muted", false))
	_fullscreen = bool(data.get("fullscreen", false))
	_options = DEFAULT_OPTIONS.duplicate()
	var saved_options = data.get("options", {})
	if saved_options is Dictionary:
		for key in saved_options.keys():
			_options[key] = saved_options[key]
	_chat_colors = DEFAULT_CHAT_COLORS.duplicate()
	var saved_colors = data.get("chat_colors", {})
	if saved_colors is Dictionary:
		for key in saved_colors.keys():
			_chat_colors[key] = Color.html(str(saved_colors[key]))
	_refresh_option_controls()

	# Apply to AudioServer and DisplayServer without re-saving
	set_bgm_volume(_bgm_volume, false)
	set_bgm_muted(_bgm_muted, false)
	set_sfx_volume(_sfx_volume, false)
	set_sfx_muted(_sfx_muted, false)
	set_fullscreen(_fullscreen, false)

func _refresh_option_controls() -> void:
	_suppress_option_events = true
	for key in OPTION_ROWS.keys():
		var check := get_node_or_null("Opt_%s" % key) as CheckBox
		if check:
			check.set_pressed_no_signal(bool(_options.get(key, DEFAULT_OPTIONS[key])))
	var title_edit := get_node_or_null("Opt_own_title") as LineEdit
	if title_edit:
		title_edit.text = str(_options.get("own_title", ""))
	for key in COLOR_ROWS.keys():
		var picker := get_node_or_null("Color_%s" % key) as ColorPickerButton
		if picker:
			picker.color = get_chat_color(key)
	_suppress_option_events = false
	_sync_real_controls()

# ==================== ACTIONS & WINDOW CONTROL ====================

func open_window() -> void:
	AuthAudioScript.play_click()
	load_settings()
	visible = true

func close_window() -> void:
	AuthAudioScript.play_click()
	visible = false
	window_closed.emit()

func toggle_window() -> void:
	if visible:
		close_window()
	else:
		open_window()

func on_resume_pressed() -> void:
	close_window()

func on_logout_pressed() -> void:
	AuthAudioScript.play_click()
	close_window()
	logout_requested.emit()
	var tree := get_tree()
	if tree:
		var login_scene_path := "res://scenes/ui/login_screen.tscn"
		if ResourceLoader.exists(login_scene_path):
			tree.change_scene_to_file(login_scene_path)

func on_exit_pressed() -> void:
	AuthAudioScript.play_click()
	var tree := get_tree()
	if tree:
		tree.quit()
