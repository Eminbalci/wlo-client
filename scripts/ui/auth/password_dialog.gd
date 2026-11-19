class_name PasswordDialog
extends Control

## Login password and secret-code dialog (Go client: login/inputpw.go, TRe_InputPwAndDarkPw).
## Four masked fields: password, password again, secret code, secret code again. Enter and Tab move
## to the next field and the last one submits. Layout is the Go constants in form-local pixels:
## fields at x 149, y 123 + 48*i, 104x14; buttons at y 312. Mode 1 (create) puts OK on the right and
## Previous on the left; mode 2 (delete) puts OK on the left and Cancel on the right.

signal confirmed(password: String, code: String)
signal cancelled
signal message(text: String)

const FORM_SIZE := Vector2(536, 352)
const FIELD_X := 149
const FIELD_Y := 123
const FIELD_STEP := 48
const FIELD_SIZE := Vector2(104, 14)
const BUTTON_Y := 312
const BUTTON_SIZE := Vector2(56, 20)
const LEFT_BUTTON_X := 342
const RIGHT_BUTTON_X := 444

var mode: int = 1
var fields: Array[LineEdit] = []
var _ok: Button
var _second: Button


func _ready() -> void:
	size = FORM_SIZE
	custom_minimum_size = FORM_SIZE
	visible = false
	_build()
	set_mode(mode)


func _build() -> void:
	for i in 4:
		var e := LineEdit.new()
		e.name = "Field%d" % (i + 1)
		e.position = Vector2(FIELD_X, FIELD_Y + i * FIELD_STEP)
		e.size = FIELD_SIZE
		e.secret = true
		e.max_length = PasswordRules.MAX_LENGTH
		e.text_submitted.connect(func(_t: String) -> void: _advance(i))
		add_child(e)
		fields.append(e)
	_ok = Button.new()
	_ok.name = "Ok"
	_ok.text = "OK"
	_ok.size = BUTTON_SIZE
	_ok.pressed.connect(_on_ok_pressed)
	add_child(_ok)
	_second = Button.new()
	_second.name = "Second"
	_second.size = BUTTON_SIZE
	_second.pressed.connect(cancel)
	add_child(_second)


## Mode 1 = create (OK right, Previous left), mode 2 = delete (OK left, Cancel right).
## Stored deletion-code hash for mode 2 (verification). Empty means create rules apply.
var verify_hash: String = ""


func set_mode(value: int) -> void:
	mode = value
	if fields.is_empty():
		return
	for i in fields.size():
		# Delete verification uses only the code field (index 2).
		fields[i].visible = mode != 2 or i == 2
	if _ok == null:
		return
	if mode == 2:
		_ok.position = Vector2(LEFT_BUTTON_X, BUTTON_Y)
		_second.position = Vector2(RIGHT_BUTTON_X, BUTTON_Y)
		_second.text = "Cancel"
	else:
		_ok.position = Vector2(RIGHT_BUTTON_X, BUTTON_Y)
		_second.position = Vector2(LEFT_BUTTON_X, BUTTON_Y)
		_second.text = "Previous"


## Builds the controls if the dialog has not entered the tree yet (its _ready has not run).
func ensure_built() -> void:
	if fields.is_empty():
		_build()
		set_mode(mode)


func clear_fields() -> void:
	ensure_built()
	for f in fields:
		f.clear()


func open() -> void:
	ensure_built()
	clear_fields()
	visible = true
	move_to_front()
	fields[0].grab_focus()


## Checks the values. On success emits confirmed(password, code); otherwise shows the message.
func submit() -> bool:
	ensure_built()
	var result := PasswordRules.check(fields[0].text, fields[1].text, fields[2].text, fields[3].text)
	if result.result != PasswordRules.OK:
		message.emit(result.message)
		return false
	confirmed.emit(fields[0].text, fields[2].text)
	visible = false
	return true


## Verification only (character deletion): checks the code field against the stored hash.
signal code_verified
signal code_rejected

func verify_code(stored_hash: String) -> bool:
	ensure_built()
	if DeletionCode.matches(fields[2].text, stored_hash):
		visible = false
		code_verified.emit()
		return true
	message.emit("The delete password is wrong.")
	code_rejected.emit()
	return false


func cancel() -> void:
	visible = false
	cancelled.emit()


func _on_ok_pressed() -> void:
	if mode == 2 and verify_hash != "":
		verify_code(verify_hash)
	else:
		submit()


func _advance(index: int) -> void:
	if mode == 2 or index >= fields.size() - 1:
		_on_ok_pressed()
	else:
		fields[index + 1].grab_focus()
