extends SceneTree

## Blocked player list (settings Blacklist form): add, refuse duplicates/empty/over-long names,
## delete the selected name, persist to disk, and emit closed on close.

const BlackNameListWindow = preload("res://scripts/ui/hud/black_name_list_window.gd")
const TEST_PATH := "user://test_blacklist.json"

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
	print("--- Black Name List Suite ---")
	await process_frame
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))

	var w = BlackNameListWindow.new()
	w.save_path = TEST_PATH
	root.add_child(w)
	await process_frame
	_record(not w.visible, "the list starts hidden")
	_record(w.names.is_empty(), "a missing save file starts with an empty list")

	_record(w.add_name("  Alpha  "), "a name is trimmed and added")
	_record(w.names == ["Alpha"], "the stored name is the trimmed text")
	_record(not w.add_name("Alpha"), "a duplicate name is refused")
	_record(not w.add_name("   "), "a blank name is refused")
	_record(not w.add_name("ABCDEFGHIJKLMNOP"), "a name longer than 14 characters is refused")
	_record(w.add_name("Beta"), "a second name is added")
	_record(w.is_blocked("Beta") and not w.is_blocked("Gamma"), "is_blocked matches exact names only")

	w._list.select(0)
	_record(w.delete_selected(), "the selected name is deleted")
	_record(w.names == ["Beta"], "only the selected name is removed")
	_record(not w.delete_selected(), "delete does nothing without a selection")

	var reloaded = BlackNameListWindow.new()
	reloaded.save_path = TEST_PATH
	reloaded.load_names()
	_record(reloaded.names == ["Beta"], "the list survives a reload from disk")
	reloaded.free()

	w.open()
	_record(w.visible, "open() shows the list")
	var closed_count := [0]
	w.closed.connect(func() -> void: closed_count[0] += 1)
	w.close()
	_record(not w.visible and closed_count[0] == 1, "close() hides the list and emits closed")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	await _check_hud()
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)


func _check_hud() -> void:
	var inst: Node = (load("res://scenes/world/map_view.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	for i in range(60):
		await process_frame
	var hud = inst.get("hud")
	hud.open_black_name_list()
	_record(hud.black_name_list_window != null and hud.black_name_list_window.visible, "the HUD opens the blocked list")
	var first = hud.black_name_list_window
	hud.open_black_name_list()
	_record(hud.black_name_list_window == first, "a second open reuses the same window")
	inst.queue_free()
