class_name MailBoxWindow
extends Control

## Mail box list (TMailSaveBoxForm, constructor aLogin.exe 0x1eada8, paint 0x1eb3a0).
## Control table (left, top, w, h):
##   form "Form_MailBox_1" 602x391, centred on the screen
##   Btn_Close_S_1 (554,25) 18x18 | Btn_Close_1 (365,350) | Btn_sendMail_2 (185,350) | Btn_deleteMail_1 (275,350)
##   Btn_PrePage_1 (185,320) | Btn_NextPage_1 (365,320)   (all 56x20)
##   Btn_MailBoxTab_1 (15,48) 64x21 "Mail Inbox" tag 0 | Btn_MailBoxTab_2 (79,48) 64x21 "Backup" tag 1
##   Icon_MailBoxTitleMash_1 ("Sender", 76x20) drawn at (282,70) over the "To" header on tab 0.
## Paint: 10 rows per page (page count = ceil(count / 10.0)), row hit-rect (19, 95+20*i) 563x20.
## Row text at y = 98+20*i: type x=36, preview x=90, name x=270 ("Unknown" if empty), time x=400
## (FormatDateTime "yyyy/mm/dd hh:mm:ss"). Unread rows 0xFFE0 (yellow), read rows 0xAD60.
## Preview = content up to the first #13; longer than 20 bytes -> first ~18 bytes + "...".
## Page text "<page> " right-aligned to x=298 and "/ <pages>" from x=298, y=320; colour 0x001F, or
## 0xF800 when the folder holds more than 900 mails.

signal compose_requested(to_name: String)
signal mail_opened(folder: String, mail: Dictionary)
signal mail_deleted(folder: String, mail_id: int)
signal tab_changed(tab: int)
signal window_closed

const S = preload("res://scripts/ui/hud/wlo_window_skin.gd")
const MailStoreScript = preload("res://scripts/ui/hud/mail_store.gd")

const WINDOW_SIZE: Vector2 = Vector2(602, 391)
const ROWS_PER_PAGE: int = 10
const ROW_ORIGIN: Vector2 = Vector2(19, 95)
const ROW_SIZE: Vector2 = Vector2(563, 20)
const ROW_PITCH: int = 20
const TEXT_DY: int = 3
const COLUMN_X: Dictionary = {"type": 36, "preview": 90, "name": 270, "time": 400}
const COLUMN_W: Dictionary = {"type": 52, "preview": 178, "name": 128, "time": 160} ## clip widths (not in the binary)
const COLOR_UNREAD: int = 0xFFE0
const COLOR_READ: int = 0xAD60
const COLOR_PAGE: int = 0x001F
const COLOR_PAGE_FULL: int = 0xF800
const TAB_INBOX: int = 0
const TAB_BACKUP: int = 1

var store: MailStore
var background: TextureRect
var close_button: TextureButton
var btn_close: TextureButton
var btn_send: TextureButton
var btn_delete: TextureButton
var btn_prev_page: TextureButton
var btn_next_page: TextureButton
var tab_inbox: TextureButton
var tab_backup: TextureButton
var title_mask: TextureRect
var page_label: Label
var page_total_label: Label
var rows: Array[Control] = []

var current_tab: int = TAB_INBOX
var current_page: int = 1
var selected_mail_id: int = -1
var _built: bool = false


func _init(p_store: MailStore = null) -> void:
	name = "MailBoxWindow"
	size = WINDOW_SIZE
	custom_minimum_size = WINDOW_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	store = p_store if p_store != null else MailStoreScript.new()


func _ready() -> void:
	_build()
	var vp := get_viewport_rect().size
	position = ((vp - WINDOW_SIZE) * 0.5).floor()


func _build() -> void:
	if _built:
		return
	_built = true
	background = S.background(self, "mail_box_form", WINDOW_SIZE)
	S.make_draggable(self, background)
	title_mask = TextureRect.new()
	title_mask.name = "TitleMask"
	title_mask.texture = S.tex("mail_box_title_mask")
	title_mask.position = Vector2(282, 70)
	title_mask.size = Vector2(76, 20)
	title_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_mask)
	for i in ROWS_PER_PAGE:
		rows.append(_make_row(i))
	page_label = S.label(self, "PageLabel", Rect2(198, 312, 100, 16), S.rgb565(COLOR_PAGE), 12, HORIZONTAL_ALIGNMENT_RIGHT)
	page_total_label = S.label(self, "PageTotalLabel", Rect2(298, 312, 60, 16), S.rgb565(COLOR_PAGE), 12)
	for l in [page_label, page_total_label]:
		l.add_theme_constant_override("outline_size", 0)
	tab_inbox = S.button(self, "TabInbox", "mail_box_tab_1", Rect2(15, 48, 64, 21), "Mail Inbox")
	tab_backup = S.button(self, "TabBackup", "mail_box_tab_2", Rect2(79, 48, 64, 21), "Backup")
	btn_prev_page = S.button(self, "BtnPrevPage", "mail_btn_prev_page", Rect2(185, 320, 56, 20))
	btn_next_page = S.button(self, "BtnNextPage", "mail_btn_next_page", Rect2(365, 320, 56, 20))
	btn_send = S.button(self, "BtnSend", "mail_btn_send", Rect2(185, 350, 56, 20))
	btn_delete = S.button(self, "BtnDelete", "mail_btn_delete", Rect2(275, 350, 56, 20))
	btn_close = S.button(self, "BtnClose", "mail_btn_close", Rect2(365, 350, 56, 20))
	close_button = S.button(self, "CloseButton", "skin_btn_close_s_1", Rect2(554, 25, 18, 18), "Close")
	tab_inbox.pressed.connect(set_tab.bind(TAB_INBOX))
	tab_backup.pressed.connect(set_tab.bind(TAB_BACKUP))
	btn_prev_page.pressed.connect(change_page.bind(-1))
	btn_next_page.pressed.connect(change_page.bind(1))
	btn_send.pressed.connect(_on_send)
	btn_delete.pressed.connect(delete_selected)
	btn_close.pressed.connect(close)
	close_button.pressed.connect(close)
	store.changed.connect(refresh)
	refresh()


