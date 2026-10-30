class_name MailSendWindow
extends Control

## Mail compose / read window. Two decoded forms share this script:
##
## MODE_SEND = TSe_SendMailForm (constructor aLogin.exe 0x3d9c88), "Form_MailSend_1" (10,50) 249x355
##   Btn_Close_s_1 (200,23) 17x17 | Btn_sendMail_2 (167,282) | btn_PastMail_1 (42,282)
##   btn_Clear_1 (104,282) | Btn_Close_1 (104,315)                       (56x20 each)
##   memo (class at 0x47fc9c) SetBounds(30, 90, 190, 200), max length 0x98 = 152, font colour 0xFFE0
##   Send-side checks seen at 0x1ad530: "No target player", "No mail content", "Can't send to GM".
## MODE_READ = TSe_ReadMailForm (constructor 0x3dac5c), "form_MailReceive_1" (10,50) 253x371
##   Btn_Close_s_1 (203,23) 17x17 | btn_reply_1 (101,285) | Btn_Close_1 (101,331)
##   btn_deleteMail_1 (164,285) | btn_NextMail_1 (36,310) | btn_PrevMail_1 (36,285)
##   btn_NextMail_Gray_1 / btn_PrevMail_Gray_1 (static images) on the same rects when disabled.
## The "To"/"From" name box and the read-mode body rect are MEASURED from the skins (the
## constructors do not create them), see docs/re/mail_window.md.

signal mail_sent(to_name: String, content: String)
signal send_failed(reason: String)
signal history_requested
signal reply_requested(to_name: String)
signal mail_deleted(mail_id: int)
signal navigate_requested(direction: int)
signal window_closed

const S = preload("res://scripts/ui/hud/wlo_window_skin.gd")
const MailStoreScript = preload("res://scripts/ui/hud/mail_store.gd")

const MODE_SEND: int = 0
const MODE_READ: int = 1
const SEND_SIZE: Vector2 = Vector2(249, 355)
const READ_SIZE: Vector2 = Vector2(253, 371)
const DEFAULT_POSITION: Vector2 = Vector2(10, 50)
const MAX_LENGTH: int = 152
const MEMO_RECT: Rect2 = Rect2(30, 90, 190, 200)
const READ_BODY_RECT: Rect2 = Rect2(30, 92, 194, 184) ## measured: skin body box (26,88)-(228,280)
const TO_RECT: Rect2 = Rect2(48, 64, 170, 20) ## measured: right of the baked "To" label
const FROM_RECT: Rect2 = Rect2(76, 64, 150, 20) ## measured: right of the baked "From" label

var store: MailStore
var mode: int = MODE_SEND
var background: TextureRect
var close_button: TextureButton
var to_edit: LineEdit
var memo: TextEdit
var from_label: Label
var body_label: RichTextLabel
var status_label: Label
# send mode
var btn_send: TextureButton
var btn_past: TextureButton
var btn_clear: TextureButton
var btn_close: TextureButton
# read mode
var btn_reply: TextureButton
var btn_delete: TextureButton
var btn_next: TextureButton
var btn_prev: TextureButton
var next_gray: TextureRect
var prev_gray: TextureRect

var current_mail: Dictionary = {}
var _has_next: bool = false
var _has_prev: bool = false
var _send_nodes: Array[Control] = []
var _read_nodes: Array[Control] = []
var _built: bool = false


func _init(p_store: MailStore = null) -> void:
	name = "MailSendWindow"
	position = DEFAULT_POSITION
	mouse_filter = Control.MOUSE_FILTER_STOP
	store = p_store if p_store != null else MailStoreScript.new()
	_apply_size()


func _ready() -> void:
	_build()


func _apply_size() -> void:
	var s := SEND_SIZE if mode == MODE_SEND else READ_SIZE
	size = s
	custom_minimum_size = s


