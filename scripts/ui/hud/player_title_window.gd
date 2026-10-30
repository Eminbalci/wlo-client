class_name PlayerTitleWindow
extends Control

## Form_PlayerTitle: list of the player's titles with an Apply button per row (probably opened from
## the System window's "Set Own Title" - not traced). Decoded from aLogin.exe (docs/re/player_title_window.md):
## - constructor 0x2beb38: skin Form_PlayerTitle (white skin set, 250x275) at screen (150,100);
##   btn_close_s_1 (200,26) 18x18 hint [ESC]; 5 x Btn_Apply1 at (165, 70 + 30*(i-1)) 56x20, tag i,
##   OnClick 0x2bef84; Btn_ArrowL_8 (85,219) and Btn_ArrowR_8 (144,219) 21x21 (handlers 0x2bf2c4 /
##   0x2bf2dc); Btn_Close_2 at (105,246) hint [ESC]. Btn_Apply2 is loaded as a second image.
## - show 0x2bef30: arrows only when the title count (+0x16c) is above 5; page (+0x170) starts at 1.
## - painter 0x2bf308: title names of the page at (22, 73 + 30*row), colour $FFFF.
## - page number 0x2beff0: Num_MainInfo digits at (103,225); two digits start at 120 - glyph width.
## - Apply 0x2bef84: index = (page-1)*5 + tag; clicking the applied row again clears it (index 0);
##   then sends the chosen title id (call 0x2d6ad8 with 10, 5).

signal window_closed
signal title_applied(title_id: int)

const AuthAudioScript = preload("res://scripts/ui/auth/auth_audio.gd")

const WINDOW_WIDTH: float = 250.0
const WINDOW_HEIGHT: float = 275.0
const DEFAULT_SCREEN_POS: Vector2 = Vector2(150, 100)
const ROWS_PER_PAGE: int = 5
const ROW_PITCH: float = 30.0
const APPLY_ORIGIN: Vector2 = Vector2(165, 70)
const APPLY_SIZE: Vector2 = Vector2(56, 20)
const NAME_ORIGIN: Vector2 = Vector2(22, 73)
const CLOSE_S_POS: Vector2 = Vector2(200, 26)
const ARROW_L_POS: Vector2 = Vector2(85, 219)
const ARROW_R_POS: Vector2 = Vector2(144, 219)
const ARROW_SIZE: Vector2 = Vector2(21, 21)
const CLOSE_2_POS: Vector2 = Vector2(105, 246)
const CLOSE_2_SIZE: Vector2 = Vector2(39, 20) # Btn_Close_2.bmp is 39x60 (3 frames)
const PAGE_NUM_POS: Vector2 = Vector2(103, 225)
const PAGE_NUM_TWO_DIGIT_RIGHT: float = 120.0
const DIGIT_SIZE: Vector2 = Vector2(11, 10) # Num_MainInfo.bmp 11x120: 0-9, %, /
const DATA_PATH: String = "res://assets/data/PlayerTitleData.txt"
## English glosses of the Big5 names in PlayerTitleData.txt (our translation, not client text).
const TITLE_GLOSSES: Dictionary = {
	0: "No title",
	1: "King Who Rules the Holy Night",
	2: "Ruler of the Holy Night",
	3: "Holy Night Knight",
	4: "Holy Night Guardian",
	5: "Perfect Lover",
	6: "Super Player",
}

## title id -> {"id", "kind" ("text"/"pic"), "name", "picture"}
var title_defs: Dictionary = {}
## Owned title ids (the original keeps them in a byte list at +0x130; index 0 = no title).
var titles: Array[int] = []
var page: int = 1
var applied_index: int = 0 # 1-based into titles, 0 = none (+0x174)

var background: TextureRect = null
var close_button: Button = null
var bottom_close_button: Button = null
var arrow_left: Button = null
var arrow_right: Button = null
var apply_buttons: Array[Button] = []
var name_labels: Array[Label] = []
var picture_rects: Array[TextureRect] = []
var page_digits: Control = null
var _digit_sheet: Texture2D = null
var _built: bool = false


func _init() -> void:
	size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)
	custom_minimum_size = size


func _ready() -> void:
	_build_ui_if_needed()


