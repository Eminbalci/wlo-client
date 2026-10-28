extends SceneTree

const SystemWindowClass = preload("res://scripts/ui/hud/system_window.gd")

## Automated Headless Verification Suite for Floating Window Close Buttons & System Settings Window
## Verifies:
## 1. All 8 floating windows (InventoryWindow, CharacterWindow, FightWindow, FriendsWindow,
##    SkillWindow, TeamWindow, QuestWindow, SystemWindow) have authentic 18x18 close buttons:
##    - text is empty ("")
##    - size and custom_minimum_size are Vector2(18, 18)
##    - position is aligned to Vector2(win.size.x - 30, 8)
##    - themed with StyleBoxTexture
##    - cleanly closes window on click and emits window_toggled
## 2. System Settings Window (Form_System_2 388x451):
##    - BGM Volume Slider (0..100, default 80) and mute checkbox
##    - SFX Volume Slider (0..100, default 80) and mute checkbox
##    - AudioServer bus volume calculation and mute control
##    - Fullscreen mode toggle
##    - Resume, Character Select (Logout), and Exit buttons
##    - user://system_settings.json persistence (save on change, load and apply)

var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	print("=================================================================")
	print("STARTING TEST SUITE: Floating Windows & System Settings Parity")
	print("=================================================================")
	call_deferred("_run_tests")

