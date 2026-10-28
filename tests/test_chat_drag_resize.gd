extends SceneTree

## Dragging the gold corner ornament at the chat's top-right resizes the chat.

var _count: int = 0
var _failures: int = 0


func _init() -> void:
	_run()


func _check(ok: bool, label: String) -> void:
	_count += 1
	if ok:
		print("  [PASS] ", label)
	else:
		_failures += 1
		print("  [FAIL] ", label)


func _mouse(button: bool, pressed: bool, y: float) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.global_position = Vector2(500, y)
	return e


func _run() -> void:
	print("--- Chat Drag Resize Suite ---")
	var hud: Control = (load("res://scenes/ui/hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	await process_frame
	await process_frame
	var chat = hud.chat_ctrl
	chat._update_chat_frame_style()
	var handle: Control = hud.get_node_or_null("ChatDock/ChatDragHandle")
	_check(handle != null, "A drag handle exists at the chat's top-right corner")
	var start_top: float = chat.chat_history_panel.offset_top
	handle.gui_input.emit(_mouse(true, true, 300.0))
	var motion := InputEventMouseMotion.new()
	motion.global_position = Vector2(500, 220.0)
	handle.gui_input.emit(motion)
	handle.gui_input.emit(_mouse(true, false, 220.0))
	_check(chat.chat_history_panel.offset_top < start_top, "Dragging up makes the chat taller")
	var grown: float = chat.chat_history_panel.offset_top
	handle.gui_input.emit(_mouse(true, true, 220.0))
	var down := InputEventMouseMotion.new()
	down.global_position = Vector2(500, 280.0)
	handle.gui_input.emit(down)
	handle.gui_input.emit(_mouse(true, false, 280.0))
	_check(chat.chat_history_panel.offset_top > grown, "Dragging down makes it shorter again")
	print("\n--- %d TESTS, %d FAILED ---" % [_count, _failures])
	quit(1 if _failures > 0 else 0)
