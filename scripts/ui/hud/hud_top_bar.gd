class_name HUDTopBar
extends Control

## Row of round action icons along the top-right edge of the real client (Btn_1..Btn_9 of the
## default skin: each bitmap is a 37x99 sheet of three 37x33 frames: normal, highlighted, pressed).
## Icons whose system exists in this client open it; the others report that they are not available.

signal action_requested(action_id: String)

const SKIN_PATH_FORMAT: String = "res://assets/menu/Skins/default/Btn_%s.bmp"
const ROW_HEIGHT: float = 36.0
const MARGIN_RIGHT: float = 6.0
const MARGIN_TOP: float = 4.0

## Tooltips read from the running client (hover): PK, Jump In, Spectate, Join Team, Make Friends, Money, Events,
## Lucky Draw, Item Mall. Order as captured: sword + chest, crossed swords, sword + figure, sword + eye,
## two figures, handshake, coins, trophy, chest, storefront. Sheet heights differ (99/102/108 px), so the
## frame height is sheet height / 3.
const ENTRIES: Array[Dictionary] = [
	{"skin": "PlayerBattle", "action": "player_battle", "tooltip": "Player Battle"},
	{"skin": "1", "action": "battle_settings", "tooltip": "PK"},
	{"skin": "2", "action": "jump_in", "tooltip": "Jump In"},
	{"skin": "3", "action": "spectate", "tooltip": "Spectate"},
	{"skin": "4", "action": "team", "tooltip": "Join Team"},
	{"skin": "5", "action": "make_friends", "tooltip": "Make Friends"},
	{"skin": "6", "action": "money", "tooltip": "Money"},
	{"skin": "8", "action": "events", "tooltip": "Events"},
	{"skin": "9", "action": "lucky_draw", "tooltip": "Lucky Draw"},
	{"skin": "711", "action": "item_mall", "tooltip": "Item Mall"},
]

var buttons: Array[TextureButton] = []
var _hud: Control = null


## Tooltips of the original client are a blue box with white text; applied once for the whole game.
static func apply_real_tooltip_style() -> void:
	var theme := ThemeDB.get_default_theme()
	if theme == null:
		return
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.24, 0.42, 0.80, 1.0)
	box.border_color = Color(0.08, 0.16, 0.42, 1.0)
	box.set_border_width_all(1)
	box.content_margin_left = 6.0
	box.content_margin_right = 6.0
	box.content_margin_top = 2.0
	box.content_margin_bottom = 2.0
	theme.set_stylebox("panel", "TooltipPanel", box)
	theme.set_color("font_color", "TooltipLabel", Color(1, 1, 1, 1))
	theme.set_color("font_outline_color", "TooltipLabel", Color(0, 0, 0, 0))


func setup(hud: Control) -> void:
	apply_real_tooltip_style()
	_hud = hud
	name = "TopActionBar"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var total_width: float = _total_width()
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	anchor_left = 1.0
	anchor_right = 1.0
	offset_left = -(total_width + MARGIN_RIGHT)
	offset_right = -MARGIN_RIGHT
	offset_top = MARGIN_TOP
	offset_bottom = MARGIN_TOP + ROW_HEIGHT
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	custom_minimum_size = Vector2(total_width, ROW_HEIGHT)
	_build_buttons()
	action_requested.connect(_on_action_requested)


func _skin_size(entry: Dictionary) -> Vector2:
	var path: String = SKIN_PATH_FORMAT % str(entry["skin"])
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		if tex != null:
			return Vector2(tex.get_width(), floorf(tex.get_height() / 3.0))
	return Vector2(37, 33)


func _total_width() -> float:
	var total := 0.0
	for entry in ENTRIES:
		total += _skin_size(entry).x
	return total


func _build_buttons() -> void:
	buttons.clear()
	var cursor_x := 0.0
	for i in ENTRIES.size():
		var entry: Dictionary = ENTRIES[i]
		var frame_size: Vector2 = _skin_size(entry)
		var btn := TextureButton.new()
		btn.name = "TopBtn_%s" % entry["action"]
		btn.position = Vector2(cursor_x, 0.0)
		btn.size = frame_size
		btn.custom_minimum_size = frame_size
		cursor_x += frame_size.x
		btn.tooltip_text = str(entry["tooltip"])
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var sheet := _keyed_sheet(SKIN_PATH_FORMAT % str(entry["skin"]))
		if sheet != null:
			btn.texture_normal = _frame(sheet, 0, frame_size)
			btn.texture_hover = _frame(sheet, 1, frame_size)
			btn.texture_pressed = _frame(sheet, 2, frame_size)
		var action_id: String = str(entry["action"])
		btn.pressed.connect(func() -> void: action_requested.emit(action_id))
		add_child(btn)
		buttons.append(btn)


## Loads a skin bitmap with its pure green (0, 255, 0) chroma key made transparent.
func _keyed_sheet(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var source := load(path) as Texture2D
	if source == null:
		return null
	var image := source.get_image()
	if image == null:
		return source
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.r < 0.02 and c.g > 0.98 and c.b < 0.02:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(image)


func _frame(sheet: Texture2D, index: int, frame_size: Vector2) -> Texture2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(0.0, frame_size.y * index, frame_size.x, frame_size.y)
	return atlas


func _on_action_requested(action_id: String) -> void:
	if _hud == null:
		return
	match action_id:
		"team":
			if _hud.has_method("toggle_team_window"):
				_hud.toggle_team_window()
		"battle_settings", "pk_settings":
			if _hud.has_method("toggle_fight_menu"):
				_hud.toggle_fight_menu()
		_:
			if _hud.has_method("add_chat_message"):
				var label := action_id.replace("_", " ").capitalize()
				_hud.add_chat_message("System", "%s is not available in this client yet." % label, "System")
