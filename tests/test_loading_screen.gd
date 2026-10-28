extends SceneTree

## Headless test suite: authentic loading screen (aLogin.exe decode).
## Verifies assets, node construction, sprite-sheet animation, progress bar and scene hand-off.

const LoadingScreenScript = preload("res://scripts/ui/loading_screen.gd")

var _test_count: int = 0
var _test_failures: int = 0


func _init() -> void:
	_run()


func _run() -> void:
	print("--- Running Loading Screen Test Suite ---")
	await process_frame
	_test_assets()
	await _test_construction_and_layout()
	await _test_animation_and_progress()
	await _test_scene_handoff()
	print("\n--- %d TESTS, %d FAILED ---" % [_test_count, _test_failures])
	quit(1 if _test_failures > 0 else 0)


func _check(condition: bool, label: String) -> void:
	_test_count += 1
	if condition:
		print("  [PASS] ", label)
	else:
		_test_failures += 1
		print("  [FAIL] ", label)


func _make_screen(target: String) -> Control:
	LoadingScreenScript.target_scene = target
	var screen: Control = load(LoadingScreenScript.SCENE_PATH).instantiate()
	root.add_child(screen)
	await process_frame
	screen.set_anchors_preset(Control.PRESET_TOP_LEFT)
	screen.size = Vector2(800, 600)
	screen._layout()
	screen.auto_change_scene = false
	return screen


func _test_assets() -> void:
	print(">>> [TEST 1] Loading assets")
	for path in LoadingScreenScript.BACKGROUNDS:
		var tex := load(path) as Texture2D
		_check(tex != null and tex.get_size() == Vector2(800, 600), "Background %s is 800x600" % path.get_file())
	var pic := load(LoadingScreenScript.LOADING_PIC_PATH) as Texture2D
	_check(pic != null and pic.get_size() == Vector2(291, 104), "NOW LOADING strip is 291x104 (4 frames)")
	var bar := load(LoadingScreenScript.BAR_BACK_PATH) as Texture2D
	_check(bar != null and bar.get_size() == Vector2(275, 10), "Progress bar plate is 275x10")
	var wait := load(LoadingScreenScript.WAIT_PATH) as Texture2D
	_check(wait != null, "Busy bubble sheet loads")
	var img := pic.get_image()
	_check(img.get_pixel(0, 0).a == 0.0, "NOW LOADING chroma key is transparent")


func _test_construction_and_layout() -> void:
	print(">>> [TEST 2] Construction and layout")
	var screen: Control = await _make_screen("")
	for node_name in ["Background", "NowLoading", "BarBack", "Percent", "Busy"]:
		_check(screen.find_child(node_name, true, false) != null, "Node '%s' exists" % node_name)
	var bar: Control = screen.find_child("BarBack", true, false)
	_check(is_equal_approx(bar.position.x + bar.size.x * 0.5, 400.0), "Progress bar horizontally centred")
	screen.size = Vector2(1280, 720)
	screen._layout()
	_check(is_equal_approx(bar.position.x + bar.size.x * 0.5, 640.0), "Layout follows window resize")
	screen.queue_free()


func _test_animation_and_progress() -> void:
	print(">>> [TEST 3] Animation and progress")
	var screen: Control = await _make_screen("")
	screen.set_process(false)
	screen._loading_timer = 0.0
	screen._wait_timer = 0.0
	screen._animate(LoadingScreenScript.LOADING_FRAME_TIME + 0.01)
	_check(screen._loading_frame == 1, "NOW LOADING advances to frame 1")
	for i in 3:
		screen._animate(LoadingScreenScript.LOADING_FRAME_TIME + 0.01)
	_check(screen._loading_frame == 0, "NOW LOADING wraps after 4 frames")
	screen._wait_timer = 0.0
	screen._wait_frame = 0
	screen._animate(LoadingScreenScript.WAIT_FRAME_TIME + 0.01)
	_check(screen._wait_frame == 1, "Busy bubble advances every 500 ms")
	screen.displayed_progress = 0.5
	screen._apply_progress()
	var clip: Control = screen.find_child("BarClip", true, false)
	_check(is_equal_approx(clip.size.x, 138.0), "50% fills 138px of 275px bar")
	_check(screen._percent_label.text == "50%", "Percent label reads 50%")
	screen.queue_free()


func _test_scene_handoff() -> void:
	print(">>> [TEST 4] Scene hand-off")
	var screen: Control = await _make_screen("res://scenes/ui/login_screen.tscn")
	var finished_scene := [""]
	screen.finished.connect(func(p: String) -> void: finished_scene[0] = p)
	_check(screen._requested, "Threaded load requested for existing scene")
	var guard := 0
	while not screen.is_done and guard < 1800:
		await process_frame
		guard += 1
	_check(screen.is_done, "Loading completes")
	_check(screen.displayed_progress >= 1.0, "Progress reaches 100%")
	_check(finished_scene[0] == "res://scenes/ui/login_screen.tscn", "finished signal carries target scene")
	var missing: Control = await _make_screen("res://does/not/exist.tscn")
	_check(not missing._requested, "Missing target does not request a load")
	missing.queue_free()
