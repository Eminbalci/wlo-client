extends SceneTree

## Password dialog: masked fields, mode button placement, submit validation and confirmation.

const PasswordDialog = preload("res://scripts/ui/auth/password_dialog.gd")

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
	print("--- Password Dialog Suite ---")
	await process_frame
	var d = PasswordDialog.new()
	root.add_child(d)
	await process_frame
	_record(d.fields.size() == 4 and d.fields[0].secret, "four masked fields are built")
	_record(d.fields[0].position == Vector2(149, 123) and d.fields[3].position.y == 123 + 3 * 48, "fields sit at the Go positions")
	d.set_mode(1)
	_record(d._ok.position.x == 444 and d._second.text == "Previous", "mode 1 puts OK on the right and Previous on the left")
	d.set_mode(2)
	_record(d._ok.position.x == 342 and d._second.text == "Cancel", "mode 2 puts OK on the left and Cancel on the right")

	var got := []
	d.confirmed.connect(func(p: String, c: String) -> void: got.append([p, c]))
	var msgs := []
	d.message.connect(func(t: String) -> void: msgs.append(t))

	d.fields[0].text = "abcdef"
	d.fields[1].text = "abcdeX"
	d.fields[2].text = "ghijkl"
	d.fields[3].text = "ghijkl"
	_record(not d.submit() and msgs.size() == 1, "a mismatch is refused with its message")
	_record(got.is_empty(), "nothing is confirmed on a failed check")

	d.fields[1].text = "abcdef"
	_record(d.submit() and got.size() == 1 and got[0] == ["abcdef", "ghijkl"], "matching values are confirmed as password and code")
	_record(not d.visible, "a confirmed dialog hides")

	var cancelled := [0]
	d.cancelled.connect(func() -> void: cancelled[0] += 1)
	d.open()
	_record(d.visible and d.fields[0].text == "", "open shows the dialog with empty fields")
	d.cancel()
	_record(cancelled[0] == 1 and not d.visible, "cancel hides the dialog and emits cancelled")

	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
