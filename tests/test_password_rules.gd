extends SceneTree

## Login password and secret code checks, in the Go order.

const PasswordRules = preload("res://scripts/ui/auth/password_rules.gd")

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
	print("--- Password Rules Suite ---")
	await process_frame
	_record(PasswordRules.check("abcdef", "abcdef", "ghijkl", "ghijkl").result == PasswordRules.OK, "matching values of 6 characters pass")
	_record(PasswordRules.check("abcdef", "abcdeX", "ghijkl", "ghijkl").result == PasswordRules.MISMATCH, "a password mismatch is reported first")
	_record(PasswordRules.check("abcdef", "abcdef", "ghijkl", "ghijkX").result == PasswordRules.CODE_MISMATCH, "a delete password mismatch is reported")
	_record(PasswordRules.check("abc", "abc", "ghijkl", "ghijkl").result == PasswordRules.BAD_LENGTH, "a short password fails the length check")
	_record(PasswordRules.check("abcdef", "abcdef", "ghi", "ghi").result == PasswordRules.BAD_CODE_LENGTH, "a short delete password fails the length check")
	_record(PasswordRules.check("abcdefghijk", "abcdefghijk", "ghijkl", "ghijkl").result == PasswordRules.BAD_LENGTH, "an 11-character password is too long")
	_record(PasswordRules.check("abcdef", "abcdef", "ghijklmnopq", "ghijklmnopq").result == PasswordRules.BAD_CODE_LENGTH, "an 11-character delete password is too long")
	_record(PasswordRules.check("abcdef", "abcdef", "abcdef", "abcdef").result == PasswordRules.SAME_AS_CODE, "identical values are refused")
	_record(PasswordRules.check("abc", "abd", "ghi", "ghj").result == PasswordRules.MISMATCH, "mismatch wins over length")
	_record(PasswordRules.check("abcdef", "abcdef", "ghijkl", "ghijkl").message == "", "a passing check has no message")

	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
