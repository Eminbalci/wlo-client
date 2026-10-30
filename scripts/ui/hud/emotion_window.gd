class_name EmotionWindow
extends Control

## Chat emote picker, rebuilt from the chat bar constructor aLogin.exe 0x27d58c (the
## "Btn_expression_1" button with hint "Chat Emotes" toggles it, handler 0x2837a0).
## Coordinates below are relative to the panel; in the client they are relative to the chat bar
## (panel origin = (492, -69)):
##   panel_expression_1 (492,-69) 263x69
##   icon_expre_1..30: (500 + 23*((i-1) mod 10), -62 + 20*((i-1) div 10)) 16x16 -> (8+23c, 7+20r)
##   icon_expre_31:    (730, -22) 16x16                                     -> (238, 47)
##   Btn_Close_s_1:    (733, -66) 18x18                                     -> (241, 3)
## Icon bitmaps are 2-frame sheets (16x32: normal, hover). Each icon's hint is the shortcut text
## (table 0x4bcb24) concatenated with the name (table 0x4bcba4), e.g. "@|Arrogant".
## Form_Emotion_1 (356x493, "social" Emote tab) is a different form built by the social window
## constructor 0x2967a4 (Ctrl+1..5 macros, btn_Action_ grid, Alt+1..8 slots); see
## docs/re/emotion_window.md. This window emits the "#NN" code used by chat_dock.gd and
## player.gd show_speech_bubble.

signal emote_selected(code: String)
signal emote_hovered(index: int, hint: String)
signal window_closed

const S = preload("res://scripts/ui/hud/wlo_window_skin.gd")

const WINDOW_SIZE: Vector2 = Vector2(263, 69)
const CHAT_BAR_OFFSET: Vector2 = Vector2(492, -69)
const ICON_SIZE: Vector2 = Vector2(16, 16)
const EMOTE_COUNT: int = 31
const CLOSE_RECT: Rect2 = Rect2(241, 3, 18, 18)

## Shortcut text (0x4bcb24) and name (0x4bcba4) per emote 1..31.
const SHORTCUTS: Array[String] = ["@|", ":$", ">|", "-\"", "XD", "TT", ":D", ":S", "==", "8D", "%#", "8(",
	":)", "^T", ">@", ":(", ":!", "JL", "8o", ":[", ":m", ":o", "|T", "\"_", "*:", "j-", ":P", "|E", "zZ", "@#", "-P"]
const NAMES: Array[String] = ["Arrogant", "Blush", "Frowned", "Despair", "XD", "Weeping", "Laugh", "Doubt",
	"Unamused", "LMAO", "Excited", "WTF?!", "Lol", "Tears", "Angry", "Upset", "Sighing", "Please", "Stupefy",
	"Humble", "Whistle", "Shocked", "Spit It Out", "Horrified", "Annoyed", "Ashamed", "Oops", "Huh",
	"Doze Off", "Confused", "Nod"]

var background: TextureRect
var close_button: TextureButton
var icons: Array[TextureButton] = []
var _built: bool = false


func _init() -> void:
	name = "EmotionWindow"
	size = WINDOW_SIZE
	custom_minimum_size = WINDOW_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	_build()


static func icon_position(index: int) -> Vector2:
	if index == EMOTE_COUNT:
		return Vector2(238, 47)
	var i := index - 1
	return Vector2(8 + 23 * (i % 10), 7 + 20 * (i / 10))


static func code_for(index: int) -> String:
	return "#%02d" % index


static func hint_for(index: int) -> String:
	return SHORTCUTS[index - 1] + NAMES[index - 1]


func _build() -> void:
	if _built:
		return
	_built = true
	background = S.background(self, "emotion_panel", WINDOW_SIZE)
	for index in range(1, EMOTE_COUNT + 1):
		var btn := TextureButton.new()
		btn.name = "Emote%02d" % index
		btn.position = icon_position(index)
		btn.size = ICON_SIZE
		btn.custom_minimum_size = ICON_SIZE
		btn.ignore_texture_size = true
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var sheet := S.tex("icon_expre_%d" % index)
		if sheet != null:
			btn.texture_normal = _frame(sheet, 0)
			btn.texture_hover = _frame(sheet, 1)
			btn.texture_pressed = btn.texture_hover
		btn.tooltip_text = hint_for(index)
		btn.pressed.connect(select_emote.bind(index))
		btn.mouse_entered.connect(func() -> void: emote_hovered.emit(index, hint_for(index)))
		add_child(btn)
		icons.append(btn)
	close_button = S.button(self, "CloseButton", "skin_btn_close_s_1", CLOSE_RECT, "Close")
	close_button.pressed.connect(close)


func _frame(sheet: Texture2D, i: int) -> Texture2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	var h := sheet.get_height() / 2.0 if sheet.get_height() >= 32 else float(sheet.get_height())
	atlas.region = Rect2(0, h * i if sheet.get_height() >= 32 else 0.0, sheet.get_width(), h)
	return atlas


# --- public API -------------------------------------------------------------------------------

## Opens the panel. Pass the chat bar's global position to place it like the client does.
func open(chat_bar_origin: Variant = null) -> void:
	_build()
	if chat_bar_origin is Vector2:
		position = (chat_bar_origin as Vector2) + CHAT_BAR_OFFSET
	visible = true
	move_to_front()


func close() -> void:
	visible = false
	window_closed.emit()


func toggle(chat_bar_origin: Variant = null) -> void:
	if visible:
		close()
	else:
		open(chat_bar_origin)


func select_emote(index: int) -> void:
	if index < 1 or index > EMOTE_COUNT:
		return
	emote_selected.emit(code_for(index))
	close()