func _build() -> void:
	if _built:
		return
	_built = true
	background = S.background(self, "mail_send_form", SEND_SIZE)
	S.make_draggable(self, background)
	# --- send controls
	to_edit = LineEdit.new()
	to_edit.name = "ToEdit"
	to_edit.position = TO_RECT.position
	to_edit.size = TO_RECT.size
	to_edit.max_length = 16
	to_edit.placeholder_text = "Name"
	_style_input(to_edit)
	add_child(to_edit)
	memo = TextEdit.new()
	memo.name = "Memo"
	memo.position = MEMO_RECT.position
	memo.size = MEMO_RECT.size
	memo.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_style_input(memo)
	memo.text_changed.connect(_enforce_max_length)
	add_child(memo)
	btn_send = S.button(self, "BtnSend", "mail_btn_send", Rect2(167, 282, 56, 20))
	btn_past = S.button(self, "BtnPast", "mail_btn_past", Rect2(42, 282, 56, 20))
	btn_clear = S.button(self, "BtnClear", "mail_btn_clear", Rect2(104, 282, 56, 20))
	btn_close = S.button(self, "BtnClose", "mail_btn_close", Rect2(104, 315, 56, 20))
	_send_nodes = [to_edit, memo, btn_send, btn_past, btn_clear]
	# --- read controls
	from_label = S.label(self, "FromLabel", FROM_RECT, S.rgb565(0xFFE0), 12)
	body_label = RichTextLabel.new()
	body_label.name = "Body"
	body_label.position = READ_BODY_RECT.position
	body_label.size = READ_BODY_RECT.size
	body_label.bbcode_enabled = false
	body_label.scroll_active = true
	body_label.add_theme_color_override("default_color", Color(0.15, 0.18, 0.35))
	body_label.add_theme_font_size_override("normal_font_size", 12)
	add_child(body_label)
	btn_reply = S.button(self, "BtnReply", "mail_btn_reply", Rect2(101, 285, 56, 20))
	btn_delete = S.button(self, "BtnDelete", "mail_btn_delete", Rect2(164, 285, 56, 20))
	prev_gray = _gray("PrevGray", "mail_btn_prev_mail_gray", Vector2(36, 285))
	next_gray = _gray("NextGray", "mail_btn_next_mail_gray", Vector2(36, 310))
	btn_prev = S.button(self, "BtnPrev", "mail_btn_prev_mail", Rect2(36, 285, 56, 20))
	btn_next = S.button(self, "BtnNext", "mail_btn_next_mail", Rect2(36, 310, 56, 20))
	_read_nodes = [from_label, body_label, btn_reply, btn_delete, prev_gray, next_gray, btn_prev, btn_next]
	status_label = S.label(self, "Status", Rect2(20, 302, 210, 14), Color(0.8, 0.1, 0.1), 11, HORIZONTAL_ALIGNMENT_CENTER)
	close_button = S.button(self, "CloseButton", "skin_btn_close_s_1", Rect2(200, 23, 17, 17), "Close")
	btn_send.pressed.connect(send)
	btn_past.pressed.connect(func() -> void: history_requested.emit())
	btn_clear.pressed.connect(clear_compose)
	btn_close.pressed.connect(close)
	close_button.pressed.connect(close)
	btn_reply.pressed.connect(_on_reply)
	btn_delete.pressed.connect(_on_delete)
	btn_prev.pressed.connect(func() -> void: navigate_requested.emit(-1))
	btn_next.pressed.connect(func() -> void: navigate_requested.emit(1))
	_apply_mode()


func _gray(node_name: String, file: String, pos: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.name = node_name
	t.texture = S.tex(file)
	t.position = pos
	t.size = Vector2(56, 20)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(t)
	return t


func _style_input(c: Control) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(1, 1, 1, 0.0)
	c.add_theme_stylebox_override("normal", box)
	c.add_theme_stylebox_override("focus", box)
	c.add_theme_color_override("font_color", Color(0.15, 0.18, 0.35))
	c.add_theme_font_size_override("font_size", 12)


# --- public API -------------------------------------------------------------------------------

func open_compose(to_name: String = "", content: String = "") -> void:
	mode = MODE_SEND
	_build()
	_apply_mode()
	to_edit.text = to_name
	memo.text = content
	status_label.text = ""
	visible = true
	move_to_front()


## Shows a stored mail with the form_MailReceive_1 layout. has_prev / has_next toggle the gray
## versions of the Prev/Next buttons like the original.
func open_read(mail: Dictionary, has_prev: bool = false, has_next: bool = false) -> void:
	mode = MODE_READ
	_build()
	current_mail = mail.duplicate()
	_has_prev = has_prev
	_has_next = has_next
	_apply_mode()
	from_label.text = String(mail.get("name", "")) if String(mail.get("name", "")) != "" else "Unknown"
	body_label.text = String(mail.get("content", ""))
	status_label.text = ""
	visible = true
	move_to_front()


func open() -> void:
	open_compose()


func close() -> void:
	visible = false
	window_closed.emit()


func clear_compose() -> void:
	memo.text = ""
	status_label.text = ""


## Validates and "sends" offline: the copy goes to the Backup folder of the shared store.
func send() -> bool:
	var to_name := to_edit.text.strip_edges()
	var content := memo.text.strip_edges()
	var reason := ""
	if to_name == "":
		reason = "No target player"
	elif content == "":
		reason = "No mail content"
	elif to_name.to_upper().begins_with("GM"):
		reason = "Can't send to GM"
	if reason != "":
		status_label.text = reason
		send_failed.emit(reason)
		return false
	store.add_mail(MailStore.FOLDER_BACKUP, to_name, content, MailStore.TYPE_NORMAL, -1, true)
	mail_sent.emit(to_name, content)
	clear_compose()
	return true


# --- internals --------------------------------------------------------------------------------

func _apply_mode() -> void:
	_apply_size()
	if not _built:
		return
	var is_send := mode == MODE_SEND
	background.texture = S.tex("mail_send_form" if is_send else "mail_read_form")
	background.size = size
	for n in _send_nodes:
		n.visible = is_send
	for n in _read_nodes:
		n.visible = not is_send
	btn_close.position = Vector2(104, 315) if is_send else Vector2(101, 331)
	close_button.position = Vector2(200, 23) if is_send else Vector2(203, 23)
	if not is_send:
		btn_prev.visible = _has_prev
		prev_gray.visible = not _has_prev
		btn_next.visible = _has_next
		next_gray.visible = not _has_next


func _enforce_max_length() -> void:
	if memo.text.length() > MAX_LENGTH:
		memo.text = memo.text.substr(0, MAX_LENGTH)
		memo.set_caret_column(memo.get_line(memo.get_line_count() - 1).length())
		memo.set_caret_line(memo.get_line_count() - 1)


func _on_reply() -> void:
	var to_name := String(current_mail.get("name", ""))
	reply_requested.emit(to_name)
	open_compose(to_name)


func _on_delete() -> void:
	if current_mail.is_empty():
		return
	var id := int(current_mail.get("id", -1))
	store.delete_mail(MailStore.FOLDER_INBOX, id)
	mail_deleted.emit(id)
	close()
