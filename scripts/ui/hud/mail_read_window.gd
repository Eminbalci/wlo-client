class_name MailReadWindow
extends Control

## Friend letter reader (Go client: hud/mailread.go, TSe_ReceiveMailForm, form_MailReceive_1).
## Layout is the Go constants, in form-local pixels: date (29,50), sender name (76,67), memo (28,88) 200x190,
## Reply (101,285), Delete (164,285), Previous (36,285), Next (36,310), Close (101,331), corner close (203,23).
## Invitation letters strip the "^inviation^" prefix and show a badge. Icons missing from the original
## pictures (icon_NextMail_1, icon_PrevMail_1, form_invitation2) stand in as grey panels, as in the Go client.

signal reply_requested
signal delete_requested
signal next_requested
signal prev_requested
signal closed

const FORM_PATH := "res://assets/hud/mail_read/form_MailReceive_1.png"
const DIR := "res://assets/hud/mail_read/"
const INVITATION_PREFIX := "^inviation^"
const FORM_SIZE := Vector2(253, 371)
const FORM_POS := Vector2(10, 50)
const INK := Color("#2b2b2b")

var _date: Label
var _name: Label
var _memo: TextEdit
var _next_btn: Button
var _prev_btn: Button
var _reply_btn: Button
var _delete_btn: Button
var _close_btn: Button
var _corner_btn: Button
var _badge: ColorRect
var _has_next := false
var _has_prev := false


func _ready() -> void:
	position = FORM_POS
	size = FORM_SIZE
	custom_minimum_size = FORM_SIZE
	visible = false
	_build()


func _build() -> void:
	var bg := TextureRect.new()
	bg.name = "Form"
	bg.texture = _tex(FORM_PATH)
	bg.stretch_mode = TextureRect.STRETCH_KEEP
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_date = _label("Date", Vector2(29, 50), Vector2(170, 16))
	_name = _label("Sender", Vector2(76, 67), Vector2(120, 16))

	_badge = ColorRect.new()
	_badge.name = "InvitationBadge"
	_badge.position = Vector2(19, 56)
	_badge.size = Vector2(20, 20)
	_badge.color = Color(1, 0.85, 0.3, 0.9)
	_badge.visible = false
	add_child(_badge)

	_memo = TextEdit.new()
	_memo.name = "Memo"
	_memo.position = Vector2(28, 88)
	_memo.size = Vector2(200, 190)
	_memo.editable = false
	_memo.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_memo.add_theme_color_override("font_readonly_color", INK)
	add_child(_memo)

	_reply_btn = _image_button("Reply", "btn_reply_1", Vector2(101, 285), Vector2(56, 20))
	_reply_btn.pressed.connect(func() -> void: reply_requested.emit())
	_delete_btn = _image_button("Delete", "btn_deleteMail_1", Vector2(164, 285), Vector2(56, 20))
	_delete_btn.pressed.connect(func() -> void: delete_requested.emit())
	_close_btn = _image_button("Close", "", Vector2(101, 331), Vector2(56, 20))
	_close_btn.text = "Close"
	_close_btn.pressed.connect(close)

	_prev_btn = _image_button("Prev", "btn_PrevMail_1", Vector2(36, 285), Vector2(56, 20))
	_prev_btn.pressed.connect(func() -> void: prev_requested.emit())
	_next_btn = _image_button("Next", "btn_NextMail_1", Vector2(36, 310), Vector2(56, 20))
	_next_btn.pressed.connect(func() -> void: next_requested.emit())

	_corner_btn = _image_button("CornerClose", "btn_close_s_1", Vector2(203, 23), Vector2(17, 17))
	_corner_btn.pressed.connect(close)


func _label(node_name: String, pos: Vector2, sz: Vector2) -> Label:
	var l := Label.new()
	l.name = node_name
	l.position = pos
	l.size = sz
	l.add_theme_color_override("font_color", INK)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _image_button(node_name: String, picture: String, pos: Vector2, sz: Vector2) -> Button:
	var b := Button.new()
	b.name = node_name
	b.position = pos
	b.size = sz
	if picture != "":
		var t := _tex(DIR + picture + ".png")
		if t:
			b.icon = t
			b.expand_icon = true
			b.flat = true
	add_child(b)
	return b


func _tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


## Shows a mail record ({name, content, time}); the invitation prefix is removed and marks an invitation.
func show_mail(mail: Dictionary, has_prev: bool, has_next: bool) -> void:
	var content := str(mail.get("content", ""))
	var invitation := content.begins_with(INVITATION_PREFIX)
	if invitation:
		content = content.substr(INVITATION_PREFIX.length())
	_memo.text = content
	_name.text = str(mail.get("name", "")) if str(mail.get("name", "")) != "" else "Unknown"
	_date.text = _format_time(int(mail.get("time", 0)))
	_badge.visible = invitation
	set_navigation(has_prev, has_next)
	open()


func set_navigation(has_prev: bool, has_next: bool) -> void:
	_has_prev = has_prev
	_has_next = has_next
	_prev_btn.visible = has_prev
	_next_btn.visible = has_next


func open() -> void:
	visible = true
	move_to_front()


func close() -> void:
	visible = false
	closed.emit()


static func _format_time(unix_time: int) -> String:
	if unix_time <= 0:
		return ""
	var d := Time.get_datetime_dict_from_unix_time(unix_time)
	return "%04d/%02d/%02d %02d:%02d:%02d" % [d.year, d.month, d.day, d.hour, d.minute, d.second]
