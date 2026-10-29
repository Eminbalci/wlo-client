extends SceneTree

## Chat driven with real mouse / keyboard events (focus, typing, Enter, channel dropdown, wheel scroll).

var _checks: int = 0
var _failed: int = 0


func _init() -> void:
	_run()


func _record(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("[PASS] " + description)
	else:
		_failed += 1
		print("[FAIL] " + description)


func _click_rect_center(rect: Rect2) -> void:
	var pos := rect.position + rect.size * 0.5

	var motion := InputEventMouseMotion.new()
	motion.position = pos
	motion.global_position = pos
	root.push_input(motion)
	await process_frame

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.position = pos
	press.global_position = pos
	root.push_input(press)
	await process_frame

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.button_mask = 0
	release.position = pos
	release.global_position = pos
	root.push_input(release)
	await process_frame


func _type_char(c: String) -> void:
	var code := c.unicode_at(0)
	var key: int = c.to_upper().unicode_at(0)

	var press := InputEventKey.new()
	press.pressed = true
	press.unicode = code
	press.keycode = key
	root.push_input(press)
	await process_frame

	var release := InputEventKey.new()
	release.pressed = false
	release.unicode = code
	release.keycode = key
	root.push_input(release)
	await process_frame


func _run() -> void:
	var inst: Node = (load("res://scenes/world/map_view.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	for _i in range(40):
		await process_frame

	var hud: Node = inst.find_child("HUD", true, false)
	if hud == null:
		_record(false, "HUD node exists")
		print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
		quit(1)
		return

	var chat_input: LineEdit = hud.get("chat_input") as LineEdit
	var chat_history: RichTextLabel = hud.get("chat_history") as RichTextLabel
	var btn_channel: Button = hud.get("btn_channel") as Button

	if chat_input != null:
		await _click_rect_center(chat_input.get_global_rect())
		_record(chat_input.has_focus(), "Chat input has focus after a real click")
	else:
		_record(false, "chat_input exists")

	var text_to_type := "hello world"
	for i in range(text_to_type.length()):
		await _type_char(text_to_type[i])
	if chat_input != null:
		_record(chat_input.text == text_to_type, "typed text arrives in the input (got '%s')" % chat_input.text)

	var enter_press := InputEventKey.new()
	enter_press.pressed = true
	enter_press.keycode = KEY_ENTER
	root.push_input(enter_press)
	await process_frame
	var enter_release := InputEventKey.new()
	enter_release.pressed = false
	enter_release.keycode = KEY_ENTER
	root.push_input(enter_release)
	for _i in range(5):
		await process_frame

	var input_cleared: bool = chat_input != null and chat_input.text == ""
	var history_text: String = chat_history.get_parsed_text() if chat_history != null else ""
	_record(input_cleared and history_text.contains("hello world"), "Enter sends: input cleared (%s), history has the line (%s)" % [input_cleared, history_text.contains("hello world")])

	if btn_channel != null:
		await _click_rect_center(btn_channel.get_global_rect())
		for _i in range(3):
			await process_frame
		var dropdown: CanvasItem = hud.get("channel_dropdown") as CanvasItem if "channel_dropdown" in hud else null
		_record(dropdown != null and dropdown.is_visible_in_tree(), "Channel dropdown opens after clicking the channel button")
	else:
		_record(false, "btn_channel exists")

	if hud.has_method("add_chat_message") and chat_history != null:
		for i in range(1, 61):
			hud.call("add_chat_message", "Tester", "line " + str(i), "Local")
		for _i in range(5):
			await process_frame
		var vbar: VScrollBar = chat_history.get_v_scroll_bar()
		var before_val: float = vbar.value
		var hist_rect: Rect2 = chat_history.get_global_rect()
		var hist_center: Vector2 = hist_rect.position + hist_rect.size * 0.5
		for _i in range(3):
			var wheel := InputEventMouseButton.new()
			wheel.button_index = MOUSE_BUTTON_WHEEL_UP
			wheel.pressed = true
			wheel.position = hist_center
			wheel.global_position = hist_center
			root.push_input(wheel)
			await process_frame
		_record(vbar.value < before_val, "Mouse wheel scrolls the log up (before %.1f, after %.1f)" % [before_val, vbar.value])
	else:
		_record(false, "add_chat_message and chat_history exist")

	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