func _make_row(i: int) -> Control:
	var row := Button.new()
	row.name = "Row%d" % i
	row.flat = true
	row.focus_mode = Control.FOCUS_NONE
	row.position = ROW_ORIGIN + Vector2(0, ROW_PITCH * i)
	row.size = ROW_SIZE
	var empty := StyleBoxEmpty.new()
	var hl := StyleBoxFlat.new()
	hl.bg_color = Color(1, 1, 1, 0.12)
	var sel := StyleBoxFlat.new()
	sel.bg_color = Color(1, 0.9, 0.3, 0.22)
	row.add_theme_stylebox_override("normal", empty)
	row.add_theme_stylebox_override("focus", empty)
	row.add_theme_stylebox_override("hover", hl)
	row.add_theme_stylebox_override("pressed", sel)
	row.set_meta("selected_style", sel)
	add_child(row)
	for col in ["type", "preview", "name", "time"]:
		var w: int = COLUMN_W[col]
		var lbl := S.label(row, col.capitalize(), Rect2(COLUMN_X[col] - ROW_ORIGIN.x, TEXT_DY - 2, w, 18), Color.WHITE, 12)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	row.gui_input.connect(_on_row_input.bind(i))
	return row


# --- public API -------------------------------------------------------------------------------

func open(tab: int = TAB_INBOX) -> void:
	_build()
	visible = true
	move_to_front()
	set_tab(tab)


func close() -> void:
	visible = false
	window_closed.emit()


func folder() -> String:
	return MailStore.FOLDER_INBOX if current_tab == TAB_INBOX else MailStore.FOLDER_BACKUP


func set_tab(tab: int) -> void:
	current_tab = clampi(tab, TAB_INBOX, TAB_BACKUP)
	current_page = 1
	selected_mail_id = -1
	tab_changed.emit(current_tab)
	refresh()


func page_count() -> int:
	return maxi(1, ceili(store.count(folder()) / float(ROWS_PER_PAGE)))


func change_page(delta: int) -> void:
	current_page = clampi(current_page + delta, 1, page_count())
	refresh()


func visible_mails() -> Array:
	var all := store.get_mails(folder())
	var start := (current_page - 1) * ROWS_PER_PAGE
	return all.slice(start, mini(start + ROWS_PER_PAGE, all.size()))


func select_row(i: int) -> void:
	var mails := visible_mails()
	if i < 0 or i >= mails.size():
		return
	selected_mail_id = int(mails[i].id)
	refresh()


func open_row(i: int) -> void:
	var mails := visible_mails()
	if i < 0 or i >= mails.size():
		return
	var m: Dictionary = mails[i]
	selected_mail_id = int(m.id)
	store.mark_read(folder(), selected_mail_id)
	mail_opened.emit(folder(), m)
	refresh()


func delete_selected() -> bool:
	if selected_mail_id < 0:
		return false
	var id := selected_mail_id
	var ok := store.delete_mail(folder(), id)
	if ok:
		selected_mail_id = -1
		current_page = clampi(current_page, 1, page_count())
		mail_deleted.emit(folder(), id)
	refresh()
	return ok


## Row preview text: first line (up to #13), >20 chars -> 18 chars + "...".
static func preview_text(content: String) -> String:
	var line := content.split("\r")[0].split("\n")[0]
	if line.length() > 20:
		return line.substr(0, 18) + "..."
	return line


static func format_time(unix_time: int) -> String:
	var d := Time.get_datetime_dict_from_unix_time(unix_time)
	return "%04d/%02d/%02d %02d:%02d:%02d" % [d.year, d.month, d.day, d.hour, d.minute, d.second]


func refresh() -> void:
	if not _built:
		return
	title_mask.visible = current_tab == TAB_INBOX
	var mails := visible_mails()
	for i in ROWS_PER_PAGE:
		var row := rows[i] as Button
		if i < mails.size():
			var m: Dictionary = mails[i]
			var c := S.rgb565(COLOR_READ if bool(m.read) else COLOR_UNREAD)
			row.visible = true
			_set_cell(row, "Type", MailStore.type_name(int(m.type)), c)
			_set_cell(row, "Preview", preview_text(String(m.content)), c)
			_set_cell(row, "Name", String(m.name) if String(m.name) != "" else "Unknown", c)
			_set_cell(row, "Time", format_time(int(m.time)), c)
			var sel := int(m.id) == selected_mail_id
			row.add_theme_stylebox_override("normal", row.get_meta("selected_style") if sel else StyleBoxEmpty.new())
		else:
			row.visible = false
	var total := store.count(folder())
	var pc := S.rgb565(COLOR_PAGE_FULL if total > MailStore.WARN_COUNT else COLOR_PAGE)
	page_label.text = "%d " % current_page
	page_total_label.text = "/ %d" % page_count()
	page_label.add_theme_color_override("font_color", pc)
	page_total_label.add_theme_color_override("font_color", pc)
	btn_delete.disabled = selected_mail_id < 0


func _set_cell(row: Control, cell: String, text: String, color: Color) -> void:
	var lbl := row.get_node(cell) as Label
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)


func _on_row_input(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click:
			open_row(i)
		else:
			select_row(i)


func _on_send() -> void:
	var to_name := ""
	if selected_mail_id >= 0:
		to_name = String(store.find(folder(), selected_mail_id).get("name", ""))
	compose_requested.emit(to_name)
