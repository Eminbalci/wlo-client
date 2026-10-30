extends SceneTree

## Headless checks for ChannelWindow (TTH_channelForm 0x29c0cc).
const CW = preload("res://scripts/ui/hud/channel_window.gd")

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
	if FileAccess.file_exists(CW.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CW.SAVE_PATH))
	call_deferred("_run")

func _run() -> void:
	var win: ChannelWindow = load("res://scenes/ui/hud/channel_window.tscn").instantiate()
	root.add_child(win)
	await process_frame
	_check(win.size == Vector2(169, 237) and win.position == Vector2(150, 100), "form (150,100) 169x237")
	_check(win.background.texture != null and win.background.texture.get_size() == Vector2(166, 237), "Form_Channel_1 texture")
	_check(win.toggles.size() == 5, "5 toggles")
	for i in 5:
		_check(win.toggles[i].position == Vector2(86, 47 + 30 * i) and win.toggles[i].size == Vector2(39, 20), "toggle %d rect" % i)
	_check(win.btn_ok.position == Vector2(41, 199) and win.btn_close.position == Vector2(86, 199), "OK/Close")
	_check(win.btn_close.tooltip_text == "[ESC]", "close hint [ESC]")
	_check(win.get_mask() == 31, "all on by default")
	win.open()
	var on_tex := win.toggles[1].texture_normal
	win.toggles[1].pressed.emit()
	_check(not win.is_pending_on("Whisper") and win.is_channel_on("Whisper"), "toggle changes pending only")
	_check(win.toggles[1].texture_normal != on_tex, "bitmap swapped to Off")
	win.close()
	_check(win.is_pending_on("Whisper"), "close discards pending")
	win.open()
	win.toggle_channel("World")
	var got: Array = []
	win.channels_changed.connect(func(s): got.append(s))
	win.btn_ok.pressed.emit()
	_check(got.size() == 1 and got[0]["World"] == false and not win.visible, "OK commits and closes")
	_check(win.get_mask() == 15, "mask without World = 15")
	var win2: ChannelWindow = CW.new()
	_check(not win2.is_channel_on("World") and win2.is_channel_on("Local"), "persisted to user://")
	win2.free()
	_finish()
