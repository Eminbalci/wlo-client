extends SceneTree

const MailboxWindow = preload("res://scripts/ui/hud/mailbox_window.gd")

## The letter reader opens from the mailbox, shows the text, strips the invitation prefix and steps through mail.

var _checks := 0
var _failed := 0


func _init() -> void:
	_run()


func _record(ok: bool, label: String) -> void:
	_checks += 1
	if ok:
		print("  [PASS] " + label)
	else:
		_failed += 1
		print("  [FAIL] " + label)


func _run() -> void:
	print("--- Mail Read Window Suite ---")
	await process_frame
	await process_frame
	var store := MailStore.new("user://test_mail_read.json")
	store.clear()
	store.add_mail(MailStore.FOLDER_INBOX, "Alice", "first letter", MailStore.TYPE_NORMAL, 1700000000, false)
	store.add_mail(MailStore.FOLDER_INBOX, "Bob", "^inviation^Join us", MailStore.TYPE_NORMAL, 1700000100, false)
	var box = MailboxWindow.new(store)
	root.add_child(box)
	await process_frame
	box.open()
	box.select_row(0)
	box.open_row(0)
	await process_frame
	var reader: MailReadWindow = box._reader
	_record(reader != null and reader.visible, "opening a letter shows the reader")
	_record(reader != null and reader._memo.text == "Join us" or reader != null and reader._memo.text == "Join us ", "the reader shows the letter text")
	_record(reader != null and reader._badge.visible == true, "the invitation prefix shows the badge")
	box.open_row(1)
	await process_frame
	_record(reader._memo.text.find("first") >= 0, "opening the second letter shows its text")
	_record(reader._prev_btn.visible and not reader._next_btn.visible, "on the last letter Previous shows and Next hides")
	store.clear()
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
