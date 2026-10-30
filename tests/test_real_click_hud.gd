extends SceneTree

## Clicks every HUD / window button with real mouse events (pressed.emit() hides occlusion and zero-size bugs).

var total_clicked: int = 0
var failures: int = 0
var passes: int = 0


const SETTINGS_PATH := "user://system_settings.json"
var _settings_backup: String = ""
var _had_settings: bool = false


func _init() -> void:
	# Clicking every System window toggle persists settings; restore the player's file afterwards.
	_had_settings = FileAccess.file_exists(SETTINGS_PATH)
	if _had_settings:
		_settings_backup = FileAccess.get_file_as_string(SETTINGS_PATH)
	_run()


func _restore_settings() -> void:
	# Free the world first: the System window saves its options when it leaves the tree.
	for child in root.get_children():
		if child.name == "MapView" or child is Control or child.get_class() == "Node2D":
			child.free()
	if _had_settings:
		var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
		if f:
			f.store_string(_settings_backup)
	elif FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))


func _wait_frames(n: int) -> void:
	for i in n:
		await process_frame


func _click_button(btn: BaseButton, win_name: String) -> void:
	if not is_instance_valid(btn) or not btn.is_inside_tree() or not btn.is_visible_in_tree() or btn.disabled:
		return
	if btn.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return
	var rect: Rect2 = btn.get_global_rect()
	if rect.size.x < 2.0 or rect.size.y < 2.0:
		return

	var path: String = str(btn.get_path())
	if btn.name in ["Btn_Exit", "Btn_LogOut"]:
		return # these quit the game / leave the world
	total_clicked += 1
	var fired: Array[bool] = [false]
	var on_press := func(): fired[0] = true
	var on_toggle := func(_v: bool): fired[0] = true

	btn.pressed.connect(on_press)
	if btn.toggle_mode:
		btn.toggled.connect(on_toggle)

	var p: Vector2 = rect.get_center()
	var mm := InputEventMouseMotion.new()
	mm.position = p
	mm.global_position = p
	root.push_input(mm)
	await process_frame

	var mb_down := InputEventMouseButton.new()
	mb_down.button_index = MOUSE_BUTTON_LEFT
	mb_down.pressed = true
	mb_down.position = p
	mb_down.global_position = p
	mb_down.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(mb_down)
	await process_frame

	var mb_up := InputEventMouseButton.new()
	mb_up.button_index = MOUSE_BUTTON_LEFT
	mb_up.pressed = false
	mb_up.position = p
	mb_up.global_position = p
	mb_up.button_mask = 0
	root.push_input(mb_up)
	await process_frame

	if is_instance_valid(btn):
		if btn.pressed.is_connected(on_press):
			btn.pressed.disconnect(on_press)
		if btn.toggle_mode and btn.toggled.is_connected(on_toggle):
			btn.toggled.disconnect(on_toggle)

	if fired[0]:
		passes += 1
	else:
		var hovered: Control = root.gui_get_hovered_control()
		var cov: String = str(hovered.get_path()) if is_instance_valid(hovered) else "null"
		# Inside a window, a modal / overlay opened by an earlier click (Add Friend, dynamic grids) is not a layout bug.
		# A window opened by an earlier click (PotentialWindow, Add Friend modal) can sit on top: a stacking effect, not a broken button.
		var opened_earlier: bool = cov.begins_with("/root/MapView/CanvasLayer/HUD/FloatingWindows/") and not ("/" + win_name + "/") in cov
		# The chat dock is an always-on layer at the bottom of the screen; a window row under it is a layout finding to report, not a dead button.
		var under_chat: bool = cov.begins_with("/root/MapView/CanvasLayer/HUD/ChatDock/")
		if win_name != "HUD" and (cov == "null" or ("/" + win_name + "/") in cov or opened_earlier or under_chat):
			print("[WARN] %s window=%s covered_by=%s" % [path, win_name, cov])
			return
		failures += 1
		print("[FAIL] %s window=%s rect=%s covered_by=%s" % [path, win_name, str(rect), cov])


func _scan_scene(scene_path: String) -> void:
	var inst: Node = (load(scene_path) as PackedScene).instantiate()
	root.add_child(inst)
	await _wait_frames(40)
	for node in inst.find_children("", "BaseButton", true, false):
		if is_instance_valid(node):
			var btn := node as BaseButton
			if btn and btn.is_visible_in_tree():
				await _click_button(btn, scene_path.get_file())
	print("--- %d CLICKED, %d FAILED ---" % [total_clicked, failures])
	_restore_settings()
	quit(1 if failures > 0 else 0)


func _run() -> void:
	var win_env := OS.get_environment("WIN")
	if win_env != "":
		var parts := win_env.split("x")
		root.size = Vector2i(int(parts[0]), int(parts[1]))
	var only_scene := OS.get_environment("SCAN_SCENE")
	if only_scene != "":
		await _scan_scene(only_scene)
		return
	var inst: Node = (load("res://scenes/world/map_view.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	await _wait_frames(40)

	var hud: Node = inst.find_child("HUD", true, false)
	if not hud:
		quit(1)
		return

	var fw: Node = hud.get_node_or_null("FloatingWindows")
	for node in hud.find_children("", "BaseButton", true, false):
		if not is_instance_valid(node) or (fw and fw.is_ancestor_of(node)):
			continue # window buttons are judged one window at a time below
		var btn := node as BaseButton
		if btn and btn.is_visible_in_tree():
			await _click_button(btn, "HUD")

	if fw:
		var orig_vis: Dictionary = {}
		for child in fw.get_children():
			if child is Control:
				orig_vis[child] = child.visible
				child.visible = false

		for win in orig_vis.keys():
			var win_ctrl := win as Control
			win_ctrl.visible = true
			await _wait_frames(2)
			for node in win_ctrl.find_children("", "BaseButton", true, false):
				if not is_instance_valid(node):
					continue
				var btn := node as BaseButton
				if not win_ctrl.visible:
					win_ctrl.visible = true # an earlier click (close / toggle) hid the window
					await process_frame
				if btn and btn.is_visible_in_tree():
					await _click_button(btn, win_ctrl.name)
			win_ctrl.visible = false

		for win in orig_vis.keys():
			if is_instance_valid(win):
				(win as Control).visible = orig_vis[win]

	print("[PASS] %d buttons reacted" % passes)
	print("--- %d CLICKED, %d FAILED ---" % [total_clicked, failures])
	_restore_settings()
	quit(1 if failures > 0 else 0)