static func load_title_defs(path: String = DATA_PATH) -> Dictionary:
	var defs := {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return defs
	var raw := f.get_buffer(f.get_length())
	var line := PackedByteArray()
	raw.append(10)
	for b in raw:
		if b == 10 or b == 13:
			if line.size() > 0:
				# "id,kind,<Big5 name>": only the ASCII id and kind are read here.
				var parts := line.get_string_from_ascii().split(",", true, 2)
				if parts.size() >= 2 and parts[0].is_valid_int():
					var id := int(parts[0])
					var pic := "res://assets/hud/title_pic_%d.png" % id
					defs[id] = {
						"id": id,
						"kind": parts[1],
						"name": str(TITLE_GLOSSES.get(id, "Title %d" % id)),
						"picture": pic if parts[1] == "pic" and ResourceLoader.exists(pic) else "",
					}
			line = PackedByteArray()
		else:
			line.append(b)
	return defs


func _build_ui_if_needed() -> void:
	if _built:
		return
	_built = true
	title_defs = load_title_defs()
	background = get_node_or_null("Background") as TextureRect
	if background == null:
		background = TextureRect.new()
		background.name = "Background"
		add_child(background)
	background.position = Vector2.ZERO
	background.size = size
	background.mouse_filter = Control.MOUSE_FILTER_PASS
	if background.texture == null:
		background.texture = _tex("assets/hud/form_player_title.png")

	for i in ROWS_PER_PAGE:
		var y := ROW_PITCH * i
		var pic := TextureRect.new()
		pic.name = "TitlePicture%d" % i
		pic.position = Vector2(NAME_ORIGIN.x - 4, APPLY_ORIGIN.y - 4 + y)
		pic.size = Vector2(138, 28)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(pic)
		picture_rects.append(pic)
		var l := Label.new()
		l.name = "TitleName%d" % i
		l.position = NAME_ORIGIN + Vector2(0, y - 2)
		l.size = Vector2(140, 16)
		l.clip_text = true
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.add_theme_font_size_override("font_size", 11)
		l.add_theme_color_override("font_color", Color(1, 1, 1))
		l.add_theme_color_override("font_outline_color", Color(0.16, 0.22, 0.42))
		l.add_theme_constant_override("outline_size", 3)
		add_child(l)
		name_labels.append(l)
		var b := _skin_button("BtnApply%d" % (i + 1), "btn_apply_1", APPLY_ORIGIN + Vector2(0, y), APPLY_SIZE, "Apply")
		b.pressed.connect(apply_row.bind(i + 1))
		apply_buttons.append(b)

	arrow_left = _skin_button("BtnArrowL", "btn_arrow_l_8", ARROW_L_POS, ARROW_SIZE, "<")
	arrow_left.pressed.connect(prev_page)
	arrow_right = _skin_button("BtnArrowR", "btn_arrow_r_8", ARROW_R_POS, ARROW_SIZE, ">")
	arrow_right.pressed.connect(next_page)
	bottom_close_button = _skin_button("BtnClose2", "btn_close_2", CLOSE_2_POS, CLOSE_2_SIZE, "Close")
	bottom_close_button.tooltip_text = "[ESC]"
	bottom_close_button.pressed.connect(close_window)

	page_digits = Control.new()
	page_digits.name = "PageNumber"
	page_digits.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(page_digits)
	_digit_sheet = _tex("assets/hud/num_main_info.png")

	close_button = get_node_or_null("CloseButton") as Button
	if close_button == null:
		close_button = Button.new()
		close_button.name = "CloseButton"
		add_child(close_button)
	WindowCloseButton.apply(close_button, WINDOW_WIDTH)
	close_button.position = CLOSE_S_POS
	close_button.custom_minimum_size = Vector2(18, 18)
	close_button.size = Vector2(18, 18)
	close_button.tooltip_text = "[ESC]"
	close_button.pressed.connect(close_window)
	move_child(close_button, -1)
	_refresh()


## owned: title ids the player owns (0 / "no title" is implicit). applied_title_id: current title.
func populate(owned: Array, applied_title_id: int = 0) -> void:
	_build_ui_if_needed()
	titles.clear()
	for t in owned:
		if int(t) > 0 and not titles.has(int(t)):
			titles.append(int(t))
	var idx := titles.find(applied_title_id)
	applied_index = idx + 1 if idx >= 0 else 0
	page = 1
	_refresh()


func page_count() -> int:
	return maxi(1, ceili(float(titles.size()) / float(ROWS_PER_PAGE)))


func next_page() -> void:
	AuthAudioScript.play_click()
	if page < page_count():
		page += 1
		_refresh()


func prev_page() -> void:
	AuthAudioScript.play_click()
	if page > 1:
		page -= 1
		_refresh()


## Apply on row tag 1..5 of the current page (0x2bef84).
func apply_row(tag: int) -> void:
	AuthAudioScript.play_click()
	var index := (page - 1) * ROWS_PER_PAGE + tag
	if index > titles.size():
		return
	applied_index = 0 if index == applied_index else index
	_refresh()
	title_applied.emit(get_applied_title_id())


func get_applied_title_id() -> int:
	return titles[applied_index - 1] if applied_index > 0 and applied_index <= titles.size() else 0


func get_title_name(title_id: int) -> String:
	return str(title_defs.get(title_id, {}).get("name", TITLE_GLOSSES.get(title_id, "Title %d" % title_id)))


func open_window() -> void:
	_build_ui_if_needed()
	visible = true
	move_to_front()
	_refresh()


func close_window() -> void:
	AuthAudioScript.play_click()
	visible = false
	window_closed.emit()


func toggle_window() -> void:
	if visible:
		close_window()
	else:
		open_window()


func _refresh() -> void:
	if not _built:
		return
	page = clampi(page, 1, page_count())
	for r in ROWS_PER_PAGE:
		var index := (page - 1) * ROWS_PER_PAGE + r + 1
		var has := index <= titles.size()
		var tid := titles[index - 1] if has else 0
		var def: Dictionary = title_defs.get(tid, {})
		var pic_path := str(def.get("picture", ""))
		picture_rects[r].texture = load(pic_path) as Texture2D if has and not pic_path.is_empty() else null
		picture_rects[r].visible = picture_rects[r].texture != null
		name_labels[r].text = get_title_name(tid) if has else ""
		name_labels[r].visible = has and not picture_rects[r].visible
		apply_buttons[r].visible = has
		_set_states(apply_buttons[r], "btn_apply_2" if index == applied_index else "btn_apply_1")
	var arrows := titles.size() > ROWS_PER_PAGE
	arrow_left.visible = arrows
	arrow_right.visible = arrows
	_draw_page_number()


func _draw_page_number() -> void:
	for c in page_digits.get_children():
		page_digits.remove_child(c)
		c.queue_free()
	var s := str(page)
	var x := PAGE_NUM_POS.x if s.length() < 2 else PAGE_NUM_TWO_DIGIT_RIGHT - DIGIT_SIZE.x
	for ch in s:
		var t := TextureRect.new()
		t.name = "Digit%s" % ch
		t.position = Vector2(x, PAGE_NUM_POS.y)
		t.size = DIGIT_SIZE
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if _digit_sheet:
			var a := AtlasTexture.new()
			a.atlas = _digit_sheet
			a.region = Rect2(0, DIGIT_SIZE.y * int(ch), DIGIT_SIZE.x, DIGIT_SIZE.y)
			t.texture = a
		page_digits.add_child(t)
		x += DIGIT_SIZE.x


func _skin_button(node_name: String, prefix: String, pos: Vector2, sz: Vector2, fallback: String) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.position = pos
	btn.size = sz
	btn.custom_minimum_size = sz
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if not _set_states(btn, prefix):
		btn.text = fallback
	add_child(btn)
	return btn


func _set_states(btn: Button, prefix: String) -> bool:
	var normal := _tex("assets/hud/%s_normal.png" % prefix)
	if normal == null:
		return false
	btn.set_meta("skin_prefix", prefix)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var t := _tex("assets/hud/%s_%s.png" % [prefix, state])
		var box := StyleBoxTexture.new()
		box.texture = t if t else normal
		btn.add_theme_stylebox_override(state, box)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return true


func _tex(rel_path: String) -> Texture2D:
	var p := "res://" + rel_path
	return load(p) as Texture2D if ResourceLoader.exists(p) else null
