extends SceneTree

## Deletion code: the hash is stored, never the code; verification accepts the right code only; the
## delete-mode dialog verifies against the stored hash.

const DeletionCode = preload("res://scripts/ui/auth/deletion_code.gd")
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
	print("--- Deletion Code Suite ---")
	await process_frame
	var h := DeletionCode.hash_code("ghijkl")
	_record(h.length() == 64 and h != "ghijkl", "the stored value is a 64-character SHA-256 hash, not the code")
	_record(DeletionCode.matches("ghijkl", h), "the right code matches its hash")
	_record(not DeletionCode.matches("ghijkX", h), "a wrong code does not match")
	_record(not DeletionCode.matches("ghijkl", ""), "a character without a hash never matches")

	var d = PasswordDialog.new()
	root.add_child(d)
	await process_frame
	d.set_mode(2)
	_record(not d.fields[0].visible and d.fields[2].visible, "delete mode shows only the code field")
	var verified := [0]
	d.code_verified.connect(func() -> void: verified[0] += 1)
	d.verify_hash = h
	d.fields[2].text = "wrong1"
	_record(not d.verify_code(h) and verified[0] == 0, "a wrong code is rejected")
	d.fields[2].text = "ghijkl"
	_record(d.verify_code(h) and verified[0] == 1, "the right code verifies once")
	_record(not d.visible, "a verified dialog hides")

	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
