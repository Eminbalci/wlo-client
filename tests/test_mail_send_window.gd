extends SceneTree

## Headless checks for MailSendWindow (TSe_SendMailForm 0x3d9c88 / TSe_ReadMailForm 0x3dac5c).
const MW = preload("res://scripts/ui/hud/mail_send_window.gd")
const MS = preload("res://scripts/ui/hud/mail_store.gd")
const PATH := "user://test_mailsend.json"

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
	var win: MailSendWindow = MW.new(store)
	root.add_child(win)
	await process_frame
	win.open_compose("Betty")
	_check(win.size == Vector2(249, 355) and win.position == Vector2(10, 50), "send form (10,50) 249x355")
	_check(win.background.texture != null and win.background.texture.get_size() == Vector2(249, 355), "Form_MailSend_1 texture")
	_check(win.close_button.position == Vector2(200, 23) and win.close_button.size == Vector2(17, 17), "Close_s (200,23)")
	_check(win.btn_send.position == Vector2(167, 282) and win.btn_past.position == Vector2(42, 282) and win.btn_clear.position == Vector2(104, 282), "send/past/clear")
	_check(win.btn_close.position == Vector2(104, 315), "close (104,315)")
	_check(win.memo.position == Vector2(30, 90) and win.memo.size == Vector2(190, 200), "memo bounds (30,90,190,200)")
	_check(win.to_edit.text == "Betty", "To prefilled")
	var fails: Array = []
	win.send_failed.connect(func(r): fails.append(r))
	_check(not win.send(), "empty content rejected")
	win.to_edit.text = ""
	win.memo.text = "hi"
	win.send()
	win.to_edit.text = "GMCenter"
	win.send()
	_check(fails == ["No mail content", "No target player", "Can't send to GM"], "validation messages %s" % str(fails))
	win.to_edit.text = "Betty"
	win.memo.text = "x".repeat(200)
	win._enforce_max_length()
	_check(win.memo.text.length() == 152, "max length 152")
	var sent: Array = []
	win.mail_sent.connect(func(t, _c): sent.append(t))
	_check(win.send() and sent == ["Betty"], "send ok")
	_check(store.count(MS.FOLDER_BACKUP) == 1 and win.memo.text == "", "copy stored in Backup, memo cleared")
	var mail := store.add_mail(MS.FOLDER_INBOX, "Daniel", "Line one", 1)
	win.open_read(mail, false, true)
	_check(win.size == Vector2(253, 371), "read form 253x371")
	_check(win.background.texture.get_size() == Vector2(253, 371), "form_MailReceive_1 texture")
	_check(win.btn_reply.position == Vector2(101, 285) and win.btn_delete.position == Vector2(164, 285), "reply/delete")
	_check(win.btn_close.position == Vector2(101, 331) and win.close_button.position == Vector2(203, 23), "read close buttons")
	_check(win.btn_next.visible and not win.next_gray.visible and win.prev_gray.visible and not win.btn_prev.visible, "gray prev/next swap")
	_check(win.from_label.text == "Daniel" and win.body_label.text == "Line one", "read content")
	_check(not win.memo.visible and not win.btn_send.visible, "send controls hidden in read mode")
	win.btn_reply.pressed.emit()
	_check(win.mode == MW.MODE_SEND and win.to_edit.text == "Daniel", "reply opens compose")
	win.open_read(mail)
	win.btn_delete.pressed.emit()
	_check(store.count(MS.FOLDER_INBOX) == 0 and not win.visible, "delete removes mail and closes")
	_finish()