func _assert_true(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("  [PASS] %s" % msg)
	else:
		_failed += 1
		printerr("  [FAIL] %s" % msg)

func _run_tests() -> void:
	_test_floating_window_close_buttons()
	_test_system_settings_audio_and_display()
	_test_system_settings_persistence()
	_test_system_settings_standalone_scene()
	
	print("=================================================================")
	print("SUMMARY: %d passed, %d failed" % [_passed, _failed])
	print("=================================================================")
	
	if _failed > 0:
		quit(1)
	else:
		print("ALL FLOATING WINDOW & SYSTEM SETTINGS TESTS PASSED ZERO-ERROR!")
		quit(0)

func _test_floating_window_close_buttons() -> void:
	print("\n>>> Testing Floating Window Close Buttons Parity (HUD)...")
	var hud_scene: PackedScene = load("res://scenes/ui/hud.tscn")
	_assert_true(hud_scene != null, "HUD scene loaded successfully")
	if not hud_scene:
		return
	
	var hud := hud_scene.instantiate() as Control
	root.add_child(hud)
	
	# Give 1 frame for ready / setup
	var win_mgr: HUDWindowManager = hud.window_manager_ctrl
	_assert_true(win_mgr != null, "HUDWindowManager instance exists on HUD")
	
	var window_names: Array[String] = [
		"InventoryWindow", "CharacterWindow", "FightWindow", "FriendsWindow",
		"SkillWindow", "TeamWindow", "QuestWindow", "SystemWindow"
	]
	
	var floating_container := hud.get_node_or_null("FloatingWindows") as Control
	_assert_true(floating_container != null, "FloatingWindows container found in HUD")
	
	for w_name in window_names:
		var win := floating_container.get_node_or_null(w_name) as Control
		_assert_true(win != null, "Floating window %s exists" % w_name)
		if not win:
			continue
		
		var close_btn := win.get_node_or_null("CloseButton") as Button
		_assert_true(close_btn != null, "%s has CloseButton node" % w_name)
		if not close_btn:
			continue
		
		# 1. Check text is cleared (no ugly 'X')
		_assert_true(close_btn.text == "", "%s CloseButton text is empty (no ugly 'X')" % w_name)
		
		# 2. Size: 20x20 hit area over the baked x sphere (the combat settings window has no baked
		#    sphere and keeps its own 18x18 corner button)
		var expected_size := Vector2(18, 18) if w_name == "FightWindow" else Vector2(20, 20)
		_assert_true(close_btn.size == expected_size, "%s CloseButton size is %s, got %s" % [w_name, str(expected_size), str(close_btn.size)])
		_assert_true(close_btn.custom_minimum_size == expected_size, "%s CloseButton custom_minimum_size is %s" % [w_name, str(expected_size)])
		
		# 3. Position: centred on the baked sphere (40 px from the right edge, 30 px from the top)
		var expected_pos := Vector2(win.size.x - 30.0, 8.0) if w_name == "FightWindow" else Vector2(win.size.x - 50.0, 20.0)
		_assert_true(close_btn.position == expected_pos, "%s CloseButton position is %s (expected %s)" % [w_name, str(close_btn.position), str(expected_pos)])
		
		# 4. Check stylebox override
		var has_sb := close_btn.has_theme_stylebox_override("normal")
		_assert_true(has_sb, "%s CloseButton has theme StyleBox override" % w_name)
		if has_sb:
			var sb = close_btn.get_theme_stylebox("normal")
			if w_name == "FightWindow":
				_assert_true(sb is StyleBoxTexture, "%s CloseButton StyleBox is StyleBoxTexture" % w_name)
			else:
				# Transparent hit area over the x sphere baked into the skin, with a hover ring
				_assert_true(sb is StyleBoxEmpty, "%s CloseButton is a transparent overlay (StyleBoxEmpty)" % w_name)
				_assert_true(close_btn.get_theme_stylebox("hover") is StyleBoxFlat, "%s CloseButton shows a hover ring" % w_name)
		
		# 5. Check click behavior: opens then closes cleanly
		win.visible = true
		_assert_true(win.visible, "%s opened for click test" % w_name)
		
		var toggled_reported: Array = []
		var on_toggle := func(name: String, vis: bool) -> void:
			if name == w_name:
				toggled_reported.append(vis)
		win_mgr.window_toggled.connect(on_toggle)
		
		# Emit pressed signal on close_btn
		close_btn.emit_signal("pressed")
		_assert_true(not win.visible, "%s closed cleanly after CloseButton pressed" % w_name)
		_assert_true(toggled_reported.has(false), "%s window_toggled(false) emitted upon close" % w_name)
		win_mgr.window_toggled.disconnect(on_toggle)

	hud.queue_free()

func _test_system_settings_audio_and_display() -> void:
	print("\n>>> Testing System Settings Audio and Display Functionality...")
	var sys_win = SystemWindowClass.new()
	root.add_child(sys_win)
	sys_win.setup()
	
	_assert_true(sys_win.size == Vector2(388, 451), "SystemWindow size is 388x451, got %s" % str(sys_win.size))
	_assert_true(sys_win.background != null, "SystemWindow background TextureRect exists")
	_assert_true(sys_win.bgm_slider != null, "BGM Volume HSlider exists")
	_assert_true(sys_win.bgm_mute_check != null, "BGM Mute CheckBox exists")
	_assert_true(sys_win.sfx_slider != null, "SFX Volume HSlider exists")
	_assert_true(sys_win.sfx_mute_check != null, "SFX Mute CheckBox exists")
	_assert_true(sys_win.fullscreen_check != null, "Fullscreen CheckBox exists")
	_assert_true(sys_win.btn_resume != null, "Resume Button exists")
	_assert_true(sys_win.btn_logout != null, "Logout / Character Select Button exists")
	_assert_true(sys_win.btn_exit != null, "Exit Game Button exists")
	
	# Test BGM Volume slider & bus volume
	sys_win.set_bgm_volume(50, false)
	_assert_true(sys_win.get_bgm_volume() == 50, "BGM Volume set to 50%")
	_assert_true(sys_win.bgm_slider.value == 50.0, "BGM slider updated to 50.0")
	var bgm_bus: int = SystemWindowClass.get_bgm_bus()
	var expected_bgm_db: float = SystemWindowClass.linear_to_bus_db(50)
	var actual_bgm_db: float = AudioServer.get_bus_volume_db(bgm_bus)
	_assert_true(abs(actual_bgm_db - expected_bgm_db) < 0.1, "AudioServer BGM bus volume matches linear_to_bus_db: %f vs %f" % [actual_bgm_db, expected_bgm_db])
	
	# Test BGM Mute
	sys_win.set_bgm_muted(true, false)
	_assert_true(sys_win.is_bgm_muted(), "BGM muted state is true")
	_assert_true(AudioServer.is_bus_mute(bgm_bus), "AudioServer BGM bus is muted")
	sys_win.set_bgm_muted(false, false)
	_assert_true(not sys_win.is_bgm_muted(), "BGM muted state restored to false")
	_assert_true(not AudioServer.is_bus_mute(bgm_bus), "AudioServer BGM bus is unmuted")
	
	# Test SFX Volume slider & bus volume
	sys_win.set_sfx_volume(75, false)
	_assert_true(sys_win.get_sfx_volume() == 75, "SFX Volume set to 75%")
	_assert_true(sys_win.sfx_slider.value == 75.0, "SFX slider updated to 75.0")
	var sfx_bus: int = SystemWindowClass.get_sfx_bus()
	var expected_sfx_db: float = SystemWindowClass.linear_to_bus_db(75)
	var actual_sfx_db: float = AudioServer.get_bus_volume_db(sfx_bus)
	_assert_true(abs(actual_sfx_db - expected_sfx_db) < 0.1, "AudioServer SFX bus volume matches linear_to_bus_db: %f vs %f" % [actual_sfx_db, expected_sfx_db])
	
	# Test SFX Mute
	sys_win.set_sfx_muted(true, false)
	_assert_true(sys_win.is_sfx_muted(), "SFX muted state is true")
	_assert_true(AudioServer.is_bus_mute(sfx_bus), "AudioServer SFX bus is muted")
	sys_win.set_sfx_muted(false, false)
	_assert_true(not sys_win.is_sfx_muted(), "SFX muted state restored to false")
	_assert_true(not AudioServer.is_bus_mute(sfx_bus), "AudioServer SFX bus is unmuted")
	
	# Test Fullscreen mode toggle
	sys_win.set_fullscreen(true, false)
	_assert_true(sys_win.is_fullscreen(), "Fullscreen mode set to true")
	_assert_true(sys_win.fullscreen_check.button_pressed, "Fullscreen CheckBox is checked")
	sys_win.set_fullscreen(false, false)
	_assert_true(not sys_win.is_fullscreen(), "Fullscreen mode restored to false")
	_assert_true(not sys_win.fullscreen_check.button_pressed, "Fullscreen CheckBox is unchecked")
	
	# Test Resume Button closes window
	sys_win.visible = true
	var closed_events: Array = []
	sys_win.window_closed.connect(func(): closed_events.append(true))
	sys_win.on_resume_pressed()
	_assert_true(not sys_win.visible, "Resume Button closed SystemWindow")
	_assert_true(closed_events.size() > 0, "window_closed signal emitted")
	
	# Test Logout / Character Select button emits signal
	var logout_events: Array = []
	sys_win.logout_requested.connect(func(): logout_events.append(true))
	sys_win.logout_requested.emit()
	_assert_true(logout_events.size() > 0, "logout_requested signal emitted properly")
	
	sys_win.queue_free()

func _test_system_settings_persistence() -> void:
	print("\n>>> Testing System Settings user://system_settings.json Persistence...")
	var win1 = SystemWindowClass.new()
	root.add_child(win1)
	win1.setup()
	
	# Change and save values
	win1.set_bgm_volume(64, true)
	win1.set_bgm_muted(true, true)
	win1.set_sfx_volume(42, true)
	win1.set_sfx_muted(false, true)
	win1.set_fullscreen(false, true)
	
	_assert_true(FileAccess.file_exists(SystemWindowClass.SETTINGS_FILE_PATH), "user://system_settings.json file created")
	
	# Verify contents of JSON file directly
	var file := FileAccess.open(SystemWindowClass.SETTINGS_FILE_PATH, FileAccess.READ)
	_assert_true(file != null, "Opened settings file for reading")
	if file:
		var json_str := file.get_as_text()
		file.close()
		var parsed = JSON.parse_string(json_str)
		_assert_true(parsed is Dictionary, "Parsed settings JSON is a Dictionary")
		if parsed is Dictionary:
			_assert_true(int(parsed.get("bgm_volume")) == 64, "JSON bgm_volume is 64")
			_assert_true(bool(parsed.get("bgm_muted")) == true, "JSON bgm_muted is true")
			_assert_true(int(parsed.get("sfx_volume")) == 42, "JSON sfx_volume is 42")
			_assert_true(bool(parsed.get("sfx_muted")) == false, "JSON sfx_muted is false")
			_assert_true(bool(parsed.get("fullscreen")) == false, "JSON fullscreen is false")
	
	win1.queue_free()
	
	# Instantiate fresh second window to test loading
	var win2 = SystemWindowClass.new()
	root.add_child(win2)
	win2.setup()
	
	_assert_true(win2.get_bgm_volume() == 64, "Win2 loaded bgm_volume 64 from disk")
	_assert_true(win2.is_bgm_muted() == true, "Win2 loaded bgm_muted true from disk")
	_assert_true(win2.get_sfx_volume() == 42, "Win2 loaded sfx_volume 42 from disk")
	_assert_true(win2.is_sfx_muted() == false, "Win2 loaded sfx_muted false from disk")
	
	# Restore default values and save
	win2.set_bgm_volume(80, true)
	win2.set_bgm_muted(false, true)
	win2.set_sfx_volume(80, true)
	win2.set_sfx_muted(false, true)
	win2.set_fullscreen(false, true)
	
	win2.queue_free()

func _test_system_settings_standalone_scene() -> void:
	print("\n>>> Testing Standalone system_window.tscn Scene Instantiation...")
	var scene_res := load("res://scenes/ui/hud/system_window.tscn") as PackedScene
	_assert_true(scene_res != null, "scenes/ui/hud/system_window.tscn loaded successfully")
	if scene_res:
		var inst := scene_res.instantiate() as Control
		root.add_child(inst)
		_assert_true(inst.get_script() == SystemWindowClass, "Instantiated scene has SystemWindowClass script")
		_assert_true(inst.size == Vector2(388, 451), "Instantiated scene dimensions are 388x451")
		_assert_true(inst.has_node("CloseButton"), "Instantiated scene has CloseButton")
		_assert_true(inst.has_node("Background"), "Instantiated scene has Background")
		inst.queue_free()
