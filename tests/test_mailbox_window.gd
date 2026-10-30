extends SceneTree

## Headless checks for MailBoxWindow (TMailSaveBoxForm 0x1eada8) and MailStore.
const MB = preload("res://scripts/ui/hud/mailbox_window.gd")
const MS = preload("res://scripts/ui/hud/mail_store.gd")
const PATH := "user://test_mailbox.json"

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("  [PASS] %s" % msg)
	else:
		_failed += 1
		printerr("  [FAIL] %s" % msg)

func _finish() -> void:
	print("SUMMARY: %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _init() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	call_deferred("_run")

func _run() -> void:
	var store: MailStore = MS.new(PATH)
	var win: MailBoxWindow = MB.new(store)
	root.add_child(win)
	await process_frame
	_check(win.size == Vector2(602, 391), "form 602x391")
	_check(win.background.texture != null and win.background.texture.get_size() == Vector2(602, 391), "Form_MailBox_1 texture")
	_check(win.close_button.position == Vector2(554, 25), "Close_S (554,25)")
	_check(win.btn_close.position == Vector2(365, 350) and win.btn_send.position == Vector2(185, 350) and win.btn_delete.position == Vector2(275, 350), "bottom buttons")
	_check(win.btn_prev_page.position == Vector2(185, 320) and win.btn_next_page.position == Vector2(365, 320), "page buttons")
	_check(win.tab_inbox.position == Vector2(15, 48) and win.tab_backup.position == Vector2(79, 48) and win.tab_inbox.size == Vector2(64, 21), "tabs")
	_check(win.rows.size() == 10 and win.rows[0].position == Vector2(19, 95) and win.rows[9].position == Vector2(19, 275), "10 rows pitch 20")
	_check(MB.preview_text("short") == "short" and MB.preview_text("abcdefghijklmnopqrstuvwxyz") == "abcdefghijklmnopqr...", "preview truncation")
	_check(MB.format_time(0) == "1970/01/01 00:00:00", "time format")
	_check(MS.type_name(1) == "Friends" and MS.type_name(4) == "Pet" and MS.type_name(9) == "Normal ", "type labels")
	for i in 23:
		store.add_mail(MS.FOLDER_INBOX, "Sender%d" % i, "Hello %d" % i, i % 5, 1000 + i)
	win.open(MB.TAB_INBOX)
	_check(win.page_count() == 3, "23 mails -> 3 pages")
	_check(win.title_mask.visible, "Sender mask on inbox tab")
	_check(win.rows[0].visible and (win.rows[0].get_node("Name") as Label).text == "Sender22", "newest first")
	win.change_page(1)
	win.change_page(1)
	win.change_page(1)
	_check(win.current_page == 3 and win.visible_mails().size() == 3, "last page has 3")
	_check(not win.rows[3].visible, "unused rows hidden")
	var opened: Array = []
	win.mail_opened.connect(func(_f, m): opened.append(int(m.id)))
	win.open_row(0)
	_check(opened.size() == 1 and bool(store.find(MS.FOLDER_INBOX, opened[0]).read), "open marks read")
	var before := store.count(MS.FOLDER_INBOX)
	win.select_row(1)
	_check(win.delete_selected() and store.count(MS.FOLDER_INBOX) == before - 1, "delete selected")
	win.set_tab(MB.TAB_BACKUP)
	_check(not win.title_mask.visible and win.visible_mails().is_empty(), "backup tab empty")
	var to: Array = []
	win.compose_requested.connect(func(n): to.append(n))
	win.btn_send.pressed.emit()
	_check(to == [""], "send emits compose_requested")
	var store2: MailStore = MS.new(PATH)
	_check(store2.count(MS.FOLDER_INBOX) == before - 1, "mailbox persisted")
	win.close()
	_check(not win.visible, "close hides")
	_finish()
