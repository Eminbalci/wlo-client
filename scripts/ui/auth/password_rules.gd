class_name PasswordRules
extends RefCounted

## Login password and secret (deletion) code checks (Go client: login/inputpw.go, Check).
## Each of the two values is typed twice. Lengths are 6..10 characters. The checks run in the Go
## order and the first failure wins. Messages are English; the Go client uses its UI strings.

const MIN_LENGTH := 6
const MAX_LENGTH := 10

const OK := 0
const MISMATCH := 1
const CODE_MISMATCH := 2
const BAD_LENGTH := 3
const BAD_CODE_LENGTH := 4
const SAME_AS_CODE := 5


## Returns {result: int, message: String}. `password`/`code` are the first entries, `password_again`
## and `code_again` the confirmations.
static func check(password: String, password_again: String, code: String, code_again: String) -> Dictionary:
	if password != password_again:
		return _result(MISMATCH, "The passwords do not match.")
	if code != code_again:
		return _result(CODE_MISMATCH, "The delete passwords do not match.")
	if password.length() < MIN_LENGTH:
		return _result(BAD_LENGTH, "The password must be at least 6 characters.")
	if code.length() < MIN_LENGTH:
		return _result(BAD_CODE_LENGTH, "The delete password must be at least 6 characters.")
	if password.length() > MAX_LENGTH:
		return _result(BAD_LENGTH, "The password is too long.")
	if code.length() > MAX_LENGTH:
		return _result(BAD_CODE_LENGTH, "The delete password is too long.")
	if password == code:
		return _result(SAME_AS_CODE, "The password and the delete password must differ.")
	return _result(OK, "")


static func _result(result: int, message: String) -> Dictionary:
	return {"result": result, "message": message}
